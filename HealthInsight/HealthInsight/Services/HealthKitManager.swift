import Foundation
import HealthKit

@Observable
final class HealthKitManager {
    let healthStore = HKHealthStore()
    var isAuthorized = false
    var todayData: DailyHealthData = .empty()
    var trendData: TrendData = TrendData()
    var isLoading = false
    var errorMessage: String?

    // MARK: - All HealthKit types we want to read

    private var allQuantityTypes: Set<HKQuantityType> {
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .distanceWalkingRunning,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .appleExerciseTime,
            .appleStandTime,
            .bodyMass,
            .height,
            .bodyMassIndex,
            .bodyFatPercentage,
            .heartRate,
            .restingHeartRate,
            .walkingHeartRateAverage,
            .heartRateVariabilitySDNN,
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .oxygenSaturation,
            .respiratoryRate,
            .bodyTemperature,
            .dietaryWater,
            .dietaryCaffeine
        ]
        return Set(identifiers.map { HKQuantityType($0) })
    }

    private var allCategoryTypes: Set<HKCategoryType> {
        Set([
            HKCategoryType(.sleepAnalysis)
        ])
    }

    private var allTypesToRead: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        allQuantityTypes.forEach { types.insert($0) }
        allCategoryTypes.forEach { types.insert($0) }
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "此设备不支持 HealthKit"
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: allTypesToRead)
            isAuthorized = true
        } catch {
            errorMessage = "请求健康数据权限失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Fetch Today's Data

    func fetchTodayData() async {
        isLoading = true
        errorMessage = nil

        let data = await withTaskGroup(of: PartialHealthData.self) { group in
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)

            // Activity queries (statistics - cumulative)
            group.addTask { await self.fetchActivityData(start: startOfDay, end: now) }

            // Sleep query
            group.addTask { await self.fetchSleepData(referenceDate: now) }

            // Body measurements (latest sample)
            group.addTask { await self.fetchBodyData() }

            // Vitals (latest sample)
            group.addTask { await self.fetchVitalsData() }

            // Nutrition (statistics - cumulative)
            group.addTask { await self.fetchNutritionData(start: startOfDay, end: now) }

            // Mindfulness
            group.addTask { await self.fetchMindfulnessData(start: startOfDay, end: now) }

            var result = DailyHealthData.empty(date: now)
            for await partial in group {
                switch partial {
                case .activity(let d): result.activity = d
                case .sleep(let d): result.sleep = d
                case .body(let d): result.body = d
                case .vitals(let d): result.vitals = d
                case .nutrition(let d): result.nutrition = d
                case .mindfulness(let d): result.mindfulness = d
                }
            }
            return result
        }

        todayData = data
        isLoading = false
    }

    // MARK: - Activity Data

    private func fetchActivityData(start: Date, end: Date) async -> PartialHealthData {
        var activity = ActivityData()

        async let steps = queryStatisticsSum(for: .stepCount, unit: .count(), start: start, end: end)
        async let distance = queryStatisticsSum(for: .distanceWalkingRunning, unit: .meter(), start: start, end: end)
        async let activeCal = queryStatisticsSum(for: .activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
        async let basalCal = queryStatisticsSum(for: .basalEnergyBurned, unit: .kilocalorie(), start: start, end: end)
        async let exercise = queryStatisticsSum(for: .appleExerciseTime, unit: .minute(), start: start, end: end)
        async let stand = queryStatisticsSum(for: .appleStandTime, unit: .minute(), start: start, end: end)

        activity.steps = await steps
        activity.distance = await distance
        activity.activeCalories = await activeCal
        activity.basalCalories = await basalCal
        activity.exerciseMinutes = await exercise
        if let standMinutes = await stand {
            activity.standHours = standMinutes / 60.0
        }

        return .activity(activity)
    }

    // MARK: - Sleep Data

    private func fetchSleepData(referenceDate: Date) async -> PartialHealthData {
        var sleep = SleepData()

        let calendar = Calendar.current
        // Query sleep from yesterday 6 PM to today 6 PM
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate) else {
            return .sleep(sleep)
        }
        var startComponents = calendar.dateComponents([.year, .month, .day], from: yesterday)
        startComponents.hour = 18
        var endComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        endComponents.hour = 18

        guard let start = calendar.date(from: startComponents),
              let end = calendar.date(from: endComponents) else {
            return .sleep(sleep)
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sleepType = HKCategoryType(.sleepAnalysis)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
                ) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: results as? [HKCategorySample] ?? [])
                    }
                }
                healthStore.execute(query)
            }

            guard !samples.isEmpty else { return .sleep(sleep) }

            var awakeSeconds: Double = 0
            var remSeconds: Double = 0
            var coreSeconds: Double = 0
            var deepSeconds: Double = 0
            var totalSleepSeconds: Double = 0
            var earliestBedtime: Date?
            var latestWakeTime: Date?

            for sample in samples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)

                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                    coreSeconds += duration
                    totalSleepSeconds += duration
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    coreSeconds += duration
                    totalSleepSeconds += duration
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    deepSeconds += duration
                    totalSleepSeconds += duration
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    remSeconds += duration
                    totalSleepSeconds += duration
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    awakeSeconds += duration
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    // Track bedtime/wake time from inBed samples
                    if earliestBedtime == nil || sample.startDate < earliestBedtime! {
                        earliestBedtime = sample.startDate
                    }
                    if latestWakeTime == nil || sample.endDate > latestWakeTime! {
                        latestWakeTime = sample.endDate
                    }
                default:
                    break
                }

                // Also track bedtime/wake from sleep samples if no inBed
                if sample.value != HKCategoryValueSleepAnalysis.awake.rawValue &&
                   sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue {
                    if earliestBedtime == nil || sample.startDate < earliestBedtime! {
                        earliestBedtime = sample.startDate
                    }
                    if latestWakeTime == nil || sample.endDate > latestWakeTime! {
                        latestWakeTime = sample.endDate
                    }
                }
            }

            if totalSleepSeconds > 0 { sleep.totalDuration = totalSleepSeconds }
            if awakeSeconds > 0 { sleep.awakeMinutes = awakeSeconds / 60.0 }
            if remSeconds > 0 { sleep.remMinutes = remSeconds / 60.0 }
            if coreSeconds > 0 { sleep.coreMinutes = coreSeconds / 60.0 }
            if deepSeconds > 0 { sleep.deepMinutes = deepSeconds / 60.0 }
            sleep.bedtime = earliestBedtime
            sleep.wakeTime = latestWakeTime

        } catch {
            // Sleep query failed, return empty
        }

        return .sleep(sleep)
    }

    // MARK: - Body Data

    private func fetchBodyData() async -> PartialHealthData {
        var body = BodyData()

        async let weight = queryLatestSample(for: .bodyMass, unit: .gramUnit(with: .kilo))
        async let height = queryLatestSample(for: .height, unit: .meterUnit(with: .centi))
        async let bmi = queryLatestSample(for: .bodyMassIndex, unit: .count())
        async let bodyFat = queryLatestSample(for: .bodyFatPercentage, unit: .percent())

        body.weight = await weight
        body.height = await height
        body.bmi = await bmi
        if let fatValue = await bodyFat {
            body.bodyFatPercentage = fatValue * 100 // Convert from 0.xx to xx%
        }

        return .body(body)
    }

    // MARK: - Vitals Data

    private func fetchVitalsData() async -> PartialHealthData {
        var vitals = VitalsData()

        async let restingHR = queryLatestSample(for: .restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let walkingHR = queryLatestSample(for: .walkingHeartRateAverage, unit: HKUnit.count().unitDivided(by: .minute()))
        async let hrv = queryLatestSample(for: .heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let sysBP = queryLatestSample(for: .bloodPressureSystolic, unit: .millimeterOfMercury())
        async let diaBP = queryLatestSample(for: .bloodPressureDiastolic, unit: .millimeterOfMercury())
        async let spo2 = queryLatestSample(for: .oxygenSaturation, unit: .percent())
        async let respRate = queryLatestSample(for: .respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let temp = queryLatestSample(for: .bodyTemperature, unit: .degreeCelsius())

        vitals.restingHeartRate = await restingHR
        vitals.walkingHeartRate = await walkingHR
        vitals.heartRateVariability = await hrv
        vitals.bloodPressureSystolic = await sysBP
        vitals.bloodPressureDiastolic = await diaBP
        if let spo2Value = await spo2 {
            vitals.bloodOxygen = spo2Value * 100 // Convert from 0.xx to xx%
        }
        vitals.respiratoryRate = await respRate
        vitals.bodyTemperature = await temp

        return .vitals(vitals)
    }

    // MARK: - Nutrition Data

    private func fetchNutritionData(start: Date, end: Date) async -> PartialHealthData {
        var nutrition = NutritionData()

        async let water = queryStatisticsSum(for: .dietaryWater, unit: .literUnit(with: .milli), start: start, end: end)
        async let caffeine = queryStatisticsSum(for: .dietaryCaffeine, unit: .gramUnit(with: .milli), start: start, end: end)

        nutrition.water = await water
        nutrition.caffeine = await caffeine

        return .nutrition(nutrition)
    }

    // MARK: - Mindfulness Data

    private func fetchMindfulnessData(start: Date, end: Date) async -> PartialHealthData {
        var mindfulness = MindfulnessData()

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let mindfulType = HKCategoryType(.mindfulSession)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                let query = HKSampleQuery(
                    sampleType: mindfulType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                ) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: results as? [HKCategorySample] ?? [])
                    }
                }
                healthStore.execute(query)
            }

            let totalMinutes = samples.reduce(0.0) { sum, sample in
                sum + sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            }
            if totalMinutes > 0 {
                mindfulness.mindfulMinutes = totalMinutes
            }
        } catch {
            // Mindfulness query failed
        }

        return .mindfulness(mindfulness)
    }

    // MARK: - Generic Query Helpers

    /// Query cumulative statistics (sum) for a quantity type over a date range
    private func queryStatisticsSum(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async -> Double? {
        let quantityType = HKQuantityType(identifier)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        do {
            return try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let value = result?.sumQuantity()?.doubleValue(for: unit)
                    continuation.resume(returning: value)
                }
                healthStore.execute(query)
            }
        } catch {
            return nil
        }
    }

    // MARK: - Trend Data (30-day sleep + today's heart rate)

    func fetchTrendData() async {
        async let sleepTrend = fetchSleepTrend(days: 30)
        async let hrSamples = fetchTodayHeartRateSamples()
        trendData.sleepTrend = await sleepTrend
        trendData.heartRateSamples = await hrSamples
    }

    private func fetchSleepTrend(days: Int) async -> [TrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        var points: [TrendPoint] = []

        for dayOffset in (1...days).reversed() {
            guard let refDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: refDate) else { continue }

            var startComp = calendar.dateComponents([.year, .month, .day], from: prevDay)
            startComp.hour = 18
            var endComp = calendar.dateComponents([.year, .month, .day], from: refDate)
            endComp.hour = 18

            guard let start = calendar.date(from: startComp),
                  let end = calendar.date(from: endComp) else { continue }

            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let sleepType = HKCategoryType(.sleepAnalysis)

            do {
                let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                    let query = HKSampleQuery(
                        sampleType: sleepType,
                        predicate: predicate,
                        limit: HKObjectQueryNoLimit,
                        sortDescriptors: nil
                    ) { _, results, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: results as? [HKCategorySample] ?? [])
                        }
                    }
                    healthStore.execute(query)
                }

                var totalSleep: Double = 0
                for sample in samples {
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                         HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                         HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                         HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
                    default:
                        break
                    }
                }

                let hours = totalSleep / 3600.0
                if hours > 0 {
                    let dayStart = calendar.startOfDay(for: refDate)
                    points.append(TrendPoint(date: dayStart, value: hours))
                }
            } catch {
                // Skip this day on error
            }
        }

        return points
    }

    private func fetchTodayHeartRateSamples() async -> [HeartRatePoint] {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let hrType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
                let query = HKSampleQuery(
                    sampleType: hrType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
                ) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: results as? [HKQuantitySample] ?? [])
                    }
                }
                healthStore.execute(query)
            }

            return samples.map { sample in
                HeartRatePoint(
                    time: sample.startDate,
                    bpm: sample.quantity.doubleValue(for: bpmUnit)
                )
            }
        } catch {
            return []
        }
    }

    /// Query the most recent sample for a quantity type
    private func queryLatestSample(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> Double? {
        let quantityType = HKQuantityType(identifier)

        do {
            return try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: quantityType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                ) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let sample = results?.first as? HKQuantitySample
                    let value = sample?.quantity.doubleValue(for: unit)
                    continuation.resume(returning: value)
                }
                healthStore.execute(query)
            }
        } catch {
            return nil
        }
    }
}

// MARK: - Internal enum to merge parallel results

private enum PartialHealthData {
    case activity(ActivityData)
    case sleep(SleepData)
    case body(BodyData)
    case vitals(VitalsData)
    case nutrition(NutritionData)
    case mindfulness(MindfulnessData)
}

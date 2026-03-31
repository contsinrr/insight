import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("今日", systemImage: "sun.max.fill")
                }

            ReportHistoryView()
                .tabItem {
                    Label("报告", systemImage: "doc.richtext.fill")
                }

            SettingsView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
        }
        .tint(Color(red: 0.45, green: 0.40, blue: 0.85))
    }
}

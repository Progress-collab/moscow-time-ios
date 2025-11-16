import SwiftUI

@main
struct MoscowTimeApp: App {
    @StateObject private var alarmStore = AlarmStore()
    
    init() {
        // Запрашиваем разрешение на уведомления при запуске
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmStore)
                .onAppear {
                    // Обновляем все будильники при запуске приложения
                    AlarmManager.shared.updateAllAlarms(alarmStore.alarms)
                }
        }
    }
    
    private func requestNotificationPermission() {
        AlarmManager.shared.requestAuthorization { granted in
            if granted {
                // Обновляем все будильники после получения разрешения
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    AlarmManager.shared.updateAllAlarms(alarmStore.alarms)
                }
            }
        }
    }
}


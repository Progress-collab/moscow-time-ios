import Foundation
import UserNotifications

class AlarmManager {
    static let shared = AlarmManager()
    private let moscowTimeZone = TimeZone(identifier: "Europe/Moscow")!
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleAlarm(_ alarm: Alarm) {
        guard alarm.isEnabled else {
            removeAlarm(alarm)
            return
        }
        
        let center = UNUserNotificationCenter.current()
        
        // Удаляем старые уведомления для этого будильника
        removeAlarm(alarm)
        
        // Создаем уведомление для каждого дня недели
        for weekday in alarm.weekdays {
            let content = UNMutableNotificationContent()
            content.title = alarm.name ?? "Будильник"
            content.body = "Время: \(alarm.timeString)"
            content.sound = .default
            content.categoryIdentifier = "ALARM"
            
            // Настраиваем триггер для конкретного дня недели
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = alarm.hour
            dateComponents.minute = alarm.minute
            dateComponents.timeZone = moscowTimeZone
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let identifier = "\(alarm.id.uuidString)-\(weekday)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Ошибка при создании уведомления: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func removeAlarm(_ alarm: Alarm) {
        let center = UNUserNotificationCenter.current()
        let identifiers = alarm.weekdays.map { "\(alarm.id.uuidString)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func updateAllAlarms(_ alarms: [Alarm]) {
        // Удаляем все старые уведомления
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Создаем новые уведомления для включенных будильников
        for alarm in alarms where alarm.isEnabled {
            scheduleAlarm(alarm)
        }
    }
    
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
}


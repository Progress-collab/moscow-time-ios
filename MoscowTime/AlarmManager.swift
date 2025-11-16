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
        
        let content = UNMutableNotificationContent()
        content.title = alarm.name ?? "Будильник"
        content.sound = .default
        content.categoryIdentifier = "ALARM"
        
        if alarm.isOneTime {
            // Разовый будильник
            guard let oneTimeDate = alarm.oneTimeDate else { return }
            
            // Проверяем, что дата в будущем
            if oneTimeDate <= Date() {
                print("Разовый будильник не может быть в прошлом")
                return
            }
            
            let calendar = Calendar.current
            let components = calendar.dateComponents(in: moscowTimeZone, from: oneTimeDate)
            
            let formatter = DateFormatter()
            formatter.timeZone = moscowTimeZone
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "d MMMM yyyy, HH:mm"
            content.body = formatter.string(from: oneTimeDate)
            
            var dateComponents = DateComponents()
            dateComponents.year = components.year
            dateComponents.month = components.month
            dateComponents.day = components.day
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            dateComponents.timeZone = moscowTimeZone
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let identifier = "\(alarm.id.uuidString)-onetime"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Ошибка при создании разового уведомления: \(error.localizedDescription)")
                }
            }
        } else {
            // Повторяющийся будильник
            content.body = "Время: \(alarm.timeString)"
            
            // Создаем уведомление для каждого дня недели
            for weekday in alarm.weekdays {
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
    }
    
    func removeAlarm(_ alarm: Alarm) {
        let center = UNUserNotificationCenter.current()
        var identifiers: [String]
        
        if alarm.isOneTime {
            identifiers = ["\(alarm.id.uuidString)-onetime"]
        } else {
            identifiers = alarm.weekdays.map { "\(alarm.id.uuidString)-\($0)" }
        }
        
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


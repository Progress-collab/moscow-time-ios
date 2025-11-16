import Foundation

struct Alarm: Identifiable, Codable {
    let id: UUID
    var hour: Int
    var minute: Int
    var weekdays: Set<Int> // 1=воскресенье, 2=понедельник, ..., 7=суббота
    var isEnabled: Bool
    var name: String?
    
    init(id: UUID = UUID(), hour: Int, minute: Int, weekdays: Set<Int> = [2, 3, 4, 5, 6], isEnabled: Bool = true, name: String? = nil) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.isEnabled = isEnabled
        self.name = name
    }
    
    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }
    
    var weekdaysString: String {
        let weekdayNames = [
            1: "Вс",
            2: "Пн",
            3: "Вт",
            4: "Ср",
            5: "Чт",
            6: "Пт",
            7: "Сб"
        ]
        
        if weekdays.count == 7 {
            return "Каждый день"
        } else if weekdays == [2, 3, 4, 5, 6] {
            return "Рабочие дни"
        } else if weekdays.count == 1 {
            return weekdayNames[weekdays.first!] ?? ""
        } else {
            let sorted = weekdays.sorted()
            return sorted.compactMap { weekdayNames[$0] }.joined(separator: ", ")
        }
    }
    
    func nextTriggerDate(in timeZone: TimeZone) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        let moscowCalendar = calendar
        var moscowComponents = moscowCalendar.dateComponents(in: timeZone, from: now)
        
        moscowComponents.hour = hour
        moscowComponents.minute = minute
        moscowComponents.second = 0
        
        guard let todayDate = moscowCalendar.date(from: moscowComponents) else { return nil }
        
        let weekday = moscowCalendar.component(.weekday, from: now)
        
        // Проверяем сегодняшний день
        if weekdays.contains(weekday) && todayDate > now {
            return todayDate
        }
        
        // Ищем следующий подходящий день
        for dayOffset in 1...7 {
            guard let futureDate = moscowCalendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let futureWeekday = moscowCalendar.component(.weekday, from: futureDate)
            
            if weekdays.contains(futureWeekday) {
                var components = moscowCalendar.dateComponents(in: timeZone, from: futureDate)
                components.hour = hour
                components.minute = minute
                components.second = 0
                return moscowCalendar.date(from: components)
            }
        }
        
        return nil
    }
}


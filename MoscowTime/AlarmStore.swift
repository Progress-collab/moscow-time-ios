import Foundation
import Combine

class AlarmStore: ObservableObject {
    @Published var alarms: [Alarm] = []
    
    private let userDefaultsKey = "MoscowTimeAlarms"
    
    init() {
        loadAlarms()
    }
    
    func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decoded
        }
    }
    
    func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            saveAlarms()
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            saveAlarms()
        }
    }
}


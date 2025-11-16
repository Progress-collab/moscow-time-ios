import SwiftUI

struct AlarmEditView: View {
    @ObservedObject var alarmStore: AlarmStore
    @Environment(\.dismiss) var dismiss
    
    private let alarmManager = AlarmManager.shared
    
    let alarm: Alarm?
    
    @State private var selectedHour: Int = 7
    @State private var selectedMinute: Int = 0
    @State private var weekdays: Set<Int> = [2, 3, 4, 5, 6] // Рабочие дни по умолчанию
    @State private var name: String = ""
    @State private var isEnabled: Bool = true
    
    private let weekdayNames = [
        1: "Воскресенье",
        2: "Понедельник",
        3: "Вторник",
        4: "Среда",
        5: "Четверг",
        6: "Пятница",
        7: "Суббота"
    ]
    
    init(alarmStore: AlarmStore, alarm: Alarm?) {
        self.alarmStore = alarmStore
        self.alarm = alarm
        
        if let alarm = alarm {
            _selectedHour = State(initialValue: alarm.hour)
            _selectedMinute = State(initialValue: alarm.minute)
            _weekdays = State(initialValue: alarm.weekdays)
            _name = State(initialValue: alarm.name ?? "")
            _isEnabled = State(initialValue: alarm.isEnabled)
            _isOneTime = State(initialValue: alarm.isOneTime)
            _oneTimeDate = State(initialValue: alarm.oneTimeDate ?? Date())
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Разовый будильник", isOn: $isOneTime)
                }
                
                Section("Время") {
                    if isOneTime {
                        DatePicker("Дата и время", selection: $oneTimeDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    } else {
                        DatePicker("Время", selection: Binding(
                            get: {
                                let calendar = Calendar.current
                                var components = DateComponents()
                                components.hour = selectedHour
                                components.minute = selectedMinute
                                return calendar.date(from: components) ?? Date()
                            },
                            set: { date in
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.hour, .minute], from: date)
                                selectedHour = components.hour ?? 7
                                selectedMinute = components.minute ?? 0
                            }
                        ), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    }
                }
                
                Section("Название (необязательно)") {
                    TextField("Название будильника", text: $name)
                }
                
                if !isOneTime {
                    Section("Дни недели") {
                    Button(action: {
                        weekdays = [2, 3, 4, 5, 6] // Рабочие дни
                    }) {
                        HStack {
                            Text("Рабочие дни")
                            Spacer()
                            if weekdays == [2, 3, 4, 5, 6] {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Button(action: {
                        weekdays = Set(1...7) // Каждый день
                    }) {
                        HStack {
                            Text("Каждый день")
                            Spacer()
                            if weekdays == Set(1...7) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Divider()
                    
                    ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { day in
                        Toggle(weekdayNames[day] ?? "", isOn: Binding(
                            get: { weekdays.contains(day) },
                            set: { isOn in
                                if isOn {
                                    weekdays.insert(day)
                                } else {
                                    weekdays.remove(day)
                                }
                            }
                        ))
                    }
                    }
                }
                
                Section {
                    Toggle("Включен", isOn: $isEnabled)
                }
            }
            .navigationTitle(alarm == nil ? "Новый будильник" : "Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveAlarm()
                    }
                    .disabled(!isOneTime && weekdays.isEmpty)
                }
            }
        }
    }
    
    private func saveAlarm() {
        let calendar = Calendar.current
        let moscowTimeZone = TimeZone(identifier: "Europe/Moscow")!
        
        var finalHour = selectedHour
        var finalMinute = selectedMinute
        var finalOneTimeDate: Date? = nil
        
        if isOneTime {
            // Для разового будильника извлекаем час и минуту из oneTimeDate
            let components = calendar.dateComponents(in: moscowTimeZone, from: oneTimeDate)
            finalHour = components.hour ?? 7
            finalMinute = components.minute ?? 0
            finalOneTimeDate = oneTimeDate
        }
        
        let newAlarm = Alarm(
            id: alarm?.id ?? UUID(),
            hour: finalHour,
            minute: finalMinute,
            weekdays: isOneTime ? [] : weekdays,
            isEnabled: isEnabled,
            name: name.isEmpty ? nil : name,
            isOneTime: isOneTime,
            oneTimeDate: finalOneTimeDate
        )
        
        if let existingAlarm = alarm {
            alarmStore.updateAlarm(newAlarm)
            if newAlarm.isEnabled {
                alarmManager.scheduleAlarm(newAlarm)
            } else {
                alarmManager.removeAlarm(newAlarm)
            }
        } else {
            alarmStore.addAlarm(newAlarm)
            if newAlarm.isEnabled {
                alarmManager.scheduleAlarm(newAlarm)
            }
        }
        
        dismiss()
    }
}

#Preview {
    AlarmEditView(alarmStore: AlarmStore(), alarm: nil)
}


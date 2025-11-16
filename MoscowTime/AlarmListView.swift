import SwiftUI

struct AlarmListView: View {
    @ObservedObject var alarmStore: AlarmStore
    @State private var showingAddAlarm = false
    @State private var editingAlarm: Alarm?
    @State private var showingPermissionAlert = false
    
    private let alarmManager = AlarmManager.shared
    
    var body: some View {
        NavigationView {
            List {
                if alarmStore.alarms.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Нет будильников")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Нажмите + чтобы добавить будильник")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(alarmStore.alarms) { alarm in
                        AlarmRowView(alarm: alarm, alarmStore: alarmStore)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingAlarm = alarm
                            }
                    }
                    .onDelete(perform: deleteAlarms)
                }
            }
            .navigationTitle("Будильники")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        checkPermissionAndShowAdd()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AlarmEditView(alarmStore: alarmStore, alarm: nil)
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmEditView(alarmStore: alarmStore, alarm: alarm)
            }
            .alert("Разрешение на уведомления", isPresented: $showingPermissionAlert) {
                Button("Настройки") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Для работы будильников необходимо разрешение на уведомления. Пожалуйста, разрешите уведомления в настройках.")
            }
            .onAppear {
                checkPermission()
            }
        }
    }
    
    private func checkPermission() {
        alarmManager.checkAuthorizationStatus { status in
            if status == .denied {
                showingPermissionAlert = true
            }
        }
    }
    
    private func checkPermissionAndShowAdd() {
        alarmManager.checkAuthorizationStatus { status in
            if status == .notDetermined {
                alarmManager.requestAuthorization { granted in
                    if granted {
                        showingAddAlarm = true
                    } else {
                        showingPermissionAlert = true
                    }
                }
            } else if status == .denied {
                showingPermissionAlert = true
            } else {
                showingAddAlarm = true
            }
        }
    }
    
    private func deleteAlarms(at offsets: IndexSet) {
        for index in offsets {
            let alarm = alarmStore.alarms[index]
            alarmManager.removeAlarm(alarm)
            alarmStore.deleteAlarm(alarm)
        }
    }
}

struct AlarmRowView: View {
    let alarm: Alarm
    @ObservedObject var alarmStore: AlarmStore
    @StateObject private var alarmManager = AlarmManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(size: 32, weight: .light, design: .default))
                
                Text(alarm.weekdaysString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let name = alarm.name, !name.isEmpty {
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { newValue in
                    var updatedAlarm = alarm
                    updatedAlarm.isEnabled = newValue
                    alarmStore.updateAlarm(updatedAlarm)
                    if newValue {
                        alarmManager.scheduleAlarm(updatedAlarm)
                    } else {
                        alarmManager.removeAlarm(updatedAlarm)
                    }
                }
            ))
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AlarmListView(alarmStore: AlarmStore())
}


import SwiftUI

struct ContentView: View {
    @State private var currentTime = Date()
    @StateObject private var alarmStore = AlarmStore()
    let moscowTimeZone = TimeZone(identifier: "Europe/Moscow")!
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Москва")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(dayOfWeek)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(timeString)
                    .font(.system(size: 64, weight: .light, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text(dateString)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                NavigationLink(destination: AlarmListView(alarmStore: alarmStore)) {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Будильники")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.timeZone = moscowTimeZone
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: currentTime).capitalized
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeZone = moscowTimeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.timeZone = moscowTimeZone
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: currentTime)
    }
}

#Preview {
    ContentView()
}


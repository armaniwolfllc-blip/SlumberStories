//
//  NotificationService.swift
//  SlumberStories
//

import Foundation
import UserNotifications
import Combine

class NotificationService: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var bedtimeHour: Int = 20
    @Published var bedtimeMinute: Int = 0

    private let enabledKey = "notificationsEnabled"
    private let hourKey = "bedtimeHour"
    private let minuteKey = "bedtimeMinute"

    private let messages = [
        ("Time for tonight's story! 🌙", "Pick an adventure and drift into dreamland..."),
        ("The stars are calling! ✨", "A magical bedtime story is waiting for you..."),
        ("Story time! 🚀", "Tonight's adventure is about to begin..."),
        ("Sweet dreams start here 🌊", "Jump into a bedtime story before sleep..."),
        ("Adventure awaits! 🌿", "Time to curl up for tonight's bedtime story..."),
        ("The moon is rising 🏔️", "Your bedtime story is ready and waiting..."),
        ("Dreamland is calling 👑", "A new story is ready for tonight..."),
        ("Time to wind down 🦁", "Start tonight's bedtime adventure now..."),
        ("Bedtime story time! ⭐", "Keep your streak alive with tonight's story..."),
        ("Settle in for the night 🎵", "A wonderful adventure awaits you tonight...")
    ]

    init() { loadSettings() }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.isEnabled = granted
                completion(granted)
                if granted { self.scheduleNotifications() }
            }
        }
    }

    func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard isEnabled else { return }

        for day in 0..<14 {
            let message = messages[day % messages.count]
            let content = UNMutableNotificationContent()
            content.title = message.0
            content.body = message.1
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = bedtimeHour
            dateComponents.minute = bedtimeMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "bedtime_\(day)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
        saveSettings()
    }

    func disableNotifications() {
        isEnabled = false
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        saveSettings()
    }

    func updateTime(hour: Int, minute: Int) {
        bedtimeHour = hour
        bedtimeMinute = minute
        if isEnabled { scheduleNotifications() }
        saveSettings()
    }

    func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isEnabled = settings.authorizationStatus == .authorized &&
                    UserDefaults.standard.bool(forKey: self.enabledKey)
            }
        }
    }

    func formattedTime() -> String {
        let hour12 = bedtimeHour == 0 ? 12 : (bedtimeHour > 12 ? bedtimeHour - 12 : bedtimeHour)
        let ampm = bedtimeHour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, bedtimeMinute, ampm)
    }

    private func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: enabledKey)
        UserDefaults.standard.set(bedtimeHour, forKey: hourKey)
        UserDefaults.standard.set(bedtimeMinute, forKey: minuteKey)
    }

    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        bedtimeHour = UserDefaults.standard.object(forKey: hourKey) != nil
            ? UserDefaults.standard.integer(forKey: hourKey) : 20
        bedtimeMinute = UserDefaults.standard.object(forKey: minuteKey) != nil
            ? UserDefaults.standard.integer(forKey: minuteKey) : 0
        checkPermissionStatus()
    }
}

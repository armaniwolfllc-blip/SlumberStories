import SwiftUI
import AVFoundation
import Combine
import UIKit

// MARK: - Models
struct Adventure: Identifiable {
    let id = UUID()
    let key: String
    let name: String
    let emoji: String
    let vibe: String
    let color: Color
    let ambientEmoji: String
}

struct StoryHistory: Identifiable, Codable {
    let id: UUID
    let childName: String
    let adventureKey: String
    let adventureName: String
    let adventureEmoji: String
    let storyText: String
    let date: Date
    let ageGroup: String
    var isFavorite: Bool

    init(childName: String, adventureKey: String, adventureName: String, adventureEmoji: String, storyText: String, ageGroup: String, isFavorite: Bool = false) {
        self.id = UUID()
        self.childName = childName
        self.adventureKey = adventureKey
        self.adventureName = adventureName
        self.adventureEmoji = adventureEmoji
        self.storyText = storyText
        self.date = Date()
        self.ageGroup = ageGroup
        self.isFavorite = isFavorite
    }
}

struct ChildInfo: Codable, Identifiable {
    let id: UUID
    var name: String
    var ageGroup: String

    init(name: String, ageGroup: String) {
        self.id = UUID()
        self.name = name
        self.ageGroup = ageGroup
    }
}

struct ChildProfile: Codable {
    var children: [ChildInfo]
    var petName: String?
    var primaryChild: ChildInfo { children[0] }
}

// MARK: - Streak Manager
class StreakManager: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var showMilestone: Bool = false
    @Published var milestoneText: String = ""

    private let streakKey = "currentStreak"
    private let longestKey = "longestStreak"
    private let lastDateKey = "lastStoryDate"

    init() { loadStreak() }

    func recordStoryTonight() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date

        if let last = lastDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 0 { return }
            else if diff == 1 { currentStreak += 1 }
            else { currentStreak = 1 }
        } else { currentStreak = 1 }

        if currentStreak > longestStreak { longestStreak = currentStreak }
        UserDefaults.standard.set(today, forKey: lastDateKey)
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestKey)
        checkMilestone()
    }

    func checkMilestone() {
        switch currentStreak {
        case 3: triggerMilestone("3 nights in a row! 🌟")
        case 7: triggerMilestone("1 week streak! 🔥 Amazing!")
        case 14: triggerMilestone("2 week streak! 🚀 Incredible!")
        case 30: triggerMilestone("30 nights! 🏆 Legendary!")
        case 50: triggerMilestone("50 nights! 👑 Unstoppable!")
        case 100: triggerMilestone("100 nights! 🌙 Hall of Fame!")
        default: break
        }
    }

    func triggerMilestone(_ text: String) {
        milestoneText = text
        showMilestone = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.showMilestone = false }
    }

    func loadStreak() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestKey)
        if let lastDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date {
            let today = Calendar.current.startOfDay(for: Date())
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff > 1 { currentStreak = 0; UserDefaults.standard.set(0, forKey: streakKey) }
        }
    }

    var streakEmoji: String {
        switch currentStreak {
        case 0: return "moon.stars.fill"
        case 1...2: return "star.fill"
        case 3...6: return "sparkles"
        case 7...13: return "flame.fill"
        case 14...29: return "rocket.fill"
        case 30...49: return "trophy.fill"
        case 50...99: return "crown.fill"
        default: return "moon.stars.fill"
        }
    }
}

// MARK: - Data
let adventures: [Adventure] = [
    Adventure(key: "magical", name: "Magical Kingdom", emoji: "wand.and.stars", vibe: "Wizards & wonder", color: Color(red: 0.24, green: 0.10, blue: 0.43), ambientEmoji: "🎵"),
    Adventure(key: "ocean", name: "Ocean Deep", emoji: "water.waves", vibe: "Mermaids & whales", color: Color(red: 0.05, green: 0.24, blue: 0.43), ambientEmoji: "🌊"),
    Adventure(key: "timetravel", name: "Time Travel", emoji: "clock.arrow.trianglehead.counterclockwise.rotate.90", vibe: "Dinosaurs & history", color: Color(red: 0.11, green: 0.23, blue: 0.10), ambientEmoji: "🌿"),
    Adventure(key: "flying", name: "Sky Journey", emoji: "wind", vibe: "Clouds & dragons", color: Color(red: 0.10, green: 0.23, blue: 0.36), ambientEmoji: "💨"),
    Adventure(key: "jungle", name: "Jungle Quest", emoji: "leaf.fill", vibe: "Animals & temples", color: Color(red: 0.05, green: 0.17, blue: 0.05), ambientEmoji: "🦜"),
    Adventure(key: "mountain", name: "Mountain Peak", emoji: "mountain.2.fill", vibe: "Courage & snowflakes", color: Color(red: 0.16, green: 0.10, blue: 0.04), ambientEmoji: "❄️"),
    Adventure(key: "space", name: "Space Explorer", emoji: "sparkles", vibe: "Stars & galaxies", color: Color(red: 0.03, green: 0.03, blue: 0.16), ambientEmoji: "⭐"),
    Adventure(key: "desert", name: "Desert Safari", emoji: "sun.max.fill", vibe: "Lions & camels", color: Color(red: 0.23, green: 0.10, blue: 0.00), ambientEmoji: "🌅")
]

let ageGroups: [(label: String, emoji: String, description: String)] = [
    (label: "2-4", emoji: "🧸", description: "Toddler"),
    (label: "5-7", emoji: "🌟", description: "Early"),
    (label: "8-10", emoji: "🔭", description: "Explorer"),
    (label: "11-13", emoji: "🚀", description: "Preteen")
]

// MARK: - Main App View
struct ContentView: View {
    @State private var selectedTab = 0
    @State private var selectedAdventure: Adventure? = nil
    @State private var currentStory = ""
    @State private var currentAdventure: Adventure? = nil
    @State private var showPlayer = false
    @State private var showPaywall = false
    @State private var historyItems: [StoryHistory] = []
    @State private var childProfile: ChildProfile? = nil
    @State private var showParentSetup = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @StateObject private var claudeService = ClaudeService()
    @StateObject private var streakManager = StreakManager()
    @StateObject private var storeManager = StoreManager()

    var favoriteItems: [StoryHistory] { historyItems.filter { $0.isFavorite } }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.04, blue: 0.10).ignoresSafeArea()

            if showOnboarding {
                OnboardingView(onComplete: {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    withAnimation { showOnboarding = false }
                })
                .transition(.opacity)
            } else if showParentSetup || childProfile == nil {
                ParentSetupView(childProfile: $childProfile, onDone: { showParentSetup = false })
            } else if showPlayer, let adventure = currentAdventure, let profile = childProfile {
                StoryPlayerView(
                    adventure: adventure,
                    childName: profile.primaryChild.name,
                    storyText: currentStory,
                    isFavorite: historyItems.first(where: { $0.storyText == currentStory })?.isFavorite ?? false,
                    onBack: { showPlayer = false },
                    onToggleFavorite: { toggleFavorite(storyText: currentStory) }
                )
            } else {
                mainTabView
            }

            if streakManager.showMilestone {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                        Text(streakManager.milestoneText)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24).padding(.vertical, 16)
                    .background(LinearGradient(colors: [Color(red: 0.58, green: 0.20, blue: 0.92), Color(red: 0.75, green: 0.15, blue: 0.82)], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(20).shadow(radius: 20)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4), value: streakManager.showMilestone)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { loadHistory(); loadProfile() }
        .sheet(isPresented: $showPaywall) {
            PaywallView(storeManager: storeManager)
        }
    }

    var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                selectedAdventure: $selectedAdventure,
                childProfile: childProfile,
                isGenerating: claudeService.isGenerating,
                streakManager: streakManager,
                storeManager: storeManager,
                onStart: startStory,
                onEditProfile: { showParentSetup = true }
            )
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            FavoritesView(
                favoriteItems: favoriteItems,
                onPlay: { item in
                    if let adventure = adventures.first(where: { $0.key == item.adventureKey }) {
                        currentAdventure = adventure
                        currentStory = item.storyText
                        showPlayer = true
                    }
                }
            )
            .tabItem { Label("Favourites", systemImage: "star.fill") }
            .tag(1)

            HistoryView(
                historyItems: $historyItems,
                onPlay: { item in
                    if let adventure = adventures.first(where: { $0.key == item.adventureKey }) {
                        currentAdventure = adventure
                        currentStory = item.storyText
                        showPlayer = true
                    }
                },
                onToggleFavorite: { item in toggleFavorite(storyText: item.storyText) }
            )
            .tabItem { Label("History", systemImage: "book.fill") }
            .tag(2)
        }
        .tint(Color(red: 0.75, green: 0.51, blue: 1.0))
    }

    func startStory() {
        guard let adventure = selectedAdventure, let profile = childProfile else { return }
        if storeManager.shouldShowPaywall() {
            showPaywall = true
            return
        }
        claudeService.generateStory(adventure: adventure.name, children: profile.children, petName: profile.petName) { story in
            currentStory = story
            currentAdventure = adventure
            showPlayer = true
            saveToHistory(adventure: adventure, story: story)
            streakManager.recordStoryTonight()
            storeManager.incrementStoriesUsed()
        }
    }

    func toggleFavorite(storyText: String) {
        if let index = historyItems.firstIndex(where: { $0.storyText == storyText }) {
            historyItems[index].isFavorite.toggle()
            if let data = try? JSONEncoder().encode(historyItems) {
                UserDefaults.standard.set(data, forKey: "storyHistory")
            }
        }
    }

    func saveToHistory(adventure: Adventure, story: String) {
        guard let profile = childProfile else { return }
        let item = StoryHistory(childName: profile.primaryChild.name, adventureKey: adventure.key, adventureName: adventure.name, adventureEmoji: adventure.emoji, storyText: story, ageGroup: profile.primaryChild.ageGroup)
        historyItems.insert(item, at: 0)
        if let data = try? JSONEncoder().encode(historyItems) {
            UserDefaults.standard.set(data, forKey: "storyHistory")
        }
    }

    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "storyHistory"),
           let items = try? JSONDecoder().decode([StoryHistory].self, from: data) {
            historyItems = items
        }
    }

    func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: "childProfile"),
           let profile = try? JSONDecoder().decode(ChildProfile.self, from: data) {
            childProfile = profile
        }
    }
}

// MARK: - Parent Setup View
struct ParentSetupView: View {
    @Binding var childProfile: ChildProfile?
    let onDone: () -> Void

    @State private var numberOfChildren = 1
    @State private var childNames: [String] = ["", "", "", ""]
    @State private var childAges: [String] = ["5-7", "5-7", "5-7", "5-7"]
    @State private var petName = ""
    @State private var addPet = false
    @State private var step = 1
    @StateObject private var notificationService = NotificationService()
    @State private var selectedTime = Date()

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.04, blue: 0.10).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    if step == 1 { howManySection }
                    else if step == 2 { childDetailsSection }
                    else { notificationSection }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            if let existing = childProfile {
                numberOfChildren = existing.children.count
                for (i, child) in existing.children.enumerated() {
                    if i < 4 { childNames[i] = child.name; childAges[i] = child.ageGroup }
                }
                if let pet = existing.petName { petName = pet; addPet = true }
                step = 2
            }
            var components = DateComponents()
            components.hour = notificationService.bedtimeHour
            components.minute = notificationService.bedtimeMinute
            if let date = Calendar.current.date(from: components) { selectedTime = date }
        }
    }

    var howManySection: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                Text("Parent Setup")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                Text("Let's set up your family's story experience!")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)

            VStack(alignment: .leading, spacing: 16) {
                Text("HOW MANY CHILDREN?")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                    .kerning(1)
                HStack(spacing: 12) {
                    ForEach(1...4, id: \.self) { count in
                        Button(action: { numberOfChildren = count }) {
                            VStack(spacing: 6) {
                                Image(systemName: count == 1 ? "person.fill" : count == 2 ? "person.2.fill" : "person.3.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                                Text("\(count)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(numberOfChildren == count ? Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.5) : Color.white.opacity(0.06))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(numberOfChildren == count ? Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.8) : Color.clear, lineWidth: 1.5))
                            .scaleEffect(numberOfChildren == count ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3), value: numberOfChildren)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.2), lineWidth: 1))

            Button(action: { step = 2 }) {
                Text("Next →")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(16)
                    .background(LinearGradient(colors: [Color(red: 0.58, green: 0.20, blue: 0.92), Color(red: 0.75, green: 0.15, blue: 0.82)], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(16)
            }
            .padding(.bottom, 40)
        }
    }

    var childDetailsSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                Text("Tell us about your kids")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
            }
            .padding(.top, 50)

            ForEach(0..<numberOfChildren, id: \.self) { i in childCard(index: i) }

            VStack(alignment: .leading, spacing: 12) {
                Button(action: { addPet.toggle() }) {
                    HStack(spacing: 12) {
                        Image(systemName: addPet ? "pawprint.fill" : "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                        Text(addPet ? "Pet added!" : "Add a pet to the story")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                        Spacer()
                    }
                    .padding(16)
                    .background(addPet ? Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.3) : Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(addPet ? Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.5) : Color.clear, lineWidth: 1))
                }
                if addPet {
                    TextField("Pet's name...", text: $petName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.3), lineWidth: 1.5))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.2), lineWidth: 1))

            HStack(spacing: 12) {
                Button(action: { step = 1 }) {
                    Text("← Back")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Color.white.opacity(0.08)).cornerRadius(16)
                }
                Button(action: { step = 3 }) {
                    Text("Next →")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(16)
                        .background(canSave ? AnyView(LinearGradient(colors: [Color(red: 0.58, green: 0.20, blue: 0.92), Color(red: 0.75, green: 0.15, blue: 0.82)], startPoint: .leading, endPoint: .trailing)) : AnyView(Color.gray.opacity(0.3)))
                        .cornerRadius(16)
                }
                .disabled(!canSave)
            }
            .padding(.bottom, 40)
        }
    }

    var notificationSection: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                Text("Bedtime Reminder")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                Text("Get a nightly reminder to start story time")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 50)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable reminder")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                        Text("Daily notification at bedtime")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { notificationService.isEnabled },
                        set: { newValue in
                            if newValue {
                                notificationService.requestPermission { granted in
                                    if granted {
                                        let hour = Calendar.current.component(.hour, from: selectedTime)
                                        let minute = Calendar.current.component(.minute, from: selectedTime)
                                        notificationService.updateTime(hour: hour, minute: minute)
                                    }
                                }
                            } else {
                                notificationService.disableNotifications()
                            }
                        }
                    ))
                    .tint(Color(red: 0.58, green: 0.20, blue: 0.92))
                }
                .padding(16)
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)

                if notificationService.isEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BEDTIME")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                            .kerning(1)
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .onChange(of: selectedTime) { newTime in
                                let hour = Calendar.current.component(.hour, from: newTime)
                                let minute = Calendar.current.component(.minute, from: newTime)
                                notificationService.updateTime(hour: hour, minute: minute)
                            }
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(Color(red: 0.75, green: 0.51, blue: 1.0))
                            Text("Reminder set for \(notificationService.formattedTime()) every night")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.spring(response: 0.3), value: notificationService.isEnabled)
                }
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.2), lineWidth: 1))

            HStack(spacing: 12) {
                Button(action: { step = 2 }) {
                    Text("← Back")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Color.white.opacity(0.08)).cornerRadius(16)
                }
                Button(action: saveProfile) {
                    Text("✨ Save & Start")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(16)
                        .background(AnyView(LinearGradient(colors: [Color(red: 0.58, green: 0.20, blue: 0.92), Color(red: 0.75, green: 0.15, blue: 0.82)], startPoint: .leading, endPoint: .trailing)))
                        .cornerRadius(16)
                }
            }
            .padding(.bottom, 40)
        }
    }

    func childCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHILD \(index + 1)\(index == 0 ? " (Main Hero)" : "")")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                .kerning(1)
            TextField("Enter name...", text: $childNames[index])
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(14)
                .background(Color.white.opacity(0.08))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.3), lineWidth: 1.5))
                .foregroundColor(.white)
            HStack(spacing: 8) {
                ForEach(ageGroups, id: \.label) { group in
                    Button(action: { childAges[index] = group.label }) {
                        VStack(spacing: 2) {
                            Text(group.emoji).font(.system(size: 18))
                            Text(group.label).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(childAges[index] == group.label ? Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.5) : Color.white.opacity(0.06))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(childAges[index] == group.label ? Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.8) : Color.clear, lineWidth: 1.5))
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.94, green: 0.78, blue: 1.0).opacity(index == 0 ? 0.4 : 0.2), lineWidth: index == 0 ? 1.5 : 1))
    }

    var canSave: Bool {
        for i in 0..<numberOfChildren {
            if childNames[i].trimmingCharacters(in: .whitespaces).isEmpty { return false }
        }
        return true
    }

    func saveProfile() {
        var children: [ChildInfo] = []
        for i in 0..<numberOfChildren {
            children.append(ChildInfo(name: childNames[i], ageGroup: childAges[i]))
        }
        let pet = addPet && !petName.isEmpty ? petName : nil
        let profile = ChildProfile(children: children, petName: pet)
        childProfile = profile
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "childProfile")
        }
        onDone()
    }
}

// MARK: - Home View
struct HomeView: View {
    @Binding var selectedAdventure: Adventure?
    let childProfile: ChildProfile?
    let isGenerating: Bool
    let streakManager: StreakManager
    let storeManager: StoreManager
    let onStart: () -> Void
    let onEditProfile: () -> Void
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.04, blue: 0.10).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    streakCard
                    if !storeManager.isPremiumUnlocked {
                        freeStoriesCard
                    }
                    welcomeCard
                    adventureGrid
                    startButton
                }
                .padding(.horizontal)
            }
        }
    }

    var headerSection: some View {
        ZStack {
            VStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                Text("Dreamy Wolf")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                Text("Magical bedtime adventures, just for you")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: onEditProfile) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                            .padding(10)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .frame(height: 120)
        }
        .padding(.top, 40)
    }

    var freeStoriesCard: some View {
        let remaining = max(0, 3 - storeManager.storiesUsed)
        return HStack(spacing: 14) {
            Image(systemName: remaining == 0 ? "lock.fill" : "gift.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
            VStack(alignment: .leading, spacing: 3) {
                Text(remaining == 0 ? "Free stories used up!" : "\(remaining) free \(remaining == 1 ? "story" : "stories") remaining")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                Text(remaining == 0 ? "Unlock premium for unlimited stories" : "Try Dreamy Wolf Premium for unlimited access")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
            }
            Spacer()
        }
        .padding(16)
        .background(remaining == 0 ? Color(red: 0.4, green: 0.05, blue: 0.05).opacity(0.5) : Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.2))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(remaining == 0 ? Color.red.opacity(0.4) : Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.3), lineWidth: 1))
    }

    var streakCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 36))
                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
            VStack(alignment: .leading, spacing: 3) {
                if streakManager.currentStreak == 0 {
                    Text("Start your streak tonight!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                    Text("Read a story every night to build your streak")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                } else {
                    Text("\(streakManager.currentStreak) night\(streakManager.currentStreak == 1 ? "" : "s") in a row!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                    Text("Best: \(streakManager.longestStreak) nights · Keep it up!")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                }
            }
            Spacer()
            if streakManager.currentStreak > 0 {
                VStack(spacing: 2) {
                    Text("\(streakManager.currentStreak)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    Text("streak")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                }
            }
        }
        .padding(16)
        .background(
            streakManager.currentStreak >= 7
            ? LinearGradient(colors: [Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.3), Color(red: 0.75, green: 0.15, blue: 0.82).opacity(0.2)], startPoint: .leading, endPoint: .trailing)
            : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)], startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(streakManager.currentStreak >= 7 ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4) : Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.2), lineWidth: 1))
    }

    @ViewBuilder
    var welcomeCard: some View {
        if let profile = childProfile {
            HStack(spacing: 14) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                VStack(alignment: .leading, spacing: 3) {
                    let names = profile.children.map { $0.name }.joined(separator: ", ")
                    Text("Hello, \(names)!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                    if let pet = profile.petName {
                        Text("\(pet) is joining the adventure!")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.75, green: 0.51, blue: 1.0))
                    } else {
                        Text("Ready for tonight's story?")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.2))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.3), lineWidth: 1))
        }
    }

    var adventureGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHOOSE YOUR ADVENTURE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                .kerning(1)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(adventures) { adventure in
                    AdventureCard(
                        adventure: adventure,
                        isSelected: selectedAdventure?.key == adventure.key,
                        onTap: { selectedAdventure = adventure }
                    )
                }
            }
        }
    }

    var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView().tint(.white)
                    Text("Creating your story...")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Text("✨ Begin Your Story")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).padding(16)
            .background(selectedAdventure == nil || isGenerating ? AnyView(Color.gray.opacity(0.3)) : AnyView(LinearGradient(colors: [Color(red: 0.58, green: 0.20, blue: 0.92), Color(red: 0.75, green: 0.15, blue: 0.82)], startPoint: .leading, endPoint: .trailing)))
            .cornerRadius(16)
        }
        .disabled(selectedAdventure == nil || isGenerating)
        .padding(.bottom, 40)
    }
}

// MARK: - Adventure Card
struct AdventureCard: View {
    let adventure: Adventure
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: adventure.emoji)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                Text(adventure.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white).multilineTextAlignment(.center)
                Text(adventure.vibe)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(adventure.color).cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(isSelected ? Color.white.opacity(0.8) : Color.clear, lineWidth: 2.5))
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

// MARK: - Story Player View
struct StoryPlayerView: View {
    let adventure: Adventure
    let childName: String
    let storyText: String
    let isFavorite: Bool
    let onBack: () -> Void
    let onToggleFavorite: () -> Void

    @StateObject private var elevenLabs = ElevenLabsService()
    @StateObject private var imageService = ImageGenerationService()
    @State private var ambientAudio = AmbientAudioService()
    @State private var words: [String] = []
    @State private var currentWordIndex = 0
    @State private var timer: Timer? = nil
    @State private var ambientVolume: Double = 0.35
    @State private var progress: Double = 0
    @State private var showFavoriteAnimation = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.04, blue: 0.10).ignoresSafeArea()
            VStack(spacing: 0) {
                playerHeader
                ScrollView {
                    VStack(spacing: 20) {
                        adventureBanner
                        if elevenLabs.isLoading { loadingView }
                        if let error = elevenLabs.errorMessage {
                            Text("⚠️ \(error)").font(.system(size: 13)).foregroundColor(.red.opacity(0.8)).padding()
                        }
                        storyTextView
                        progressBar
                        playerControls
                        ambientControl
                        thetaIndicator
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            if showFavoriteAnimation {
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .scaleEffect(showFavoriteAnimation ? 1.2 : 0.1)
                    .opacity(showFavoriteAnimation ? 1 : 0)
                    .animation(.spring(response: 0.4), value: showFavoriteAnimation)
            }
        }
        .onAppear {
            words = storyText.components(separatedBy: " ")
            startStory()
            ambientAudio.play(adventureKey: adventure.key, volume: Float(ambientVolume))
            imageService.generateIllustration(adventure: adventure.name, childName: childName, adventureKey: adventure.key)
        }
        .onDisappear { elevenLabs.stop(); stopWordTimer(); ambientAudio.stop() }
        .onChange(of: ambientVolume) { newVolume in ambientAudio.setVolume(Float(newVolume)) }
    }

    var playerHeader: some View {
        HStack {
            Button(action: { elevenLabs.stop(); stopWordTimer(); ambientAudio.stop(); onBack() }) {
                Text("← Back")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.77, green: 0.69, blue: 0.91))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.white.opacity(0.08)).cornerRadius(10)
            }
            Spacer()
            Text(adventure.name)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
            Spacer()
            Button(action: {
                onToggleFavorite()
                if !isFavorite {
                    showFavoriteAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { showFavoriteAnimation = false }
                }
            }) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 22))
                    .foregroundColor(isFavorite ? Color(red: 1.0, green: 0.84, blue: 0.0) : Color(red: 0.61, green: 0.54, blue: 0.75))
                    .padding(10).background(Color.white.opacity(0.08)).clipShape(Circle())
            }
        }
        .padding()
    }

    var adventureBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24).fill(adventure.color).frame(height: 220)
            if let data = imageService.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
                    .frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 24))
                VStack {
                    Spacer()
                    LinearGradient(colors: [Color.clear, adventure.color.opacity(0.8)], startPoint: .center, endPoint: .bottom)
                        .frame(height: 80).clipShape(RoundedRectangle(cornerRadius: 24))
                }.frame(height: 220)
                VStack {
                    Spacer()
                    Text("\(childName)'s adventure begins...")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white).padding(.bottom, 14)
                }.frame(height: 220)
            } else {
                VStack(spacing: 8) {
                    if imageService.isLoading {
                        VStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Creating your illustration...")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        Image(systemName: adventure.emoji)
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                        Text("\(childName)'s adventure begins...")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
    }

    var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView().tint(Color(red: 0.75, green: 0.51, blue: 1.0))
            Text("Preparing your story voice...")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
        }.padding()
    }

    var storyTextView: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.15), lineWidth: 1))
            FlowLayout(words: words, currentIndex: currentWordIndex).padding(20)
        }.frame(minHeight: 140)
    }

    var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)).frame(height: 5)
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [Color(red: 0.58, green: 0.20, blue: 0.92), Color(red: 0.91, green: 0.47, blue: 0.98)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progress, height: 5)
            }
        }.frame(height: 5)
    }

    var playerControls: some View {
        HStack(spacing: 20) {
            Button(action: restartStory) {
                Image(systemName: "backward.end.fill").font(.system(size: 20))
                    .foregroundColor(Color(red: 0.77, green: 0.69, blue: 0.91))
                    .frame(width: 48, height: 48).background(Color.white.opacity(0.08)).clipShape(Circle())
            }
            Button(action: togglePlayPause) {
                Image(systemName: elevenLabs.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 26))
                    .foregroundColor(.white).frame(width: 64, height: 64)
                    .background(LinearGradient(colors: [Color(red: 0.58, green: 0.20, blue: 0.92), Color(red: 0.75, green: 0.15, blue: 0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(Circle())
            }.disabled(elevenLabs.isLoading)
            Button(action: skipAhead) {
                Image(systemName: "forward.end.fill").font(.system(size: 20))
                    .foregroundColor(Color(red: 0.77, green: 0.69, blue: 0.91))
                    .frame(width: 48, height: 48).background(Color.white.opacity(0.08)).clipShape(Circle())
            }
        }
    }

    var ambientControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
            Text("Ambient sounds").font(.system(size: 13)).foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
            Slider(value: $ambientVolume, in: 0...1).tint(Color(red: 0.58, green: 0.20, blue: 0.92))
            Text("\(Int(ambientVolume * 100))%").font(.system(size: 12)).foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75)).frame(width: 36)
        }.padding(12).background(Color.white.opacity(0.05)).cornerRadius(14)
    }

    var thetaIndicator: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(red: 0.75, green: 0.51, blue: 1.0)).frame(width: 8, height: 8)
            Text("Theta wave frequency active").font(.system(size: 12, weight: .semibold)).foregroundColor(Color(red: 0.75, green: 0.51, blue: 1.0))
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.2))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.4), lineWidth: 1))
        .cornerRadius(20)
    }

    func startStory() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch { print("Audio session error: \(error)") }
        elevenLabs.speak(text: storyText) { startWordTimer() }
    }

    func togglePlayPause() {
        if elevenLabs.isPlaying { elevenLabs.pause(); ambientAudio.pause(); stopWordTimer() }
        else { elevenLabs.resume(); ambientAudio.resume(); startWordTimer() }
    }

    func startWordTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { _ in
            if currentWordIndex < words.count {
                currentWordIndex += 1
                progress = Double(currentWordIndex) / Double(words.count)
            } else { stopWordTimer() }
        }
    }

    func stopWordTimer() { timer?.invalidate(); timer = nil }

    func restartStory() {
        elevenLabs.stop(); ambientAudio.stop(); stopWordTimer()
        currentWordIndex = 0; progress = 0
        startStory()
        ambientAudio.play(adventureKey: adventure.key, volume: Float(ambientVolume))
    }

    func skipAhead() {
        currentWordIndex = min(currentWordIndex + 30, words.count - 1)
        progress = Double(currentWordIndex) / Double(words.count)
    }
}

// MARK: - Flow Layout for Words
struct FlowLayout: View {
    let words: [String]
    let currentIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<getLineCount(), id: \.self) { lineIndex in
                HStack(spacing: 4) {
                    ForEach(getWordsForLine(lineIndex), id: \.offset) { item in
                        Text(item.element)
                            .font(.system(size: item.offset == currentIndex - 1 ? 20 : 17, weight: item.offset == currentIndex - 1 ? .bold : .semibold, design: .rounded))
                            .foregroundColor(item.offset == currentIndex - 1 ? Color(red: 0.94, green: 0.82, blue: 1.0) : item.offset < currentIndex - 1 ? Color(red: 0.48, green: 0.42, blue: 0.60) : Color(red: 0.77, green: 0.69, blue: 0.91))
                    }
                }
            }
        }
    }

    func getLineCount() -> Int { max(1, (words.count / 7) + 1) }

    func getWordsForLine(_ line: Int) -> [(offset: Int, element: String)] {
        let start = line * 7
        let end = min(start + 7, words.count)
        if start >= words.count { return [] }
        return words[start..<end].enumerated().map { (offset: $0.offset + start, element: $0.element) }
    }
}

// MARK: - Favorites View
struct FavoritesView: View {
    let favoriteItems: [StoryHistory]
    let onPlay: (StoryHistory) -> Void

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.04, blue: 0.10).ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        Text("Favourites")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                    }
                    Text("Your most loved stories")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                }
                .padding(.top, 40).padding(.bottom, 20)

                if favoriteItems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        Text("No favourites yet")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                        Text("Tap the star while a story plays to save it!")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.42, green: 0.35, blue: 0.54))
                            .multilineTextAlignment(.center).padding(.horizontal)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(favoriteItems) { item in
                                Button(action: { onPlay(item) }) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("\(item.childName)'s \(item.adventureName)")
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundColor(Color(red: 0.94, green: 0.88, blue: 1.0))
                                            HStack(spacing: 6) {
                                                Text("Age \(item.ageGroup)")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(Color(red: 0.75, green: 0.51, blue: 1.0))
                                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                                    .background(Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.3))
                                                    .cornerRadius(6)
                                                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color(red: 0.48, green: 0.42, blue: 0.60))
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color(red: 0.75, green: 0.51, blue: 1.0))
                                    }
                                    .padding(14)
                                    .background(Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.15))
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), lineWidth: 1))
                                }
                            }
                        }.padding()
                    }
                }
            }
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @Binding var historyItems: [StoryHistory]
    let onPlay: (StoryHistory) -> Void
    let onToggleFavorite: (StoryHistory) -> Void

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.04, blue: 0.10).ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.75, green: 0.51, blue: 1.0))
                        Text("Story History")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                    }
                    Text("Relive your adventures")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                }
                .padding(.top, 40).padding(.bottom, 20)

                if historyItems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 0.94, green: 0.78, blue: 1.0))
                        Text("No stories yet")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.61, green: 0.54, blue: 0.75))
                        Text("Start your first adventure!")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.42, green: 0.35, blue: 0.54))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(historyItems) { item in historyRow(item: item) }
                        }.padding()
                    }
                }
            }
        }
    }

    func historyRow(item: StoryHistory) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "book.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(red: 0.75, green: 0.51, blue: 1.0))
            VStack(alignment: .leading, spacing: 3) {
                Text("\(item.childName)'s \(item.adventureName)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.94, green: 0.88, blue: 1.0))
                HStack(spacing: 6) {
                    Text("Age \(item.ageGroup)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.75, green: 0.51, blue: 1.0))
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.3))
                        .cornerRadius(6)
                    Text(item.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.48, green: 0.42, blue: 0.60))
                }
            }
            Spacer()
            Button(action: { onToggleFavorite(item) }) {
                Image(systemName: item.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 18))
                    .foregroundColor(item.isFavorite ? Color(red: 1.0, green: 0.84, blue: 0.0) : Color(red: 0.61, green: 0.54, blue: 0.75))
            }
            Button(action: { onPlay(item) }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.75, green: 0.51, blue: 1.0))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.94, green: 0.78, blue: 1.0).opacity(0.15), lineWidth: 0.5))
    }
}

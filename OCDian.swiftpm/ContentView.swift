import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isPresented = false
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.systemGray2
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray2]
        itemAppearance.selected.iconColor = UIColor.systemBlue
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        appearance.stackedLayoutAppearance = itemAppearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            TrackerView()
                .tabItem {
                    Label("Tracker", systemImage: "list.bullet")
                }
            
            RelaxationView(showBackButton: false)
                .tabItem {
                    Label("Relaxation", systemImage: "leaf")
                }
            
            ERPView(isPresented: $isPresented)
                .tabItem {
                    Label("ERP", systemImage: "clock")
                }
        }
        .sheet(isPresented: $isPresented) {
            RelaxationView(showBackButton: true)
        }
    }
}

struct TrackerView: View {
    @State private var entries: [OCDEntry] = []
    @State private var newEntry = ""
    @State private var selectedObsession: OCDEntry? = nil
    @State private var compulsion: String = ""
    @State private var showDeleteAllConfirmation = false
    @Environment(\.editMode) private var editMode
    @State private var selectedEntryForStrategies: OCDEntry? = nil
    
    // New state variables
    @State private var moodHistory: [OCDMood] = []
    @State private var currentMood: Int = 3
    @State private var showMoodInput = false
    @State private var selectedTriggers: Set<String> = []
    @State private var moodNote: String = ""
    @State private var showInsights = false
    
    let copingStrategies: [String: [String]] = [
        "Fear of contamination": [
            "Mindfulness",
            "Gradual Exposure",
            "Hand-washing control",
            "Cognitive Restructuring",
            "Delayed Response Strategy"
        ],
        
        "Fear of harm": [
            "Thought Defusion",
            "Reality Checking",
            "Exposure Therapy",
            "Cognitive Reframing",
            "Mindfulness-Based Anxiety Reduction"
        ],
        
        "Checking behavior": [
            "Limiting Checking",
            "Confidence Building",
            "Postpone Checking",
            "Journaling Assurances",
            "Reducing Ritual Frequency"
        ],
        
        "Intrusive thoughts": [
            "Cognitive Defusion",
            "Exposure & Response Prevention (ERP)",
            "Thought Labeling",
            "Letting Thoughts Pass Without Judgment",
            "Reducing Reassurance Seeking"
        ],
        
        "Symmetry and Orderliness": [
            "Gradual Desensitization",
            "Deliberate Disorder Exercise",
            "Cognitive Flexibility Training",
            "Challenging Perfectionism",
            "Reducing Rearranging Rituals"
        ],
        
        "Hoarding behaviors": [
            "Decluttering Challenge",
            "Categorization Practice",
            "Cognitive Behavioral Therapy (CBT)",
            "Mindful Disposal",
            "Setting Limits on Acquiring Items"
        ],
        
        "Fear of saying or doing something offensive": [
            "Mindfulness and Self-Compassion",
            "Cognitive Behavioral Exposure",
            "Acceptance Commitment Therapy (ACT)",
            "Challenging Thought Distortions",
            "Gradual Exposure to Social Situations"
        ],
        
        "Religious or moral obsessions (Scrupulosity)": [
            "Exposure to Religious Texts Without Rituals",
            "Reducing Confession or Reassurance Seeking",
            "Accepting Uncertainty",
            "Challenging Guilt-Inducing Thoughts",
            "Practicing Self-Compassion"
        ],
        
        "Superstitious OCD": [
            "Challenging Magical Thinking",
            "Exposure to Feared Numbers or Words",
            "Cognitive Reframing",
            "Reducing Avoidance Behaviors",
            "Breaking Ritual Cycles"
        ],
        
        "Health-related OCD (Hypochondria)": [
            "Postpone Googling Symptoms",
            "Avoid Excessive Body Scanning",
            "Mindful Awareness of Anxiety",
            "Reduce Doctor Visits for Reassurance",
            "Thought Record for Health Fears"
        ]
    ]
    
    let triggers = [
        OCDTrigger(name: "Stress", icon: "bolt.circle.fill"),
        OCDTrigger(name: "Social", icon: "person.2.fill"),
        OCDTrigger(name: "Health", icon: "heart.fill"),
        OCDTrigger(name: "Work", icon: "briefcase.fill"),
        OCDTrigger(name: "Family", icon: "house.fill"),
        OCDTrigger(name: "Environment", icon: "leaf.fill")
    ]
    
    var matchingStrategies: [String] {
        return copingStrategies.first { newEntry.lowercased().contains($0.key.lowercased()) }?.value ?? []
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Mood Tracking Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How are you feeling?")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button(action: { showMoodInput = true }) {
                                HStack {
                                    Text(moodEmoji(for: currentMood))
                                        .font(.system(size: 40))
                                    Text("Track your mood")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 5)
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // OCD Journal Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("OCD Journal")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            // Entry Input
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    TextField("Log your obsession", text: $newEntry)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.body)
                                    
                                    Button(action: addEntry) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.blue)
                                    }
                                    .disabled(newEntry.isEmpty)
                                }
                                .padding(.horizontal)
                                
                                // Suggested Strategies
                                if !matchingStrategies.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Suggested Strategies")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(matchingStrategies, id: \.self) { strategy in
                                            HStack(spacing: 8) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                    .font(.system(size: 16))
                                                Text(strategy)
                                                    .font(.subheadline)
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                    .padding(.vertical, 16)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Entries List
                            VStack(alignment: .leading, spacing: 12) {
                                if !entries.isEmpty {
                                    Text("Your Entries")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                    
                                    ForEach(entries) { entry in
                                        Button(action: { selectedEntryForStrategies = entry }) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(entry.obsession)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                    .multilineTextAlignment(.leading)
                                                
                                                if let compulsion = entry.compulsion, !compulsion.isEmpty {
                                                    Text("Response: \(compulsion)")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                HStack {
                                                    Image(systemName: "lightbulb.fill")
                                                        .foregroundColor(.yellow)
                                                    Text("View coping strategies")
                                                        .font(.footnote)
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            .padding(16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)
                                        }
                                    }
                                    .onDelete(perform: deleteEntry)
                                    .padding(.horizontal)
                                } else {
                                    Text("No entries yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding()
                                }
                            }
                            .sheet(item: $selectedEntryForStrategies) { entry in
                                NavigationView {
                                    EntryCopingStrategiesView(entry: entry, strategies: findStrategiesForEntry(entry))
                                }
                            }
                        }
                        .padding(.vertical)
                        
                        // Add padding at the bottom to account for the fixed button
                        Color.clear.frame(height: 80)
                    }
                }
                .background(Color(.systemGroupedBackground))
                
                // Fixed Insights Button at bottom
                VStack {
                    Button(action: { showInsights = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.headline)
                            Text("View Insights")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("OCD Tracker")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showMoodInput) {
                MoodInputView(
                    currentMood: $currentMood,
                    selectedTriggers: $selectedTriggers,
                    moodNote: $moodNote,
                    moodHistory: $moodHistory,
                    triggers: triggers
                )
            }
            .sheet(isPresented: $showInsights) {
                InsightsView(moodHistory: moodHistory, entries: entries)
            }
            .toolbar {
                EditButton()
            }
        }
    }
    
    private func addEntry() {
        if !newEntry.isEmpty {
            let newOCDEntry = OCDEntry(obsession: newEntry, compulsion: "")
            entries.append(newOCDEntry)
            saveData()
            newEntry = ""
        }
    }
    
    private func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveData()
    }
    
    private func deleteAllEntries() {
        entries.removeAll()
        saveData()
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "OCDEntries")
        }
    }
    
    private func loadData() {
        if let savedData = UserDefaults.standard.data(forKey: "OCDEntries"),
           let decodedEntries = try? JSONDecoder().decode([OCDEntry].self, from: savedData) {
            entries = decodedEntries
        }
    }
    
    private func saveCompulsion(for selectedObsession: OCDEntry) {
        if !compulsion.isEmpty {
            if let index = entries.firstIndex(where: { $0.id == selectedObsession.id }) {
                entries[index].compulsion = compulsion
                saveData()
                self.compulsion = ""
                self.selectedObsession = nil
            }
        }
    }
    
    private func cancelSelection() {
        self.compulsion = ""
        self.selectedObsession = nil
    }
    
    private func findStrategiesForEntry(_ entry: OCDEntry) -> [String] {
        return copingStrategies.first { entry.obsession.lowercased().contains($0.key.lowercased()) }?.value ?? []
    }
    
    private func moodEmoji(for value: Int) -> String {
        switch value {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }
}

struct OCDEntry: Identifiable, Codable {
    var id = UUID()
    var obsession: String
    var compulsion: String?
}

// RelaxationView with calming background color
struct RelaxationView: View {
    @State private var timeRemaining = 5
    @State private var breatheIn = true
    @State private var breathMessage = "Breathe In"
    @State private var counter = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var isCompleted = false
    
    @State private var bodyScanIndex = 0
    @State private var bodyScanMessage = "Focus on your forehead. Relax your forehead."
    @State private var countdown = 5
    @State private var showBreathingExerciseModal = false
    @State private var showBodyScanExerciseModal = false
    @State private var countdownTimer: Timer?
    @State private var autoStartCountdown = 3
    @State private var autoStartTimer: Timer?
    @State private var shouldAutoStart: Bool
    
    var showBackButton: Bool
    @Environment(\.presentationMode) var presentationMode
    
    init(showBackButton: Bool, autoStart: Bool = false) {
        self.showBackButton = showBackButton
        self.shouldAutoStart = autoStart
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if shouldAutoStart && autoStartCountdown > 0 {
                    // Countdown overlay
                    VStack {
                        Text("Breathing exercise starting in")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("\(autoStartCountdown)")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.95))
                    .onAppear {
                        startAutoStartCountdown()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 30) {
                            ExerciseCardView(
                                exerciseTitle: "Exercise 1: Relaxing your Body",
                                imageName: "figure.walk.diamond.fill",
                                action: {
                                    showBodyScanExerciseModal.toggle()
                                },
                                backgroundImage: "body_scan"
                            )
                            
                            ExerciseCardView(
                                exerciseTitle: "Exercise 2: Breathing",
                                imageName: "cloud.sun.fill",
                                action: {
                                    showBreathingExerciseModal.toggle()
                                },
                                backgroundImage: "breathing_bg.png"
                            )
                        }
                        .padding()
                    }
                }
                Spacer()
            }
            .navigationTitle("Relaxation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showBackButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showBreathingExerciseModal) {
                NavigationView {
                    startBreathingExercise()
                }
            }
            .sheet(isPresented: $showBodyScanExerciseModal) {
                NavigationView {
                    startBodyScanExercise()
                }
            }
        }
    }

    // Card View for each exercise
    struct ExerciseCardView: View {
        var exerciseTitle: String
        var imageName: String
        var action: () -> Void
        var backgroundImage: String // Background image name
        
        var body: some View {
            ZStack {
                Image(backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 281)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.5), .clear, .black.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                VStack(spacing: 16) {
                    Image(systemName: imageName)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text(exerciseTitle)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal)
            .onTapGesture(perform: action)
        }
    }
    
    // MARK: - Breathing Exercise
    
    
    private func startBreathingExercise() -> some View {
        VStack(spacing: 20) {
            Text(breathMessage)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .animation(.easeInOut, value: breathMessage)
                .padding(.top, 30)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .foregroundColor(.blue.opacity(0.3))
                    .frame(width: 280, height: 280)
                
                Circle()
                    .stroke(lineWidth: 8)
                    .foregroundColor(.blue)
                    .frame(width: 280, height: 280)
                    .scaleEffect(isRunning ? (breatheIn ? 1.3 : 0.8) : 0.8)
                    .opacity(isRunning ? (breatheIn ? 1 : 0.5) : 0.5)
                    .animation(.easeInOut(duration: 5), value: breatheIn)
                    .animation(.easeInOut(duration: 1), value: isRunning)
                
                if isRunning {
                    Text("\(timeRemaining)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.blue)
                        .animation(.none, value: timeRemaining)
                }
            }
            .padding(40)
            
            if isCompleted {
                Text("Great job! Take a moment to notice how you feel.")
                    .font(.headline)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
            
            Button(action: startBreathing) {
                Text(isRunning ? "Reset" : "Start Breathing")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(isRunning ? Color.orange : Color.blue)
                    .cornerRadius(16)
                    .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Breathing Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    showBreathingExerciseModal = false
                }
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
        }
    }
    
    private func startBreathing() {
        // Reset states
        timeRemaining = 5 // Start with 5 seconds
        isRunning = true
        isCompleted = false
        breatheIn = false  // Start contracted
        breathMessage = "Get ready..."
        
        // Cancel any existing timer
        timer?.invalidate()
        
        // Initial delay before starting the exercise
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.breathMessage = "Breathe in..."
            withAnimation(.easeInOut(duration: 5)) {
                self.breatheIn = true  // Expand over 5 seconds
            }
            self.startBreathingCycle()
        }
    }
    
    private func startBreathingCycle() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    // Switch to next phase
                    withAnimation(.easeInOut(duration: 5)) {
                        self.breatheIn.toggle()  // Toggle with 5-second animation
                    }
                    self.timeRemaining = 5 // Reset to 5 seconds
                    self.breathMessage = self.breatheIn ? "Breathe in..." : "Breathe out..."
                    
                    if self.counter >= 6 {
                        self.completeExercise()
                        return
                    }
                    self.counter += 1
                }
            }
        }
    }
    
    private func completeExercise() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isCompleted = true
        breathMessage = "Exercise Complete"
        triggerHapticFeedback()
    }

    // Haptic Feedback when Breathing Timer ends
    private func triggerHapticFeedback() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.success) // Trigger success haptic feedback
    }
    
    // MARK: - Body Scan Relaxation
    
    private func startBodyScanExercise() -> some View {
        VStack(spacing: 20) {
            Text(bodyScanMessage)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
            
            Text("Hold: \(countdown) seconds")
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.top, 10)
            
            ProgressView(value: Double(bodyScanIndex), total: 6)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .onAppear {
            startBodyScan()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    showBodyScanExerciseModal = false
                    // Clean up timers when dismissing
                    countdownTimer?.invalidate()
                    countdownTimer = nil
                    bodyScanIndex = 0
                }
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
        }
    }
    
    // Body Scan Logic (relaxing different body parts)
    private func startBodyScan() {
        if bodyScanIndex < 6 {
            // Start countdown for each body part
            countdown = 10
            bodyScanMessage = bodyScanDescription(for: bodyScanIndex)
            
            // Countdown timer for each body part relaxation
            countdownTimer?.invalidate() // Invalidate any previous countdown timer
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                DispatchQueue.main.async {
                    if countdown > 0 {
                        countdown -= 1
                    } else {
                        self.timer?.invalidate() // Stop the timer when countdown reaches 0
                        self.bodyScanIndex += 1
                        startBodyScan() // Continue to the next body part
                    }
                }
            }
        }
    }
    
    private func bodyScanDescription(for index: Int) -> String {
        switch index {
        case 0: return "Focus on your forehead. Relax your forehead."
        case 1: return "Focus on your eyes. Relax your eyes."
        case 2: return "Focus on your jaw. Relax your jaw."
        case 3: return "Focus on your shoulders. Relax your shoulders."
        case 4: return "Focus on your arms. Relax your arms."
        case 5: return "Focus on your legs. Relax your legs."
        case 6: return "Focus on your feet. Relax your feet."
        default: return "Focus on your body."
        }
    }
    
    private func startAutoStartCountdown() {
        autoStartTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.autoStartCountdown > 1 {
                    self.autoStartCountdown -= 1
                } else {
                    self.autoStartTimer?.invalidate()
                    self.autoStartTimer = nil
                    self.showBreathingExerciseModal = true
                    self.shouldAutoStart = false // Reset for future uses
                }
            }
        }
    }
}

// ERPView with calming background color
struct ERPView: View {
    @State private var timeRemaining = 60
    @State private var isTimerRunning = false
    @State private var timer: Timer?
    @State private var exposureChallenge = ""
    @State private var selectedTime = 60
    @State private var anxietyBefore = 5
    @State private var anxietyAfter = 5
    @State private var sessionCompleted = false
    @State private var showCopingTips = false
    @State private var navigateToRelaxation = false
    @Binding var isPresented: Bool
    @State private var autoStart: Bool
    @State private var showBreathingExerciseModal = false
    @State private var breatheIn = true
    @State private var breathMessage = "Breathe In"
    @State private var counter = 0
    @State private var isRunning = false
    @State private var isCompleted = false

    let timeOptions = [60, 300, 600]
    let anxietyLevels = Array(1...10)

    init(isPresented: Binding<Bool>, autoStart: Bool = false) {
        self._isPresented = isPresented
        self._autoStart = State(initialValue: autoStart)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Challenge Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Describe your challenge")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("I feel anxious about...", text: $exposureChallenge)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 5)
                            )
                    }
                    .padding()
                    
                    // Timer Section
                    VStack(spacing: 16) {
                        Text("Duration")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Picker("Time", selection: $selectedTime) {
                            Text("1 min").tag(60)
                            Text("5 min").tag(300)
                            Text("10 min").tag(600)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        if isTimerRunning {
                            Text(formatTime(timeRemaining))
                                .font(.system(size: 54, weight: .bold))
                                .foregroundColor(.blue)
                                .padding()
                        }
                        
                        Button(action: toggleTimer) {
                            Text(isTimerRunning ? "Stop" : "Start")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isTimerRunning ? Color.red : Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8)
                    )
                    .padding(.horizontal)
                    
                    // Anxiety Level Section
                    if !isTimerRunning {
                        VStack(spacing: 16) {
                            Text("Anxiety Levels")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 20) {
                                anxietySlider(value: $anxietyBefore, title: "Before")
                                
                                if sessionCompleted {
                                    anxietySlider(value: $anxietyAfter, title: "After")
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8)
                        )
                        .padding(.horizontal)
                    }
                    
                    // If sessionCompleted is true, add this view after the anxiety sliders
                    if sessionCompleted {
                        let anxietyChange = anxietyBefore - anxietyAfter
                        VStack(spacing: 12) {
                            Text("Anxiety Change")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: anxietyChange > 0 ? "arrow.down.circle.fill" :
                                       anxietyChange < 0 ? "arrow.up.circle.fill" : "equal.circle.fill")
                                    .foregroundColor(anxietyChange > 0 ? .green :
                                       anxietyChange < 0 ? .red : .orange)
                                    .font(.system(size: 24))
                                
                                Text("\(abs(anxietyChange)) point\(abs(anxietyChange) == 1 ? "" : "s") \(anxietyChange > 0 ? "decrease" : anxietyChange < 0 ? "increase" : "no change")")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 20) {
                        Button("Coping Tips") {
                            showCopingTips = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.green)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                        .sheet(isPresented: $showCopingTips) {
                            CopingTipsView()
                        }
                        
                        Button("Panic Button") {
                            showBreathingExerciseModal = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.orange)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("ERP Session")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showBreathingExerciseModal) {
                NavigationView {
                    startBreathingExercise()
                }
            }
        }
    }
    
    private func toggleTimer() {
        if isTimerRunning {
            timer?.invalidate()
            timer = nil
            isTimerRunning = false
        } else {
            timeRemaining = selectedTime
            isTimerRunning = true
            sessionCompleted = false

            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                DispatchQueue.main.async {
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        self.timer?.invalidate()
                        self.timer = nil
                        isTimerRunning = false
                        sessionCompleted = true
                    }
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func moodEmoji(for anxietyLevel: Int) -> (emoji: String, description: String) {
        switch anxietyLevel {
        case 1...2:
            return ("😊", "Very Calm")
        case 3...4:
            return ("🙂", "Calm")
        case 5...6:
            return ("😐", "Neutral")
        case 7...8:
            return ("😟", "Anxious")
        case 9...10:
            return ("😰", "Very Anxious")
        default:
            return ("😐", "Neutral")
        }
    }

    private func anxietySlider(value: Binding<Int>, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(title) Exposure: \(value.wrappedValue)")
                    .foregroundColor(.secondary)
                
                // Show emoji for both Before and After exposure
                let mood = moodEmoji(for: value.wrappedValue)
                Text(mood.emoji)
                    .font(.system(size: 24))
                Text(mood.description)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0) }
            ), in: 1...10, step: 1)
            .accentColor(.blue)
            
            // Add colored indicators below the slider
            HStack {
                Text("Less Anxious")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Text("More Anxious")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func startBreathingExercise() -> some View {
        VStack(spacing: 20) {
            Text(breathMessage)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .animation(.easeInOut, value: breathMessage)
                .padding(.top, 30)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .foregroundColor(.blue.opacity(0.3))
                    .frame(width: 280, height: 280)
                
                Circle()
                    .stroke(lineWidth: 8)
                    .foregroundColor(.blue)
                    .frame(width: 280, height: 280)
                    .scaleEffect(isRunning ? (breatheIn ? 1.3 : 0.8) : 0.8)
                    .opacity(isRunning ? (breatheIn ? 1 : 0.5) : 0.5)
                    .animation(.easeInOut(duration: 5), value: breatheIn)
                    .animation(.easeInOut(duration: 1), value: isRunning)
                
                if isRunning {
                    Text("\(timeRemaining)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.blue)
                        .animation(.none, value: timeRemaining)
                }
            }
            .padding(40)
            
            if isCompleted {
                Text("Great job! Take a moment to notice how you feel.")
                    .font(.headline)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
            
            Button(action: startBreathing) {
                Text(isRunning ? "Reset" : "Start Breathing")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(isRunning ? Color.orange : Color.blue)
                    .cornerRadius(16)
                    .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Breathing Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    showBreathingExerciseModal = false
                }
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
        }
    }

    private func startBreathing() {
        // Reset states
        counter = 0
        timeRemaining = 5
        isRunning = true
        isCompleted = false
        breatheIn = false  // Start contracted
        breathMessage = "Get ready..."
        
        // Cancel any existing timer
        timer?.invalidate()
        
        // Initial delay before starting the exercise
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.breathMessage = "Breathe in..."
            withAnimation(.easeInOut(duration: 5)) {
                self.breatheIn = true  // Expand over 5 seconds
            }
            self.startBreathingCycle()
        }
    }

    private func startBreathingCycle() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    // Switch to next phase
                    withAnimation(.easeInOut(duration: 5)) {
                        self.breatheIn.toggle()  // Toggle with 5-second animation
                    }
                    self.timeRemaining = 5 // Reset to 5 seconds
                    self.breathMessage = self.breatheIn ? "Breathe in..." : "Breathe out..."
                    
                    if self.counter >= 6 {
                        self.completeExercise()
                        return
                    }
                    self.counter += 1
                }
            }
        }
    }

    private func completeExercise() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isCompleted = true
        breathMessage = "Exercise Complete"
        triggerHapticFeedback()
    }

    private func triggerHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func stopBreathing() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        counter = 0
        timeRemaining = 5
        breatheIn = true
        breathMessage = "Breathe In"
    }
}

struct CopingTipsView: View {
    @Environment(\.presentationMode) var presentationMode // To dismiss the sheet
    
    var body: some View {
        
        VStack(spacing: 20) {
            Text("Coping Strategies")
                .font(.largeTitle)
                .padding()
            
            Text("🧘 **Deep Breathing Exercise**: Inhale for 4 seconds, hold for 4 seconds, exhale for 4 seconds.")
                .padding()
                .multilineTextAlignment(.center)
            
            Text("🌿 **Mindfulness Tip**: Focus on the present moment and observe your surroundings without judgment.")
                .padding()
                .multilineTextAlignment(.center)
            
            Text("💡 **Reassuring Message**: You're in control. Anxiety will pass, and you are stronger than your fears.")
                .padding()
                .multilineTextAlignment(.center)
            
            Button("Close") {
                self.presentationMode.wrappedValue.dismiss() // Dismiss the sheet when clicked
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: 400)
        .padding()
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex
        _ = scanner.scanString("#") // Remove #

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

struct EntryCopingStrategiesView: View {
    @Environment(\.presentationMode) var presentationMode
    let entry: OCDEntry
    let strategies: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Entry details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Entry:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(entry.obsession)
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 5)
                        )
                }
                .padding(.horizontal)
                
                // Strategies
                VStack(alignment: .leading, spacing: 16) {
                    Text("Suggested Coping Strategies")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    
                    ForEach(strategies, id: \.self) { strategy in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            
                            Text(strategy)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 5)
                        )
                    }
                }
                .padding(.horizontal)
                
                if strategies.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                        Text("General coping strategies:")
                            .font(.headline)
                        Text("1. Practice deep breathing")
                        Text("2. Use mindfulness techniques")
                        Text("3. Challenge negative thoughts")
                        Text("4. Seek support when needed")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 5)
                    )
                    .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Coping Strategies")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .fontWeight(.bold)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// Add these new structs at the top level
struct OCDMood: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let mood: Int // 1-5 scale
    let triggers: [String]
    let notes: String
}

struct OCDTrigger: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

// Add these new view structs
struct MoodInputView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentMood: Int
    @Binding var selectedTriggers: Set<String>
    @Binding var moodNote: String
    @Binding var moodHistory: [OCDMood]
    let triggers: [OCDTrigger]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How are you feeling?")) {
                    Picker("Mood", selection: $currentMood) {
                        Text("😢").tag(1)
                        Text("😕").tag(2)
                        Text("😐").tag(3)
                        Text("🙂").tag(4)
                        Text("😊").tag(5)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 8)
                    
                    // Show the description below
                    HStack {
                        Text(moodEmoji(for: currentMood))
                            .font(.system(size: 32))
                        Text(moodDescription(for: currentMood))
                            .foregroundColor(.secondary)
                            .font(.headline)
                    }
                    .padding(.top, 8)
                }
                
                Section(header: Text("What triggered these feelings?")) {
                    ForEach(triggers) { trigger in
                        Button(action: {
                            if selectedTriggers.contains(trigger.name) {
                                selectedTriggers.remove(trigger.name)
                            } else {
                                selectedTriggers.insert(trigger.name)
                            }
                        }) {
                            HStack {
                                Image(systemName: trigger.icon)
                                Text(trigger.name)
                                Spacer()
                                if selectedTriggers.contains(trigger.name) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $moodNote)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Track Mood")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveMood()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func saveMood() {
        let newMood = OCDMood(
            date: Date(),
            mood: currentMood,
            triggers: Array(selectedTriggers),
            notes: moodNote
        )
        moodHistory.append(newMood)
        selectedTriggers.removeAll()
        moodNote = ""
    }
    
    private func moodEmoji(for value: Int) -> String {
        switch value {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }
    
    private func moodDescription(for value: Int) -> String {
        switch value {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Very Good"
        default: return "Neutral"
        }
    }
}

// Create a separate view for the Mood Trends card
struct MoodTrendsCard: View {
    let moodHistory: [OCDMood]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Trends")
                .font(.headline)
            
            Text("Last 7 days")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Bar Chart
            MoodBarChart(moodHistory: moodHistory)
            
            // Legend
            MoodLegend()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Update the MoodBarChart struct
struct MoodBarChart: View {
    let moodHistory: [OCDMood]
    @Namespace private var animation
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Changed from reversed() to normal order to show oldest to newest
            ForEach(Array(moodHistory.suffix(7)), id: \.id) { mood in
                MoodBar(mood: mood)
                    .transition(.scale)
                    .animation(.easeInOut, value: mood.id)
            }
        }
        .frame(height: 200)
    }
}

// Individual mood bar
struct MoodBar: View {
    let mood: OCDMood
    
    var body: some View {
        VStack(spacing: 8) {
            Text(moodEmoji(for: mood.mood))
                .font(.system(size: 16))
            
            Rectangle()
                .fill(moodColor(for: mood.mood))
                .frame(width: 30, height: CGFloat(mood.mood) * 30)
                .cornerRadius(8)
            
            Text(formatDate(mood.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func moodEmoji(for value: Int) -> String {
        switch value {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }
    
    private func moodColor(for value: Int) -> Color {
        switch value {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// Legend view
struct MoodLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(1...5, id: \.self) { value in
                HStack(spacing: 4) {
                    Circle()
                        .fill(moodColor(for: value))
                        .frame(width: 8, height: 8)
                    Text(moodDescription(for: value))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
    
    private func moodColor(for value: Int) -> Color {
        switch value {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        default: return .gray
        }
    }
    
    private func moodDescription(for value: Int) -> String {
        switch value {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Very Good"
        default: return "Neutral"
        }
    }
}

// Update the InsightsView to use these components
struct InsightsView: View {
    let moodHistory: [OCDMood]
    let entries: [OCDEntry]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    MoodTrendsCard(moodHistory: moodHistory)
                    
                    // Common Triggers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Common Triggers")
                            .font(.headline)
                        
                        ForEach(mostCommonTriggers(), id: \.0) { trigger, count in
                            HStack {
                                Text(trigger)
                                Spacer()
                                Text("\(count) times")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func mostCommonTriggers() -> [(String, Int)] {
        var triggerCounts: [String: Int] = [:]
        moodHistory.forEach { mood in
            mood.triggers.forEach { trigger in
                triggerCounts[trigger, default: 0] += 1
            }
        }
        return triggerCounts.sorted { $0.value > $1.value }
    }
}

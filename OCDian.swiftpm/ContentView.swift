import SwiftUI
//import PlaygroundSupport
import AVFoundation

struct ContentView: View {
    init() {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(hex: "#FFFFFF")

            // Set up tab bar item appearance
            let itemAppearance = UITabBarItemAppearance()
            
            // Unselected item color (Icon + Label)
            itemAppearance.normal.iconColor = UIColor(hex: "#B0BEC5")
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(hex: "#B0BEC5")]
            
            // Selected item color (Icon + Label)
            itemAppearance.selected.iconColor = UIColor(hex: "#006400")
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hex: "#006400")]

            // Apply appearance to the tab bar
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
            
            ERPView()
                .tabItem {
                    Label("ERP", systemImage: "clock")
                }
        }
//        .onAppear {
//            // Ensure changes apply on appearing
//            UITabBar.appearance().tintColor = UIColor(hex: "#A8D5BA") // Selected tab color
//            UITabBar.appearance().unselectedItemTintColor = UIColor(hex: "#B0BEC5") // Unselected tab color
//        }
    }
}

// Tab 1: Tracker
struct TrackerView: View {
    @State private var entries: [String] = []
    @State private var newEntry = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with larger title
                VStack {
                    Text("OCD Tracker")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.black)
                        .shadow(radius: 5)
                        .padding(.top, 40)
                        .padding(.bottom, 10)
                    Text("Track your thoughts and compulsions")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#A8D5BA"), Color(hex: "#E4F0F2")]), startPoint: .top, endPoint: .bottom))
                .edgesIgnoringSafeArea(.top)
                
                // Input text field for new entry
                HStack {
                    TextField("Log your obsession/compulsion", text: $newEntry)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal, 20)
                    
                    Button(action: addEntry) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.blue)
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)

                // List of entries
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(entries, id: \.self) { entry in
                            HStack {
                                Text(entry)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .cornerRadius(15)
                                    .shadow(radius: 10)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 20)
                }

                Spacer()
            }
            .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#A8D5BA"), Color(hex: "#E4F0F2")]), startPoint: .top, endPoint: .bottom))
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                loadData()
            }
            .navigationBarTitleDisplayMode(.inline) // Set the title to a smaller, inline style for consistency with modern design
            .navigationBarHidden(true) // Hide the default navigation bar for a cleaner look
        }
    }

    
    private func addEntry() {
        if !newEntry.isEmpty {
            entries.append(newEntry)
            saveData()
            newEntry = ""
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "OCDEntries")
        }
    }
    
    private func loadData() {
        if let savedData = UserDefaults.standard.data(forKey: "OCDEntries"),
           let decodedEntries = try? JSONDecoder().decode([String].self, from: savedData) {
            entries = decodedEntries
        }
    }
}

// Tab 2: Relaxation
struct RelaxationView: View {
    @State private var breatheIn = true
    @State private var breathMessage = "Breathe In"
    @State private var counter = 9
    @State private var timer: Timer?
    @State private var isRunning = false
    var showBackButton: Bool // Flag to control visibility of the back button
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(hex: "#A8D5BA"), Color(hex: "#E4F0F2")]), startPoint: .top, endPoint: .bottom)
                                   .edgesIgnoringSafeArea(.all)
                VStack {
                    Text(breathMessage)
                        .font(.largeTitle)
                        .padding()

                    Text("\(counter)")
                        .font(.system(size: 60))
                        .padding()

                    Circle()
                        .stroke(lineWidth: 4)
                        .foregroundColor(breatheIn ? .green : .blue)
                        .scaleEffect(breatheIn ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 4.0), value: breatheIn)
                        .frame(width: 200, height: 200)

                    Button(isRunning ? "Restart" : "Start") { // Change text dynamically
                        startBreathing()
                    }
                    .padding()

                    // Show Back button only when it's set to true
                    if showBackButton {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss() // Dismiss Relaxation view
                        }) {
                            Text("Back")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                }
                
                .navigationBarHidden(true) // Hide the navigation bar entirely when in RelaxationView
            }
        }
    }
    
    private func startBreathing() {
        counter = 9
        isRunning = true
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [self] timer in
            DispatchQueue.main.async {
                if counter > 0 {
                    counter -= 1
                    breatheIn.toggle()
                    breathMessage = breatheIn ? "Breathe In" : "Breathe Out"
                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                    isRunning = false
                }
            }
        }
    }
}

// Tab 3: ERP
struct ERPView: View {
    @State private var timeRemaining = 60 // Default 1 minute
    @State private var isTimerRunning = false
    @State private var timer: Timer?
    @State private var exposureChallenge = "" // User-defined challenge
    @State private var selectedTime = 60 // Default timer selection
    @State private var anxietyBefore = 5 // Default anxiety level before exposure
    @State private var anxietyAfter = 5 // Default anxiety level after exposure
    @State private var sessionCompleted = false // Track session completion
    @State private var showCopingTips = false // Show coping tips sheet
    @State private var navigateToRelaxation = false // Navigate to relaxation tab

    let timeOptions = [60, 300, 600] // 1 min, 5 min, 10 min
    let anxietyLevels = Array(1...10) // Anxiety scale from 1 to 10

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "#A8D5BA"), Color(hex: "#E4F0F2")]), startPoint: .top, endPoint: .bottom)
                               .edgesIgnoringSafeArea(.all)

            ScrollView { // Make the entire content scrollable
                VStack {
                    Text("ERP Exercise")
                        .font(.largeTitle)
                        .padding()

                    TextField("Enter Exposure Challenge", text: $exposureChallenge)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Text("Select Duration:")
                        .font(.headline)

                    Picker("Select Time", selection: $selectedTime) {
                        Text("1 min").tag(60)
                        Text("5 min").tag(300)
                        Text("10 min").tag(600)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    Text("Time Remaining: \(formatTime(timeRemaining))")
                        .font(.title2)
                        .padding()

                    Button(action: toggleTimer) {
                        Text(isTimerRunning ? "Stop" : "Start")
                            .padding()
                            .background(isTimerRunning ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()

                    if !isTimerRunning {
                        VStack {
                            Text("Rate Anxiety Before Exposure:")
                                .font(.headline)
                            Picker("Anxiety Before", selection: $anxietyBefore) {
                                ForEach(anxietyLevels, id: \.self) { level in
                                    Text("\(level)").tag(level)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()

                            if sessionCompleted {
                                Text("Rate Anxiety After Exposure:")
                                    .font(.headline)
                                Picker("Anxiety After", selection: $anxietyAfter) {
                                    ForEach(anxietyLevels, id: \.self) { level in
                                        Text("\(level)").tag(level)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding()

                                // Calmness Meter (Progress Bar)
                                VStack {
                                    Text("Calmness Meter")
                                        .font(.headline)
                                    ProgressView(value: Double(10 - anxietyAfter), total: 10)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .padding()
                                        .frame(width: 200)
                                }
                            }
                        }
                        .padding(.top, 5)
                    }

                    // Buttons side by side in HStack
                    HStack(spacing: 20) { // Set spacing between buttons
                        // Coping Tips Button
                        Button("Coping Tips") {
                            showCopingTips = true
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .sheet(isPresented: $showCopingTips) {
                            CopingTipsView() // Display coping tips when tapped
                        }

                        // Panic Button
                        Button("Panic Button") {
                            navigateToRelaxation = true
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .fullScreenCover(isPresented: $navigateToRelaxation) {
                            RelaxationView(showBackButton: true) // Pass the flag to RelaxationView
                        }
                    }
                    .padding() // Adds space around the HStack
                    .frame(maxWidth: .infinity) // Ensures buttons take equal space
                }
                .padding()
            }
        }
    }

    private func toggleTimer() {
        if isTimerRunning {
            timer?.invalidate()
            timer = nil
            isTimerRunning = false
        } else {
            timeRemaining = selectedTime // Set timer based on user selection
            isTimerRunning = true
            sessionCompleted = false // Reset session completion

            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
                DispatchQueue.main.async {
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        self.timer?.invalidate()
                        self.timer = nil
                        isTimerRunning = false
                        sessionCompleted = true // Mark session as completed
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
}

// ✅ Coping Tips View (Shows breathing exercises, mindfulness, and reassurance)
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

            // Close Button to dismiss the sheet
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
//PlaygroundPage.current.setLiveView(ContentView())

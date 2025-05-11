import SwiftUI

struct ContentView: View {
    @State private var safeAreaTop: CGFloat = 0
    @State private var displayItems: [DisplayableListItem] = []
    @State private var scrollOffset: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    @State private var searchText: String = ""
    @State private var searchBarHeight: CGFloat = 0
    @State private var currentDateSeparator: String = ""
    @State private var dateSeparatorPositions: [String: CGFloat] = [:]
    
    // Recording state variables
    @State private var isRecording: Bool = false
    @State private var isPaused: Bool = false
    @State private var recordingDuration: Double = 0
    @State private var recordingTimer: Timer? = nil
    @State private var showRecordingSheet: Bool = false
    @State private var noteTitle: String = "New note"
    @State private var noteDescription: String = "Feel free to write notes here"
    
    // Animation state for waveform
    @State private var waveformHeights: [CGFloat] = Array(repeating: 0, count: 10)
    @State private var waveformTimer: Timer? = nil

    private let largeScrollableTitleFontSize: CGFloat = 34
    private let searchBarScrollThreshold: CGFloat = 40
    private let titleTransitionThreshold: CGFloat = 50
    private let dateSeparatorHeight: CGFloat = 30
    
    var filteredItems: [DisplayableListItem] {
        if searchText.isEmpty {
            return displayItems
        }
        
        let searchTextLowercased = searchText.lowercased()
        var filteredList: [DisplayableListItem] = []
        var lastDateHeader: String? = nil
        
        for item in displayItems {
            switch item {
            case .dateSeparator(let text):
                lastDateHeader = text
            case .note(let note):
                if note.title.lowercased().contains(searchTextLowercased) {
                    // If we find a matching note, add its date header first (if not already added)
                    if let header = lastDateHeader {
                        // Check if the header already exists in the filtered list
                        let headerExists = filteredList.contains { item in
                            if case .dateSeparator(let text) = item {
                                return text == header
                            }
                            return false
                        }
                        
                        // Add header if it doesn't exist yet
                        if !headerExists {
                            filteredList.append(.dateSeparator(header))
                        }
                    }
                    filteredList.append(item)
                }
            }
            
            // Reset date header tracking if we've moved to a new date
            if case .dateSeparator = item {
                lastDateHeader = nil
            }
        }
        
        return filteredList
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack(alignment: .top) {
                    Color(.systemGray6)
                        .edgesIgnoringSafeArea(.all)

                    ScrollView {
                        ScrollDetector { offset in
                            scrollOffset = offset
                            updateCurrentDateSeparator()
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            // Spacer to push content down by header height
                            Color.clear
                                .frame(height: calculateHeaderOffset())
                                .frame(maxWidth: .infinity)
                            
                            // Search bar (scrolls with content)
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color(.systemGray2))
                                    .padding(.leading, 8)
                                
                                ZStack(alignment: .leading) {
                                    if searchText.isEmpty {
                                        Text("Search")
                                            .foregroundColor(Color(.systemGray2))
                                    }
                                    
                                    TextField("", text: $searchText)
                                        .foregroundColor(Color(.label))
                                        .accentColor(Color(.systemGray4))
                                }
                                .padding(10)
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color(.systemGray4))
                                    }
                                    .padding(.trailing, 8)
                                }
                            }
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                            .padding(.bottom, 15)
                            .background(
                                GeometryReader { geo in
                                    DispatchQueue.main.async {
                                        searchBarHeight = geo.size.height
                                    }
                                    Color.clear
                                }
                            )

                            if filteredItems.isEmpty && !searchText.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "text.magnifyingglass")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    
                                    Text("No results found")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                    
                                    Text("Try a different search term")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                            } else {
                                ForEach(filteredItems) { item in
                                    switch item {
                                    case .dateSeparator(let text):
                                        DateSeparatorView(text: text)
                                            .background(
                                                GeometryReader { geo -> Color in
                                                    let frame = geo.frame(in: .global)
                                                    DispatchQueue.main.async {
                                                        dateSeparatorPositions[text] = frame.minY
                                                    }
                                                    return Color.clear
                                                }
                                            )
                                    case .note(let note):
                                        NoteCardView(note: note)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Fixed overlay header
                    VStack(alignment: .leading, spacing: 0) {
                        Text("My Notes")
                            .font(.system(size: largeScrollableTitleFontSize, weight: .bold))
                            .foregroundColor(Color(.label))
                            .padding(.top, safeAreaTop + 20)
                            .padding(.horizontal)
                            .opacity(headerOpacity)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                GeometryReader { geo -> Color in
                                    DispatchQueue.main.async {
                                        headerHeight = geo.size.height
                                    }
                                    return Color.clear
                                }
                            )
                        
                        Spacer()
                    }
                    .frame(height: headerHeight)
                    .frame(maxWidth: .infinity)
                    .offset(y: calculateTitleOffset())
                    .background(Color(.systemGray6))
                    .zIndex(3)
                    
                    // Sticky date separator
                    if headerOpacity <= 0.01 && !currentDateSeparator.isEmpty {
                        VStack(spacing: 0) {
                            // Add extra spacing to avoid navbar overlap
                            Color.clear
                                .frame(height: safeAreaTop + navBarHeight + 8)
                            
                            HStack {
                                Text(currentDateSeparator)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(.darkGray))
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                
                                Spacer()
                            }
                            .frame(height: dateSeparatorHeight)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .transition(.opacity)
                            .id(currentDateSeparator) // Forces view recreation on change
                            
                            Spacer()
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                        .zIndex(2)
                        .animation(.easeInOut(duration: 0.2), value: currentDateSeparator)
                    }
                }
                .navigationTitle("My Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("My Notes")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .opacity(navBarTitleOpacity)
                            .animation(.easeInOut(duration: 0.2), value: scrollOffset)
                    }
                }
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarBackground(navBarVisibility, for: .navigationBar)
                .edgesIgnoringSafeArea(.top)
                .onAppear {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        safeAreaTop = window.safeAreaInsets.top
                    }
                    generateDisplayItems()
                }
            }
            
            // Add recording button
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // New recording button
                    Button(action: {
                        showRecordingSheet = true
                        noteTitle = "New note"
                        noteDescription = "Feel free to write notes here"
                        startRecording()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                            Text("New")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 35)
                        .padding(.vertical, 20)
                        .background(Color(red: 0.06, green: 0.54, blue: 0.42))
                        .cornerRadius(30)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            
            // Bottom sheet using the new component
            if showRecordingSheet {
                BottomSheet(
                    isPresented: $showRecordingSheet,
                    title: $noteTitle,
                    description: $noteDescription,
                    isRecording: $isRecording,
                    isPaused: $isPaused,
                    recordingDuration: $recordingDuration,
                    waveformHeights: $waveformHeights,
                    onClose: {
                        stopRecording()
                    },
                    onPauseResume: {
                        if isPaused {
                            resumeRecording()
                        } else {
                            pauseRecording()
                        }
                    },
                    onUpdateTitle: { newValue in
                        updateLiveActivityTitle(newValue)
                    }
                ) {
                    // Additional content can go here
                    EmptyView()
                }
            }
        }
        .onAppear {
            setupWaveformAnimation()
        }
    }
    
    private var navBarHeight: CGFloat {
        return 44 // Standard navbar height
    }
    
    private func updateCurrentDateSeparator() {
        guard !dateSeparatorPositions.isEmpty else { return }
        
        // Calculate the exact threshold where the navbar ends
        let stickyThreshold = safeAreaTop + navBarHeight + dateSeparatorHeight + 5
        
        // Find the separator that should be sticky - the one that just passed the threshold
        var newSeparator = ""
        var closestPassedPosition: CGFloat = -.infinity
        
        for (separator, position) in dateSeparatorPositions {
            // If this separator has passed the threshold but is still closest to it (most recently passed)
            if position < stickyThreshold && position > closestPassedPosition {
                closestPassedPosition = position
                newSeparator = separator
            }
        }
        
        // Only update if we found a valid separator
        if !newSeparator.isEmpty {
            currentDateSeparator = newSeparator
        }
    }
    
    private func calculateHeaderOffset() -> CGFloat {
        // Keep space for the header when scrolling
        return headerHeight
    }
    
    private func calculateTitleOffset() -> CGFloat {
        // Title should stick until search bar scrolls out
        if scrollOffset < searchBarHeight + 10 {
            return 0
        }
        
        // Then title starts moving up too
        let additionalOffset = scrollOffset - (searchBarHeight + 10)
        return -min(additionalOffset, headerHeight)
    }
    
    private var headerOpacity: Double {
        // Title stays visible until search bar scrolls out
        if scrollOffset < searchBarScrollThreshold {
            return 1.0
        }
        
        // Then start fading out
        let opacityOffset = scrollOffset - searchBarScrollThreshold
        let progress = min(1, max(0, 1 - (opacityOffset / titleTransitionThreshold)))
        return Double(progress)
    }
    
    private var navBarTitleOpacity: Double {
        return headerOpacity <= 0.01 ? 1.0 : 0.0
    }
    
    private var navBarVisibility: Visibility {
        return headerOpacity <= 0.01 ? .visible : .hidden
    }

    private func generateDisplayItems() {
        var processedNotes: [NoteItem] = NoteDataProvider.rawNotesData.compactMap {
            guard let date = NoteDataProvider.inputDateFormatter.date(from: $0.dateString) else {
                print("Failed to parse date: \($0.dateString)")
                return nil
            }
            return NoteItem(title: $0.title, date: date, iconName: $0.icon, isCustomIcon: $0.isCustom)
        }.sorted { $0.date > $1.date }

        var tempDisplayItems: [DisplayableListItem] = []
        var lastDateProcessed: Date? = nil

        for i in 0..<processedNotes.count {
            var note = processedNotes[i]
            note.dateString = NoteDataProvider.timeFormatter.string(from: note.date)
            processedNotes[i] = note

            let currentDate = note.date
            if lastDateProcessed == nil || !Calendar.current.isDate(currentDate, inSameDayAs: lastDateProcessed!) {
                let separatorText = formatDateSeparator(for: currentDate)
                tempDisplayItems.append(.dateSeparator(separatorText))
            }
            tempDisplayItems.append(.note(note))
            lastDateProcessed = currentDate
        }
        self.displayItems = tempDisplayItems
    }

    private func formatDateSeparator(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return NoteDataProvider.dateSeparatorFormatter.string(from: date)
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func setupWaveformAnimation() {
        // Initialize random heights for the waveform bars
        for i in 0..<waveformHeights.count {
            waveformHeights[i] = CGFloat.random(in: 5...35)
        }
    }
    
    private func startWaveformAnimation() {
        // Cancel any existing timer
        waveformTimer?.invalidate()
        
        // Create a timer that updates the waveform every 0.1 seconds
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            for i in 0..<waveformHeights.count {
                withAnimation(.easeInOut(duration: 0.2)) {
                    waveformHeights[i] = CGFloat.random(in: 5...35)
                }
            }
        }
    }
    
    private func stopWaveformAnimation() {
        waveformTimer?.invalidate()
        waveformTimer = nil
    }
    
    private func updateLiveActivityTitle(_ title: String) {
        #if canImport(ActivityKit)
        LiveActivityManager.shared.updateActivityTitle(title, duration: recordingDuration, isPaused: isPaused)
        #endif
    }
    
    private func startRecording() {
        isRecording = true
        isPaused = false
        recordingDuration = 0
        
        // Start timer to track duration
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingDuration += 1.0
            
            // Update Live Activity if available
            #if canImport(ActivityKit)
            LiveActivityManager.shared.updateRecordingActivity(
                duration: recordingDuration,
                isPaused: false
            )
            #endif
        }
        
        // Start the waveform animation
        startWaveformAnimation()
        
        // Start Live Activity if available
        #if canImport(ActivityKit)
        LiveActivityManager.shared.startRecordingActivity(title: noteTitle)
        #endif
    }
    
    private func pauseRecording() {
        isPaused = true
        recordingTimer?.invalidate()
        
        // Pause the waveform animation
        stopWaveformAnimation()
        
        // Update Live Activity if available
        #if canImport(ActivityKit)
        LiveActivityManager.shared.updateRecordingActivity(
            duration: recordingDuration,
            isPaused: true
        )
        #endif
    }
    
    private func resumeRecording() {
        isPaused = false
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingDuration += 1.0
            
            // Update Live Activity if available
            #if canImport(ActivityKit)
            LiveActivityManager.shared.updateRecordingActivity(
                duration: recordingDuration,
                isPaused: false
            )
            #endif
        }
        
        // Resume the waveform animation
        startWaveformAnimation()
    }
    
    private func stopRecording() {
        isRecording = false
        isPaused = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDuration = 0
        
        // Stop the waveform animation
        stopWaveformAnimation()
        
        // End Live Activity if available
        #if canImport(ActivityKit)
        LiveActivityManager.shared.endRecordingActivity()
        #endif
    }
}

#Preview {
    ContentView()
}


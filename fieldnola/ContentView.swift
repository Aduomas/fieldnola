import SwiftUI

struct ContentView: View {
    @State private var safeAreaTop: CGFloat = 0
    @State private var displayItems: [DisplayableListItem] = []
    @State private var scrollOffset: CGFloat = 0
    @State private var headerHeight: CGFloat = 0

    private let largeScrollableTitleFontSize: CGFloat = 34
    private let transitionThreshold: CGFloat = 40
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGray6)
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    ScrollDetector { offset in
                        scrollOffset = offset
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("My Notes")
                            .font(.system(size: largeScrollableTitleFontSize, weight: .bold))
                            .padding(.top, safeAreaTop + 20)
                            .padding(.bottom, 15)
                            .opacity(headerOpacity)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color(.label))
                            .background(GeometryReader { geo -> Color in
                                DispatchQueue.main.async {
                                    headerHeight = geo.size.height
                                }
                                return Color.clear
                            })

                        ForEach(displayItems) { item in
                            switch item {
                            case .dateSeparator(let text):
                                DateSeparatorView(text: text)
                            case .note(let note):
                                NoteCardView(note: note)
                            }
                        }
                    }
                    .padding(.horizontal)
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
    }
    
    private var headerOpacity: Double {
        let progress = min(1, max(0, 1 - (scrollOffset / transitionThreshold)))
        return Double(progress)
    }
    
    private var navBarTitleOpacity: Double {
        let progress = min(1, max(0, scrollOffset / transitionThreshold))
        return Double(progress)
    }
    
    private var navBarVisibility: Visibility {
        return scrollOffset > 0 ? .visible : .hidden
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
}

struct ScrollDetector: View {
    let onScroll: (CGFloat) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: ScrollOffsetPreferenceKey.self,
                value: geometry.frame(in: .global).minY
            )
        }
        .frame(height: 0)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            onScroll(-value)
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ContentView()
}


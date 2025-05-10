import SwiftUI

struct ContentView: View {
    @State private var safeAreaTop: CGFloat = 0
    @State private var displayItems: [DisplayableListItem] = []
    @State private var isScrolling: Bool = false

    private let largeScrollableTitleFontSize: CGFloat = 34

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGray6)
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("My Notes")
                            .font(.system(size: largeScrollableTitleFontSize, weight: .bold))
                            .padding(.top, safeAreaTop + 20)
                            .padding(.bottom, 15)
                            .opacity(isScrolling ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.2), value: isScrolling)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color(.label))

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
                .onScrollPhaseChange { _, phase in
                    switch phase {
                    case .idle:
                        isScrolling = false
                    case .tracking, .decelerating:
                        isScrolling = true
                    @unknown default:
                        isScrolling = false
                    }
                }
            }
            .navigationTitle("My Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarVisibility(isScrolling ? .hidden : .visible, for: .navigationBar)
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

#Preview {
    ContentView()
}


import SwiftUI

// Define the reusable color
extension Color {
    static let appIconBackground = Color(red: 0.8, green: 0.88, blue: 0.82) // Neutral greenish
}

// 1. Define NoteItem Struct
struct NoteItem: Identifiable {
    let id = UUID()
    var title: String
    var dateString: String
    var iconName: String
}

// NEW: Enum for the list items
enum DisplayableListItem: Identifiable {
    case note(NoteItem)
    case dateSeparator(String)

    var id: String {
        switch self {
        case .note(let item):
            return item.id.uuidString
        case .dateSeparator(let text):
            return text // Separator texts should be unique enough for ID in sample data
        }
    }
}

struct ContentView: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var safeAreaTop: CGFloat = 0
    
    // UPDATED: Sample Data using DisplayableListItem
    @State private var displayItems: [DisplayableListItem] = [
        .dateSeparator("Earlier Today"),
        .note(NoteItem(title: "Meeting Recap", dateString: "10:30 AM", iconName: "doc.text.fill")),
        .note(NoteItem(title: "Call John", dateString: "2:00 PM", iconName: "phone.fill")),
        .dateSeparator("Thu 08 May"),
        .note(NoteItem(title: "Project Proposal", dateString: "3:15 PM", iconName: "folder.fill")),
        .dateSeparator("Tue 06 May"),
        .note(NoteItem(title: "Grocery List", dateString: "9:00 AM", iconName: "list.bullet")),
        .dateSeparator("Last Week"),
        .note(NoteItem(title: "Book Flight", dateString: "Morning", iconName: "airplane"))
    ]

    // Constants for the new design
    private let largeScrollableTitleFontSize: CGFloat = 34
    private let navbarTitleFontSize: CGFloat = 18
    private let navbarContentHeight: CGFloat = 44 // Height of the navbar's content area (e.g., title)
    private let scrollTransitionThreshold: CGFloat = 60 // Pixels to scroll for full transition

    // Animation computed properties based on scrollOffset
    private var scrollProgress: CGFloat {
        // Normalized scroll: 0 (top) to 1 (scrolled past threshold)
        let progress = abs(scrollOffset) / scrollTransitionThreshold
        return min(1.0, max(0.0, progress))
    }

    private var scrollViewHeadingOpacity: CGFloat {
        // Fades out as you scroll down (0.0 to 1.0 maps to 1.0 to 0.0 opacity)
        // Start fading a bit later and fade faster
        let adjustedProgress = max(0, (abs(scrollOffset) - (scrollTransitionThreshold * 0.2)) / (scrollTransitionThreshold * 0.8))
        return 1.0 - min(1.0, max(0.0, adjustedProgress))
    }

    private var navbarElementsOpacity: CGFloat {
        // Fades in as you scroll down
        return scrollProgress
    }
    
    private var blurIntensity: CGFloat {
        // Blur increases with scroll, capped
        return scrollProgress * 10
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Set overall background for the ZStack content area (ScrollView will be on top)
                Color(.systemGray6) // Slightly gray background
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Rectangle()
                            .frame(height: 1)
                            .opacity(0)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("scroll")).minY)
                                }
                            )

                        Text("My Notes")
                            .font(.system(size: largeScrollableTitleFontSize, weight: .bold))
                            .padding(.top, safeAreaTop + 20)
                            .padding(.bottom, 15)
                            .opacity(scrollViewHeadingOpacity)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            // Make sure heading text color is appropriate for gray background
                            .foregroundColor(Color(.label))

                        // UPDATED: ForEach loop and conditional rendering
                        ForEach(displayItems) { item in
                            switch item {
                            case .dateSeparator(let text):
                                Text(text)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(.secondaryLabel))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 15)
                                    .padding(.bottom, 5)
                                    // No horizontal padding here, relies on ScrollView's main padding

                            case .note(let note):
                                HStack(spacing: 15) {
                                    // Icon Container - Size Adjusted
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10) // Slightly smaller corner radius
                                            .fill(Color.appIconBackground)
                                            .frame(width: 35, height: 35) // ADJUSTED SIZE
                                        Image(systemName: note.iconName)
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.system(size: 20, weight: .medium)) // Slightly smaller icon font
                                    }

                                    // Text Content
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(note.title)
                                            .font(.headline)
                                            .foregroundColor(Color(.label))
                                        Text(note.dateString)
                                            .font(.subheadline)
                                            .foregroundColor(Color(.secondaryLabel))
                                    }
                                    Spacer()
                                }
                                .padding(14) // ADJUSTED PADDING for the card
                                .background(Color(.systemBackground))
                                .cornerRadius(10) // Slightly smaller corner radius for card
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2) // Adjusted shadow
                            }
                        }
                    }
                    .padding(.horizontal) // This provides horizontal padding for cards and separators
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    // Ensure scrollOffset is always 0 or negative (scrolling down)
                    self.scrollOffset = min(0, value)
                    print("ScrollOffsetKey changed: \(self.scrollOffset)") // DEBUG
                }
                
                // New Overlay Navbar
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("My Notes")
                            .font(.system(size: navbarTitleFontSize, weight: .semibold))
                            .opacity(navbarElementsOpacity)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .frame(height: navbarContentHeight)
                    
                    if scrollProgress >= 0.95 { // Show divider when navbar is almost fully opaque
                        Divider()
                            .opacity(navbarElementsOpacity) // Also tied to navbar opacity
                    }
                }
                .padding(.top, safeAreaTop) // Position content below safe area inset
                .frame(maxWidth: .infinity) // Span full width
                // Total height includes safe area, content height, and potential 1pt divider
                .frame(height: safeAreaTop + navbarContentHeight + (scrollProgress >= 0.95 ? 1 : 0))
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(navbarElementsOpacity) // Background fades in
                        .blur(radius: blurIntensity)
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: scrollProgress)
                .onChange(of: scrollProgress) { newValue in // DEBUG
                    print("scrollProgress changed: \(newValue), navbarElementsOpacity: \(navbarElementsOpacity)")
                }
            }
            .edgesIgnoringSafeArea(.top)
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    safeAreaTop = window.safeAreaInsets.top
                }
            }
        }
    }
}

// ScrollOffset preference key
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ContentView()
}


import Foundation

struct NoteDataProvider {
    // Static DateFormatters
    static let inputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Important for parsing
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    static let dateSeparatorFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return formatter
    }()

    // Static Raw Notes Data
    static let rawNotesData: [(title: String, dateString: String, icon: String, isCustom: Bool)] = [
        ("Note: Granola app integration ideas", "May 9, 6:00 PM", "device_phone_portrait", true),
        ("project phase one review and client communication strategy", "May 9, 1:34 PM", "doc.text.fill", false),
        ("Note: Granola preparation process insights", "May 8, 9:27 PM", "device_phone_portrait", true),
        ("Project plan review and user research insights for ml dashboard", "May 6, 6:04 PM", "doc.text.fill", false),
        ("Untitled Meeting", "May 5, 10:31 PM", "doc.text.fill", false),
        ("Wireframe and data visualization strategy for multi-objective reinforcement learning dashboard", "May 2, 6:10 PM", "doc.text.fill", false),
        ("Customer insights for Compass wearable device user experience", "May 2, 5:32 PM", "doc.text.fill", false),
        ("Project repo and weekly meeting setup", "May 2, 1:35 PM", "doc.text.fill", false),
        ("Tomek Sapeta <> Compass", "Apr 22, 3:00 PM", "doc.text.fill", false)
    ]
} 
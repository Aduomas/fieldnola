import SwiftUI

// Color Extension for Icon Background
extension Color {
    static let appIconBackground = Color(red: 0.8, green: 0.88, blue: 0.82)
}

// Data Model for a Single Note
struct NoteItem: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
    var iconName: String
    var isCustomIcon: Bool = false
    var dateString: String = "" // Populated with formatted time
}

// Enum to represent either a Note or a Date Separator in the list
enum DisplayableListItem: Identifiable {
    case note(NoteItem)
    case dateSeparator(String)

    var id: String {
        switch self {
        case .note(let item):
            return item.id.uuidString
        case .dateSeparator(let text):
            return text // Assuming separator texts are unique enough for ID in sample data
        }
    }
}

// View for displaying a single Note Card
struct NoteCardView: View {
    let note: NoteItem

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appIconBackground)
                    .frame(width: 35, height: 35)
                if note.isCustomIcon {
                    Image(note.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Image(systemName: note.iconName)
                        .foregroundColor(Color.gray)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(note.dateString)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// View for displaying a Date Separator
struct DateSeparatorView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Color(.secondaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 15)
            .padding(.bottom, 5)
    }
} 
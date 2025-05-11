import SwiftUI

struct NoteDetailView: View {
    let note: NoteItem
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Note title - large multi-line text
                Text(note.title)
                    .font(.system(size: 32, weight: .bold))
                    .padding(.top, 8)
                    .padding(.horizontal)
                
                // Date with icon
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    
                    Text(formatFullDate(note.date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Markdown content placeholder
                // In a real app, this would render actual markdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("This is a placeholder for markdown content.")
                        .font(.body)
                    
                    ForEach(1...10, id: \.self) { i in
                        Text("Sample paragraph \(i) to demonstrate scrolling behavior.")
                            .font(.body)
                            .padding(.vertical, 3)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 30)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("My Notes")
                    }
                    .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.42))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        // Share note functionality would go here
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.42))
                    }
                    
                    Button(action: {
                        // More options functionality would go here
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.42))
                    }
                }
            }
        }
        .background(Color.secondary.opacity(0.1))
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

struct NoteItem: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
    var iconName: String
    var isCustomIcon: Bool = false
    var dateString: String = "" // Populated with formatted time
}

#Preview {
    // Create a sample note for preview
    let sampleDate = Date()
    let sampleNote = NoteItem(
        title: "Project plan review and user research insights for ml dashboard",
        date: sampleDate,
        iconName: "doc.text.fill"
    )
    
    NavigationView {
        NoteDetailView(note: sampleNote)
    }
} 
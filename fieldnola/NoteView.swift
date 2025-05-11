import SwiftUI

class TranscriptManager: ObservableObject {
    @Published var segments: [TranscriptSegment] = []
    
    init(sampleData: Bool = false) {
        if sampleData {
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        segments = [
            TranscriptSegment(id: UUID(), text: "We should focus on improving the user experience first.", timestamp: 0, duration: 5.2),
            TranscriptSegment(id: UUID(), text: "The mobile app needs to be our top priority for Q2.", timestamp: 6.1, duration: 4.8),
            TranscriptSegment(id: UUID(), text: "Let's schedule a follow-up meeting with the design team next week.", timestamp: 12.4, duration: 6.5)
        ]
    }
}

struct TranscriptSegment: Identifiable {
    let id: UUID
    let text: String
    let timestamp: TimeInterval
    let duration: TimeInterval
    
    var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct NoteView: View {
    let note: NoteItem
    @Environment(\.presentationMode) var presentationMode
    @State private var isSettingsPresented = false
    @State private var isSharePresented = false
    @State private var isEditing = false
    @State private var markdownContent: String
    
    // Add state for transcript functionality
    @State private var isTranscriptPresented = false
    @StateObject private var transcriptManager = TranscriptManager(sampleData: true)
    
    // Initialize with sample content or pass from parent
    init(note: NoteItem, initialContent: String? = nil) {
        self.note = note
        let defaultContent = """
        # Meeting Notes
        
        ## Agenda Items
        
        1. Project timeline review
        2. User research findings
        3. Next steps
        
        ## Key Decisions
        
        - Extend research phase by one week
        - Focus on mobile experience first
        - Schedule follow-up with stakeholders
        
        ## Action Items
        
        - [ ] Send meeting summary to team
        - [x] Update project timeline
        - [ ] Schedule user testing sessions
        """
        
        // Use the provided content or default to sample
        _markdownContent = State(initialValue: initialContent ?? defaultContent)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGray6)
                .edgesIgnoringSafeArea(.all)
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Note title
                    Text(note.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 12)
                        .padding(.horizontal)
                        .multilineTextAlignment(.leading)
                    
                    // Date with icon
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                            .font(.system(size: 15))
                        
                        Text(formatFullDate(note.date))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    // Content section
                    if isEditing {
                        contentEditorView
                    } else {
                        contentDisplayView
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 30)
            }
            
            // Floating edit button (if not in edit mode)
            if !isEditing {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                    }
                }
            }
            
            // Transcript bottom sheet
            TranscriptBottomSheet(transcriptManager: transcriptManager, isPresented: $isTranscriptPresented)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Leading navigation items
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if isEditing {
                        // Ask for confirmation if editing
                        // In a real app, you might want to show an alert here
                        isEditing = false
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("My Notes")
                    }
                    .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.42))
                }
            }
            
            // Title in navigation bar
            ToolbarItem(placement: .principal) {
                Text("Note")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            // Trailing navigation items
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Done button when editing
                    if isEditing {
                        Button(action: {
                            withAnimation {
                                isEditing = false
                                // In a real app, save the content here
                            }
                        }) {
                            Text("Done")
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.42))
                        }
                    } else {
                        // Normal toolbar buttons when viewing
                        Button(action: {
                            isSharePresented = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.42))
                        }
                        .sheet(isPresented: $isSharePresented) {
                            shareSheet
                        }
                        
                        Button(action: {
                            isSettingsPresented = true
                        }) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.42))
                        }
                        .actionSheet(isPresented: $isSettingsPresented) {
                            settingsActionSheet
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Content Views
    
    private var contentDisplayView: some View {
        VStack(alignment: .leading) {
            MarkdownRenderer(content: markdownContent)
                .padding(.horizontal)
        }
    }
    
    private var contentEditorView: some View {
        VStack(alignment: .leading) {
            // Basic editor - in a real app, you would use a more sophisticated editor
            TextEditor(text: $markdownContent)
                .font(.body)
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .frame(minHeight: 300)
                .padding(.horizontal)
            
            // Simple markdown guide
            VStack(alignment: .leading, spacing: 8) {
                Text("Markdown Guide")
                    .font(.headline)
                    .padding(.top, 12)
                
                markdownGuideItem(symbol: "# ", description: "Heading 1")
                markdownGuideItem(symbol: "## ", description: "Heading 2")
                markdownGuideItem(symbol: "- ", description: "Bullet point")
                markdownGuideItem(symbol: "1. ", description: "Numbered list")
                markdownGuideItem(symbol: "> ", description: "Blockquote")
                markdownGuideItem(symbol: "- [ ] ", description: "Task (unchecked)")
                markdownGuideItem(symbol: "- [x] ", description: "Task (checked)")
                markdownGuideItem(symbol: "`code`", description: "Inline code")
                markdownGuideItem(symbol: "```", description: "Code block (surround with triple backticks)")
                markdownGuideItem(symbol: "[text](url)", description: "Link")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
    
    private func markdownGuideItem(symbol: String, description: String) -> some View {
        HStack {
            Text(symbol)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(description)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Views
    
    // Action sheet for settings
    private var settingsActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Options"),
            buttons: [
                .default(Text("Edit Note")) {
                    withAnimation {
                        isEditing = true
                    }
                },
                .default(Text("Show Transcript")) {
                    withAnimation {
                        isTranscriptPresented = true
                    }
                },
                .default(Text("Add to Favorites")) {
                    // Add to favorites action would go here
                },
                .default(Text("Add Tags")) {
                    // Add tags action would go here
                },
                .destructive(Text("Delete Note")) {
                    // Delete action would go here
                },
                .cancel()
            ]
        )
    }

    
    // Share sheet
    private var shareSheet: some View {
        VStack {
            Text("Share Note")
                .font(.headline)
                .padding()
            
            HStack(spacing: 30) {
                // Sample share options
                shareButton(icon: "message.fill", text: "Message")
                shareButton(icon: "envelope.fill", text: "Mail")
                shareButton(icon: "doc.on.doc", text: "Copy")
                shareButton(icon: "square.and.arrow.down", text: "Save")
            }
            .padding(.vertical, 30)
            
            Button("Cancel") {
                isSharePresented = false
            }
            .padding()
        }
        .frame(height: 200)
    }
    
    private func shareButton(icon: String, text: String) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.42))
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
struct TranscriptBottomSheet: View {
    @ObservedObject var transcriptManager: TranscriptManager
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            if isPresented {
                Color.black
                    .opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
            }
            
            // Transcript view
            VStack {
                Spacer()
                
                TranscriptView(transcriptManager: transcriptManager, isPresented: $isPresented)
                    #if os(iOS)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
                    #else
                    .frame(maxHeight: 600) // Fixed height for macOS
                    #endif
                    .transition(.move(edge: .bottom))
            }
            .edgesIgnoringSafeArea(.bottom)
            .opacity(isPresented ? 1 : 0)
            #if os(iOS)
            .offset(y: isPresented ? 0 : UIScreen.main.bounds.height)
            #else
            .offset(y: isPresented ? 0 : 1000) // Large enough offset for macOS
            #endif
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct TranscriptView: View {
    @ObservedObject var transcriptManager: TranscriptManager
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Transcript")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 15)
            
            // Empty state
            if transcriptManager.segments.isEmpty {
                emptyTranscriptView
            } else {
                // Transcript segments
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(transcriptManager.segments) { segment in
                            TranscriptSegmentCard(segment: segment)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            
        }
        #if os(iOS)
        .background(Color(UIColor.systemGray6))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .cornerRadius(15)
    }
    
    // Empty state view
    private var emptyTranscriptView: some View {
        VStack(spacing: 15) {
            Image(systemName: "text.bubble")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.7))
            
            Text("No transcript available")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Start recording to generate transcript")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }
}

struct TranscriptSegmentCard: View {
    let segment: TranscriptSegment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Timestamp and duration
            HStack {
                Text(segment.formattedTimestamp)
                    .font(.footnote)
                    .foregroundColor(Color(.systemGray))
                
                Spacer()
                
                Text(segment.formattedDuration)
                    .font(.footnote)
                    .foregroundColor(Color(.systemGray))
            }
            
            Text(segment.text)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// Sample Preview
struct NoteView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample note for preview
        let sampleDate = Date()
        let sampleNote = NoteItem(
            title: "Project plan review and user research insights for ML dashboard",
            date: sampleDate,
            iconName: "doc.text.fill"
        )
        
        NavigationView {
            NoteView(note: sampleNote)
        }
    }
}

import SwiftUI
import ActivityKit

// Color Extension for Icon Background
extension Color {
    static let appIconBackground = Color(red: 0.8, green: 0.88, blue: 0.82)
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
                    .frame(width: 38, height: 38)
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
            
            VStack(alignment: .leading, spacing: 4) { // Increased spacing for better distribution
                Spacer(minLength: 0) // Help center content
                Text(note.title)
                    .font(.system(size: 16, weight: .semibold)) // Changed from headline to semibold
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(note.dateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer(minLength: 0) // Help center content
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white)
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
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 15)
            .padding(.bottom, 5)
    }
}

// Recording States
enum RecordingState {
    case idle
    case recording
    case paused
}

// Activity Attributes for Live Activity in Dynamic Island
struct RecordingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var duration: TimeInterval
        var isRecording: Bool
        var isPaused: Bool
    }
    
    var title: String
}

// Bottom Sheet Recording View
struct RecordingBottomSheet: View {
    @Binding var isPresented: Bool
    @Binding var recordingState: RecordingState
    @Binding var recordingDuration: TimeInterval
    @State private var sheetHeight: CGFloat = 0.45
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Sheet handle and close button
            HStack {
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                    recordingState = .idle
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            
            // Note title
            Text("New note")
                .font(.system(size: 24, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Description text
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .foregroundColor(.gray)
                
                Text("Feel free to write notes here")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 6)
            
            Spacer()
            
            // Recording controls
            HStack(alignment: .center) {
                // Pause/Resume Button
                Button(action: {
                    recordingState = recordingState == .recording ? .paused : .recording
                }) {
                    Image(systemName: recordingState == .recording ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                }
                .frame(width: 44, height: 44)
                
                Spacer()
                
                // Waveform and duration
                HStack(spacing: 6) {
                    // Simple waveform visualization
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.green)
                            .frame(width: 3, height: CGFloat(10 + Int.random(in: 5...20)))
                    }
                    
                    // Duration text
                    Text(formatDuration(recordingDuration))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .monospacedDigit()
                    
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.green)
                            .frame(width: 3, height: CGFloat(10 + Int.random(in: 5...20)))
                    }
                }
                
                Spacer()
                
                // End Button
                Button(action: {
                    isPresented = false
                    recordingState = .idle
                }) {
                    Text("End")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .background(Color(red: 0.06, green: 0.54, blue: 0.42))
                        .cornerRadius(30)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .background(Color.white)
        .cornerRadius(16)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Simple drag without needing screen dimensions
                    let newOffset = value.translation.height
                    if newOffset < 0 {
                        // Dragging up - limit how far it can go
                        dragOffset = max(newOffset, -200)
                    } else {
                        // Dragging down - allow regular movement
                        dragOffset = newOffset
                    }
                }
                .onEnded { _ in
                    // Reset to default positions
                    withAnimation(.spring()) {
                        if dragOffset < -100 {
                            // If dragged significantly up, expand to full screen
                            dragOffset = -300
                        } else if dragOffset > 100 {
                            // If dragged significantly down, dismiss
                            isPresented = false
                            recordingState = .idle
                        } else {
                            // Return to original position
                            dragOffset = 0
                        }
                    }
                }
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// New Recording Button
struct NewRecordingButton: View {
    @Binding var isRecordingPresented: Bool
    @Binding var recordingState: RecordingState
    
    var body: some View {
        Button(action: {
            isRecordingPresented = true
            recordingState = .recording
        }) {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 16))
                Text("New")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
    }
}

// Dynamic Island Recording Indicator
struct RecordingIndicator: View {
    @Binding var recordingState: RecordingState
    @Binding var recordingDuration: TimeInterval
    
    var body: some View {
        if recordingState != .idle {
            HStack(spacing: 8) {
                Circle()
                    .fill(recordingState == .recording ? Color.red : Color.orange)
                    .frame(width: 8, height: 8)
                    .opacity(recordingState == .recording ? 1.0 : 0.6)
                
                Text(formatDuration(recordingDuration))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 

import SwiftUI

enum SheetPosition {
    case closed, mid, full
}

struct BottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    @Binding var title: String
    @Binding var description: String
    @Binding var isRecording: Bool
    @Binding var isPaused: Bool
    @Binding var recordingDuration: Double
    @Binding var waveformHeights: [CGFloat]
    
    let content: Content
    let onClose: () -> Void
    let onPauseResume: () -> Void
    let onUpdateTitle: (String) -> Void
    
    @State private var sheetOffset: CGFloat = 0
    @State private var sheetPosition: SheetPosition = .mid
    @State private var sheetScrollOffset: CGFloat = 0
    
    // Sheet position constants
    private let closedPosition: CGFloat = 1000
    private let midPosition: CGFloat = 320
    private let fullPosition: CGFloat = 50
    
    init(
        isPresented: Binding<Bool>,
        title: Binding<String>,
        description: Binding<String>,
        isRecording: Binding<Bool>,
        isPaused: Binding<Bool>,
        recordingDuration: Binding<Double>,
        waveformHeights: Binding<[CGFloat]>,
        onClose: @escaping () -> Void,
        onPauseResume: @escaping () -> Void,
        onUpdateTitle: @escaping (String) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self._title = title
        self._description = description
        self._isRecording = isRecording
        self._isPaused = isPaused
        self._recordingDuration = recordingDuration
        self._waveformHeights = waveformHeights
        self.onClose = onClose
        self.onPauseResume = onPauseResume
        self.onUpdateTitle = onUpdateTitle
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    closeSheet()
                }
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Interactive bottom sheet
                    VStack(spacing: 0) {
                        // Handle indicator at the very top edge of the sheet
                        VStack(spacing: 0) {
                            // Thin horizontal line handle
                            Capsule()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 36, height: 5)
                                .padding(.top, 8)
                                .padding(.bottom, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .clipShape(CustomCorner(corners: [.topLeft, .topRight], radius: 16))
                        
                        // Rest of the sheet content
                        VStack(spacing: 0) {
                            // Close button row
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    closeSheet()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.gray)
                                        .padding(10)
                                }
                                .padding(.top, 0)
                                .padding(.trailing, 4)
                            }
                            .padding(.horizontal)
                            
                            // Scrollable content area
                            ScrollView {
                                ScrollDetector { offset in
                                    sheetScrollOffset = offset
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    // Editable note title
                                    TextField("Title", text: $title)
                                        .font(.system(size: 24, weight: .bold))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                        .padding(.top, 4)
                                        .onChange(of: title) { newValue in
                                            onUpdateTitle(newValue)
                                        }
                                    
                                    // Editable description text
                                    TextField("Description", text: $description)
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                        .padding(.top, 6)
                                    
                                    // Custom content
                                    content
                                    
                                    // Add extra space at the bottom to ensure content is scrollable
                                    Spacer(minLength: 300)
                                }
                            }
                            .disabled(sheetPosition != .full) // Only enable scrolling in full position
                            
                            Spacer(minLength: 0)
                        }
                        .background(Color.white)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .offset(y: calculateSheetOffset(in: geometry))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: sheetOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: sheetPosition)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Only allow dragging when not scrolling in full mode
                                if !(sheetPosition == .full && sheetScrollOffset > 5) {
                                    sheetOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                snapSheetToPosition(dragTranslation: value.predictedEndTranslation.height)
                            }
                    )
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // Recording controls - fixed to the screen
            VStack {
                Spacer()
                
                // Controls container with background
                VStack(spacing: 8) {
                    // Buttons, waveform and duration in one row
                    HStack {
                        // Pause/Resume Button
                        Button(action: {
                            onPauseResume()
                        }) {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 110, height: 60)
                                .background(Color(.systemGray5))
                                .cornerRadius(30)
                        }
                        
                        Spacer()
                        
                        // Waveform and duration together as a single centered unit
                        HStack(spacing: 4) {
                            // Waveform in the middle
                            ZStack {
                                ForEach(0..<3, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(Color(red: 0.06, green: 0.54, blue: 0.42))
                                        .frame(width: 3, height: waveformHeights[i])
                                        .offset(x: CGFloat(i * 6))
                                }
                            }
                            .frame(width: 40, height: 40)
                            
                            // Duration text
                            Text(formatDuration(recordingDuration))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                                .monospacedDigit()
                                .frame(width: 40, height: 40)
                        }
                        .frame(width: 100)
                        
                        Spacer()
                        
                        // End Button
                        Button(action: {
                            closeSheet()
                        }) {
                            Text("End")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 110, height: 60)
                                .background(Color(red: 0.06, green: 0.54, blue: 0.42))
                                .cornerRadius(30)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
            }
            .edgesIgnoringSafeArea(.bottom)
            .zIndex(100) // Ensure controls are above the sheet
        }
    }
    
    // Calculate the actual offset based on current sheet position and drag offset
    private func calculateSheetOffset(in geometry: GeometryProxy) -> CGFloat {
        let baseHeight: CGFloat
        switch sheetPosition {
        case .closed:
            baseHeight = closedPosition
        case .mid:
            baseHeight = midPosition
        case .full:
            baseHeight = fullPosition
        }
        
        return baseHeight + sheetOffset
    }
    
    // Determine where to snap the sheet based on the drag
    private func snapSheetToPosition(dragTranslation: CGFloat) {
        withAnimation {
            sheetOffset = 0 // Reset the drag offset
            
            // Determine which position to snap to based on current position and drag
            switch sheetPosition {
            case .full:
                if dragTranslation > 50 {
                    sheetPosition = .mid
                } else if dragTranslation > 300 {
                    closeSheet()
                } else {
                    sheetPosition = .full
                }
            case .mid:
                if dragTranslation < -50 {
                    sheetPosition = .full
                } else if dragTranslation > 120 {
                    closeSheet()
                } else {
                    sheetPosition = .mid
                }
            case .closed:
                if dragTranslation < -50 {
                    sheetPosition = .mid
                }
            }
        }
    }
    
    // Helper to close the sheet
    private func closeSheet() {
        // First animate to the closed position
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            sheetPosition = .closed
            sheetOffset = 0
        }
        
        // Then after animation, hide the sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            onClose()
            
            // Reset sheet state for next time
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                sheetPosition = .mid
            }
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// Reuse the ScrollDetector view from ContentView
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
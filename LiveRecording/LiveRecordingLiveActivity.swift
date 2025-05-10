//
//  LiveRecordingLiveActivity.swift
//  LiveRecording
//
//  Created by Adomas Valiukevicius on 5/10/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// This struct must match the one in ContentView.swift
struct LiveRecordingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that changes during recording
        var duration: TimeInterval
        var isRecording: Bool
        var isPaused: Bool
    }

    // Fixed properties that don't change
    var title: String
}

struct LiveRecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveRecordingAttributes.self) { context in
            // Lock screen/banner UI
            VStack(spacing: 8) {
                HStack {
                    Text(context.attributes.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "waveform")
                        .foregroundColor(.green)
                }
                
                HStack(spacing: 12) {
                    // Recording status indicator
                    Circle()
                        .fill(context.state.isPaused ? Color.orange : Color.red)
                        .frame(width: 12, height: 12)
                        .opacity(context.state.isRecording ? 1.0 : 0.0)
                        .opacity(context.state.isPaused ? 0.6 : 1.0)
                    
                    // Duration text
                    Text(formatDuration(context.state.duration))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    
                    Spacer()
                    
                    // Recording controls
                    HStack(spacing: 16) {
                        Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        
                        Image(systemName: "stop.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "waveform")
                        .foregroundColor(.green)
                        .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatDuration(context.state.duration))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .padding(.trailing, 4)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.attributes.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(context.state.isPaused ? Color.orange : Color.red)
                                    .frame(width: 8, height: 8)
                                    .opacity(context.state.isPaused ? 0.6 : 1.0)
                                
                                Text(context.state.isPaused ? "Recording paused" : "Recording in progress")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            Button {
                                // Handled by the app
                            } label: {
                                Image(systemName: context.state.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.42))
                            }
                            
                            Button {
                                // Handled by the app
                            } label: {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                Image(systemName: "waveform")
                    .foregroundColor(.green)
            } compactTrailing: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(context.state.isPaused ? Color.orange : Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(context.state.isRecording ? 1.0 : 0.0)
                        .opacity(context.state.isPaused ? 0.6 : 1.0)
                    
                    Text(formatDuration(context.state.duration))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            } minimal: {
                Image(systemName: "waveform")
                    .foregroundColor(.green)
            }
            .keylineTint(Color.green)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension LiveRecordingAttributes {
    fileprivate static var preview: LiveRecordingAttributes {
        LiveRecordingAttributes(title: "New note")
    }
}

extension LiveRecordingAttributes.ContentState {
    fileprivate static var recording: LiveRecordingAttributes.ContentState {
        LiveRecordingAttributes.ContentState(
            duration: 45,
            isRecording: true,
            isPaused: false
        )
    }
     
    fileprivate static var paused: LiveRecordingAttributes.ContentState {
        LiveRecordingAttributes.ContentState(
            duration: 120,
            isRecording: true,
            isPaused: true
        )
    }
}

#Preview("Notification", as: .content, using: LiveRecordingAttributes.preview) {
   LiveRecordingLiveActivity()
} contentStates: {
    LiveRecordingAttributes.ContentState.recording
    LiveRecordingAttributes.ContentState.paused
}

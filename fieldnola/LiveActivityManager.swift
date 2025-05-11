#if canImport(ActivityKit)
import ActivityKit

import SwiftUI


struct LiveRecordingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var duration: TimeInterval
        var isRecording: Bool
        var isPaused: Bool
    }
    
    var title: String
}

class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var recordingActivity: Activity<LiveRecordingAttributes>? = nil
    
    private init() {}
    
    var isLiveActivitySupported: Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    // Getter to check if we have an active recording
    var hasActiveRecording: Bool {
        return recordingActivity != nil
    }
    
    // Method to update the title of existing activity
    func updateActivityTitle(_ title: String, duration: TimeInterval, isPaused: Bool) {
        guard let activity = recordingActivity else { return }
        
        Task {
            let updatedContentState = LiveRecordingAttributes.ContentState(
                duration: duration,
                isRecording: true,
                isPaused: isPaused
            )
            
            await activity.update(
                ActivityContent(state: updatedContentState, staleDate: nil)
            )
        }
    }
    
    func startRecordingActivity(title: String) {
        guard isLiveActivitySupported else { return }
        
        do {
            let attributes = LiveRecordingAttributes(title: title)
            let initialContentState = LiveRecordingAttributes.ContentState(
                duration: 0,
                isRecording: true,
                isPaused: false
            )
            
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil)
            )
            
            self.recordingActivity = activity
            print("Started recording LiveActivity with ID: \(activity.id)")
        } catch {
            print("Error starting LiveActivity: \(error.localizedDescription)")
        }
    }
    
    func updateRecordingActivity(duration: TimeInterval, isPaused: Bool) {
        guard let activity = recordingActivity else { return }
        
        Task {
            let updatedContentState = LiveRecordingAttributes.ContentState(
                duration: duration,
                isRecording: true,
                isPaused: isPaused
            )
            
            await activity.update(
                ActivityContent(state: updatedContentState, staleDate: nil)
            )
        }
    }
    
    func endRecordingActivity() {
        guard let activity = recordingActivity else { return }
        
        Task {
            let finalContentState = LiveRecordingAttributes.ContentState(
                duration: 0,
                isRecording: false,
                isPaused: false
            )
            
            await activity.end(
                ActivityContent(state: finalContentState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            
            recordingActivity = nil
        }
    }
}
#endif

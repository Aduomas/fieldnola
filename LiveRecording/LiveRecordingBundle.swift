//
//  LiveRecordingBundle.swift
//  LiveRecording
//
//  Created by Adomas Valiukevicius on 5/10/25.
//

import WidgetKit
import SwiftUI

@main
struct LiveRecordingBundle: WidgetBundle {
    var body: some Widget {
        LiveRecording()
        LiveRecordingControl()
        LiveRecordingLiveActivity()
    }
}

//
//  ContentView.swift
//  SegmentPeople
//
//  Created by Nguyen Loc on 21/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var cameraModel = CameraViewModel()
    var body: some View {
        CameraView()
    }
}

#Preview {
    ContentView()
}

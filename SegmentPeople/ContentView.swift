//
//  ContentView.swift
//  SegmentPeople
//
//  Created by Nguyen Loc on 21/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var cameraModel = CameraViewModel()
    @State var selectedFilter: FilterItem?
    var body: some View {
        CameraView(viewModel: cameraModel)
            .onChange(of: selectedFilter) { newScenePhase in
                cameraModel.pipeline?.reset()
                cameraModel.addPeopleSegmentFilter()
                cameraModel.pipeline?.addFilter { image in
                    let selected = newScenePhase
                    let filter = selected?.filterNameType.getCIFilter()
                    if let filter = filter {
                        let bgimage = UIImage(named: "IMG8")
                        
                        let values = CIFilterValueHelper.filter.randomValuesForFilter(filter)
                        for (key, value) in values {
                            filter.setValue(value, forKey: key)
                        }
                        for key in filter.inputKeys {
                            if key == "inputImage" {
                                filter.setValue(image, forKey: "inputImage")
                                continue
                            }
                        }
                        return filter.outputImage ?? image
                    }
                    return image
                }
            }
        HStack {
            Spacer()
            CIFilterView(selectedFilter: $selectedFilter)
                .frame(maxHeight: 400)
        }
    }
}

#Preview {
    ContentView()
}

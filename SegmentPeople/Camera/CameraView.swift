//
//  CameraView.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/24/25.
//

import SwiftUI

struct CameraView: View {
    @ObservedObject var viewModel: CameraViewModel
    var body: some View {
        VStack {
            ZStack {
                VStack {
                    if viewModel.isSessionRunning {
                        CameraPreview(session: viewModel.session)
                        Spacer()
                    }
                    
                    if let error = viewModel.error {
                        Text("Camera Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                AdvancedDraggableResizableView {
                    ZStack {
                        Image(viewModel.selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        VStack {
                            if let mask = viewModel.segmentationMask {
                                Image(mask, scale: 1.0, label: Text("Segmentation Mask"))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .border(.red, width: 1)
                                    .overlay {
                                        GeometryReader { proxy in
                                            let _ = print(proxy)
                                            let x = viewModel.faceBox.origin.x.scaled(by: proxy.size.width)
                                            let y = viewModel.faceBox.origin.y.scaled(by: proxy.size.height)
                                            Rectangle()
                                                .position(x: x, y:y)
                                                .frame(width: viewModel.faceBox.width*proxy.size.width, height: viewModel.faceBox.height*proxy.size.height)
                                                .background(.red.opacity(0.2))
                                        }
                                    }
                            }
                            
                        }
                    }
                }
                HStack {
                    Button {
                        self.viewModel.selectedImage = viewModel.ranges.randomElement() ?? ""
                    } label: {
                        Text("Next")
                    }
                    
                    Button {
                        viewModel.pipeline?.addFilter { image in
                            guard let image = image else { return nil }
                            let vignetteFilter = CIFilter.zoomBlur()
                            vignetteFilter.inputImage = image
                            vignetteFilter.setValue(30, forKey: "inputAmount")
                            vignetteFilter.setValue(CIVector(x: 350, y: 200), forKey: "inputCenter")
                //            vignetteFilter.center = .init(x: 200, y: 500)
                //            vignetteFilter.radius = 1.0
                            return vignetteFilter.outputImage
                        }
                    } label: {
                        Text("Filters")
                    }
                    
                }

            }
            .frame(maxWidth: .infinity, minHeight: 300, alignment: .top)
            
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
}

#Preview {
    CameraView(viewModel: .init())
}

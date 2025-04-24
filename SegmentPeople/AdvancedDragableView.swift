//
//  AdvancedDragableView.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/22/25.
//

import SwiftUI

struct AdvancedDraggableResizableView<Content: View>: View {
    @State private var position = CGPoint(x: 100, y: 000)
    @State private var size = CGSize(width: 200, height: 200)
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var lastDragPosition: CGPoint?
    @State private var resizeStartPosition: CGPoint?
    @State private var resizeStartSize: CGSize?
    @State private var activeCorner: Corner?
    
    private let minSize: CGSize = CGSize(width: 80, height: 80)
    private let handleSize: CGFloat = 18
    private let content: Content
    
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Main content
            content
                .frame(width: size.width, height: size.height)
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: isDragging ? 3 : 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                .position(position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isResizing {
                                if !isDragging {
                                    isDragging = true
                                    lastDragPosition = position
                                }
                                let translation = value.translation
                                if let lastPosition = lastDragPosition {
                                    position = CGPoint(
                                        x: lastPosition.x + translation.width,
                                        y: lastPosition.y + translation.height
                                    )
                                }
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            lastDragPosition = nil
                        }
                )
            
            // Resize handles
            ForEach(corners(), id: \.self) { corner in
                resizeHandle(for: corner)
            }
        }
    }
    
    private func corners() -> [Corner] {
        return [.topLeft, .topRight, .bottomLeft, .bottomRight]
    }
    
    private func resizeHandle(for corner: Corner) -> some View {
        let isActive = activeCorner == corner && isResizing
        
        return Circle()
            .fill(isActive ? Color.red : Color.blue)
            .frame(width: handleSize, height: handleSize)
            .position(position(for: corner))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            if !isResizing {
                                isResizing = true
                                activeCorner = corner
                                resizeStartPosition = position
                                resizeStartSize = size
                            }
                            
                            guard let startPos = resizeStartPosition,
                                  let startSize = resizeStartSize else { return }
                            
                            var newSize = startSize
                            var newPosition = startPos
                            
                            // Apply different resize logic based on which corner is being dragged
                            switch corner {
                            case .topLeft:
                                let widthChange = -value.translation.width
                                let heightChange = -value.translation.height
                                
                                newSize.width = max(minSize.width, startSize.width + widthChange)
                                newSize.height = max(minSize.height, startSize.height + heightChange)
                                
                                // Adjust position to keep the bottom-right corner fixed
                                newPosition.x = startPos.x - (newSize.width - startSize.width) / 2
                                newPosition.y = startPos.y - (newSize.height - startSize.height) / 2
                                
                            case .topRight:
                                let widthChange = value.translation.width
                                let heightChange = -value.translation.height
                                
                                newSize.width = max(minSize.width, startSize.width + widthChange)
                                newSize.height = max(minSize.height, startSize.height + heightChange)
                                
                                // Adjust position to keep the bottom-left corner fixed
                                newPosition.x = startPos.x + (newSize.width - startSize.width) / 2
                                newPosition.y = startPos.y - (newSize.height - startSize.height) / 2
                                
                            case .bottomLeft:
                                let widthChange = -value.translation.width
                                let heightChange = value.translation.height
                                
                                newSize.width = max(minSize.width, startSize.width + widthChange)
                                newSize.height = max(minSize.height, startSize.height + heightChange)
                                
                                // Adjust position to keep the top-right corner fixed
                                newPosition.x = startPos.x - (newSize.width - startSize.width) / 2
                                newPosition.y = startPos.y + (newSize.height - startSize.height) / 2
                                
                            case .bottomRight:
                                let widthChange = value.translation.width
                                let heightChange = value.translation.height
                                
                                newSize.width = max(minSize.width, startSize.width + widthChange)
                                newSize.height = max(minSize.height, startSize.height + heightChange)
                                
                                // Adjust position to keep the top-left corner fixed
                                newPosition.x = startPos.x + (newSize.width - startSize.width) / 2
                                newPosition.y = startPos.y + (newSize.height - startSize.height) / 2
                            }
                            
                            size = newSize
                            position = newPosition
                        }
                    }
                    .onEnded { _ in
                        isResizing = false
                        activeCorner = nil
                        resizeStartPosition = nil
                        resizeStartSize = nil
                    }
            )
    }
    
    private func position(for corner: Corner) -> CGPoint {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        
        switch corner {
        case .topLeft:
            return CGPoint(
                x: position.x - halfWidth + handleSize/2,
                y: position.y - halfHeight + handleSize/2
            )
        case .topRight:
            return CGPoint(
                x: position.x + halfWidth - handleSize/2,
                y: position.y - halfHeight + handleSize/2
            )
        case .bottomLeft:
            return CGPoint(
                x: position.x - halfWidth + handleSize/2,
                y: position.y + halfHeight - handleSize/2
            )
        case .bottomRight:
            return CGPoint(
                x: position.x + halfWidth - handleSize/2,
                y: position.y + halfHeight - handleSize/2
            )
        }
    }
}

// Example usage in your app
struct AdvancedResizableViewExample: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            
            AdvancedDraggableResizableView {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Resize Me")
                        .font(.headline)
                        .padding(.top, 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    AdvancedResizableViewExample()
}

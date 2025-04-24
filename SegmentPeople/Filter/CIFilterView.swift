//
//  CIFilterView.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/24/25.
//

import SwiftUI

struct CIFilterView: View {
    @StateObject var viewModel: ViewModel = .init()
    @Binding var selectedFilter: FilterItem?
    var body: some View {
        VStack {
            Text("SelectedFilter: \(selectedFilter?.filterName)")
            CIFilterItemList(filterList: viewModel.filterList, selectedFilter: $selectedFilter)
        }
        
    }
}

struct CIFilterItemList: View {
    let filterList: [FilterItem]
    @Binding var selectedFilter: FilterItem?
    private var columns: [GridItem] {
        let columnsCount = Int(ceil(Double(filterList.count) / 3.0))
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
    }
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(filterList.indices, id: \.self) { index in
                    let filter = filterList[index]
                    let isSelected = selectedFilter?.filterNameType == filter.filterNameType
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.filterName)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minWidth: 80)
                    }
                    .padding(8)
                    .background(isSelected ? Color.primary : Color.secondary)
                    .foregroundColor(isSelected ? Color.secondary : Color.primary)
                    .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    CIFilterView(selectedFilter: .constant(nil))
}

extension CIFilterView {
    class ViewModel: ObservableObject {
        var filterList: [FilterItem] = []
        init() {
            filterList = CIFilterHelper().getAllCIFilters()
        }
    }
}

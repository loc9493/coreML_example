//
//  CIFilterView.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/24/25.
//

import SwiftUI

struct CIFilterView: View {
    @StateObject var viewModel: ViewModel = .init()
    var body: some View {
        VStack {
            Text("SelectedFilter: \(viewModel.selectedFilter?.filterName)")
            CIFilterItemList(filterList: viewModel.filterList, selectedFilter: $viewModel.selectedFilter)
        }
        
    }
}

struct CIFilterItemList: View {
    let filterList: [FilterItem]
    @Binding var selectedFilter: FilterItem?
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(filterList.indices) { index in
                    let _ = print(index)
                    let filter = filterList[index]
                    let isSelected = selectedFilter?.filterNameType == filter.filterNameType
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.filterName)
                    }
                    .padding()
                    .background(isSelected ? .primary : .secondary)
                    .cornerRadius(8)

                }
            }
        }
    }
}

#Preview {
    CIFilterView()
}

extension CIFilterView {
    class ViewModel: ObservableObject {
        var filterList: [FilterItem] = []
        @Published var selectedFilter: FilterItem? = nil
        init() {
            filterList = CIFilterHelper().getAllCIFilters()
        }
    }
}

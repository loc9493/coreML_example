//
//  CIFilterHelper.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/24/25.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

struct FilterItem {
    var filterName: String
    var filterNameType: String
}
struct CIFilterHelper {
    func getAllCIFilters() -> [FilterItem] {
        // Get all filter names
        let filterNames = CIFilter.filterNames(inCategory: nil)
        var result = [FilterItem]()
        filterNames.forEach { filterName in
            if let filter = filterName.getCIFilter(), let displayName = filter.attributes["CIAttributeFilterDisplayName"] as? String {
                let filterItem = FilterItem.init(filterName: displayName, filterNameType: filter.name)
                result.append(filterItem)
            }
        }
        return result
    }
}

extension String {
    func getCIFilter() -> CIFilter? {
        return CIFilter(name: self)
    }
}

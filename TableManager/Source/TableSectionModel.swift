//
//  TableSectionModel.swift
//  TableManager
//
//  Created by Susmita Horrow on 06/01/19.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import Foundation

public struct TableSectionModel: Hashable {
    public let cellModels: [TableCellModel]
    public let headerModel: TableViewHeaderFooterModel?
    public let footerModel: TableViewHeaderFooterModel?
    
   public init(cellModels: [TableCellModel], headerModel: TableViewHeaderFooterModel? = nil, footerModel: TableViewHeaderFooterModel? = nil) {
        self.cellModels = cellModels
        self.headerModel = headerModel
        self.footerModel = footerModel
    }
    
    public static func == (lhs: TableSectionModel, rhs: TableSectionModel) -> Bool {
        return lhs.cellModels.map { $0.identifier } == rhs.cellModels.map { $0.identifier } && lhs.headerModel?.identifier == rhs.headerModel?.identifier && lhs.footerModel?.identifier == rhs.footerModel?.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        self.headerModel?.identifier.hash(into: &hasher)
        self.footerModel?.identifier.hash(into: &hasher)
        for cellModel in self.cellModels {
            cellModel.identifier.hash(into: &hasher)
        }
    }
}

//
//  TableSectionModel.swift
//  TableManager
//
//  Created by Susmita Horrow on 06/01/19.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import Foundation
import DeepDiff

public struct TableSectionModel: Hashable, DiffAware {
    public var diffId: Int {
        return self.hashValue
    }
    
    public static func compareContent(_ a: TableSectionModel, _ b: TableSectionModel) -> Bool {
        return a == b
    }
    
    public let cellModels: [TableCellModel]
    public let headerModel: TableViewHeaderFooterModel?
    public let footerModel: TableViewHeaderFooterModel?
    let equatableCellModels: [EquatableCellModel]
    public let identifier: String
    
    public init(identifier: String, cellModels: [TableCellModel], headerModel: TableViewHeaderFooterModel? = nil, footerModel: TableViewHeaderFooterModel? = nil) {
        self.identifier = identifier
        self.cellModels = cellModels
        self.headerModel = headerModel
        self.footerModel = footerModel
        self.equatableCellModels = cellModels.map { EquatableCellModel(cellModel: $0) }
    }
    
    public static func == (lhs: TableSectionModel, rhs: TableSectionModel) -> Bool {
        guard lhs.cellModels.count == rhs.cellModels.count else {
            return false
        }
        return (lhs.equatableCellModels == rhs.equatableCellModels)
            && lhs.isHeaderModelEqual(sectionModel: rhs)
            && lhs.isFooterModelEqual(sectionModel: rhs)
    }
    
    public func isHeaderModelEqual(sectionModel: TableSectionModel) -> Bool {
        var isEqual = true
        if let headerModel = self.headerModel, let otherHeaderModel = sectionModel.headerModel {
            isEqual = isEqual && headerModel.isEqual(item: otherHeaderModel)
        } else {
            isEqual = isEqual && (self.headerModel == nil && sectionModel.headerModel == nil)
        }
        return isEqual
    }
    
    public func isFooterModelEqual(sectionModel: TableSectionModel) -> Bool {
        var isEqual = true
        if let footerModel = self.footerModel, let otherFooterModel = sectionModel.footerModel {
            isEqual = isEqual && footerModel.isEqual(item: otherFooterModel)
        } else {
            isEqual = isEqual && (self.footerModel == nil && sectionModel.footerModel == nil)
        }
        return isEqual
    }
    
    public func hash(into hasher: inout Hasher) {
        self.identifier.hash(into: &hasher)
    }
}

struct EquatableCellModel: Hashable, DiffAware {
    var diffId: Int {
        return self.hashValue
    }
    
    static func compareContent(_ a: EquatableCellModel, _ b: EquatableCellModel) -> Bool {
        return a == b
    }
    
    static func == (lhs: EquatableCellModel, rhs: EquatableCellModel) -> Bool {
        return lhs.cellModel.isEqual(item: rhs.cellModel)
    }
    func hash(into hasher: inout Hasher) {
        self.cellModel.identifier.hash(into: &hasher)
    }
    let cellModel: TableCellModel
    init(cellModel: TableCellModel) {
        self.cellModel = cellModel
    }
}

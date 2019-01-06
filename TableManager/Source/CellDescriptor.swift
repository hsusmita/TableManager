//
//  CellDescriptor.swift
//  TableManager
//
//  Created by Susmita Horrow on 06/01/19.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import UIKit

public enum CellPrototypeSource {
    case storyboard
    case nib(UINib)
    case `class`(AnyObject.Type)
}

public enum CellHeight {
    case constant(CGFloat)
    case automatic
    case customHeight((IndexPath, Any) -> CGFloat)
    
    func value(indexPath: IndexPath, item: Any) -> CGFloat {
        switch self {
        case .constant(let height):
            return height
        case .automatic:
            return UITableView.automaticDimension
        case .customHeight(let closure):
            return closure(indexPath, item)
        }
    }
}

public struct CellDescriptor {
    public let reuseIdentifier: String
    public let prototypeSource: CellPrototypeSource
    public let height: CellHeight
    public let isMatching: (IndexPath, Any) -> Bool
    
    public init(
        _ reuseIdentifier: String,
        _ prototypeSource: CellPrototypeSource,
        _ height: CellHeight,
        isMatching: @escaping (IndexPath, Any) -> Bool) {
        
        self.reuseIdentifier = reuseIdentifier
        self.prototypeSource = prototypeSource
        self.height = height
        self.isMatching = isMatching
    }
    
    public init<Item>(
        _ reuseIdentifier: String,
        _ prototypeSource: CellPrototypeSource,
        _ height: CellHeight,
        _ itemType: Item.Type) {
        
        self.init(reuseIdentifier, prototypeSource, height) { $1 is Item }
    }
}

//
//  HeaderFooterDescriptor.swift
//  TableManager
//
//  Created by Susmita Horrow on 06/01/19.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import UIKit

enum HeaderFooterPrototypeSource {
    case none
    case nib(UINib)
    case `class`(AnyObject.Type)
}

enum HeaderFooterHeight {
    case constant(CGFloat)
    case automatic
    case customHeight((Int, Any) -> CGFloat)
    
    func value(index: Int, item: Any) -> CGFloat {
        switch self {
        case .constant(let height):
            return height
        case .automatic:
            return UITableView.automaticDimension
        case .customHeight(let closure):
            return closure(index, item)
        }
    }
}

struct HeaderFooterDescriptor {
    let reuseIdentifier: String
    let prototypeSource: HeaderFooterPrototypeSource
    let height: HeaderFooterHeight
    let isMatching: (Int, Any) -> Bool
    
    init(
        _ reuseIdentifier: String,
        _ prototypeSource: HeaderFooterPrototypeSource,
        _ height: HeaderFooterHeight,
        isMatching: @escaping (Int, Any) -> Bool) {
        
        self.reuseIdentifier = reuseIdentifier
        self.prototypeSource = prototypeSource
        self.height = height
        self.isMatching = isMatching
    }
    
    init<Item>(
        _ reuseIdentifier: String,
        _ prototypeSource: HeaderFooterPrototypeSource,
        _ height: HeaderFooterHeight,
        _ itemType: Item.Type) {
        
        self.init(reuseIdentifier, prototypeSource, height) { $1 is Item }
    }
}

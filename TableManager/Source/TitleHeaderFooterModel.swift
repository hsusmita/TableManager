//
//  TitleHeaderFooterModel.swift
//  TableManager
//
//  Created by Susmita Horrow on 06/01/19.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import Foundation

public struct TitleHeaderFooterModel: TableViewHeaderFooterModel, Hashable {
    public let title: String
    public let identifier: String
    
    public init(title: String, identifier: String = UUID().uuidString) {
        self.title = title
        self.identifier = identifier
    }
}


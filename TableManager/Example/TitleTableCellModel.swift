//
//  TitleTableCellModel.swift
//  TableManager
//
//  Created by Susmita Horrow on 04/07/2019.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import Foundation

struct TitleTableCellModel: TableCellModel, Hashable {
    var identifier: String {
        return title
    }
    let title: String
}

func ==(lhs: TitleTableCellModel, rhs: TitleTableCellModel) -> Bool {
    return lhs.title == rhs.title
}

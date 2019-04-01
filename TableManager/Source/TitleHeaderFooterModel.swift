//
//  TitleHeaderFooterModel.swift
//  TableManager
//
//  Created by Susmita Horrow on 06/01/19.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import Foundation

public struct TitleHeaderFooterModel: TableViewHeaderFooterModel {
	public let title: String
	public let identifier = UUID().uuidString
	
	public init(title: String) {
		self.title = title
	}
}

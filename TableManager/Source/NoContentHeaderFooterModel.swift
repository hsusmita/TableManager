//
//  NoContentHeaderFooterModel.swift
//  TableManager
//
//  Created by Susmita Horrow on 06/04/19.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import UIKit

public struct NoContentHeaderFooterModel: TableViewHeaderFooterModel {
	public let identifier: String
	public let backgroundColor: UIColor

	public init(identifier: String, backgroundColor: UIColor) {
		self.identifier = identifier
		self.backgroundColor = backgroundColor
	}
}

//
//  NoContentHeaderFooterView.swift
//  TableManager
//
//  Created by Susmita Horrow on 06/04/19.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import UIKit

public class NoContentHeaderFooterView: UITableViewHeaderFooterView, TableViewHeaderFooterView {
	@IBOutlet var containerView: UIView!

	public func configure(with model: TableViewHeaderFooterModel) {
		if let model = model as? NoContentHeaderFooterModel {
			self.containerView.backgroundColor = model.backgroundColor
		}
	}
}

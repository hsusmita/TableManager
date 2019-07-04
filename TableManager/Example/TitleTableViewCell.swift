//
//  TitleTableViewCell.swift
//  TableManager
//
//  Created by Susmita Horrow on 04/07/2019.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import UIKit

class TitleTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

extension TitleTableViewCell: TableViewCell {
    func configure(with cellModel: TableCellModel) {
        if let model = cellModel as? TitleTableCellModel {
            self.titleLabel.text = model.title
        }
    }
}

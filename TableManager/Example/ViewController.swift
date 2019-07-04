//
//  ViewController.swift
//  TableManager
//
//  Created by Susmita Horrow on 28/11/18.
//  Copyright © 2018 hsusmita. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private var tableViewManager: TableViewManager?
    
    override func viewDidLoad() {
		super.viewDidLoad()
        self.configureTableView()
        let models = [
            TitleTableCellModel(title: "Title1"),
            TitleTableCellModel(title: "Title2"),
            TitleTableCellModel(title: "Title3"),
            TitleTableCellModel(title: "Title4"),
            TitleTableCellModel(title: "Title5"),
            TitleTableCellModel(title: "Title6"),
            TitleTableCellModel(title: "Title7"),
            TitleTableCellModel(title: "Title8")
        ]
        self.tableViewManager?.reload(cellModels: models)
    }
    
    private func configureTableView() {
        let cellDescriptor = CellDescriptor(
            TitleTableViewCell.reuseIdentifier,
            .nib(TitleTableViewCell.nib),
            .constant(85.0),
            TitleTableCellModel.self
        )
        self.tableViewManager = TableViewManager(self.tableView, cellDescriptors: [cellDescriptor])
        self.tableView.estimatedRowHeight = 60.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableViewManager?.delegate = self
    }
}

extension ViewController: TableViewManagerProtocol {
    func manager(manager: TableViewManager, didSelect indexPath: IndexPath) {

    }
    
    func manager(manager: TableViewManager, didDeselect indexPath: IndexPath) {
        
    }
    
    func manager(manager: TableViewManager, didInvokeCTA cta: EventCTA, indexPath: IndexPath) {
        
    }
}

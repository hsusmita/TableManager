//
//  TableManager.swift
//  TableManager
//
//  Created by Susmita Horrow on 28/11/18.
//  Copyright © 2018 hsusmita. All rights reserved.
//

import UIKit
import DeepDiff

public protocol TableCellModel {
	var identifier: String { get }
}

public protocol TableViewHeaderFooterModel {
	var identifier: String { get }
}

public protocol TableViewCell {
	func configure(with cellModel: TableCellModel)
}

public protocol TableViewHeaderFooterView {
	func configure(with model: TableViewHeaderFooterModel)
}

public protocol TableViewCellEventDelegate {
	func handleEvent(cell: TableViewCell, event: EventCTA)
}

public protocol TableViewHeaderFooterEventDelegate {
	func handleEvent(headerFooterView: TableViewHeaderFooterView, event: EventCTA)
}

public protocol EventEmittingElement {
	var events: [Event] { get }
}

public protocol EventEmittingCell: EventEmittingElement {
	var delegate: TableViewCellEventDelegate? { get set }
}

public protocol EventEmittingHeaderFooter: EventEmittingElement {
	var delegate: TableViewHeaderFooterEventDelegate? { get set }
}

public protocol TableViewManagerProtocol {
	func manager(manager: TableViewManager, didSelect indexPath: IndexPath)
	func manager(manager: TableViewManager, didDeselect indexPath: IndexPath)
	func manager(manager: TableViewManager, didInvokeCTA cta: EventCTA, indexPath: IndexPath)
	func manager(manager: TableViewManager, didHeaderFooterInvokeCTA cta: EventCTA, section: Int)
}

public extension TableViewManagerProtocol {
	func manager(manager: TableViewManager, didInvokeCTA cta: EventCTA, indexPath: IndexPath){}
	func manager(manager: TableViewManager, didSelect indexPath: IndexPath){}
	func manager(manager: TableViewManager, didDeselect indexPath: IndexPath){}
	func manager(manager: TableViewManager, didHeaderFooterInvokeCTA cta: EventCTA, section: Int){}
}

public class TableViewManager: NSObject {
	private(set) var sectionModels: [TableSectionModel] = []
	private var reuseIdentifierForCell: (IndexPath, TableCellModel) -> String
	private var reuseIdentifierForHeader: ((Int, TableViewHeaderFooterModel) -> String)?
	private var reuseIdentifierForFooter: ((Int, TableViewHeaderFooterModel) -> String)?
	private var heightForCell: (IndexPath, TableCellModel) -> CGFloat
	private var heightForHeader: ((Int, TableViewHeaderFooterModel) -> CGFloat)?
	private var heightForFooter: ((Int, TableViewHeaderFooterModel) -> CGFloat)?
	
	public var tableView: UITableView
	public var delegate: TableViewManagerProtocol?
	
	public required init(_ tableView: UITableView, cellDescriptors: [CellDescriptor]) {
		self.tableView = tableView
		self.reuseIdentifierForCell = { indexPath, item in
			for descriptor in cellDescriptors {
				if descriptor.isMatching(indexPath, item) {
					return descriptor.reuseIdentifier
				}
			}
			fatalError("ReuseIdentifier not found for indexPath = \(indexPath) item = \(item)")
		}
		
		self.heightForCell = { indexPath, item in
			var height = UITableView.automaticDimension
			for descriptor in cellDescriptors {
				if descriptor.isMatching(indexPath, item) {
					height = descriptor.height.value(indexPath: indexPath, item: item)
					break
				}
			}
			return height
		}
		super.init()
		for descriptor in cellDescriptors {
			switch descriptor.prototypeSource {
			case .storyboard:
				break
			case .nib(let nib):
				tableView.register(nib, forCellReuseIdentifier: descriptor.reuseIdentifier)
			case .class(let type):
				tableView.register(type, forCellReuseIdentifier: descriptor.reuseIdentifier)
			}
		}
		
		tableView.dataSource = self
		self.tableView.delegate = self
	}
	
	func configureHeaderDescriptor(_ headerDescriptors: [HeaderFooterDescriptor]) {
		self.reuseIdentifierForHeader = { index, item in
			for descriptor in headerDescriptors {
				if descriptor.isMatching(index, item) {
					return descriptor.reuseIdentifier
				}
			}
			fatalError("ReuseIdentifier for header not found for section = \(index) item = \(item)")
		}
		self.registerHeaderFooter(headerDescriptors)
		
		self.heightForHeader = { index, item in
			var height = UITableView.automaticDimension
			for descriptor in headerDescriptors {
				if descriptor.isMatching(index, item) {
					height = descriptor.height.value(index: index, item: item)
					break
				}
			}
			return height
		}
	}
	
	func configureFooterDescriptor(_ footerDescriptors: [HeaderFooterDescriptor]) {
		self.reuseIdentifierForHeader = { index, item in
			for descriptor in footerDescriptors {
				if descriptor.isMatching(index, item) {
					return descriptor.reuseIdentifier
				}
			}
			fatalError("ReuseIdentifier for footer not found for section = \(index) item = \(item)")
		}
		self.registerHeaderFooter(footerDescriptors)
		
		self.heightForFooter = { index, item in
			var height = UITableView.automaticDimension
			for descriptor in footerDescriptors {
				if descriptor.isMatching(index, item) {
					height = descriptor.height.value(index: index, item: item)
					break
				}
			}
			return height
		}
	}
	
	private func registerHeaderFooter(_ headerDescriptors: [HeaderFooterDescriptor]) {
		for descriptor in headerDescriptors {
			switch descriptor.prototypeSource {
			case .none:
				break
			case .nib(let nib):
				tableView.register(nib, forHeaderFooterViewReuseIdentifier: descriptor.reuseIdentifier)
			case .class(let type):
				tableView.register(type, forHeaderFooterViewReuseIdentifier: descriptor.reuseIdentifier)
			}
		}
	}
	
	public func reload(with sectionModels: [TableSectionModel]) {
		let old = self.sectionModels
		self.sectionModels = sectionModels
		let changes = diff(old: old, new: sectionModels)
		self.tableView.applyChanges(changes)
	}
	
	public func reload(cellModels: [TableCellModel]) {
		let sectionModel = TableSectionModel(cellModels: cellModels)
		self.sectionModels = [sectionModel]
		let changes = diff(old: self.sectionModels.first?.equatableCellModels ?? [], new: sectionModel.equatableCellModels)
		if !changes.isEmpty {
			self.tableView.reload(changes: changes, updateData: { [weak self] in
				self?.sectionModels = [sectionModel]
			}, completion: nil)
		}
	}
	
	public func model(at indexPath: IndexPath) -> TableCellModel {
		let sectionModel = sectionModels[indexPath.section]
		return sectionModel.cellModels[indexPath.row]
	}
	
	public func selectedModels() -> [TableCellModel] {
		guard let indexPaths = tableView.indexPathsForSelectedRows else {
			return []
		}
		return indexPaths.map { model(at: $0) }
	}
}

extension TableViewManager: UITableViewDataSource {
	public func numberOfSections(in tableView: UITableView) -> Int {
		return sectionModels.count
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.sectionModels[section].cellModels.count
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cellModel = self.sectionModels[indexPath.section].cellModels[indexPath.row]
		let reuseIdentifier = self.reuseIdentifierForCell(indexPath, cellModel)
		let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
		if let tableViewCell = cell as? TableViewCell {
			tableViewCell.configure(with: cellModel)
		}
		if var eventEmittingCell = cell as? EventEmittingCell {
			eventEmittingCell.delegate = self
		}
		return cell
	}
	
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let cellModel = self.sectionModels[indexPath.section].cellModels[indexPath.row]
		return self.heightForCell(indexPath, cellModel)
	}
	
	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let headerModel = self.sectionModels[section].headerModel as? TitleHeaderFooterModel
		return headerModel?.title
	}
	
	public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		let footerModel = self.sectionModels[section].footerModel as? TitleHeaderFooterModel
		return footerModel?.title
	}
}

extension TableViewManager: UITableViewDelegate {
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		delegate?.manager(manager: self, didSelect: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		delegate?.manager(manager: self, didDeselect: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let headerModel = sectionModels[section].headerModel else {
			return nil
		}
		guard let reuseIdentifier = self.reuseIdentifierForHeader?(section, headerModel) else {
			return nil
		}
		let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier)
		if let view = headerView as? TableViewHeaderFooterView {
			view.configure(with: headerModel)
		}
		if var eventEmittingHeader = headerView as? EventEmittingHeaderFooter {
			eventEmittingHeader.delegate = self
		}
		return headerView
	}
	
	public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		guard let headerModel = sectionModels[section].headerModel else {
			return 0.0
		}
		return self.heightForHeader?(section, headerModel) ?? UITableView.automaticDimension
	}
	
	public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		guard let footerModel = sectionModels[section].footerModel else {
			return nil
		}
		guard let reuseIdentifier = self.reuseIdentifierForFooter?(section, footerModel) else {
			return nil
		}
		let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier)
		if let view = footerView as? TableViewHeaderFooterView {
			view.configure(with: footerModel)
		}
		if var eventEmittingFooter = footerView as? EventEmittingHeaderFooter {
			eventEmittingFooter.delegate = self
		}
		return footerView
	}
	
	public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		guard let footerModel = sectionModels[section].footerModel else {
			return 0.0
		}
		return self.heightForFooter?(section, footerModel) ?? UITableView.automaticDimension
	}
}

extension TableViewManager: TableViewCellEventDelegate {
	public func handleEvent(cell: TableViewCell, event: EventCTA) {
		let indexPath = tableView.indexPath(for: cell as! UITableViewCell)
		delegate?.manager(manager: self, didInvokeCTA: event, indexPath: indexPath!)
	}
}

extension TableViewManager: TableViewHeaderFooterEventDelegate {
	public func handleEvent(headerFooterView: TableViewHeaderFooterView, event: EventCTA) {
		for index in 0..<self.sectionModels.count {
			let reuseIdentifier = tableView.headerView(forSection: index)!.reuseIdentifier
			let headerModel = self.sectionModels[index].headerModel!
			if self.reuseIdentifierForHeader?(index, headerModel) == reuseIdentifier {
				delegate?.manager(manager: self, didHeaderFooterInvokeCTA: event, section: index)
				break
			}
		}
	}
}

extension UITableView {
	fileprivate func unifiedPerformBatchUpdates(
		_ updates: (() -> Void),
		completion: (@escaping (Bool) -> Void)) {
		
		if #available(iOS 11, tvOS 11, *) {
			self.performBatchUpdates(updates, completion: completion)
		} else {
			self.beginUpdates()
			updates()
			self.endUpdates()
			completion(true)
		}
	}
	
	fileprivate func applyChanges(_ changes: [Change<TableSectionModel>]) {
		let inserts = changes.compactMap({ $0.insert }).map({ $0.index })
		let deletes = changes.compactMap({ $0.delete }).map({ $0.index })
		let replaces = changes.compactMap({ $0.replace }).map({ $0.index })
		let moves = changes.compactMap({ $0.move }).map({
			(
				from: $0.fromIndex,
				to: $0.toIndex
			)
		})
		self.unifiedPerformBatchUpdates({
			deletes.executeIfPresent {
				self.deleteSections(IndexSet($0), with: .automatic)
			}
			
			inserts.executeIfPresent {
				self.insertSections(IndexSet($0), with: .automatic)
			}
			
			moves.executeIfPresent {
				$0.forEach { move in
					self.moveSection(move.from, toSection: move.to)
				}
			}
		}, completion: { _ in })
		
		replaces.executeIfPresent {
			self.reloadSections(IndexSet($0), with: .automatic)
		}
	}
}

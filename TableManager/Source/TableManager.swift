//
//  TableManager.swift
//  TableManager
//
//  Created by Susmita Horrow on 28/11/18.
//  Copyright © 2018 hsusmita. All rights reserved.
//

import UIKit
import DeepDiff

public protocol TableItemModel {
    var identifier: String { get }
    func isEqual(item: TableItemModel) -> Bool
}

public extension TableItemModel where Self: Equatable {
    func isEqual(item: TableItemModel) -> Bool {
        guard let item = item as? Self else { return false }
        return self == item
    }
}

public typealias TableCellModel = TableItemModel
public typealias TableViewHeaderFooterModel = TableItemModel

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

public enum TableViewAnimationKey {
    case rowInsert
    case rowDelete
    case rowReload
    case sectionInsert
    case sectionDelete
    case sectionReload
}

open class TableViewManager: NSObject {
    private(set) public var sectionModels: [TableSectionModel] = []
    private var reuseIdentifierForCell: (IndexPath, TableCellModel) -> String
    private var reuseIdentifierForHeader: ((Int, TableViewHeaderFooterModel) -> String)?
    private var reuseIdentifierForFooter: ((Int, TableViewHeaderFooterModel) -> String)?
    private var heightForCell: (IndexPath, TableCellModel) -> CGFloat
    private var heightForHeader: ((Int, TableViewHeaderFooterModel) -> CGFloat)?
    private var heightForFooter: ((Int, TableViewHeaderFooterModel) -> CGFloat)?
    private var animationStyleDictionary: [TableViewAnimationKey: UITableView.RowAnimation] = [:]
    
    public var tableView: UITableView
    public var delegate: TableViewManagerProtocol?
    public var animationOn = true
    var tableReloadInProcess = false
    
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
        self.animationStyleDictionary[.rowInsert] = .automatic
        self.animationStyleDictionary[.rowDelete] = .automatic
        self.animationStyleDictionary[.rowReload] = .automatic
        self.animationStyleDictionary[.sectionInsert] = .automatic
        self.animationStyleDictionary[.sectionDelete] = .automatic
        self.animationStyleDictionary[.sectionReload] = .automatic
    }
    
    public func configureHeaderDescriptor(_ headerDescriptors: [HeaderFooterDescriptor]) {
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
    
    public func configureFooterDescriptor(_ footerDescriptors: [HeaderFooterDescriptor]) {
        self.reuseIdentifierForFooter = { index, item in
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
                self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: descriptor.reuseIdentifier)
            case .class(let type):
                self.tableView.register(type, forHeaderFooterViewReuseIdentifier: descriptor.reuseIdentifier)
            }
        }
    }
    
    public func reload(with sectionModels: [TableSectionModel]) {
        if self.sectionModels.isEmpty {
            self.sectionModels = sectionModels
            self.tableView.reloadData()
        } else {
            let old = self.sectionModels
            let changes = diff(old: old, new: sectionModels)
            self.tableReloadInProcess = true
            self.sectionModels = sectionModels
            self.tableView.applyChanges(
                changes,
                animationOn: self.animationOn,
                animationStyles: self.animationStyleDictionary,
                completion: { _ in
                    self.tableReloadInProcess = false
            })
        }
    }
    
    public func reload(cellModels: [TableCellModel]) {
        let sectionModel = TableSectionModel(identifier: "First", cellModels: cellModels)
        if self.sectionModels.isEmpty {
            self.sectionModels = [sectionModel]
            self.tableView.reloadData()
        } else {
            let changes = diff(old: self.sectionModels.first?.equatableCellModels ?? [], new: sectionModel.equatableCellModels)
            if !changes.isEmpty {
                self.sectionModels = [sectionModel]
                self.tableReloadInProcess = true
                self.tableView.reload(
                    changes: changes,
                    updateData: { [weak self] in
                        self?.tableReloadInProcess = false
                    },
                    completion: nil)
            }
        }
    }
    
    public func model(at indexPath: IndexPath) -> TableCellModel {
        let sectionModel = sectionModels[indexPath.section]
        return sectionModel.cellModels[indexPath.row]
    }
    
    public func selectedModels() -> [TableCellModel] {
        guard let indexPaths = self.tableView.indexPathsForSelectedRows else {
            return []
        }
        return indexPaths.map { model(at: $0) }
    }
    
    public func setAnimationStyle(key: TableViewAnimationKey, value: UITableView.RowAnimation) {
        self.animationStyleDictionary[key] = value
    }
}

extension TableViewManager: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionModels.count
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
        self.delegate?.manager(manager: self, didSelect: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.delegate?.manager(manager: self, didDeselect: indexPath)
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
        return self.heightForHeader?(section, headerModel) ?? 0.0
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
        return self.heightForFooter?(section, footerModel) ?? 0.0
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard let headerModel = sectionModels[section].headerModel else {
            return 0.0
        }
        return self.heightForHeader?(section, headerModel) ?? 0.0
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        guard let footerModel = sectionModels[section].footerModel else {
            return 0.0
        }
        return self.heightForFooter?(section, footerModel) ?? 0.0
    }
}

extension TableViewManager: TableViewCellEventDelegate {
    public func handleEvent(cell: TableViewCell, event: EventCTA) {
        let indexPath = tableView.indexPath(for: cell as! UITableViewCell)
        self.delegate?.manager(manager: self, didInvokeCTA: event, indexPath: indexPath!)
    }
}

extension TableViewManager: TableViewHeaderFooterEventDelegate {
    public func handleEvent(headerFooterView: TableViewHeaderFooterView, event: EventCTA) {
        for index in 0..<self.sectionModels.count {
            if let reuseIdentifier = self.tableView.headerView(forSection: index)?.reuseIdentifier {
                let headerModel = self.sectionModels[index].headerModel!
                if self.reuseIdentifierForHeader?(index, headerModel) == reuseIdentifier {
                    self.delegate?.manager(manager: self, didHeaderFooterInvokeCTA: event, section: index)
                    break
                }
            }
        }
    }
}

extension UITableView {
    fileprivate func unifiedPerformBatchUpdates(
        _ updates: (() -> Void),
        animationOn: Bool,
        completion: (@escaping (Bool) -> Void)) {
        
        if #available(iOS 11, tvOS 11, *) {
            if !animationOn {
                UIView.setAnimationsEnabled(false)
            }
            self.performBatchUpdates(updates, completion: { result in
                UIView.setAnimationsEnabled(true)
                completion(result)
            })
        } else {
            self.beginUpdates()
            if !animationOn {
                UIView.setAnimationsEnabled(false)
            }
            updates()
            self.endUpdates()
            UIView.setAnimationsEnabled(true)
            completion(true)
        }
    }
    
    fileprivate func applyChanges(
        _ changes: [Change<TableSectionModel>],
        animationOn: Bool,
        animationStyles: ([TableViewAnimationKey: UITableView.RowAnimation]),
        completion: (@escaping (Bool) -> Void)) {
        let inserts = changes.compactMap { $0.insert }.map { $0.index }
        let deletes = changes.compactMap { $0.delete }.map { $0.index }
        let replaces = changes.compactMap { $0.replace }.map { $0.index }
        let moves = changes.compactMap { $0.move }.map {
            (
                from: $0.fromIndex,
                to: $0.toIndex
            )
        }
        self.unifiedPerformBatchUpdates({
            deletes.executeIfPresent {
                self.deleteSections(IndexSet($0), with: animationStyles[.sectionDelete] ?? .automatic)
            }
            
            inserts.executeIfPresent {
                self.insertSections(IndexSet($0), with: animationStyles[.sectionInsert] ?? .automatic)
            }
            
            moves.executeIfPresent {
                $0.forEach { move in
                    self.moveSection(move.from, toSection: move.to)
                }
            }
            replaces.executeIfPresent { _ in
                self.applyChangesForCellModels(changes, animationStyles: animationStyles)
            }
        }, animationOn: animationOn,
           completion: completion
        )
    }
    
    fileprivate func applyChangesForCellModels(
        _ changes: [Change<TableSectionModel>],
        animationStyles: ([TableViewAnimationKey: UITableView.RowAnimation])) {
        let replaces = changes.compactMap({ $0.replace })
        let rowInsertAnimation = animationStyles[.rowInsert] ?? .automatic
        let rowDeleteAnimation = animationStyles[.rowDelete] ?? .automatic
        let rowReloadAnimation = animationStyles[.rowReload] ?? .automatic
        let sectionReloadAnimation = animationStyles[.sectionReload] ?? .automatic
        
        replaces.forEach { replace in
            guard replace.oldItem.isHeaderModelEqual(sectionModel: replace.newItem) &&
                replace.oldItem.isFooterModelEqual(sectionModel: replace.newItem) else {
                    self.reloadSections(IndexSet([replace.index]), with: sectionReloadAnimation)
                    return
            }
            guard !replace.oldItem.cellModels.isEmpty else {
                self.reloadSections(IndexSet([replace.index]), with: sectionReloadAnimation)
                return
            }
            let modelChanges = diff(old: replace.oldItem.equatableCellModels, new: replace.newItem.equatableCellModels)
            
            let inserts = modelChanges.compactMap { $0.insert }
                .map { $0.index }
                .map { IndexPath(item: $0, section: replace.index) }
            
            let deletes = modelChanges.compactMap { $0.delete }
                .map { $0.index }
                .map { IndexPath(item: $0, section: replace.index) }
            
            let moves = modelChanges.compactMap { $0.move }
                .map { (
                    from: IndexPath(item: $0.fromIndex, section: replace.index),
                    to: IndexPath(item: $0.toIndex, section: replace.index)
                    ) }
            
            var replaces = modelChanges.compactMap { $0.replace }
                .map { $0.index }
                .map { IndexPath(item: $0, section: replace.index) }
            
            //Remove delete and insert indexes for replaces
            replaces.removeAll(where: { deletes.contains($0) })
            replaces.removeAll(where: { inserts.contains($0) })

            self.insertRows(at: inserts, with: rowInsertAnimation)
            self.deleteRows(at: deletes, with: rowDeleteAnimation)
            moves.forEach {
                self.moveRow(at: $0.from, to: $0.to)
            }
            self.reloadRows(at: replaces, with: rowReloadAnimation)
        }
    }
}

//
//  UIViewExtensions.swift
//  TableManager
//
//  Created by Susmita Horrow on 04/07/2019.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import UIKit

extension UIView {
    static var reuseIdentifier: String { return String(describing: self).components(separatedBy: ".").last! }
    static var nib: UINib { return UINib(nibName: self.reuseIdentifier, bundle: nil) }
}

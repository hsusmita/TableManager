//
//  Event.swift
//  TableManager
//
//  Created by Susmita Horrow on 06/01/19.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import Foundation

public protocol EventCTA {}

public struct EventListener {
	var target: AnyHashable
	var action: () -> ()
	func execute() {
		self.action()
	}
}

extension EventListener: Equatable {
	static public func == (lhs: EventListener, rhs: EventListener) -> Bool {
		return lhs.target == rhs.target
	}
}

public class Event {
	var cta: EventCTA
	private var listeners: [EventListener] = []
	
	public init(cta: EventCTA) {
		self.cta = cta
	}
	
	public func fire() {
		self.listeners.forEach({ $0.execute() })
	}
	
	public func addListener(listener: EventListener) {
		if let index = self.listeners.index(where: { $0.target == listener.target }) {
			self.listeners.remove(at: index)
		}
		self.listeners.append(listener)
	}
}


//
//  Event.swift
//  TableManager
//
//  Created by Susmita Horrow on 06/01/19.
//  Copyright © 2019 hsusmita. All rights reserved.
//

import Foundation

public protocol EventCTA {}

public class Event {
    struct EventListener {
        var target: AnyHashable
        var action: () -> ()
        func execute() {
            action()
        }
    }
    
    var cta: EventCTA
    init(cta: EventCTA) {
        self.cta = cta
    }
    private var listeners: [EventListener] = []
    
    func fire() {
        listeners.forEach({ $0.execute() })
    }
    
    func addListener(listener: EventListener) {
        if let index = listeners.index(where: { $0.target == listener.target }) {
            listeners.remove(at: index)
        }
        listeners.append(listener)
    }
}

extension Event.EventListener: Equatable {
    static public func == (lhs: Event.EventListener, rhs: Event.EventListener) -> Bool {
        return lhs.target == rhs.target
    }
}

//
//  SSoT.swift
//  Onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public protocol SSoT: AnyObject {}

extension SSoT {
    func dispatch(action: Action<Self>) async {
        await action.perform(self)
    }
}

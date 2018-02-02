//
//  ObjectManager.swift
//  MoyskladiOSRemapSDK
//
//  Created by Anton Efimenko on 22.01.2018.
//  Copyright © 2018 Andrey Parshakov. All rights reserved.
//

import Foundation

public class ObjectManager<Element> {
    private(set) var current: [Element]
    public private(set) var deleted: [Element]
    public private(set) var added: [Element]
    public private(set) var updated: [Element]
    private(set) var filtered: [Element]
    
    let isEqual: (Element, Element) -> Bool
    
    public init(data: [Element], isEqual: @escaping (Element, Element) -> Bool) {
        current = data
        filtered = current
        deleted = [Element]()
        added = [Element]()
        updated = [Element]()
        self.isEqual = isEqual
    }
    
    func contains(_ value: Element) -> Bool {
        return current.contains(where: { isEqual($0, value) })
    }
    
    public func append(_ value: Element) -> (Bool, count: Int) {
        guard !contains(where: { isEqual($0, value) }) else { return (false, current.count) }
        
        current.append(value)
        added.append(value)
        filtered = current
        
        return (true, current.count)
    }
    
    public func appendOrUpdate(_ value: Element) -> Int {
        guard !append(value).0 else { return current.count }
        _ = update(value)
        return 0
    }
    
    public func update(_ value: Element) -> (Bool, count: Int)  {
        // если нет в списке - выходим
        guard let currentIndex = index(where: { isEqual($0, value) }) else { return (false, current.count) }
        // если есть в списке добавленных - выходим
        guard !added.contains(where: { isEqual($0, value) }) else { return (false, current.count)  }
        
        if let updatedIndex = updated.index(where:{ isEqual($0, value) }) {
          updated[updatedIndex] = value
        } else {
            updated.append(value)
        }
        
        current[currentIndex] = value
        filtered = current
        
        return (true, current.count)
    }
    
    public func remove(_ value: Element) -> (Bool, count: Int) {
        guard let index = current.index(where: { isEqual($0, value) }) else { return (false, current.count) }
        current.remove(at: index)
        
        // если объект был добавлен, то удаляем его из списка добавленных
        if let addedIndex = added.index(where: { isEqual($0, value) }) {
            added.remove(at: addedIndex)
        } else {
            // если объект был изменен, то удаляем его из списка измененных
            if let updatedIndex = updated.index(where: { isEqual($0, value) }) {
                updated.remove(at: updatedIndex)
            }
            
            // и добавляем в список удаленных
            deleted.append(value)
        }
        filtered = current
        return (true, current.count)
    }
    
    public func filter(_ isIncluded: (Element) -> Bool) {
        filtered = current.filter(isIncluded)
    }
    
    public func removeFilter() {
        filtered = current
    }
    
    public func dropDeleted(count: Int) {
        deleted = Array(deleted.dropFirst(count))
    }
    
    public func refreshUpdated(with data: [Element]) {
        data.forEach { updatedElement in
            if let currentIndex = current.index(where: { isEqual($0, updatedElement) }) {
                current[currentIndex] = updatedElement
            }
            
            if let updatedIndex = updated.index(where: { isEqual($0, updatedElement) }) {
                updated.remove(at: updatedIndex)
            }
        }
    }
    
    public func refreshAdded(with data: [Element]) {
        data.forEach { updatedElement in
            if let currentIndex = current.index(where: { isEqual($0, updatedElement) }) {
                current[currentIndex] = updatedElement
            }
            
            if let addedIndex = added.index(where: { isEqual($0, updatedElement) }) {
                added.remove(at: addedIndex)
            }
        }
    }
    public func hasChanges() -> Bool {
        return deleted.count > 0 ||
            filtered.count > 0 ||
            updated.count > 0
    }
}

extension ObjectManager: Collection {
    public var startIndex: Int { return filtered.startIndex }
    public var endIndex: Int { return filtered.endIndex }
    
    public func index(after i: Int) -> Int {
        return filtered.index(after: i)
    }
    
    public subscript(index: Int) -> Element { get { return filtered[index] } }
}


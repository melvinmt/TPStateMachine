//
//  TPStateMachine.swift
//
//  Created by Melvin Tercan on 10/31/14.
//  Copyright (c) 2014 Melvin Tercan. All rights reserved.

import Foundation

class TPStateMachine : NSObject {
    
    // Public
    weak var collectionView : UICollectionView? {
        didSet {
            self.collectionView?.reloadData()
        }
    }
    weak var tableView : UITableView? {
        didSet {
            self.tableView?.reloadData()
        }
    }
    var section = 0 // Use a separate state machine for each section.
    var rowAnimation = UITableViewRowAnimation.None

    // Private
    private var items = [AnyObject]()
    let serialQueue = NSOperationQueue()

    override init() {
        super.init()
        self.serialQueue.maxConcurrentOperationCount = 1
    }

}

// Serial Manipulation
extension TPStateMachine {

    func setItems(items:[AnyObject]) {
        mainThread {
            self.items = items
            self.reloadData()
        }
    }
    
    func clearItems() {
        mainThread {
            self.items = [AnyObject]()
            self.reloadData()
        }
    }
    
    func insertItem(item:AnyObject, atIndex index: Int) {
        serialOperation {
            if index == 0 || index < self.items.count {
                self.mainThread {
                    self.items.insert(item, atIndex: index)
                    self.insertItemsAtIndexPaths([index])
                }
            } else {
                NSLog("index out of bounds: %d", index)
            }
        }
    }
    
    func appendItem(item:AnyObject) {
        mainThread {
            self.items.append(item)
            self.insertItemsAtIndexPaths([self.items.count - 1])
        }
    }
    
    // Slightly slower because it needs to do a lookup first.
    func updateItem(item:AnyObject) {
        mainThread {
            if let index = self.indexForItem(item) {
                self.items[index] = item
                self.reloadItemsAtIndexPaths([index])
            } else {
                NSLog("item not found")
            }
        }
    }

    func updateItem(item:AnyObject, atIndex index:Int) {
        mainThread {
            if index < self.items.count {
                self.items[index] = item
                self.reloadItemsAtIndexPaths([index])
            } else {
                NSLog("index out of bounds: %d", index)
            }
        }
    }

    // Slightly slower because it needs to do a lookup first.
    func removeItem(item:AnyObject) {
        mainThread {
            if let index = self.indexForItem(item) {
                self.items.removeAtIndex(index)
                self.removeItemsAtIndexPaths([index])
            } else {
                NSLog("item not found")
            }
        }
    }

    func removeItem(item:AnyObject, atIndex index:Int) {
        mainThread {
            if index < self.items.count {
                self.items.removeAtIndex(index)
                self.removeItemsAtIndexPaths([index])
            } else {
                NSLog("index out of bounds: %d", index)
            }
        }
    }

}

// Data retrieval
extension TPStateMachine {
    
    func countItems() -> Int {
        return self.items.count
    }
    
    func itemForIndex(index:Int) -> AnyObject? {
        if index < self.items.count {
            return self.items[index]
        } else {
            NSLog("index out of bounds: %d", index)
        }
        return nil
    }
    
    func indexForItem(item:AnyObject) -> Int? {
        for (index, existingItem) in enumerate(self.items) {
            if existingItem.isEqual(item) {
                return index
            }
        }
        return nil
    }
    
    func itemExists(item:AnyObject) -> Bool {
        for existingItem in self.items {
            if existingItem.isEqual(item) {
                return true
            }
        }
        return false
    }
    
    func allItems() -> [AnyObject] {
        return self.items
    }
}

// Private functions
extension TPStateMachine {
    
    private func mainThread(dispatch_block:()->()) {
        dispatch_async(dispatch_get_main_queue()) {
            dispatch_block()
        }
    }
    
    private func serialOperation(dispatch_block:()->()) {
        self.serialQueue.addOperationWithBlock() {
            dispatch_block()
        }
    }

    private func indexPathsForIndexes(indexes:[Int]) -> [NSIndexPath] {
        var indexPaths = [NSIndexPath]()
        for index in indexes {
            let indexPath = NSIndexPath(forItem: index, inSection: self.section)
            indexPaths.append(indexPath)
        }
        return indexPaths
    }

    private func insertItemsAtIndexPaths(indexes:[Int]) {
        let indexPaths = self.indexPathsForIndexes(indexes)
        self.collectionView?.insertItemsAtIndexPaths(indexPaths)
        self.tableView?.insertRowsAtIndexPaths(indexPaths, withRowAnimation: self.rowAnimation)
    }

    private func reloadItemsAtIndexPaths(indexes:[Int]) {
        let indexPaths = self.indexPathsForIndexes(indexes)
        self.collectionView?.reloadItemsAtIndexPaths(indexPaths)
        self.tableView?.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: self.rowAnimation)
    }
    
    private func removeItemsAtIndexPaths(indexes:[Int]) {
        let indexPaths = self.indexPathsForIndexes(indexes)
        self.collectionView?.deleteItemsAtIndexPaths(indexPaths)
        self.tableView?.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: self.rowAnimation)
    }
    
    private func reloadData() {
        self.collectionView?.reloadData()
        self.tableView?.reloadData()
    }

}

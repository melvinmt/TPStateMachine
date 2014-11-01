//
//  TPStateMachine.swift
//  github.com/melvinmt/TPStateMachine
//
//  Created by Melvin Tercan (github.com/melvinmt) on 10/31/14.
//  Copyright (c) 2014 Melvin Tercan. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

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
        mainThread {
            if index == 0 || index < self.items.count {
                self.items.insert(item, atIndex: index)
                self.insertItemsAtIndexPaths([index])
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

    func removeItemAtIndex(index:Int) {
        mainThread {
            if index < self.items.count {
                self.items.removeAtIndex(index)
                self.removeItemsAtIndexPaths([index])
            } else {
                NSLog("index out of bounds: %d", index)
            }
        }
    }
    
    func moveItemFromIndex(fromIndex:Int, toIndex: Int) {
        mainThread {
            if fromIndex < self.items.count && toIndex < self.items.count {
                if fromIndex == toIndex {
                    return
                }
                if let item = self.itemForIndex(fromIndex) {
                    self.items.removeAtIndex(fromIndex)
                    self.items.insert(item, atIndex: toIndex)
                    self.moveItemAtIndexPath(fromIndex, toIndex: toIndex)
                }
            }
        }
    }
    
    func moveUpdatedItem(updatedItem:AnyObject, toIndex: Int) {
        mainThread {
            if toIndex < self.items.count {
                if let fromIndex = self.indexForItem(updatedItem) {
                    if fromIndex == toIndex {
                        return
                    }
                    self.items.removeAtIndex(fromIndex)
                    self.items.insert(updatedItem, atIndex: toIndex)
                    self.moveItemAtIndexPath(fromIndex, toIndex: toIndex)
                }
            }
        }
    }
    
    func moveUpdatedItem(updatedItem:AnyObject, fromIndex: Int, toIndex: Int) {
        if fromIndex == toIndex {
            return
        }
        mainThread {
            if fromIndex < self.items.count && toIndex < self.items.count {
                self.items.removeAtIndex(fromIndex)
                self.items.insert(updatedItem, atIndex: toIndex)
                self.moveItemAtIndexPath(fromIndex, toIndex: toIndex)
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
    
    private func moveItemAtIndexPath(fromIndex:Int, toIndex: Int) {
        let fromIndexPath = NSIndexPath(forItem: fromIndex, inSection: 0)
        let toIndexPath = NSIndexPath(forItem: toIndex, inSection: 0)
        self.collectionView?.moveItemAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
        self.tableView?.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
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

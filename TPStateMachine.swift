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

typealias TPStateMachineCompletionHandler = () -> ()

protocol TPStateMachineDelegate : class {
    func didInsertItemsAtIndexPaths(indexPaths:[NSIndexPath])
    func didReloadItemsAtIndexPaths(indexPaths:[NSIndexPath])
    func didMoveItemAtIndexPath(fromIndexPath:NSIndexPath, toIndexPath: NSIndexPath)
    func didRemoveItemsAtIndexPaths(indexPaths:[NSIndexPath])
    func didReloadData()
}

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
    weak var delegate : TPStateMachineDelegate?
    var section = 0 // Use a separate state machine for each section.
    var rowAnimation = UITableViewRowAnimation.None
    var delayBetweenStates : NSTimeInterval = 0
    
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
        self.setItems(items, completionHandler:nil)
    }
    
    func setItems(items:[AnyObject], completionHandler:TPStateMachineCompletionHandler?) {
        serialOperation {
            self.mainThread {
                self.items = items
                self.reloadData()
                completionHandler?()
            }
            NSThread.sleepForTimeInterval(self.delayBetweenStates)
        }
    }
    
    func clearItems() {
        self.clearItems(nil)
    }
    
    func clearItems(completionHandler:TPStateMachineCompletionHandler?) {
        serialOperation {
            self.mainThread {
                self.items = [AnyObject]()
                self.reloadData()
                completionHandler?()
            }
            NSThread.sleepForTimeInterval(self.delayBetweenStates)
        }
    }
    
    func insertItem(item:AnyObject, atIndex index: Int) {
        self.insertItem(item, atIndex:index) {}
    }
    
    func insertItem(item:AnyObject, atIndex index:Int, completionHandler:TPStateMachineCompletionHandler?) {
        serialOperation {
            self.mainThread {
                if index <= self.items.count {
                    self.items.insert(item, atIndex: index)
                    self.insertItemsAtIndexPaths([index])
                    completionHandler?()
                } else {
                    NSLog("index out of bounds: %d", index)
                }
            }
            NSThread.sleepForTimeInterval(self.delayBetweenStates)
        }
    }
    
    func appendItem(item:AnyObject) {
        self.appendItem(item, completionHandler:nil)
    }
    
    func appendItem(item:AnyObject, completionHandler:TPStateMachineCompletionHandler?) {
        serialOperation {
            self.mainThread {
                self.items.append(item)
                self.insertItemsAtIndexPaths([self.items.count - 1])
                completionHandler?()
            }
            NSThread.sleepForTimeInterval(self.delayBetweenStates)
        }
    }
    
    func updateItem(item:AnyObject, atIndex index:Int) {
        self.updateItem(item, atIndex:index, completionHandler:nil)
    }

    
    func updateItem(item:AnyObject, atIndex index:Int, completionHandler:TPStateMachineCompletionHandler?) {
        serialOperation {
            self.mainThread {
                if index < self.items.count {
                    self.items[index] = item
                    self.reloadItemsAtIndexPaths([index])
                    completionHandler?()
                } else {
                    NSLog("index out of bounds: %d", index)
                }
            }
            NSThread.sleepForTimeInterval(self.delayBetweenStates)
        }
    }

    func removeItemAtIndex(index:Int) {
        self.removeItemAtIndex(index, completionHandler:nil)
    }
    
    func removeItemAtIndex(index:Int, completionHandler:TPStateMachineCompletionHandler?) {
        serialOperation {
            self.mainThread {
                if index < self.items.count {
                    self.items.removeAtIndex(index)
                    self.removeItemsAtIndexPaths([index])
                    completionHandler?()
                } else {
                    NSLog("index out of bounds: %d", index)
                }
            }
            NSThread.sleepForTimeInterval(self.delayBetweenStates)
        }
    }
    
    func moveItemFromIndex(fromIndex:Int, toIndex: Int) {
        self.moveItemFromIndex(fromIndex, toIndex:toIndex, completionHandler:nil)
    }

    func moveItemFromIndex(fromIndex:Int, toIndex: Int, completionHandler:TPStateMachineCompletionHandler?) {
        serialOperation {
            self.mainThread {
                if fromIndex < self.items.count && toIndex < self.items.count {
                    if fromIndex == toIndex {
                        return
                    }
                    if let item = self.itemForIndex(fromIndex) {
                        self.items.removeAtIndex(fromIndex)
                        self.items.insert(item, atIndex: toIndex)
                        self.moveItemAtIndexPath(fromIndex, toIndex: toIndex)
                        completionHandler?()
                    }
                }
            }
            NSThread.sleepForTimeInterval(self.delayBetweenStates)
        }
    }
    
    func moveUpdatedItem(updatedItem:AnyObject, toIndex: Int) {
        self.moveUpdatedItem(updatedItem, toIndex:toIndex, completionHandler:nil)
    }
    
    func moveUpdatedItem(updatedItem:AnyObject, toIndex: Int, completionHandler:TPStateMachineCompletionHandler?) {
        serialOperation {
            self.mainThread {
                if toIndex < self.items.count {
                    if let fromIndex = self.indexForItem(updatedItem) {
                        if fromIndex == toIndex {
                            return
                        }
                        self.items.removeAtIndex(fromIndex)
                        self.items.insert(updatedItem, atIndex: toIndex)
                        self.moveItemAtIndexPath(fromIndex, toIndex: toIndex)
                        completionHandler?()
                    }
                }
            }
            NSThread.sleepForTimeInterval(self.delayBetweenStates)
        }
    }
    
    func moveUpdatedItem(updatedItem:AnyObject, fromIndex: Int, toIndex: Int) {
        self.moveUpdatedItem(updatedItem, fromIndex: fromIndex, toIndex: toIndex, completionHandler:nil)
    }

    func moveUpdatedItem(updatedItem:AnyObject, fromIndex: Int, toIndex: Int, completionHandler:TPStateMachineCompletionHandler?) {
        if fromIndex == toIndex {
            return
        }
        serialOperation {
            self.mainThread {
                if fromIndex < self.items.count && toIndex < self.items.count {
                    self.items.removeAtIndex(fromIndex)
                    self.items.insert(updatedItem, atIndex: toIndex)
                    self.moveItemAtIndexPath(fromIndex, toIndex: toIndex)
                    completionHandler?()
                }
            }
            NSThread.sleepForTimeInterval(self.delayBetweenStates)
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

        self.delegate?.didInsertItemsAtIndexPaths(indexPaths)
    }

    private func reloadItemsAtIndexPaths(indexes:[Int]) {
        let indexPaths = self.indexPathsForIndexes(indexes)

        self.collectionView?.reloadItemsAtIndexPaths(indexPaths)
        self.tableView?.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: self.rowAnimation)

        self.delegate?.didReloadItemsAtIndexPaths(indexPaths)
    }
    
    private func moveItemAtIndexPath(fromIndex:Int, toIndex: Int) {
        let fromIndexPath = NSIndexPath(forItem: fromIndex, inSection: self.section)
        let toIndexPath = NSIndexPath(forItem: toIndex, inSection: self.section)

        self.collectionView?.moveItemAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
        self.tableView?.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)

        self.delegate?.didMoveItemAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
    }
    
    private func removeItemsAtIndexPaths(indexes:[Int]) {
        let indexPaths = self.indexPathsForIndexes(indexes)
        
        self.collectionView?.deleteItemsAtIndexPaths(indexPaths)
        self.tableView?.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: self.rowAnimation)
        
        self.delegate?.didRemoveItemsAtIndexPaths(indexPaths)
    }
    
    private func reloadData() {
        self.collectionView?.reloadData()
        self.tableView?.reloadData()
        self.delegate?.didReloadData()
    }

}



TPStateMachine
==============

State machine for highly dynamic `UICollectionViews`/`UITableViews`. No more `NSInternalInconsistencyExceptions` when you try to change your data from concurrent threads!

The state machine ensures that every change to your data model is matched perfectly with your collection/table views by handling them at the same time in the main thread (or in a serial queue when needed).

# Installation

Drag `TPStateMachine.swift` into your project.

# Usage

```swift
class ViewController : UIViewController {
  let state = TPStateMachine()
  let viewModel = ViewModel()
  @IBOutlet weak var collectionView: UICollectionView!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Attach a collection or table view to the state machine.
    state.collectionView = collectionView
    // or: state.tableView = tableView
    // also optional for tableViews: state.rowAnimation = UITableViewRowAnimation.Middle

    state.section = 0 // Default: 0, make sure to use separate state machines for each section.

    let users = viewModel.getUsers()
    state.setItems(users) // -> calls reloadData()
  }
  
  func insertUser(user:User) {
    state.insertItem(user, atIndex: 0) // -> calls insertItemsAtIndexPaths() call
  }
  
  func updateUser(user:User) {
    state.updateItem(user) // -> calls reloadItemsAtIndexPaths()
  }
  
  func removeUser(user:User) {
    state.removeItem(user) // -> calls deleteItemsAtIndexPaths()
  }
}

extension ViewController : UICollectionViewDelegate {
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return state.countItems()
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("userCell", forIndexPath: indexPath) as UICollectionViewCell
    
    if let user = state.itemForIndex(indexPath.row) as? User {
      let nameLabel = cell.viewWithTag(0) as UILabel
      nameLabel.text = user.name
    }

    return cell
  }

}

```
You can find more handy functions in the file itself.

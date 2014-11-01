TPStateMachine
==============

State machine for dynamic `UICollectionViews`/`UITableViews`. No more `NSInternalInconsistencyException`!

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
    state.collectionView = collectionView
    // or: state.tableView = tableView
    state.section = 0 // Use separate state machines for each section.
    // optional for tableViews: state.rowAnimation = UITableViewRowAnimation.Middle
    
    let users = viewModel.getUsers()
    state.setItems(users)
  }
  
  func insertUser(user:User) {
    state.insertItem(user, atIndex: 0)
  }
  
  func updateUser(user:User) {
    state.updateItem(user)
  }
  
  func removeUser(user:User) {
    state.removeItem(user)
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

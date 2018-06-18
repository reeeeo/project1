import UIKit
import CoreData
import JSQMessagesViewController

class ViewController: JSQMessagesViewController {
  
  private var appDelegate: AppDelegate!
  private var manageContext:NSManagedObjectContext!
  private var messageHistory:NSEntityDescription!
  
  var messages: [JSQMessage] = []
  var incomingBubble: JSQMessagesBubbleImage!
  var outgoingBubble: JSQMessagesBubbleImage!
  var incomingAvatar: JSQMessagesAvatarImage!
  var outgoingAvatar: JSQMessagesAvatarImage!
  var nowUserId: String! = "user1"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    inputToolbar!.contentView!.leftBarButtonItem = nil
    automaticallyScrollsToMostRecentMessage = true
    self.senderId = "user1"
    self.senderDisplayName = "user1"
    self.inputToolbar.contentView.rightBarButtonItem.setTitle("⇔", for: UIControlState.normal)
    self.inputToolbar.backgroundColor = UIColor.jsq_messageBubbleBlue()
    
    let bubbleFactory = JSQMessagesBubbleImageFactory()
    self.incomingBubble = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    self.outgoingBubble = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    
    prepareCoreData()
    loadHistory()
  }
  
  private func prepareCoreData() {
    appDelegate = UIApplication.shared.delegate as! AppDelegate
    manageContext = appDelegate.persistentContainer.viewContext
    messageHistory = NSEntityDescription.entity(forEntityName: "MessageHistory", in: manageContext)
  }
  
  private func loadHistory() {
    let fetchRequest: NSFetchRequest<MessageHistory> = MessageHistory.fetchRequest()
    do {
      let results = try manageContext.fetch(fetchRequest)
      let history = results
        .map { JSQMessage(senderId: $0.senderId, displayName: $0.senderDisplayName, text: $0.text) }
        .map { $0! }
      messages = history
    } catch {
      // TODO: 例外処理
      print(error)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  override func textViewDidChange(_ textView: UITextView) {
    self.inputToolbar.contentView.rightBarButtonItem.setTitle(self.inputToolbar.contentView.textView.hasText() ? "Send" : "⇔", for: UIControlState.normal)
  }
  
  override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
    if self.inputToolbar.contentView.textView.hasText() {
      self.inputToolbar.contentView.textView.text = ""
      addMessage(withId: nowUserId, name: senderDisplayName, text: text)
      self.finishReceivingMessage(animated: true)
      textViewDidChange(self.inputToolbar.contentView.textView)
    } else {
      nowUserId = nowUserId == "user1" ? "user2" : "user1"
    }
    self.inputToolbar.backgroundColor = self.nowUserId == "user1" ? UIColor.jsq_messageBubbleBlue() : UIColor.jsq_messageBubbleLightGray()
  }
  
  private func addMessage(withId id: String, name: String, text: String) {
    if let message = JSQMessage(senderId: id, displayName: name, text: text) {
      self.messages.append(message)
      addMessageHistory(with: message)
    }
  }
  
  private func addMessageHistory(with message: JSQMessage) {
    let newRecord = NSManagedObject(entity: messageHistory!, insertInto: manageContext) as? MessageHistory
    newRecord?.setValue(message.senderId, forKey: "senderId")
    newRecord?.setValue(message.senderDisplayName, forKey: "senderDisplayName")
    newRecord?.setValue(message.text, forKey: "text")
    do {
      try manageContext.save()
    } catch {
      // TODO: 例外処理
      print(error)
    }
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
    return self.messages[indexPath.item]
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
    let message = self.messages[indexPath.item]
    if message.senderId == self.senderId {
      return self.outgoingBubble
    }
    return self.incomingBubble
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
    let message = self.messages[indexPath.item]
    if message.senderId == self.senderId {
      return self.outgoingAvatar
    }
    return self.incomingAvatar
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return messages.count
  }
}

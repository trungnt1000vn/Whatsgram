//
//  File.swift
//  AppChat
//
//  Created by Trung on 05/06/2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation
import FirebaseStorage

final class ChatViewController: MessagesViewController, AVAudioPlayerDelegate{
    private var audioPlayer: AVAudioPlayer?
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .long
        formatter.locale = .none
        return formatter
    }()
    public static let dateFormatter1: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    private var conversationId: String?
    
    public var isNewConversation = false
    
    public let otherUserEmail: String
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: "Me")
    }
    
    weak var playingCell: AudioMessageCell?
    
    var playingMessage: MessageType?
    
    private var audioController: BasicAudioController?
    
    init(with email: String,id : String?){
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    private func setupInputButton(){
        let button = InputBarButtonItem()
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside{[weak self] _ in
            self?.presentInputActionSheet()
        }
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach media", message: "What would you like to attach ? ", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: {
            [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {
            [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Record", style: .default, handler: {
            _ in
            self.presentRecord()
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: {
            [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    private func presentLocationPicker(){
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = {
            [weak self] selectedCoorindates in
            guard let strongSelf = self else {
                return
            }
            guard let messageId = strongSelf.createMessageId(),
                  let conversationId = strongSelf.conversationId,
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender
            else{
                return
            }
            let longitude: Double = selectedCoorindates.longitude
            let latitude: Double = selectedCoorindates.latitude
            
            print("long = \(longitude) || lat = \(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                    size: .zero)
            let message = Message(sender: selfSender,
                                  messageId: messageId ,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: {
                success in
                if success {
                    print("sent location message")
                }
                else{
                    print("failed to send location message")
                }
            })
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    private func presentPhotoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Photo ", message: "What would you like to attach ? ", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {
            [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[weak self]
            _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    private func presentVideoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Video ", message: "What would you like to attach a video from ?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {
            [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {[weak self]
            _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    private func presentRecord() {
        let vc = RecordViewController()
        vc.completion = { [weak self] fileURL, audioDuration, fileSize in
            guard let strongSelf = self,
                  let messageId = strongSelf.createMessageId(),
                  let conversationId = strongSelf.conversationId,
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender
            else {
                return
            }
            
            let fileName = "audio_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".m4a"
            
            
            StorageManager.shared.uploadMessageAudio(with: fileURL, fileName: fileName, completion: { result in
                switch result {
                case .success(let audioURL):
                    let recURL1: URL
                    if let recURL = URL(string: audioURL){
                        recURL1 = recURL
                    }
                    else {
                        return
                    }
                    let audioItem = Audio(url: recURL1, duration: Float(audioDuration), size: CGSize(width: 100, height: 50))
                    print("Uploaded audio message :  \(audioURL)")
                    
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .audio(audioItem))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("Sent audio message")
                        } else {
                            print("Failed to send audio message")
                        }
                    }
                case .failure(let error):
                    print("Failed to upload audio: \(error.localizedDescription)")
                }
            })
        }
        
        present(vc, animated: true)
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        print(id)
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                print("success in getting messages: \(messages)")
                guard !messages.isEmpty else {
                    print("messages are empty")
                    return
                }
                self?.messages = messages
                print("message is : \(messages)")
                DispatchQueue.main.async {
                    [weak self] in
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom(animated: true)
                    }
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
    }
   private func playAudioFromFirebaseStorage(url: URL) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                audioPlayer?.delegate = self
                audioPlayer?.play()
                if let cell = playingCell {
                    //cell.playButton.isSelected = true
                }
            } catch {
                print("Failed to create AVAudioPlayer with URL: \(url)")
            }
        }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId{
            listenForMessages(id: conversationId,shouldScrollToBottom: true)
        }
    }
}
extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " " , with: "").isEmpty,
              let selfSender = self.selfSender ,
              let messageId = createMessageId() else{
            return
        }
        inputBar.inputTextView.text = ""
        print("Sending: \(text)")
        let message = Message(sender: selfSender,
                              messageId: messageId ,
                              sentDate: Date(),
                              kind: .text(text))
        //Send Message
        if isNewConversation{
            //create conver in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success{
                    print ("Message sent")
                    self?.isNewConversation = false
                    let newConversationId = "conversation_\(message.messageId)"
                    self?.conversationId = newConversationId
                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                }
                else{
                    print("Failed to send")
                }
            })
        }
        else{
            guard let conversationId = conversationId,
                  let name = self.title
            else{
                return
            }
            //append to existing conversation data
            DatabaseManager.shared.sendMessage(to: conversationId,otherUserEmail: otherUserEmail,name :name, newMessage: message, completion: { success in
                if(success){
                    print("message sent")
                }
                else{
                    print("failed to sent")
                }
            })
            
        }
    }
    private func createMessageId() -> String? {
        // date, otherUserEmail, senderEmail, randomInt
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("Created message id : \(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
              let conversationId = conversationId,
              let name = self.title,
              let selfSender = selfSender
        else{
            return
        }
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData(){
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            //Upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: {[weak self] result in
                guard let strongSelf = self
                        
                else {
                    return
                }
                switch result{
                case.success(let urlString):
                    /// Ready to message
                    print("Uploaded message photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else{
                        return
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: messageId ,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: {
                        success in
                        if success {
                            print("sent photo message")
                        }
                        else{
                            print("failed to send photo message")
                        }
                    })
                case.failure(let error):
                    print("Message photo upload error : \(error)")
                }
            })
            
        }
        else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            ///Upload Video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: {[weak self] result in
                guard let strongSelf = self
                        
                else {
                    return
                }
                switch result{
                case.success(let urlString):
                    /// Ready to message
                    print("Uploaded message video: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else{
                        return
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: messageId ,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: {
                        success in
                        if success {
                            print("Sent video message")
                        }
                        else{
                            print("Failed to send photo message")
                        }
                    })
                case.failure(let error):
                    print("Message video upload error : \(error)")
                }
            })
        }
    }
}
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender{
            return sender
        }
        
        fatalError(" Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            imageView.sd_setImage(with: imageUrl, placeholderImage: nil)
            print("got media")
        default:
            break
        }
        
    }
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        audioController?.configureAudioCell(cell, message: message)
    }
    func didTapPlayButton(in cell: AudioMessageCell) {
        
    }
    func configureMessageCollectionView() {
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
    }
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId{
            return .link
        }
        return .secondarySystemBackground
    }
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId{
            if let currentUserImageURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImageURL, completed: nil)
            }
            else {
                
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                //Fetch Url
                StorageManager.shared.downloadURL(for: path, completion: {[weak self]result in
                    switch result{
                    case .success(let url):
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        }
        else{
            if let otherUserPhotoURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserPhotoURL, completed: nil)
            }
            else {
                //Fetch URL
                let email = self.otherUserEmail
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                //Fetch Url
                StorageManager.shared.downloadURL(for: path, completion: {[weak self]result in
                    switch result{
                    case .success(let url):
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        }
    }
}
extension ChatViewController : MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            print("Location showing")
            
            navigationController?.pushViewController(vc, animated: true)
        case .audio(let audioItem):
            playAudioFromFirebaseStorage(url: audioItem.url)
        default:
            break
        }
    }
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else{
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
        default:
            break
        }
    }
}
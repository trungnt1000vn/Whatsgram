//
//  ConversationTableViewCell.swift
//  AppChat
//
//  Created by Trung on 05/06/2023.
//
import UIKit
import SDWebImage
import Firebase

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        return imageView
    }()
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    private let mediaMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    private let messageTime: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    private let iconMedia: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        return imageView
    }()
    private let iconImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "circle.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        return imageView
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
        contentView.addSubview(messageTime)
        contentView.addSubview(iconImage)
        contentView.addSubview(iconMedia)
        contentView.addSubview(mediaMessageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        userNameLabel.frame = CGRect(x: userImageView.right + 10, y: 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height-20)/2)
        userMessageLabel.frame = CGRect(x: userImageView.right + 10, y: userNameLabel.bottom + 10, width: contentView.width - 100 - userImageView.width, height: (contentView.height-50)/2)
        iconMedia.frame = CGRect(x: userImageView.right + 10, y: userNameLabel.bottom + 20, width: 20, height: 20)
        mediaMessageLabel.frame = CGRect(x: iconMedia.right + 10, y: userNameLabel.bottom + 13 , width: contentView.width - 100 - userImageView.width, height: (contentView.height-50)/2)
        messageTime.frame = CGRect(x: userMessageLabel.right + 42, y: userNameLabel.bottom + 18, width: 100, height: 20)
        iconImage.frame = CGRect(x: userMessageLabel.right + 50, y: 28, width: 10, height: 10)
        
    }
    public func configure(with model: Conversation) {
        guard let userEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: userEmail)
        
        userNameLabel.text = model.name
        messageTime.text = model.latestMessage.time
        
        if model.latestMessage.type == "photo" {
            iconMedia.isHidden = false
            iconMedia.image = UIImage(named: "cam")
            userMessageLabel.isHidden = true
            mediaMessageLabel.isHidden = false
            mediaMessageLabel.text = "Photo"
        } else if model.latestMessage.type == "video" {
            iconMedia.isHidden = false
            iconMedia.image = UIImage(named: "video")
            userMessageLabel.isHidden = true
            mediaMessageLabel.isHidden = false
            mediaMessageLabel.text = "Video"
        } else if model.latestMessage.type == "text" {
            iconMedia.isHidden = true
            mediaMessageLabel.isHidden = true
            userMessageLabel.isHidden = false
            
            if model.latestMessage.sender == safeEmail {
                userMessageLabel.text = "You: \(model.latestMessage.text)"
            } else {
                userMessageLabel.text = model.latestMessage.text
            }
        }
        else if model.latestMessage.type == "audio" {
            iconMedia.isHidden = true
            mediaMessageLabel.isHidden = true
            userMessageLabel.isHidden = false
            if model.latestMessage.sender == safeEmail {
                userMessageLabel.text = "You: Audio Message"
            } else {
                userMessageLabel.text = "Audio Message"
            }
        }
        
        if model.latestMessage.isRead == false && model.latestMessage.sender != safeEmail {
            userMessageLabel.font = .systemFont(ofSize: 19, weight: .bold)
            messageTime.font = .systemFont(ofSize: 12, weight: .bold)
            iconImage.isHidden = false
        } else {
            userMessageLabel.font = .systemFont(ofSize: 19, weight: .regular)
            messageTime.font = .systemFont(ofSize: 12, weight: .regular)
            iconImage.isHidden = true
        }
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Failed to get image URL: \(error)")
            }
        }
    }
}


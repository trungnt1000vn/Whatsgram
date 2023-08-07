//
//  StorageManager.swift
//  AppChat
//
//  Created by Trung on 05/06/2023.
//

import Foundation
import FirebaseStorage

final class StorageManager{
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     
     */
    public typealias UploadAudioCompletion = (Result<String, Error>) -> Void
    /// Tải lên tệp âm thanh lên Firebase Storage, trả về kết quả với chuỗi URL để tải xuống
    public func uploadAudio(with fileURL: URL, fileName: String, completion: @escaping UploadAudioCompletion) {
        storage.child("audios/\(fileName)").putFile(from: fileURL, metadata: nil) { [weak self] (metadata, error) in
            guard let strongSelf = self else { return }
            
            guard error == nil else {
                print("Failed to upload audio file to Firebase: \(error!.localizedDescription)")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            let reference = strongSelf.storage.child("audios/\(fileName)").downloadURL(completion: { (url, error) in
                guard let url = url else {
                    print("Failed to get download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL returned: \(urlString)")
                completion(.success(urlString))
            })
        }
    }
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    ///Upload picture to firebase to storage, returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String,completion: @escaping UploadPictureCompletion ){
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: {[weak self]metadata, error in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else{
                //failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            let reference = strongSelf.storage.child("images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else{
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("Download url returned : \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    public func uploadCoverPicture(with data:Data, fileName: String, completion: @escaping UploadPictureCompletion ){
        storage.child("coverphotos/\(fileName)").putData(data, metadata: nil, completion: {[weak self]metadata, error in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
                //failed
                print("Failed to upload data to firebase for cover photo")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            let reference = strongSelf.storage.child("coverphotos/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else{
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("Download url returned : \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    public func downloadURL(for path: String,completion:@escaping (Result<URL, Error>) -> Void){
        let reference = storage.child(path)
        reference.downloadURL(completion: { url, error in
            guard let url = url , error == nil else{
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
    ///upload  image for sending
    public func uploadMessagePhoto(with data: Data, fileName: String,completion: @escaping UploadPictureCompletion ){
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: {[weak self]metadata, error in
            
            guard error == nil else{
                //failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            let reference = self?.storage.child("message_images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else{
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("Download url returned : \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    ///upload video
    public func uploadMessageVideo(with fileUrl: URL, fileName: String,completion: @escaping UploadPictureCompletion ){
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: {[weak self]metadata, error in
            
            guard error == nil else{
                //failed
                print("Failed to upload video file to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            let reference = self?.storage.child("message_videos/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else{
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("Download url returned : \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    /// Upload audio for sending
    public func uploadMessageAudio(with fileUrl: URL, fileName: String, completion: @escaping UploadAudioCompletion) {
        storage.child("message_audios/\(fileName)").putFile(from: fileUrl, metadata: nil) { [weak self] metadata, error in
            guard error == nil else {
                print("Failed to upload audio file to Firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_audios/\(fileName)").downloadURL { url, error in
                guard let downloadURL = url else {
                    print("Failed to get download URL for audio")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = downloadURL.absoluteString
                completion(.success(urlString))
            }
        }
    }
    
    
}

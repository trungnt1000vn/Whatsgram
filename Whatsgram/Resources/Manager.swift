//
//  Manager.swift
//  AppChat
//
//  Created by Trung on 23/06/2023.
//

import Foundation
import UIKit
import AVFoundation

struct Manager {
    
    static let shared = Manager()
    
    // MARK:- Get Time String
    
    func toShortTimeString() -> String {
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: Date())
        return timeString
    }
    
    // MARK:- Function to get path to directory
    
    func getDirectory() -> URL {
        
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = path[0]
        return documentDirectory
    }
    
    // MARK:- Second into Minutes and hours
    
    func secondsToHoursMinutesSeconds(_ seconds: Int) -> String {
        
        let second = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let hours = (seconds % 3600) % 60
        
        return "0\(second):0\(minutes):\(hours)"
    }
    
    // MARK:- Function Getting Recording Total Time
    
    func GetRecordingTotalTime(indexpath: Int) -> Int {
        
        let path = getDirectory().appendingPathComponent("\(indexpath + 1).m4a")
        
        let audioAsset = AVURLAsset.init(url: path, options: nil)
        let duration = audioAsset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        let original = Int(durationInSeconds)
        let seconds = original % 60
        
        return seconds
    }
    
    // MARK:- Function Getting Audio File Creation Date
    
    func GetFileSaveTime(indexpath: Int) -> AVMetadataItem {
        
        let path = getDirectory().appendingPathComponent("\(indexpath + 1).m4a")
        
        let audioAsset = AVURLAsset.init(url: path, options: nil)
        let saveTime = audioAsset.creationDate!
        
        return saveTime
    }
    
    // MARK:- Function to Get Recording Save Time
    
    func GetRecordingSaveTime(indexpath: Int) -> String {
        
        let pathURL = Manager.shared.getDirectory().appendingPathComponent("\(indexpath + 1).m4a")
        let pathString = pathURL.path // String
        
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: pathString)
            let date = (attr[FileAttributeKey.modificationDate] as? Date)!
            let formatter2 = DateFormatter()
            formatter2.timeStyle = .short
            return formatter2.string(from: date)
        }
        catch {
            return "Recorded Time Not Found!"
        }
    }
}

extension UIViewController {
    
    // MARK:- Display Alert Function
    
    func displayAlert(title:String,message:String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

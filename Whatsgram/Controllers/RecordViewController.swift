//
//  RecordViewController.swift
//  AppChat
//
//  Created by Trung on 14/06/2023.
//
import UIKit
import AVFoundation


class RecordViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    private let circle: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "circle")
        return image
    }()
    private let recButton: UIButton = {
        let button = UIButton()
        var image = UIImage(named: "rec")
        button.setImage(image, for: .normal)
        return button
    }()
    private let playButton: UIButton = {
        let button = UIButton()
        button.setTitle("Play", for: .normal)
        return button
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton()
        button.setTitle("Send", for: .normal)
        return button
    }()
    public var completion: ((URL, Double, UInt64) -> Void)?
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(circle)
        view.addSubview(recButton)
        view.addSubview(sendButton)
        view.addSubview(playButton)
        sendButton.setTitleColor(.black, for: .normal)
        playButton.setTitleColor(.black, for: .normal)
        view.backgroundColor = .white
        recButton.addTarget(self, action: #selector(reccordButtonTapped), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playbuttonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        setupAudioSession()
        updateUIForRecordingState(isRecording: false)
    }
    override func viewDidLayoutSubviews() {
        let buttonSize: CGFloat = 100
        let padding: CGFloat = 20
        
        let centerY = view.bounds.height / 2
        let centerX = view.bounds.width / 2
        
        circle.frame = CGRect(x: centerX - buttonSize / 2, y: centerY - buttonSize, width: buttonSize, height: buttonSize)
        recButton.frame = CGRect(x: centerX - buttonSize / 2, y: centerY - buttonSize, width: buttonSize, height: buttonSize)
        
        sendButton.frame = CGRect(x: view.bounds.width - buttonSize - padding, y: padding, width: buttonSize, height: buttonSize)
        
        playButton.frame = CGRect(x: centerX - buttonSize / 2, y: centerY + buttonSize, width: buttonSize, height: buttonSize)
    }
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session")
        }
    }
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String: Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            updateUIForRecordingState(isRecording: true)
        } catch {
            print("Failed to start recording")
        }
    }
    
    
    func finishRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        updateUIForRecordingState(isRecording: false)
    }
    func startPlayback() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1
            audioPlayer?.play()
            updateUIForPlaybackState(isPlaying: true)
        } catch {
            print("Failed to start playback")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        updateUIForPlaybackState(isPlaying: false)
    }
    
    
    func updateUIForPlaybackState(isPlaying: Bool) {
        if isPlaying {
            playButton.setTitle("Stop Playback", for: .normal)
            recButton.isEnabled = false
        } else {
            playButton.setTitle("Start Playback", for: .normal)
            recButton.isEnabled = true
        }
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
    
    @objc func reccordButtonTapped(){
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording()
        }
        updateUIForRecordingState(isRecording: audioRecorder != nil)
    }
    
    @objc func playbuttonTapped() {
        if audioPlayer == nil {
            startPlayback()
        } else {
            stopPlayback()
        }
    }
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !flag {
            print("Playback finished")
        }
    }
    
    
    @objc func sendTapped() {
        
        guard let fileURL = getDocumentsDirectory().appendingPathComponent("recording.m4a") as URL? else {
            print("Audio file not found")
            return
        }
        do{
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            guard let fileSize = fileAttributes[FileAttributeKey.size] as? UInt64 else {
                print("Failed to get file size")
                return
            }
            let audioAsset = AVURLAsset(url: fileURL)
            let audioDuration = audioAsset.duration.seconds
            
            completion?(fileURL, audioDuration, fileSize)
        }
        catch{
            print("Failed to retrieve audio file information: \(error.localizedDescription)")
        }
        self.dismiss(animated: true)
    }
    
}

extension RecordViewController {
    enum RecordingState {
        case recording
        case notRecording
    }
    
    func updateRecButtonImage(for state: RecordingState) {
        switch state {
        case .recording:
            let stopImage = UIImage(named: "stop")
            recButton.setImage(stopImage, for: .normal)
        case .notRecording:
            let recImage = UIImage(named: "rec")
            recButton.setImage(recImage, for: .normal)
        }
    }
    
    func updateUIForRecordingState(isRecording: Bool) {
        if isRecording {
            updateRecButtonImage(for: .recording)
            playButton.isEnabled = false
        } else {
            updateRecButtonImage(for: .notRecording)
            playButton.isEnabled = true
        }
    }
}

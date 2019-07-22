//
//  ViewController.swift
//  PhoneMonitor
//
//  Created by Jacob Metcalf on 7/18/19.
//  Copyright © 2019 Jacob Metcalf. All rights reserved.
//

import UIKit
import AVFoundation
import WatchConnectivity

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
  
  @IBOutlet weak var myImageView: UIImageView!
  @IBOutlet weak var recordButton: UIButton!
  
  var audioRecorder:AVAudioRecorder!
  var audioPlayer: AVAudioPlayer!
  
  var session: WCSession!
  
  var timer: Timer!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    UserDefaults.standard.set(true, forKey: "TimerIsntGoing")
    
    session = WCSession.default
    session.activate()
    
    recordButton.isHidden = true
    
    CaptureManager.shared.statSession()
    CaptureManager.shared.delegate = self
    CaptureManager.shared.statSession()
  
    
    timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { (_) in
      if let content = FileManager.default.contents(atPath: self.url().path) {
        if self.session.isReachable && self.session.isWatchAppInstalled && self.session.isPaired {
          self.session.sendMessageData(content, replyHandler: nil, errorHandler: nil)
          self.doTheLoop()
        }
      }
    })
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name("NeedImage"), object: nil, queue: .main) { (notification) in
      DispatchQueue.main.async {
        let image = self.resizeImage(image: self.myImageView.image!, targetSize: CGSize(width: self.view.frame.width / 3, height: self.view.frame.height / 3))
        let data = image.jpegData(compressionQuality: 0.0)
        if self.session.isReachable && self.session.isWatchAppInstalled && self.session.isPaired {
          self.session.sendMessageData(data!, replyHandler: nil, errorHandler: nil)
        }
      }
    }
    setUpRecorder()
    doTheLoop()
    timer.fire()
  }
  
  func doTheLoop() {
    record()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.stopRecording()
    }
  }
  
  func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
    
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
      newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
      newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  
  func sessionDidBecomeInactive(_ session: WCSession) {
    print("Session Inactive")
  }
  
  func sessionDidDeactivate(_ session: WCSession) {
    print("Session Deactivate")
  }

  
  // AUDIO STUFFS
  
  @IBAction func playButtonTapped(_ sender: UIButton) {
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: url())
      audioPlayer.play()
    } catch let e {
      print("ERROR --- \(e.localizedDescription)")
    }
  }
  
  @IBAction func recordButtonTapped(_ sender: UIButton) {
//    if sender.titleLabel?.text == "Record" {
//      record()
//    } else {
//      stopRecording()
//    }
  }
  
  func setUpRecorder() {
    let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
    
    do {
      
      try audioSession.setCategory(.playAndRecord)
      try audioSession.setActive(true, options: [])
      
      let recordSettings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
                                           AVSampleRateKey: 44100.0,
                                           AVLinearPCMBitDepthKey:16,
                                           AVNumberOfChannelsKey: 2,
                                           AVLinearPCMIsBigEndianKey: false,
                                           AVLinearPCMIsFloatKey: false]
      
      print("url : \(url())")
      
      audioRecorder = try AVAudioRecorder(url: url(), settings: recordSettings)
      audioRecorder.prepareToRecord()
      audioRecorder.delegate = self
    } catch let e {
      print("ERROR --- \(e.localizedDescription)")
    }
  }
  
  func record() {
    audioRecorder.record()
//    recordButton.setTitle("Stop", for: .normal)
  }
  
  func stopRecording() {
    audioRecorder.stop()
//    recordButton.setTitle("Record", for: .normal)
  }
  
  private func url() -> URL {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    let str =  documents.appendingPathComponent("sound_recording.wav")
    let url = URL(fileURLWithPath: str.path)
    return url
  }
  
  
  //  func checkRecordPermission()
  //  {
  //    switch AVAudioSession.sharedInstance().recordPermission {
  //    case .granted:
  //      isAudioRecordingGranted = true
  //      break
  //    case .denied:
  //      isAudioRecordingGranted = false
  //      break
  //    case .undetermined:
  //      AVAudioSession.sharedInstance().requestRecordPermission({ (allowed) in
  //        if allowed {
  //          self.isAudioRecordingGranted = true
  //        } else {
  //          self.isAudioRecordingGranted = false
  //        }
  //      })
  //      break
  //    default:
  //      break
  //    }
  //  }
}

extension ViewController: CaptureManagerDelegate {
  func processCapturedImage(image: UIImage) {
    self.myImageView.image = image
  }
}

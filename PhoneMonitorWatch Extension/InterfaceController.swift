//
//  InterfaceController.swift
//  PhoneMonitorWatch Extension
//
//  Created by Jacob Metcalf on 7/18/19.
//  Copyright © 2019 Jacob Metcalf. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import AVFoundation

class InterfaceController: WKInterfaceController, WCSessionDelegate {
  
  @IBOutlet weak var beginTheStreamButton: WKInterfaceButton!
  @IBOutlet weak var monitorImageView: WKInterfaceImage!
  
  var session: WCSession!
  
  var isPresentingAlert: Bool = false
  
  var player = AVAudioPlayer()
  let audioSession = AVAudioSession.sharedInstance()
  
  override func awake(withContext context: Any?) {
    super.awake(withContext: context)
    
    
    if WCSession.isSupported() {
      session = WCSession.default
      session.delegate = self
      session.activate()
    }
    
    let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
      if self.isPresentingAlert == false {
        if self.session.isReachable && UserDefaults.standard.bool(forKey: "OkayTapped") {
          self.session.sendMessage([:], replyHandler: nil, errorHandler: nil)
        } else if UserDefaults.standard.bool(forKey: "OkayTapped") {
          print("Do Nothing.. they know whats up")
        } else if UserDefaults.standard.bool(forKey: "OkayTapped") == false {
          self.isPresentingAlert = true
          self.presentAlert(withTitle: "Unlock your phone", message: "To have the app work please unlock you phoen and open the app", preferredStyle: .actionSheet, actions: [WKAlertAction(title: "Okay", style: .default, handler: {
            UserDefaults.standard.set(true, forKey: "OkayTapped")
            self.isPresentingAlert = false
          })])
        }
      }
    }
    
    timer.fire()
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name("image"), object: nil, queue: .main) { (notification) in
      DispatchQueue.main.async {
        if let image = notification.userInfo?["image"] as? UIImage {
          self.monitorImageView.setImage(image)
          self.session.sendMessage([:], replyHandler: nil, errorHandler: nil)
        }
      }
    }
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name("sound"), object: nil, queue: .main) { (notification) in
      if let player = notification.userInfo?["sound"] as? AVAudioPlayer {
        
        
        do {
          try self.audioSession.setCategory(AVAudioSession.Category.playback,
                                       mode: .default,
                                       policy: .default,
                                       options: [])
          try self.audioSession.setActive(true, options: [])
          
        } catch let error {
          print(error.localizedDescription)
//          fatalError("*** Unable to set up the audio session: \(error.localizedDescription) ***")
        }
//        if let path = Bundle.main.url(forResource: "piano", withExtension: "mp3") {
//          let fileUrl = path
//          do{
//            player = try AVAudioPlayer(contentsOf: fileUrl)
//          }
//          catch
//          {
//            print("*** Unable to set up the audio player: \(error.localizedDescription) ***")
//            // Handle the error here.
//            return
//          }
//        }
        if !player.isPlaying {
          player.play()
        }
      }
    }
  }
  
  override func didAppear() {
    super.didAppear()
    self.session.sendMessage([:], replyHandler: nil, errorHandler: nil)
  }
  
  @IBAction func beginTheStream() {
    self.session.sendMessage([:], replyHandler: nil, errorHandler: nil)
  }
  
  func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
    if let image = UIImage(data: messageData) {
    NotificationCenter.default.post(name: Notification.Name("image"), object: nil, userInfo: ["image":image])
    } else if let soundData = try? AVAudioPlayer(data: messageData) {
      NotificationCenter.default.post(name: NSNotification.Name("sound"), object: nil, userInfo: ["sound": soundData])
    }
  }
  
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    if let url = message["url"] as? URL {
      let content = FileManager.default.contents(atPath: url.absoluteString)
      let player = try? AVAudioPlayer(contentsOf: url)
      player?.play()
    }
  }
  
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    print("Activation State: \(activationState.rawValue)")
  }
  
}

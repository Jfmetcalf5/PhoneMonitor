//
//  CaptureManager.swift
//  PhoneMonitor
//
//  Created by Jacob Metcalf on 7/18/19.
//  Copyright © 2019 Jacob Metcalf. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol CaptureManagerDelegate: class {
  func processCapturedImage(image: UIImage)
}

class CaptureManager: NSObject {
  internal static let shared = CaptureManager()
  weak var delegate: CaptureManagerDelegate?
  var session: AVCaptureSession?
  
  var timer: Timer?
  
  override init() {
    super.init()
    session = AVCaptureSession()
    
    let device =  AVCaptureDevice.default(for: .video)!
    let input = try! AVCaptureDeviceInput(device: device)
    session?.addInput(input)
    
    let output = AVCaptureVideoDataOutput()
    output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
    session?.addOutput(output)
  }
  
  func statSession() {
    session?.startRunning()
  }
  
  func stopSession() {
    session?.stopRunning()
  }
}

extension CaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    connection.videoOrientation = AVCaptureVideoOrientation.portrait;
    let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
    let ciimage = CIImage(cvPixelBuffer: imageBuffer)
    let image = self.convert(cmage: ciimage)
    runSendImagEveryTwoSeconds(image: image)
  }
  
  func runSendImagEveryTwoSeconds(image: UIImage) {
    delegate?.processCapturedImage(image: image)
  }
  
  func convert(cmage:CIImage) -> UIImage
  {
    cmage.oriented(CGImagePropertyOrientation.up)
    let context:CIContext = CIContext.init(options: nil)
    let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
    let image:UIImage = UIImage.init(cgImage: cgImage)
    return image
  }
}

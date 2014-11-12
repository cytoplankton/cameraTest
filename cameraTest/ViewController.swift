//
//  ViewController.swift
//  cameraTest
//
//  Created by Jarrod Perez on 11/5/14.
//  Copyright (c) 2014 Jarrod Perez. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation

class ViewController: UIViewController {
    
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    let capture = AVCaptureStillImageOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        beginSession()
    }
    
    func takePhoto(){
        // we do this on another thread so that we don't hang the UI
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var videoConnection = self.capture.connectionWithMediaType(AVMediaTypeVideo)
            
            if videoConnection != nil {
                self.capture.captureStillImageAsynchronouslyFromConnection(videoConnection){
                    (imageSampleBuffer : CMSampleBuffer!, _) in
                    
                    let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                    var pickedImage: UIImage = UIImage(data: imageDataJpeg)!
                }
                
                self.captureSession.stopRunning()
            }
        }
    }
    
    @IBAction func getEventTime(sender: AnyObject) {
        let url = NSURL(string: "http://107.170.209.55:3000/")
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            println(NSString(data: data, encoding: NSUTF8StringEncoding))
            var error: NSError?
            let jsonData: NSData = data
            let jsonDict = NSJSONSerialization.JSONObjectWithData(jsonData, options: nil, error: &error) as NSDictionary
            
            var serverTime = jsonDict["serverTime"] as NSTimeInterval
            var eventTime = jsonDict["eventAt"] as? NSTimeInterval
            
            println(eventTime)
            
            var clientDate = NSDate()
            var serverDate = NSDate(timeIntervalSince1970: serverTime / 1000)
        
            if eventTime != nil {
                var eventDate = NSDate(timeIntervalSince1970: eventTime! / 1000)
                let elapsedTime = NSDate().timeIntervalSinceDate(eventDate)
                let duration = Int64(elapsedTime)
                
                println(abs(duration))
                
                var delta: Int64 = abs(duration) * Int64(NSEC_PER_SEC)
                var time = dispatch_time(DISPATCH_TIME_NOW, delta)
                
                dispatch_after(time, dispatch_get_main_queue(), {
                    self.takePhoto()
                });
            }
        }
    
        task.resume()
    }
    
    func beginSession() {
        
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.focusMode = .Locked
            device.unlockForConfiguration()
        }
        
        var err : NSError? = nil
        
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        captureSession.addOutput(capture)
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
    }
}



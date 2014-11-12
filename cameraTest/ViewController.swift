//
//  ViewController.swift
//  cameraTest
//
//  Created by Jarrod Perez on 11/5/14.
//  Copyright (c) 2014 Jarrod Perez. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureConnection = AVCaptureConnection()
    let devices = AVCaptureDevice.devices()
    var capture = AVCaptureStillImageOutput()
    
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        println("Capture device found")
                        beginSession()
                    }
                }
            }
        }
        
    }
    
    func takePhoto(){
        var connection : AVCaptureConnection
        var port : AVCaptureInputPort
        
        // we do this on another thread so that we don't hang the UI
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            //find the video connection
            var videoConnection : AVCaptureConnection?
            
            println(self.capture.connections.count)
            
            for connecton in self.capture.connections {
                //find a matching input port
                for port in connecton.inputPorts! {
                    if port.mediaType == AVMediaTypeVideo {
                        videoConnection = connecton as? AVCaptureConnection
                        break //for port
                    }
                }
                
                if videoConnection  != nil {
                    break// for connections
                }
            }
            
            if videoConnection  != nil {
                self.capture.captureStillImageAsynchronouslyFromConnection(videoConnection){
                    (imageSampleBuffer : CMSampleBuffer!, _) in
                    
                    println("snap")
                    let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                    var pickedImage: UIImage = UIImage(data: imageDataJpeg)!
                }
                
                self.captureSession.stopRunning()
            }
        }
    }
    
    func beginSession() {
        
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.focusMode = .Locked
            device.unlockForConfiguration()
        }
        
        var err : NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
        
        var delta: Int64 = 2 * Int64(NSEC_PER_SEC)
        
        var time = dispatch_time(DISPATCH_TIME_NOW, delta)
        
        dispatch_after(time, dispatch_get_main_queue(), {
            self.takePhoto()
        });
    }
    
    
}



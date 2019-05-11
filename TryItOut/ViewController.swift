//
//  ViewController.swift
//  TryItOut
//
//  Created by Shashwat  on 11/05/19.
//  Copyright © 2019 Shashwat . All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    lazy var captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(flipCamera))
        self.view.addGestureRecognizer(tap)
        prepareCamera()
    }
    var cameraMode : AVCaptureDevice.Position = .back {
        didSet{
            stopSession()
            prepareCamera()
        }
    }
    
    func prepareCamera(){
        //        captureSession.sessionPreset = AVCaptureSession.Preset.photo //Preset to take still pictures
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: cameraMode) //Gets available devices
        captureDevice = availableDevices.devices.first
        beginSession()
    }
    
    
    func beginSession(){
        //Session specific processsing
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput) //Device to session
        }catch{
            print(error.localizedDescription)
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) //Get AVCaptureVideoPreviewLayer
        
        self.previewLayer.frame = self.view.layer.bounds
        self.view.layer.addSublayer(previewLayer)
        captureSession.startRunning()  //Starts session
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCMPixelFormat_32BGRA) ]
        dataOutput.alwaysDiscardsLateVideoFrames = true //Gets and process data
        if captureSession.canAddOutput(dataOutput){
            captureSession.addOutput(dataOutput)
        }
        captureSession.commitConfiguration()
        
        
        let queue = DispatchQueue(label: "com.shashwat.camera")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
    }
    
    func stopSession(){
        captureSession.stopRunning()
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput]{
            for input in inputs {
                self.captureSession.removeInput(input)
            }
        }
        previewLayer.removeFromSuperlayer()
    }
    
    @objc func flipCamera(){
        if cameraMode == .front {
            cameraMode = .back
        }else{
            cameraMode = .front
        }
    }
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
    }
}


//
//  ViewController.swift
//  TryItOut
//
//  Created by Shashwat  on 11/05/19.
//  Copyright © 2019 Shashwat . All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var faceView: FaceView!
    lazy var captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    lazy var sequenceHandler = VNSequenceRequestHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(flipCamera))
        self.view.addGestureRecognizer(tap)
        faceView.backgroundColor = .clear
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
        self.view.layer.insertSublayer(previewLayer, at: 0)
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
//        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//        _ = CIImage(cvPixelBuffer: pixelBuffer!)
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // 2
        let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFace)
        
        // 3
        do {
            try sequenceHandler.perform(
                [detectFaceRequest],
                on: imageBuffer,
                orientation: .leftMirrored)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    func convert(rect: CGRect) -> CGRect {
        // 1
        let origin = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.origin)
        
        // 2
        let size = previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: rect.maxX, y: rect.maxY))
        
        // 3
        let width = size.x - origin.x
        let height = size.y - origin.y
        
        return CGRect(origin: origin, size: CGSize(width: width, height: height))
    }
    
    func detectedFace(request: VNRequest, error: Error?) {
        // 1
        guard
            let results = request.results as? [VNFaceObservation],
            let result = results.first
            else {
                // 2
                faceView.clear()
                return
        }
        
        // 3
        let box = result.boundingBox
        faceView.boundingBox = convert(rect: box)
        
        // 4
        DispatchQueue.main.async {
            self.faceView.setNeedsDisplay()
        }
    }
}


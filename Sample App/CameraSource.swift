//
//  CameraSource.swift
//  eldade_metal_tests
//
//  Created by Eldad Eilam on 10/2/16.
//  Copyright © 2016 Eldad Eilam. All rights reserved.
//

import Foundation
import AVFoundation

class CameraSource : NSObject, PixelSource, AVCaptureVideoDataOutputSampleBufferDelegate {

    let pickerCameraResolutionSettings = [
        "AVCaptureSessionPresetPhoto",
        "AVCaptureSessionPresetHigh",
        "AVCaptureSessionPresetMedium",
        "AVCaptureSessionPresetLow",
        "AVCaptureSessionPreset352x288",
        "AVCaptureSessionPreset640x480",
        "AVCaptureSessionPreset1280x720",
        "AVCaptureSessionPreset1920x1080",
        "AVCaptureSessionPreset3840x2160",
        ]
    
    var pixelFormat : OSType = kCVPixelFormatType_32BGRA {
        didSet {
            videoOutputQueue.sync {
                videoOut.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: Int(pixelFormat)) ]
            }
        }
    }
    var supportedImages : [String] {
        var availablePresets : [String] = []
        for currentPreset in pickerCameraResolutionSettings {
            if (captureSession.canSetSessionPreset(AVCaptureSession.Preset(rawValue: currentPreset))) {
                availablePresets.append(currentPreset)
            }
        }
        
        return availablePresets
    }
    
    var supportedPixelFormats : [String : OSType] = [
        "32BGRA" : 1111970369,
        "420YpCbCr8BiPlanarVideoRange" : 875704438,
        "420YpCbCr8BiPlanarFullRange" : 875704422]
    
    var supportedPixelFormatNames: [String] {
        let allKeys = supportedPixelFormats.keys
        let pixFormatNamesSortedList : [String] = allKeys.sorted {
            $0 < $1
        }
        
        return pixFormatNamesSortedList
    }
    
    var currentImage : String = "AVCaptureSessionPresetHigh" {
        didSet {
            videoOutputQueue.async {
                self.captureSession.sessionPreset = AVCaptureSession.Preset(rawValue: self.currentImage)
            }
        }
    }
    
    internal var delegate: PixelSourceDelegate! = nil {
        didSet {
//            setupCaptureSession()
        }
    }
    
    var videoIn : AVCaptureDeviceInput?
    
    var captureSession : AVCaptureSession = AVCaptureSession()
    
    var videoConnection : AVCaptureConnection = AVCaptureConnection()
    
    let videoOutputQueue : DispatchQueue = DispatchQueue(label: "videoOutputQueue")
    
    let videoOut = AVCaptureVideoDataOutput.init()
    
    override init() {
        super.init()
        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(startedRunning),
//            name: NSNotification.Name.AVCaptureSessionDidStartRunning,
//            object: nil)
//
//        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(captureError),
//            name: NSNotification.Name.AVCaptureSessionRuntimeError,
//            object: nil)
    }
    
    func startedRunning(notification: NSNotification) {
        
    }
    
    func captureError(notification: NSNotification) {
        
    }

    
    func setupCaptureSession()
    {
        let videoDevice = AVCaptureDevice.default(for: AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)))
        
        do {
            videoIn = try AVCaptureDeviceInput.init(device: videoDevice!)
        }
        catch {
            
        }
        
        if ( captureSession.canAddInput(videoIn!) ) {
            captureSession.addInput(videoIn!)
        }
        else {
            return;
        }
        
        videoOut.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String! : NSNumber(value: Int(pixelFormat))]/*,
                                   kCVPixelBufferIOSurfacePropertiesKey as String! : NSNumber(value: true)]*/
        
        videoOut.setSampleBufferDelegate(self, queue: videoOutputQueue)
        
        videoOut.alwaysDiscardsLateVideoFrames = true
        
        
        if ( captureSession.canAddOutput(videoOut)) {
            captureSession.addOutput(videoOut)
        }
        
        //        let videoConnection = videoOut.connection(withMediaType: AVMediaTypeVideo)
        
        var frameDuration = CMTime.invalid
        
        if (captureSession.canSetSessionPreset(AVCaptureSession.Preset(rawValue: currentImage))) {
            captureSession.sessionPreset = AVCaptureSession.Preset(rawValue: currentImage)
        }
        
        do {
            if (( try videoDevice?.lockForConfiguration() ) != nil) {
                let frameRateRange = videoDevice?.activeFormat.videoSupportedFrameRateRanges
                let firstRange = frameRateRange?.first as! AVFrameRateRange
                
                frameDuration = CMTimeMake ( value: 1, timescale: Int32(firstRange.maxFrameRate) )
                
                videoDevice?.activeVideoMaxFrameDuration = frameDuration
                videoDevice?.activeVideoMinFrameDuration = frameDuration
                
//                videoDevice?.setFocusModeLocked(lensPosition: 0.0, completionHandler: { (time) in
//
//                })
                videoDevice?.unlockForConfiguration()
            }
            else {
                print ( "videoDevice lockForConfiguration returned error")
            }
        }
        catch {
            
        }
        
        
        return;
    }
        
    func startStreaming() {
        setupCaptureSession()
        captureSession.startRunning()
    }
    
    func stopStreaming() {
        captureSession.stopRunning()
        videoOutputQueue.sync {
        }
        captureSession.removeOutput(videoOut)
        captureSession.removeInput(videoIn!)
        videoIn = nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let formatDescription = CMSampleBufferGetFormatDescription( sampleBuffer )
        let sourcePixelBuffer = CMSampleBufferGetImageBuffer( sampleBuffer )
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription!)
        
        delegate.imageSize = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
        delegate.renderCVImageBuffer(sourcePixelBuffer!)
    }
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVMediaType(_ input: AVMediaType) -> String {
	return input.rawValue
}

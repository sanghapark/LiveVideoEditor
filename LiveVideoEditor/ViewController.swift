
//
//  ViewController.swift
//  LiveCameraFiltering
//
//  Created by Simon Gladman on 05/07/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//
// Thanks to: http://www.objc.io/issues/21-camera-and-photos/camera-capture-on-ios/

import UIKit
import AVFoundation
import CoreMedia
import MediaPlayer
import AssetsLibrary


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    enum Status{
        case NotRecording
        case Recording
        case DidRecording
    }
    
    var input:AVCaptureDeviceInput!
    var output:AVCaptureVideoDataOutput!
    var session:AVCaptureSession!
    var camera:AVCaptureDevice!
    
    
    var images : [UIImage] = [UIImage]()
    
    let cameraPreview = UIImageView(frame: CGRectZero)
    let settingView = UIView(frame: CGRectZero)
    let videoButton = UIButton(frame: CGRectZero)
    
    var recording = false
    var status : Status = Status.NotRecording
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        
        cameraPreview.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.width*(4/3))
        cameraPreview.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.addSubview(self.cameraPreview)
        
        
        self.settingView.frame = CGRectMake(0, self.cameraPreview.frame.height, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height - self.cameraPreview.bounds.height)
        self.settingView.backgroundColor = UIColor.darkGrayColor()
        self.view.addSubview(self.settingView)
        
        
        let captureButtonImage = UIImage(named: "record")
        self.videoButton.setImage(captureButtonImage, forState: UIControlState.Normal)
        self.videoButton.frame = CGRectMake(0, 0, captureButtonImage!.size.width, captureButtonImage!.size.height)
        self.videoButton.center.x = self.settingView.frame.width / 2
        self.videoButton.center.y = self.settingView.frame.height / 2
        self.videoButton.addTarget(self, action: "videoButtonPressed", forControlEvents: UIControlEvents.TouchDown)
        self.settingView.addSubview(self.videoButton)
        
        
        self.setupCamera()
    }
    
    
    func setupCamera(){
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSessionPreset640x480
        
        
        for caputureDevice: AnyObject in AVCaptureDevice.devices() {
            // 背面カメラを取得
            if caputureDevice.position == AVCaptureDevicePosition.Back {
                self.camera = caputureDevice as? AVCaptureDevice
            }
            // 前面カメラを取得
            //if caputureDevice.position == AVCaptureDevicePosition.Front {
            //    camera = caputureDevice as? AVCaptureDevice
            //}
        }
        
        
        do{
            self.input = try AVCaptureDeviceInput(device: camera)
        }
        catch{
            print("can't access camera")
            return
        }
        
        if session.canAddInput(self.input) {
            session.addInput(input)
        }
        
        
        
        let videoOutput = AVCaptureVideoDataOutput()
        if self.session.canAddOutput(videoOutput){
            self.session.addOutput(videoOutput)
        }
        
        
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        // although we don't use this, it's required to get captureOutput invoked
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        view.layer.addSublayer(previewLayer)
        
        self.session.startRunning()
        
        
        do {
            try self.camera.lockForConfiguration()
            self.camera.activeVideoMinFrameDuration = CMTimeMake(1, 30)
            self.camera.activeVideoMaxFrameDuration = CMTimeMake(1, 30)
            
            self.camera.unlockForConfiguration()
        }
        catch{
            fatalError("Failed to set frame rate: \(error)")
        }
        
    }
    
    
    func videoButtonPressed(){
        
        //        if self.recording == false{
        //            self.videoButton.setImage(UIImage(named: "stop"), forState: UIControlState.Normal)
        //        }
        //        else{
        //            self.videoButton.setImage(UIImage(named: "record"), forState: UIControlState.Normal)
        //        }
        //        self.recording = !self.recording
        
        if self.status == Status.NotRecording {
            self.videoButton.setImage(UIImage(named: "stop"), forState: UIControlState.Normal)
            self.status = Status.Recording
        }
        else if self.status == Status.Recording {
            self.videoButton.setImage(UIImage(named: "record"), forState: UIControlState.Normal)
            self.status = Status.DidRecording
        }
        
        if self.status == Status.DidRecording{
            self.process()
            self.status = Status.NotRecording
        }
        
    }
    
    var timer : NSTimer?
    var i : Int = 0
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!){
        
        print(i++)
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
        
        
        var tempImage = UIImage(CIImage: cameraImage, scale: 1.0, orientation: UIImageOrientation.Right)
        UIGraphicsBeginImageContextWithOptions(tempImage.size, false, 0.0)
        
        tempImage.drawInRect(CGRectMake( 0, 0, tempImage.size.width, tempImage.size.height ))
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetLineWidth(context, 5.0)
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, tempImage.size.width, tempImage.size.height);
        CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor);
        CGContextStrokePath(context);
        
        tempImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        dispatch_async(dispatch_get_main_queue()){
            self.cameraPreview.image = tempImage
            
            if self.status == Status.Recording{
                self.images.append(tempImage)
            }
            
        }
    }
    
    
    
    // Create a collection of UIImages
    var movieMaker :  CEMovieMaker?
    var frames : NSMutableArray = NSMutableArray()
    func process(){
        
        
        var settings : NSDictionary = CEMovieMaker.videoSettingsWithCodec(AVVideoCodecH264, withWidth: self.images[0].size.width*2, andHeight: self.images[0].size.height*2)
        self.movieMaker = CEMovieMaker(settings: settings as [NSObject : AnyObject])
        
        
        for image in self.images{
            self.frames.addObject(image)
        }
        
        
        self.movieMaker!.createMovieFromImages(self.frames.copy() as! [AnyObject], withCompletion: {(fileURL)
            in
            self.viewMoviewAtURL(fileURL)
            self.saveToCameraRoll(fileURL)
        })
        
    }
    
    func viewMoviewAtURL(fileURL : NSURL){
        let player = MPMoviePlayerViewController(contentURL: fileURL)
        player.view.frame = self.view.bounds
        self.presentMoviePlayerViewControllerAnimated(player)
        player.moviePlayer.prepareToPlay()
        player.moviePlayer.play()
        self.view.addSubview(player.view)
    }
    
    func saveToCameraRoll(fileURL : NSURL){
        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(fileURL, completionBlock: nil)
    }
    
}





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
import AVKit


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    let imageWidth : CGFloat = 480
    let imageHeight : CGFloat = 640
    
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
    var drawingImageView : UIImageView = UIImageView(frame: CGRectZero)
    
    let settingView = UIView(frame: CGRectZero)
    let videoButton = UIButton(frame: CGRectZero)
    
    var status : Status = Status.NotRecording
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        

        
        cameraPreview.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.width*(4/3))
        cameraPreview.contentMode = .ScaleAspectFit
        self.view.addSubview(self.cameraPreview)
        
        self.drawingImageView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.width*(4/3))
        self.drawingImageView.contentMode = .ScaleAspectFit
//        self.drawingImageView.image = UIImage()
        self.view.addSubview(self.drawingImageView)
        
        
        
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
        
        self.view.userInteractionEnabled = true
        self.cameraPreview.userInteractionEnabled = false
        self.drawingImageView.userInteractionEnabled = true
        self.settingView.userInteractionEnabled = true
        
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
            self.camera.activeVideoMinFrameDuration = CMTimeMake(20, 600)
            self.camera.activeVideoMaxFrameDuration = CMTimeMake(20, 600)
            
            self.camera.unlockForConfiguration()
        }
        catch{
            fatalError("Failed to set frame rate: \(error)")
        }
        
    }
    
    private func supportedFPS(){
        
    }
    
    
    func videoButtonPressed(){
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
    

    var i : Int = 0
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!){
        
        
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
        let tempImage = UIImage(CIImage: cameraImage, scale: 1.0, orientation: UIImageOrientation.Right)
    
        
        dispatch_async(dispatch_get_main_queue()){
            

            
            
            if self.status == Status.Recording{
                print(self.i++)
                self.images.append(self.cameraPreview.image!)
            }
            
            self.cameraPreview.image = tempImage
            
        
        }
    }
    
    
    
    
    
    
    
    var lastPoint = CGPoint.zero
    var red: CGFloat = 52.0
    var green: CGFloat = 152.0
    var blue: CGFloat = 219.0
    var brushWidth: CGFloat = 5.0
    var opacity: CGFloat = 1.0
    var swiped = false
    

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        swiped = false
        let touch = touches.first! as UITouch
        
        
        
        lastPoint = touch.locationInView(self.drawingImageView)
        
        let width = self.cameraPreview.frame.width
        let height = self.cameraPreview.frame.height
        let x = lastPoint.x
        let y = lastPoint.y
        
        if y < self.cameraPreview.frame.height {
        
            self.drawLineFrom(lastPoint, toPoint: lastPoint)
            self.cameraPreview.image = self.blendTwoImagesIntoOneImage(self.cameraPreview.image!, topImage: self.drawingImageView.image!)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        swiped = true
        let touch = touches.first! as UITouch
        let currentPoint = touch.locationInView(self.drawingImageView)
        
        let x = currentPoint.x
        let y = currentPoint.y
        
        if y < self.cameraPreview.frame.height{
            drawLineFrom(lastPoint, toPoint: currentPoint)
            lastPoint = currentPoint
            self.cameraPreview.image = self.blendTwoImagesIntoOneImage(self.cameraPreview.image!, topImage: self.drawingImageView.image!)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first! as UITouch
        let currentPoint = touch.locationInView(self.drawingImageView)
        
        let x = currentPoint.x
        let y = currentPoint.y
        
        if y < self.cameraPreview.frame.height {
            if self.swiped == false{
                self.drawingImageView.image = self.addBadgeImageOnImage(UIImage(named: "heart")!, x: lastPoint.x, y: lastPoint.y)
            }
            self.cameraPreview.image = self.blendTwoImagesIntoOneImage(self.cameraPreview.image!, topImage: self.drawingImageView.image!)
        }
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        
        let retinaScale : CGFloat = UIScreen.mainScreen().scale
        let nativeScale : CGFloat = UIScreen.mainScreen().nativeScale
        
        
        // 1
//        UIGraphicsBeginImageContext(self.drawingImageView.frame.size)
//        UIGraphicsBeginImageContextWithOptions(self.drawingImageView.frame.size, false, 0)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: self.imageWidth, height: self.imageHeight), false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        let width = self.cameraPreview.frame.size.width
        let height = self.cameraPreview.frame.size.height
        
        drawingImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: self.imageWidth, height: self.imageHeight))
        
        // 2
        
//        화면 터치 Coordinate과 320x426.66 (cameraPreview, drawingImageView frame size)
//        Drawing Context 480x640(이미지 사이즈) 사이즈가 다르기 때문에
//        320x568 (UIScreen.mainScreen().bounds.size) 에서 발생한  (x,y) 는
//        480x640  시스템에 맞에 스케일 조정을 해줘야된다.
//        480x640 시스템이 320x426.66 화면에 축속되서 들어 가기 때문에
//        그래서 밑에 1.5를 곱해준다
        CGContextMoveToPoint(context, fromPoint.x*1.5, fromPoint.y*1.5)
        CGContextAddLineToPoint(context, toPoint.x*1.5, toPoint.y*1.5)
        
        // 3
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, brushWidth)
        CGContextSetRGBStrokeColor(context, red, green, blue, 1.0)
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        
        // 4
        CGContextStrokePath(context)
        
        // 5
        drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        
        let finalImageWidth = drawingImageView.image?.size.width
        let finalImageHeight = drawingImageView.image?.size.height
        
        drawingImageView.alpha = opacity
        UIGraphicsEndImageContext()
    }
    
    func blendTwoImagesIntoOneImage(bottomImage : UIImage, topImage : UIImage) -> UIImage{
        let size = CGSizeMake(bottomImage.size.width, bottomImage.size.height)
        
        let bottomImageWidth = bottomImage.size.width
        let bottomImageHeight = bottomImage.size.height
        let topImageWidth = topImage.size.width
        let topImageHeight = topImage.size.height
        
        
        let retinaScale : CGFloat = UIScreen.mainScreen().scale
//        UIGraphicsBeginImageContext(size)
         UIGraphicsBeginImageContextWithOptions(CGSize(width: self.imageWidth, height: self.imageHeight), false, 0.0)
        bottomImage.drawInRect(CGRectMake(0, 0, size.width, size.height))
        topImage.drawInRect(CGRectMake(0, 0, size.width, size.height))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        
        let finalImageWidth = image.size.width
        let finalImageHeight = image.size.height
        
        
        UIGraphicsEndImageContext()
        return image
    }
    
    
    func addBadgeImageOnImage(badge : UIImage, x : CGFloat, y : CGFloat) -> UIImage{
        
        let backgroundSize = self.drawingImageView.image!.size
        let badgeSize = badge.size
        
        // Create a graphics context in which we will do our drawing
        // The graphics context is kind of like a piece of paper
//        UIGraphicsBeginImageContext(backgroundSize)
        let retinaScale : CGFloat = UIScreen.mainScreen().scale
         UIGraphicsBeginImageContextWithOptions(CGSize(width: self.imageWidth, height: self.imageHeight), false, 0.0)
        
        // First thing we want to draw on it is the background photo
        self.drawingImageView.image!.drawInRect(CGRectMake(0, 0, backgroundSize.width, backgroundSize.height))
        
        // We draw badge at the position that we want it o be on top of the background image
        badge.drawInRect(CGRectMake((x*1.5) - (badgeSize.width/2.0), (y*1.5) - (badgeSize.height/2.0), badgeSize.width, badgeSize.height))
        
        // we create the new UIImage
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        
        let imageWidht = finalImage.size.width
        let imageHeight = finalImage.size.height
        
        // Clean up and close the context we no long need it
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // Create a collection of UIImages
    var movieMaker :  CEMovieMaker?
    var frames : NSMutableArray = NSMutableArray()
    func process(){
        
        let scale : CGFloat = UIScreen.mainScreen().scale
        
        let settings : NSDictionary = CEMovieMaker.videoSettingsWithCodec(AVVideoCodecH264, withWidth: self.imageWidth*scale, andHeight: self.imageHeight*scale)
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
    

//    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        
//        var tempImage = self.cameraPreview.image
//        UIGraphicsBeginImageContextWithOptions(tempImage!.size, false, 0.0)
//        
//        var preTouch : UITouch?
//        for touch in touches{
//            let touchX = touch.locationInView(self.view).x
//            let touchY = touch.locationInView(self.view).y
//            
//            if touchY < self.cameraPreview.frame.height && preTouch != nil{
//                
//                tempImage!.drawInRect(CGRectMake( 0, 0, tempImage!.size.width, tempImage!.size.height ))
//                let context = UIGraphicsGetCurrentContext()
//                CGContextSetLineWidth(context, 5.0)
//                CGContextMoveToPoint(context, preTouch!.locationInView(self.view).x, preTouch!.locationInView(self.view).y);
//                CGContextAddLineToPoint(context, touchX, touchY);
//                CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor);
//                CGContextStrokePath(context);
//                tempImage = UIGraphicsGetImageFromCurrentImageContext()
//                
//                self.cameraPreview.image = tempImage
//            }
//            preTouch = touch
//        }
//        UIGraphicsEndImageContext()
//        
//    }
//    
//    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        let touch = touches.first! as UITouch
//        let touchLocation = touch.locationInView(self.view)
//        let touchY = touchLocation.y
//        let touchX = touchLocation.x
//        
//        if touchY < self.cameraPreview.frame.height {
//        
//            
//            var tempImage = self.cameraPreview.image
//            
//            UIGraphicsBeginImageContextWithOptions(tempImage!.size, false, 0.0)
//            tempImage!.drawInRect(CGRectMake( 0, 0, tempImage!.size.width, tempImage!.size.height ))
//            let context = UIGraphicsGetCurrentContext()
//            CGContextSetLineWidth(context, 5.0)
//            CGContextMoveToPoint(context, preTouchLocation.x, preTouchLocation.y);
//            CGContextAddLineToPoint(context, touchX, touchY);
//            CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor);
//            CGContextStrokePath(context);
//            tempImage = UIGraphicsGetImageFromCurrentImageContext()
//            UIGraphicsEndImageContext()
//            self.cameraPreview.image = tempImage
//
//        }
//    }

}




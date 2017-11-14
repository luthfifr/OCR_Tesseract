//
//  ViewController.swift
//  tesOCR
//
//  Created by Luthfi Fathur Rahman on 11/13/17.
//  Copyright © 2017 Luthfi Fathur Rahman. All rights reserved.
//

import UIKit
import TesseractOCR
import AVFoundation

class ViewController: UIViewController, G8TesseractDelegate {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var btn_capture: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var captureImageView: UIImageView!
    
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    let tesseract = G8Tesseract(language: "eng")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressBar.isHidden = false
        btn_capture.layer.cornerRadius = btn_capture.frame.size.width/2
        btn_capture.clipsToBounds = true
        
        captureImageView.isUserInteractionEnabled = true
        captureImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.previewImage)))
        
        if let tessr = tesseract {
            tessr.delegate = self
            tessr.maximumRecognitionTime = 30
        }
        
        /*if let tesseract = G8Tesseract(language: "eng") {
            tesseract.delegate = self
            tesseract.image = UIImage(named: "tester1")?.g8_blackAndWhite()
            tesseract.recognize()
            
            textView.text = tesseract.recognizedText
        }*/
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.tesseractStart), name: NSNotification.Name(rawValue: "startTesseract"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.tesseractFinish), name: NSNotification.Name(rawValue: "finishTesseract"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSession.Preset.photo
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera!)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
            
            if session!.canAddOutput(stillImageOutput!) {
                session!.addOutput(stillImageOutput!)
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
                videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspect
                videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                previewView.layer.addSublayer(videoPreviewLayer!)
                session!.startRunning()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = previewView.bounds
    }
    
    @objc func previewImage() {
        if captureImageView.image != nil {
            animateImagePreview(captureImageView)
        }
    }
    
    //MARK: G8TesseractDelegate
    func progressImageRecognition(for tesseract: G8Tesseract!) {
        print("tesseract progress: \(tesseract.progress)%")
        progressBar.progress = Float(tesseract.progress)
        
        if tesseract.progress >= 94 {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "finishTesseract"), object: nil)
        }
    }
    
    @objc func tesseractStart() {
        
    }
    
    @objc func tesseractFinish() {
        guard let tessr = tesseract else {return}
        progressBar.isHidden = true
        textView.text = tessr.recognizedText
        btn_capture.isEnabled = true
        btn_capture.backgroundColor = UIColor.red
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btn_capture(_ sender: UIButton) {
        print("btn pressed")
        guard let tessr = tesseract else {
            print("Tesseract object is nil")
            
            return
        }
        
        progressBar.isHidden = false
        progressBar.progress = 0.0
        btn_capture.isEnabled = false
        btn_capture.backgroundColor = UIColor.darkGray
        
        if let videoConnection = stillImageOutput!.connection(with: AVMediaType.video) {
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)
                    let dataProvider = CGDataProvider(data: imageData! as CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    //let image:UIImage = UIImage(cgImage: cgImageRef!)
                    tessr.image = UIImage(cgImage: cgImageRef!).g8_blackAndWhite()
                    self.captureImageView.image = tessr.image
                    tessr.recognize()
                    //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "startTesseract"), object: nil)
                }
            })
        }
    }
    
    //MARK: Preview User Post Image
    
    let zoomImageView = UIImageView()
    var blackBackgroundView = UIView()
    var navBarCoverView = UIView()
    var tabBarCoverView = UIView()
    
    var zoomImage_Yposition: CGFloat?
    var zoomImage_height: CGFloat?
    
    var postImageView: UIImageView?
    
    func animateImagePreview(_ postImageView: UIImageView) {
        if postImageView.image != nil {
            self.postImageView = postImageView
            
            if let imageViewStartingFrame = postImageView.superview?.convert(postImageView.frame, to: nil) {
                zoomImageView.alpha = 0
                
                blackBackgroundView.frame = self.view.frame
                blackBackgroundView.backgroundColor = UIColor.black
                blackBackgroundView.alpha = 0
                view.addSubview(blackBackgroundView)
                
                navBarCoverView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 20 + 44)
                navBarCoverView.backgroundColor = UIColor.black
                navBarCoverView.alpha = 0
                
                if let keyWindow = UIApplication.shared.keyWindow {
                    keyWindow.addSubview(navBarCoverView)
                }
                
                zoomImageView.backgroundColor = UIColor.red
                zoomImageView.frame = imageViewStartingFrame
                zoomImageView.isUserInteractionEnabled = true
                zoomImageView.image = postImageView.image
                zoomImageView.contentMode = .scaleAspectFill
                zoomImageView.clipsToBounds = true
                zoomImageView.alpha = 0
                view.addSubview(zoomImageView)
                
                zoomImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.imagePreviewZoomOut)))
                print("image frame: \(String(describing: postImageView.image?.size))")
                UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: { () -> Void in
                    
                    if (postImageView.image?.size.height)! > (postImageView.image?.size.width)! {
                        print("imageToShow is in portrait mode.")
                        self.zoomImage_height = self.view.frame.width * ((postImageView.image?.size.height)!/(postImageView.image?.size.width)!)
                    } else {
                        print("imageToShow is in landscape mode.")
                        self.zoomImage_height = (self.view.frame.width / imageViewStartingFrame.width) * imageViewStartingFrame.height
                    }
                    
                    print("zoomImage_height: \(String(describing: self.zoomImage_height))")
                    
                    self.zoomImage_Yposition = self.view.frame.height / 2 - self.zoomImage_height! / 2
                    
                    self.zoomImageView.frame = CGRect(x: 0, y: self.zoomImage_Yposition!, width: self.view.frame.width, height: self.zoomImage_height!)
                    
                    self.zoomImageView.alpha = 1
                    
                    self.blackBackgroundView.alpha = 1
                    
                    self.navBarCoverView.alpha = 1
                    
                    //self.tabBarCoverView.alpha = 1
                    
                }, completion: nil)
                
                //self.zoomImage_height = (self.view.frame.width / imageViewStartingFrame.width) * imageViewStartingFrame.height
                
                //self.zoomImage_Yposition = self.view.frame.height / 2 - self.zoomImage_height! / 2
                //self.selectedRow = cellRow
                //self.performSegue(withIdentifier: "segue_previewImagePost", sender: self)
            }
        }
    }
    
    @objc func imagePreviewZoomOut() {
        if let startingFrame = postImageView!.superview?.convert(postImageView!.frame, to: nil) {
            UIView.animate(withDuration: 0.75, animations: { () -> Void in
                self.zoomImageView.frame = startingFrame
                
                self.blackBackgroundView.alpha = 0
                self.navBarCoverView.alpha = 0
                
            }, completion: { (didComplete) -> Void in
                self.zoomImageView.removeFromSuperview()
                self.blackBackgroundView.removeFromSuperview()
                self.navBarCoverView.removeFromSuperview()
                self.postImageView?.alpha = 1
            })
            
        }
    }
}


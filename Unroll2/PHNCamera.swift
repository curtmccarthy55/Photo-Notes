//
//  PHNCamera.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 12/7/21.
//  Copyright © 2021 Curtis McCarthy. All rights reserved.
//

import Foundation
import UIKit
import Photos

protocol PHNCameraDelegate: AnyObject {
    func camera(_ camera: PHNCamera, didFinishProcessingPhotos photoNotes: [PhotoNote]?)
    func cameraDidCancel(error: CameraError?)
}

enum CameraError: Error {
    case AccessDenied
    case CameraUnavailable
}

/// Class to help present and receive user actions for the on-device camera.
class PHNCamera: NSObject { // Object conformance added to allow conformance to UIImagePickerControllerDelegate.
    weak var delegate: PHNCameraDelegate?
    
    /// The view controller to present the camera from.
    weak var presentingView: UIViewController?
    /// ImagePickerController to use the device camera.
    var imagePicker: UIImagePickerController?
    /// Flash toggle button in the camera overlay.
    var flashButton: UIButton?
    /// Done button in the camera overlay.
    var doneButton: UIButton?
    /// Cancel button in the camera overlay.
    var cameraCancelButton: UIButton?
    /// Front/rear camera toggle button in the camera overlay.
    var cameraFlipButton: UIButton?
    /// ImageView to display last photo taken in the camera overlay.
    var capturedPhotos: UIImageView?
    /// Variable to help track device orientation
    var lastOrientation: UIDeviceOrientation?
    /// Collection of new image data from the UIImagePickerController.
    var pickerPhotos: [[String : Any?]]?
    /// A temporary container for newly created Photo Notes, imported from a user library or captured by the camera.
    var newPhotoNotes: [PhotoNote]?
    
    convenience init(presentingView: UIViewController) {
        self.init()
        self.presentingView = presentingView
    }
    
    /// Confirm camera access authorization, then present.
    func openCamera() {
        // Check if a camera is available, and alert the user and return if not.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            delegate?.cameraDidCancel(error: .CameraUnavailable)
            return
        }
        // Check for camera access authorization.
        let mediaType = AVMediaType.video
        let authStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        if authStatus == .authorized {
            // If authorized, present the camera.
            prepareAndPresentCamera()
        } else {
            // If not authorized, request access.
            AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted) in
                if granted {
                    // If camera access is granted, call for the camera to be prepared and presented.
                    #if DEBUG
                        print("Permission for camera access granted")
                    #endif
                    self?.prepareAndPresentCamera()
                } else {
                    // If camera access denied, alert the user that they'll need to enable it to allow photo capture.
                    self?.delegate?.cameraDidCancel(error: .AccessDenied)
                }
            }
        }
    }
    
    /// Prepares the camera overlay and then presents it on the presenting view controller.
    func prepareAndPresentCamera() {
        imagePicker = UIImagePickerController()
        imagePicker?.sourceType = UIImagePickerController.SourceType.camera
        imagePicker?.showsCameraControls = false
        imagePicker?.allowsEditing = false
        imagePicker?.delegate = self
        imagePicker?.cameraFlashMode = .off
        imagePicker?.cameraDevice = .rear
        imagePicker?.mediaTypes
        
        // Determine if viewport needs translation, and find bottom bar height.
        let screenHeight = UIScreen.main.bounds.size.height
        let screenWidth = UIScreen.main.bounds.size.width
        var longDimension: CGFloat
        var shortDimension: CGFloat
        if screenHeight > screenWidth {
            longDimension = screenHeight
            shortDimension = screenWidth
        } else {
            longDimension = screenWidth
            shortDimension = screenHeight
        }
        var cameraFrame: CGSize
        let aspectRatio = CGFloat(4.0 / 3.0)
        cameraFrame = CGSize(width: shortDimension, height: shortDimension * aspectRatio)
        let portraitFrame = CGRect(x: 0, y: 0, width: shortDimension, height: longDimension)
        
        if longDimension > 800 {
            // Determine remaining space for bottom buttons.
            longDimension -= 44.0 // subtract top bar
            let adjustHeight = CGAffineTransform(translationX: 0.0, y: 44.0)
            imagePicker?.cameraViewTransform = adjustHeight
        }
        let bottomBarHeight = longDimension - cameraFrame.height // Subtract viewport.
        
        let overlay = cameraOverlayWithFrame(portraitFrame, containerHeight: bottomBarHeight)
        imagePicker?.cameraOverlayView = overlay
        imagePicker?.modalTransitionStyle = .coverVertical
        
        lastOrientation = UIDevice.current.orientation
        NotificationCenter.default.addObserver(self, selector: #selector(rotateCameraViews), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        presentingView?.present(imagePicker!, animated: true) { [weak self] in
            self?.rotateCameraViews()
        }
    }
    
    @objc func rotateCameraViews() {
        let orientation = UIDevice.current.orientation
        var rotation: Double = 1
        switch orientation {
        case .portrait:
            rotation = 0
        case .landscapeLeft:
            rotation = Double.pi / 2
        case .landscapeRight:
            rotation = -(Double.pi / 2)
        default:
            break
        }
        if rotation != 1 {
            UIView.animate(withDuration: 0.2) { [weak self] in
                let transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
                self?.capturedPhotos?.transform = transform
                self?.flashButton?.transform = transform
                self?.cameraFlipButton?.transform = transform
                self?.doneButton?.transform = transform
                self?.cameraCancelButton?.transform = transform
            }
        }
        lastOrientation = orientation
    }
    
    // TODO replace with nib based overlay view?
    func cameraOverlayWithFrame(_ overlayFrame: CGRect, containerHeight barHeight: CGFloat) -> UIView {
        let mainOverlay = UIView(frame: overlayFrame)
        
        // Create container view for buttons.
        let buttonBar = UIView()
        buttonBar.backgroundColor = .clear
        buttonBar.clipsToBounds = true
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        mainOverlay.addSubview(buttonBar)
        buttonBar.centerXAnchor.constraint(equalTo: mainOverlay.centerXAnchor).isActive = true
        buttonBar.bottomAnchor.constraint(equalTo: mainOverlay.bottomAnchor).isActive = true
        buttonBar.widthAnchor.constraint(equalTo: mainOverlay.widthAnchor).isActive = true
        buttonBar.heightAnchor.constraint(equalToConstant: barHeight).isActive = true
        let saGuide = buttonBar.safeAreaLayoutGuide
        
        // Add container view to hold the top row of buttons.
        let topRow = UIView()
        topRow.backgroundColor = .clear
        topRow.translatesAutoresizingMaskIntoConstraints = false
        mainOverlay.addSubview(topRow)
        topRow.centerXAnchor.constraint(equalTo: saGuide.centerXAnchor).isActive = true
        topRow.leadingAnchor.constraint(equalTo: saGuide.leadingAnchor).isActive = true
        topRow.topAnchor.constraint(equalTo: saGuide.topAnchor).isActive = true
        topRow.trailingAnchor.constraint(equalTo: saGuide.trailingAnchor).isActive = true
        topRow.bottomAnchor.constraint(equalTo: saGuide.centerYAnchor).isActive = true
        let topGuide = topRow.safeAreaLayoutGuide
        
        // Add captured photos thumbnail
        capturedPhotos = UIImageView()
        capturedPhotos!.layer.borderColor = UIColor.lightGray.cgColor
        capturedPhotos!.layer.borderWidth = 1.0
        capturedPhotos!.layer.cornerRadius = 5.0
        capturedPhotos!.translatesAutoresizingMaskIntoConstraints = false
        capturedPhotos!.contentMode = .scaleAspectFit
        capturedPhotos!.image = UIImage(named: "NoImage")
        topRow.addSubview(capturedPhotos!)
        capturedPhotos!.widthAnchor.constraint(equalTo: topGuide.heightAnchor, multiplier: 0.7).isActive = true
        capturedPhotos!.heightAnchor.constraint(equalTo: topGuide.heightAnchor, multiplier: 0.7).isActive = true
        capturedPhotos!.centerXAnchor.constraint(equalTo: topGuide.centerXAnchor).isActive = true
//        capturedPhotos!.topAnchor.constraint(equalTo: saGuide.topAnchor, constant: 16.0).isActive = true
        capturedPhotos!.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor).isActive = true
        
        // Add flash button
        var currentFlash: UIImage
        if imagePicker!.cameraFlashMode == .on {
            currentFlash = UIImage(named: "FlashOn")!
        } else {
            currentFlash = UIImage(named: "FlashOff")!
        }
        flashButton =  UIButton(type: .custom)
        flashButton!.addTarget(self, action: #selector(updateFlashMode), for: .touchUpInside)
        flashButton!.setImage(currentFlash, for: .normal)
        flashButton!.tintColor = .white
        flashButton!.translatesAutoresizingMaskIntoConstraints = false
        topRow.addSubview(flashButton!)
        flashButton!.topAnchor.constraint(equalTo: topGuide.topAnchor, constant: 8.0).isActive = true
//        flashButton!.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor).isActive = true
        flashButton!.leadingAnchor.constraint(equalTo: topGuide.leadingAnchor, constant: 8.0).isActive = true
        flashButton!.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        flashButton!.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        // Add button for front/back camera toggle.
        cameraFlipButton = UIButton(type: .custom)
        cameraFlipButton!.setImage(UIImage(named: "CamFlip"), for: .normal)
        cameraFlipButton!.addTarget(self, action: #selector(reverseCamera), for: .touchUpInside)
        cameraFlipButton!.tintColor = .white
        cameraFlipButton!.translatesAutoresizingMaskIntoConstraints = false
        topRow.addSubview(cameraFlipButton!)
        cameraFlipButton!.topAnchor.constraint(equalTo: saGuide.topAnchor, constant: 8.0).isActive = true
//        cameraFlipButton!.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor).isActive = true
        cameraFlipButton!.trailingAnchor.constraint(equalTo: topGuide.trailingAnchor, constant: -8.0).isActive = true
        cameraFlipButton!.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        cameraFlipButton!.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        // Add container view to hold the bottom row of buttons.
        let bottomRow = UIView()
        bottomRow.backgroundColor = .clear
        bottomRow.translatesAutoresizingMaskIntoConstraints = false
        mainOverlay.addSubview(bottomRow)
        bottomRow.centerXAnchor.constraint(equalTo: saGuide.centerXAnchor).isActive = true
        bottomRow.leadingAnchor.constraint(equalTo: saGuide.leadingAnchor).isActive = true
        bottomRow.topAnchor.constraint(equalTo: saGuide.centerYAnchor).isActive = true
        bottomRow.trailingAnchor.constraint(equalTo: saGuide.trailingAnchor).isActive = true
        bottomRow.bottomAnchor.constraint(equalTo: saGuide.bottomAnchor).isActive = true
        let bottomGuide = bottomRow.safeAreaLayoutGuide
        
        // Add camera shutter button.
        let cameraButton = UIButton(type: .roundedRect)
        cameraButton.setImage(UIImage(named: "CameraShutter"), for: .normal)
        cameraButton.setImage(UIImage(named: "PressedCameraShutter"), for: .highlighted) // TODO: not triggering
        cameraButton.tintColor = .white
        cameraButton.addTarget(self, action: #selector(shutterPressed), for: .touchUpInside)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        bottomRow.addSubview(cameraButton)
        cameraButton.centerXAnchor.constraint(equalTo: bottomGuide.centerXAnchor).isActive = true
        cameraButton.centerYAnchor.constraint(equalTo: bottomGuide.centerYAnchor).isActive = true
        
        // Add done button.
        doneButton = UIButton(type: .custom)
        doneButton!.setTitle("Done", for: .normal)
        doneButton!.setTitleColor(.darkGray, for: .normal)
        doneButton!.addTarget(self, action: #selector(photoCaptureFinished), for: .touchUpInside)
        doneButton!.translatesAutoresizingMaskIntoConstraints = false
        bottomRow.addSubview(doneButton!)
        doneButton!.isEnabled = false
        doneButton!.bottomAnchor.constraint(equalTo: bottomGuide.bottomAnchor, constant: -8.0).isActive = true
//        doneButton!.bottomAnchor.constraint(equalTo: bottomGuide.centerYAnchor).isActive = true
        doneButton!.trailingAnchor.constraint(equalTo: bottomGuide.trailingAnchor, constant: -8.0).isActive = true
        
        // Add cancel button.
        cameraCancelButton = UIButton(type: .custom)
        cameraCancelButton!.setTitle("Cancel", for: .normal)
        cameraCancelButton!.translatesAutoresizingMaskIntoConstraints = false
        cameraCancelButton!.addTarget(self, action: #selector(cancelCamera), for: .touchUpInside)
        bottomRow.addSubview(cameraCancelButton!)
        cameraCancelButton!.bottomAnchor.constraint(equalTo: bottomGuide.bottomAnchor, constant: -8.0).isActive = true
//        cameraCancelButton!.centerYAnchor.constraint(equalTo: bottomGuide.centerYAnchor).isActive = true
        cameraCancelButton!.leadingAnchor.constraint(equalTo: bottomGuide.leadingAnchor, constant: -8.0).isActive = true
        
        return mainOverlay
    }
    
    @objc func updateFlashMode() {
        if let flashMode = imagePicker?.cameraFlashMode, flashMode == .off {
            imagePicker?.cameraFlashMode = .on
            flashButton?.setImage(UIImage(named: "FlashOn"), for: .normal)
        } else {
            imagePicker?.cameraFlashMode = .off
            flashButton?.setImage(UIImage(named: "FlashOff"), for: .normal)
        }
    }
    
    @objc func reverseCamera() {
        if let camDevice = imagePicker?.cameraDevice, camDevice == .rear {
            imagePicker?.cameraDevice = .front
        } else {
            imagePicker?.cameraDevice = .rear
        }
    }
    
    @objc func shutterPressed() {
        imagePicker?.takePicture()
    }
    
    /// Called once the user dismisses the camera with the 'Done' button.
    @objc func photoCaptureFinished() {
        guard let pickedPhotos = pickerPhotos else {
            delegate?.camera(self, didFinishProcessingPhotos: nil)
            return
        }
        
        var tempAlbum = [PhotoNote]()
        
        for dic in pickedPhotos {
            let newPhotoNote = PhotoNote()
            if let newPhotoData = dic["newImage"] as? Data {
                PHNServices.shared.writeImageData(newPhotoData,
                                    forPhotoNote: newPhotoNote)
            }
            if let thumbnail = dic["newThumbnail"] as? UIImage {
                PHNServices.shared.writeThumbnail(thumbnail,
                                    forPhotoNote: newPhotoNote)
            }
            
            newPhotoNote.photoCreationDate = Date()
            newPhotoNote.thumbnailNeedsRedraw = false
            tempAlbum.append(newPhotoNote)
        }
        
        newPhotoNotes = Array(tempAlbum)
        delegate?.camera(self, didFinishProcessingPhotos: newPhotoNotes)
    }
    
    @objc func cancelCamera() {
        presentingView?.dismiss(animated: true) { [weak self] in
            self?.pickerPhotos = nil
            self?.imagePicker = nil
        }
    }
}

extension PHNCamera: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // Converting photo captured by in-app camera to PhotoNote.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        doneButton?.isEnabled = true
        doneButton?.setTitleColor(.white, for: .normal)
        
//        TODO: Use PHAsset instead of UIImage. cjm album fetch
//        let newAsset = info[UIImagePickerController.InfoKey.phAsset]
        let newPhoto = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
//        let newPhotoData = newPhoto?.jpegData(compressionQuality: 1.0)
        let newPhotoData = newPhoto?.pngData()
        
        // cjm TODO: previously the value passed in for size was CGSize(width: 120.0, height: 120.0).  Consider changing 'size' type on generateSquareThumbnail.
        let thumbnail = PHNImageServices.shared.generateSquareThumbnail(fromImage: newPhoto!, size: .largeThumbnail)
        
        //cjm album fetch
        let metaDic = info[UIImagePickerController.InfoKey.mediaMetadata]
        #if DEBUG
        print("metaDic == \(metaDic ?? "nil")")
        #endif
        
        let dic: [String : Any?] = [ "newImage" : newPhotoData,
                                     "newThumbnail" : thumbnail ]
        
        if pickerPhotos == nil {
            pickerPhotos = []
        }
        pickerPhotos?.append(dic)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        presentingView?.dismiss(animated: true, completion: nil)
    }
}

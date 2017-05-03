//
//  CameraMan.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/21/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import MobileCoreServices

private let COPY_TITLE_ALERT = "Oh No!"
private let COPY_DENIED_VIDEO_CAMERA_ACCESS_MESSAGE = "We need permission to use the Camera and the Microphone, please change privacy settings."
private let COPY_DENIED_CAMERA_ACCESS_MESSAGE = "We need permission to use the Camera, please change privacy settings."
private let COPY_DENIED_PHOTO_LIBRARY_ACCESS_MESSAGE = "We need permission to access your Photos, please change privacy settings."
private let COPY_VIDEO_CAMERA_UNAVAILABLE_MESSAGE = "It looks like the Video Camera is unavailable. You can upload a video from your Photo Library instead."
private let COPY_CAMERA_UNAVAILABLE_MESSAGE = "It looks like the Camera is unavailable. You can upload a video from your Photo Library instead"
private let COPY_VIDEO_MEDIA_TYPE_UNAVAILABLE_PHOTO_LIBRARY_MESSAGE = "There are no available videos in your Photo Library."
private let COPY_IMAGE_MEDIA_TYPE_UNAVAILABLE_PHOTO_LIBRARY_MESSAGE = "There are no available images in your Photo Library."

private let DURATION_MAX_VIDEO_MINUTES = 20

typealias VideoURLCompletion = (URL?) -> Void
typealias ImageCompletion = (UIImage?) -> Void

class CameraMan: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    let pickerController = UIImagePickerController()
    
    //public maxDuration var for client to express duration in minutes,
    //private computed var below will convert it to a proper TimeInterval type:
    var maxVideoDurationMinutes: Double? = Double(DURATION_MAX_VIDEO_MINUTES)
    
    private var maxVideoDuration: TimeInterval? {
        guard let duration = self.maxVideoDurationMinutes else { return nil }
        let minute: TimeInterval = 60.0
        let seconds: TimeInterval = duration * minute
        return seconds
    }
    
    private var videoCompletionHandler: VideoURLCompletion?
    private var imageCompletionHandler: ImageCompletion?
    
    /**
     * opens the camera for recording a video.
     * This method opens camera full screen modally from presenter and passes video file url in the completion:
     */
    func getVideoFromCamera(withPresenter presenter: UIViewController, completion: @escaping VideoURLCompletion)
    {
        let sourceType = UIImagePickerControllerSourceType.camera
        let mediaType = kUTTypeMovie as String
        
        //check that we have a camera that can record video and verify mediaType:
        guard UIImagePickerController.isSourceTypeAvailable(sourceType),
            let mediaTypes = UIImagePickerController.availableMediaTypes(for: sourceType),
            mediaTypes.contains(mediaType) else {
                UIAlertController.explain(withPresenter: presenter, title: COPY_TITLE_ALERT, message: COPY_VIDEO_CAMERA_UNAVAILABLE_MESSAGE)
                return
        }
        
        AVCaptureDevice.verifyVideoAndAudioAuthorization(authorizedHandler: {
            
            self.showImagePicker(forSourceType: sourceType, mediaTypes: [mediaType], withPresenter: presenter)
            
        }, notAuthorizedHandler: {
            
            UIAlertController.alertUser(withPresenter: presenter, title: COPY_TITLE_ALERT, message: COPY_DENIED_VIDEO_CAMERA_ACCESS_MESSAGE, okButton: true, settingsButton: true)
        })
        
        self.videoCompletionHandler = completion
    }
    
    /**
     * opens the camera roll for picking a video only.
     * This method opens the picker full screen modally on iphone, and as a popover on iPad.
     * Client must configure popoverPresentationController of self.pickerController.
     * presenter is the controller that will present this, and video file url is passed along in the completion:
     */
    func getVideoFromLibrary(withPresenter presenter: UIViewController, completion: @escaping VideoURLCompletion)
    {
        let sourceType = UIImagePickerControllerSourceType.photoLibrary
        let mediaType = kUTTypeMovie as String
        
        //verify mediaType:
        guard let mediaTypes = UIImagePickerController.availableMediaTypes(for: sourceType), mediaTypes.contains(mediaType) else {
            UIAlertController.explain(withPresenter: presenter, title: COPY_TITLE_ALERT, message: COPY_VIDEO_MEDIA_TYPE_UNAVAILABLE_PHOTO_LIBRARY_MESSAGE)
            return
        }
        
        //verify Photo Library authorization and proceed accordingly:
        PHPhotoLibrary.verifyAuthorization(authorizedHandler: {
            
            self.showImagePicker(forSourceType: .photoLibrary, mediaTypes: [mediaType], withPresenter: presenter)
            
        }, notAuthorizedHandler: {
            
            UIAlertController.alertUser(withPresenter: presenter, title: COPY_TITLE_ALERT, message: COPY_DENIED_PHOTO_LIBRARY_ACCESS_MESSAGE, okButton: true, settingsButton: true)
        })
        
        self.videoCompletionHandler = completion
    }
    
    /**
     * opens the camera for taking a still image.
     * This method opens camera full screen modally from presenter and passes UIImage along in the completion:
     */
    func getPhotoFromCamera(withPresenter presenter: UIViewController, completion: @escaping ImageCompletion)
    {
        let sourceType = UIImagePickerControllerSourceType.photoLibrary
        let mediaType = kUTTypeImage as String
        
        //check that we have a camera that can take photos and verify mediaType:
        guard UIImagePickerController.isSourceTypeAvailable(sourceType),
            let mediaTypes = UIImagePickerController.availableMediaTypes(for: sourceType),
            mediaTypes.contains(mediaType) else {
                UIAlertController.explain(withPresenter: presenter, title: COPY_TITLE_ALERT, message: COPY_CAMERA_UNAVAILABLE_MESSAGE)
                return
        }
        
        AVCaptureDevice.verifyVideoAndAudioAuthorization(authorizedHandler: {
            
            self.showImagePicker(forSourceType: sourceType, mediaTypes: [mediaType], withPresenter: presenter)
            
        }, notAuthorizedHandler: {
            
            UIAlertController.alertUser(withPresenter: presenter, title: COPY_TITLE_ALERT, message: COPY_DENIED_CAMERA_ACCESS_MESSAGE, okButton: true, settingsButton: true)
        })
        
        self.imageCompletionHandler = completion
    }
    
    /**
     * opens the camera roll for picking a still image only.
     * This method opens the picker full screen modally on iphone, and as a popover fromView on iPad.
     * Client must configure popoverPresentationController of self.pickerController.
     * presenter is the controller that will present this, and UIImage is passed along in the completion:
     */
    func getPhotoFromLibrary(withPresenter presenter: UIViewController, completion: @escaping ImageCompletion)
    {
        let sourceType = UIImagePickerControllerSourceType.photoLibrary
        let mediaType = kUTTypeImage as String
        
        //verify mediaType:
        guard let mediaTypes = UIImagePickerController.availableMediaTypes(for: sourceType), mediaTypes.contains(mediaType) else {
            UIAlertController.explain(withPresenter: presenter, title: COPY_TITLE_ALERT, message: COPY_IMAGE_MEDIA_TYPE_UNAVAILABLE_PHOTO_LIBRARY_MESSAGE)
            return
        }
        
        //verify Photo Library authorization and proceed accordingly:
        PHPhotoLibrary.verifyAuthorization(authorizedHandler: {
            
            self.showImagePicker(forSourceType: .photoLibrary, mediaTypes: [mediaType], withPresenter: presenter)
            
        }, notAuthorizedHandler: {
            
            UIAlertController.alertUser(withPresenter: presenter, title: COPY_TITLE_ALERT, message: COPY_DENIED_PHOTO_LIBRARY_ACCESS_MESSAGE, okButton: true, settingsButton: true)
        })
        
        self.imageCompletionHandler = completion
    }
    
    //MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        picker.presentingViewController?.dismiss(animated: true) {
            
            if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
                print("got edited image")
                self.imageCompletionHandler?(editedImage)
            }
            else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                print("got original image")
                self.imageCompletionHandler?(originalImage)
            }
            else if let editedVideoURL = info[UIImagePickerControllerMediaURL] as? URL {
                print("got video file url")
                self.videoCompletionHandler?(editedVideoURL)
            }
            else if let originalVideoURL = info[UIImagePickerControllerReferenceURL] as? URL {
                print("got original video file assets url")
                self.videoCompletionHandler?(originalVideoURL)
            }
        }
    }
    
    //MARK: Utilities:
    
    private func showImagePicker(forSourceType sourceType: UIImagePickerControllerSourceType, mediaTypes: [String], withPresenter presenter: UIViewController)
    {
        self.pickerController.sourceType = sourceType
        self.pickerController.mediaTypes = mediaTypes
        self.pickerController.allowsEditing = true
        self.pickerController.delegate = self
        
        //check for max video duration:
        if let maxDuration = self.maxVideoDuration {
            self.pickerController.videoMaximumDuration = maxDuration
        }
        
        presenter.present(self.pickerController, animated: true, completion: nil)
    }
}

extension PHPhotoLibrary
{
    /**
     * Upon first authorization request, if user denies permission we do not call notAuthorizedHandler.
     * Since they just denied, nothing will happen and this seems appropriate/ expected.
     * every time after, the notAuthorizedHandler will be called if authorization is denied or restricted:
     */
    class func verifyAuthorization(authorizedHandler: @escaping () -> Void, notAuthorizedHandler: @escaping () -> Void)
    {
        switch PHPhotoLibrary.authorizationStatus() {
        
        case .authorized:
            DispatchQueue.main.async {
                authorizedHandler()
            }
        
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { authorizationStatus in
                
                guard authorizationStatus == .authorized else {
                    
                    //do nothing first time denied:
                    return
                }
                
                DispatchQueue.main.async {
                    authorizedHandler()
                }
            }
            
        default:
            DispatchQueue.main.async {
                notAuthorizedHandler()
            }
        }
    }
}

extension AVCaptureDevice
{
    /**
     * Upon first authorization request, if user denies permission we do not call notAuthorizedHandler.
     * Since they just denied, nothing will happen and this seems appropriate/ expected.
     * every time after, the notAuthorizedHandler will be called if authorization is denied or restricted:
     */
    class func verifyVideoAndAudioAuthorization(authorizedHandler: @escaping () -> Void, notAuthorizedHandler: @escaping () -> Void)
    {
        //first verify camera authorization:
        //only proceed to audio verification if we have camera authorized:
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        
        case .authorized:
            
            //granted, now check for microphone authorization:
            AVCaptureDevice.verifyAudioAuthorization(authorizedHandler: authorizedHandler, notAuthorizedHandler: notAuthorizedHandler)
        
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                
                guard granted == true else {
                    
                    //do nothing first time denied:
                    return
                }
                
                //granted, now check for microphone authorization:
                AVCaptureDevice.verifyAudioAuthorization(authorizedHandler: authorizedHandler, notAuthorizedHandler: notAuthorizedHandler)
            }
        
        default:
            DispatchQueue.main.async {
                notAuthorizedHandler()
            }
        }
    }
    
    /**
     * Upon first authorization request, if user denies permission we do not call notAuthorizedHandler.
     * Since they just denied, nothing will happen and this seems appropriate/ expected.
     * every time after, the notAuthorizedHandler will be called if authorization is denied or restricted:
     */
    class func verifyVideoAuthorization(authorizedHandler: @escaping () -> Void, notAuthorizedHandler: @escaping () -> Void)
    {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
            
        case .authorized:
            DispatchQueue.main.async {
                authorizedHandler()
            }
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                
                guard granted == true else {
                    
                    //do nothing first time denied:
                    return
                }
                
                DispatchQueue.main.async {
                    authorizedHandler()
                }
            }
            
        default:
            DispatchQueue.main.async {
                notAuthorizedHandler()
            }
        }
    }
    
    /**
     * Upon first authorization request, if user denies permission we do not call notAuthorizedHandler.
     * Since they just denied, nothing will happen and this seems appropriate/ expected.
     * every time after, the notAuthorizedHandler will be called if authorization is denied or restricted:
     */
    private class func verifyAudioAuthorization(authorizedHandler: @escaping () -> Void, notAuthorizedHandler: @escaping () -> Void)
    {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) {
            
        case .authorized:
            authorizedHandler()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio) { granted in
                
                guard granted == true else {
                    
                    //do nothing first time denied:
                    return
                }
                authorizedHandler()
            }
            
        default:
            notAuthorizedHandler()
        }
    }
}

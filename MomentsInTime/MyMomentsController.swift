//
//  MyMomentsController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import RealmSwift
import AVKit
import AVFoundation

private let COPY_TITLE_MOMENT_DETAIL = "Moment"
private let COPY_TITLE_UPLOAD_FAILED = "Oh No!"
private let COPY_MESSAGE_UPLOAD_FAILED = "Something went wrong during the upload. Please try again and make sure the app is running and connected until the upload completes."

private let COPY_TITLE_DELETE_UPLOADING_ALERT = "Oh No!"
private let COPY_MESSAGE_DELETE_UPLOADING_ALERT = "Sorry, but you'll need to wait until the upload is finished to modify this Moment."

private let COPY_TITLE_ALREADY_UPLOADING = "Oh No!"
private let COPY_MESSAGE_ALREADY_UPLOADING = "Sorry, but you'll need to wait until the current upload is finished before uploading another Moment."

typealias NewMomentCompletion = (Moment, _ justCreated: Bool, _ shouldUpload: Bool) -> Void

class MyMomentsController: UIViewController, MITMomentCollectionViewAdapterMomentDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    lazy var momentList = MomentList()
    
    private var emptyStateView: MITTextActionView = {
        let view = MITTextActionView.mitEmptyStateView()
        view.actionButton.addTarget(self, action: #selector(handleNewMoment), for: .touchUpInside)
        return view
    }()
    
    private lazy var adapter: MITMomentCollectionViewAdapter = {
        let adapter = MITMomentCollectionViewAdapter(withCollectionView: self.collectionView,
                                                     moments: self.momentList.moments,
                                                     emptyStateView: self.emptyStateView,
                                                     bannerView: nil)
        adapter.momentDelegate = self
        return adapter
    }()
    
    private enum Identifiers
    {
        static let IDENTIFIER_SEGUE_NEW_MOMENT = "NewMoment"
        static let IDENTIFIER_SEGUE_PLAYER = "myMomentsToPlayer"
    }
    
    private let vimeoConnector = VimeoConnector()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.listenForNotifications(true)
        self.setupCollectionView()
        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //need this in case we rotate, switch tabs, then rotate back...
        //when we come back to this screen, the layout will be where we left it
        //even though viewWilTransition: gets called on all VCs in the tab bar controller,
        //when we come back on screen the collectinView width is no longer valid.
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if self.collectionView != nil {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard let id = segue.identifier else { return }
        
        switch id {
            
        case Identifiers.IDENTIFIER_SEGUE_NEW_MOMENT:
            if let newMomentController = segue.destination.contentViewController as? NewMomentController {
                
                newMomentController.completion = { moment, justCreated, shouldSubmit in
                    self.handleNewMomentCompletion(withMoment: moment, justCreated: justCreated, shouldSubmit: shouldSubmit)
                }
                
                //pass along moment if we have one:
                if let selectedMoment = sender as? Moment {
                    newMomentController.moment = selectedMoment
                    newMomentController.title = COPY_TITLE_MOMENT_DETAIL
                }
            }
            
        case Identifiers.IDENTIFIER_SEGUE_PLAYER:
            if let playerController = segue.destination.contentViewController as? AVPlayerViewController, let videoURL = sender as? URL {
                playerController.player = AVPlayer(url: videoURL)
                playerController.player?.play()
            }
            
        default:
            break
        }
    }
    
    deinit
    {
        self.listenForNotifications(false)
    }
    
    //MARK: Actions
    
    @objc private func handleNewMoment()
    {
        self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_NEW_MOMENT, sender: nil)
    }
    
    @IBAction func handleCreateMoment(_ sender: BouncingButton)
    {
        self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_NEW_MOMENT, sender: nil)
        
        //for debugging (delete all the moments then tap create button and make sure realm is empty):
        if let realm = try? Realm() {
            if realm.isEmpty {
                print("\nrealm is empty")
            }
            else {
                print("\nrealm is NOT empty")
            }
        }
    }
    
    //MARK: MITMomentCollectionViewAdapterMomentDelegate
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handleShareForMoment moment: Moment, sender: UIButton)
    {
        let shareSheet = ShareAlertSheet()
        shareSheet.showFrom(viewController: self, sender: sender, moment: moment)
    }
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handlePlayForMoment moment: Moment, sender: UIButton)
    {
        guard let video = moment.video else { return }
        
        if moment.momentStatus == .live {
            video.fetchPlaybackURL { (urlString, error) in
                
                guard error == nil else { return }
                
                if let videoURLString = urlString, let videoURL = URL(string: videoURLString) {
                    self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_PLAYER, sender: videoURL)
                    return
                }
            }
            return
        }
        
        //for local videos:
        if video.localURL != nil {
            if let localVideoURL = video.localPlaybackURL {
                self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_PLAYER, sender: localVideoURL)
            }
        }
    }
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handleOptionsForMoment moment: Moment, sender: UIButton)
    {
        UIAlertController.showDeleteSheet(withPresenter: self, sender: sender, title: nil, itemToDeleteTitle: "Moment") { action in
            DispatchQueue.main.async {
                self.handleDelete(forMoment: moment)
            }
        }
    }
    
    func didSelectMoment(_ moment: Moment)
    {
        self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_NEW_MOMENT, sender: moment)
    }
    
    //MARK: CollectionView
    
    private func setupCollectionView()
    {
        if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumLineSpacing = 0
            flowLayout.sectionInset = .zero
        }
        
        self.collectionView.contentInset.top = 12
    }
    
    //MARK: Utilities
    
    private func handleDelete(forMoment moment: Moment)
    {
        //no deleting while a moment is uploading... strange and unwanted things will ensue:
        guard moment.momentStatus != .uploading else {
            UIAlertController.explain(withPresenter: self, title: COPY_TITLE_DELETE_UPLOADING_ALERT, message: COPY_MESSAGE_DELETE_UPLOADING_ALERT)
            return
        }
        
        self.adapter.removeMoment(moment)
        moment.delete()
    }
    
    private func handleNewMomentCompletion(withMoment moment: Moment, justCreated: Bool, shouldSubmit: Bool)
    {
        if justCreated {
            self.adapter.insertNewMoment(moment)
        }
        
        if shouldSubmit {
            self.handleSubmit(forMoment: moment) {
                self.adapter.refreshMoment(moment)
            }
        }
        else {
            self.adapter.refreshMoment(moment)
        }
    }
    
    private func handleSubmit(forMoment moment: Moment, completion: @escaping () -> Void)
    {
        self.vimeoConnector.checkForPendingUploads { alreadyUploading in
            DispatchQueue.main.async {
                
                guard !alreadyUploading else {
                    UIAlertController.explain(withPresenter: self, title: COPY_TITLE_ALREADY_UPLOADING, message: COPY_MESSAGE_ALREADY_UPLOADING)
                    return
                }
                
                moment.upload { (_, error) in
                    
                    if error != nil {
                        
                        //inform the user that the upload failed,
                        //the moment's status is already set to .uploadFailed:
                        UIAlertController.explain(withPresenter: self, title: COPY_TITLE_UPLOAD_FAILED, message: COPY_MESSAGE_UPLOAD_FAILED)
                    }
                    
                    self.adapter.refreshMoment(moment)
                }
                
                completion()
            }
        }
    }
    
    @objc private func refresh()
    {
        self.adapter.moments = self.momentList.getLocalMoments()
        self.adapter.refreshData(shouldReload: true)
        
        //verification temporary?
        self.verifyMoments {
            print("verification complete")
        }
    }
    
    private func verifyMoments(completion: (() -> Void)?)
    {
        self.vimeoConnector.checkForPendingUploads { uploadIsInProgress in
            
            print("upload is in progeress: \(uploadIsInProgress)")
            
            for moment in self.momentList.moments {
                
                switch moment.momentStatus {
                    
                case .uploading:
                    if moment.video?.uri != nil {
                        print("video has uri, changing status from uploading to live")
                        moment.handleSuccessUpload()
                        self.verifyMetadata(forMoment: moment)
                    }
                    else if uploadIsInProgress == false {
                        print("moment is uploading but no upload is going on so changing status to uploadFailed: \(moment)")
                        moment.handleFailedUpload()
                    }
                    
                case .live:
                    self.verifyMetadata(forMoment: moment)
                    
                default:
                    if moment.video?.uri != nil {
                        print("video has uri, changing status from uploadFailed to live")
                        moment.handleSuccessUpload()
                        self.verifyMetadata(forMoment: moment)
                    }
                    print("status was new or local or uploadFailed")
                }
                
                self.adapter.refreshMoment(moment)
            }
            
            //completion after inspecting all the moments:
            completion?()
        }
    }
    
    private func verifyMetadata(forMoment moment: Moment)
    {
        guard let video = moment.video, video.uri != nil, !video.liveVerified else {
            if let video = moment.video, video.liveVerified { print("\nvideo has already been verified") }
            return
        }
        
        self.vimeoConnector.getRemoteVideo(video) { (fetchedVideo, error) in
            
            if let newVideo = fetchedVideo {
                
                //add link and playback url:
                Moment.writeToRealm {
                    moment.video?.videoLink = newVideo.videoLink
                    moment.video?.playbackURL = newVideo.playbackURL
                }
                
                //if we got a playback url, remove the local video:
                if moment.video?.playbackURL != nil, let relativeLocalURL = moment.video?.localURL {
                    print("\nwe have a playback url, so removing local video from disk")
                    Assistant.removeVideoFromDisk(atRelativeURLString: relativeLocalURL) { success in
                        if success {
                            Moment.writeToRealm {
                                moment.video?.localURL = nil
                                moment.video?.liveVerified = true
                            }
                        }
                    }
                }
                
                //check for metadata and add if necessary:
                if newVideo.name == nil
                    || newVideo.name == "Untitled"
                    || newVideo.name == "untitled"
                    || newVideo.videoDescription == nil {
                    
                    print("\nadding metadata in verify moments")
                    
                    BackgroundUploadVideoMetadataSessionManager.shared.sendMetadata(moment: moment) { (moment, error) in
                        DispatchQueue.main.async {
                            
                            guard error == nil else {
                                print(error!)
                                Moment.writeToRealm {
                                    moment?.video?.liveVerified = false
                                }
                                return
                            }
                            
                            //mark the video as verified so we don't check next time:
                            Moment.writeToRealm {
                                moment?.video?.liveVerified = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc private func handleVideoUploaded(notification: Notification)
    {
        if let moment = notification.object as? Moment {
            self.adapter.refreshMoment(moment)
        }
    }
    
    private func listenForNotifications(_ shouldListen: Bool)
    {
        if shouldListen {
            NotificationCenter.default.addObserver(self, selector: #selector(handleVideoUploaded(notification:)), name: Notification.Name(rawValue: NOTIFICATION_VIDEO_UPLOADED), object: nil)
        } else {
            NotificationCenter.default.removeObserver(self)
        }
    }
}


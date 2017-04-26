//
//  CommunityController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout
import AVKit
import AVFoundation
import FacebookCore
import FacebookLogin
import FacebookShare

private let FREQUENCY_ACCESSORY_VIEW = 2
private let IDENTIFIER_SEGUE_PLAYER = "communityToPlayer"

private let COPY_MESSAGE_INVITE_INTERVIEW = "Hello, I would like to interview you on the Moments In Time app!"

class CommunityController: UIViewController, MITVideoCollectionViewAdapterDelegate, MITVideoCollectionViewAdapterVideoDelegate, MITVideoCollectionViewAdapterInfiniteScrollDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    lazy var videoList = VideoList()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    private var emptyStateView: MITTextActionView = {
        let view = MITTextActionView.mitEmptyStateView()
        view.actionButton.addTarget(self, action: #selector(handleNewMoment), for: .touchUpInside)
        return view
    }()
    
    private lazy var adapter: MITVideoCollectionViewAdapter = {
        let adapter = MITVideoCollectionViewAdapter(withCollectionView: self.collectionView,
                                                   videos: self.videoList.videos,
                                                   emptyStateView: self.emptyStateView,
                                                   bannerView: nil)
        adapter.allowsEmptyStateScrolling = true
        adapter.accessoryViewdelegate = self
        adapter.videoDelegate = self
        adapter.infiniteScrollDelegate = self
        adapter.allowsInfiniteScrolling = true
        return adapter
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.spinner.startAnimating()
        self.setupCollectionView()
        self.fetchCommunityVideos()
        
        self.checkForUser {
            print("We have a user!")
        }
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
    
    //MARK: Trait Collection layout:
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if self.collectionView != nil {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    //for IDENTIFIER_SEGUE_PLAYER, sender will be the videoURL to pass to AVPlayer:
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == IDENTIFIER_SEGUE_PLAYER && sender is URL {
            
            if let playerController = segue.destination.contentViewController as? AVPlayerViewController, let videoURL = sender as? URL {
                playerController.player = AVPlayer(url: videoURL)
                playerController.player?.play()
            }
        }
    }
    
    //MARK: Actions
    
    @objc private func handleNewMoment()
    {
        print("handle new moment")
    }
    
    @objc private func handleAskToInterview(_ sender: BouncingButton)
    {
        //Display AlertActionSheet for user to choose Facebook or iMessage,
        //must be popover for iPad:
        let controller = UIAlertController(title: "Ask To Interview", message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        let facebookAction = UIAlertAction(title: "Ask on Facebook", style: .default) { action in
            self.handleFacebookInvite()
        }
        controller.addAction(facebookAction)
        
        let messageAction = UIAlertAction(title: "Message...", style: .default) { action in
            self.handleMessageInvite(sender: sender)
        }
        controller.addAction(messageAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        self.present(controller, animated: true, completion: nil)
    }
    
    private func handleFacebookInvite()
    {
        print("handle facebook invite")
        
        //this is a bunch of test code:
        
        FacebookConnector().getTaggableFriends()
        //FacebookConnector().lauchAppInvite(withPresenter: self)
    }
    
    private func handleMessageInvite(sender: UIView)
    {
        //present UIActivityViewController,
        //must be popover for iPad:
        let message = COPY_MESSAGE_INVITE_INTERVIEW
        let link = URL(string: "https://marvelapp.com/fj8ic86/screen/26066627")! //just a test appLink for angry birds...
        
        let controller = UIActivityViewController(activityItems: [message, link], applicationActivities: nil)
        
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        self.present(controller, animated: true, completion: nil)
    }
    
    //MARK: MITVideoCollectionViewAdapterDelegate
    
    func accessoryViewFrequency(forAdaptor adapter: MITVideoCollectionViewAdapter) -> Int
    {
        return 7
    }
    
    func accessoryView(for adapter: MITVideoCollectionViewAdapter) -> UIView
    {
        let textActionView = MITTextActionView.mitAskToInterviewView()
        textActionView.actionButton.addTarget(self, action: #selector(handleAskToInterview), for: .touchUpInside)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textActionView)
        textActionView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0))
        
        return containerView
    }
    
    //MARK: MITVideoCollectionViewAdapterVideoDelegate
    
    func adapter(adapter: MITVideoCollectionViewAdapter, handlePlayForVideo video: Video)
    {
        video.fetchPlaybackURL { (urlString, error) in
            
            guard error == nil else {
                return
            }
            
            if let videoURLString = urlString, let videoURL = URL(string: videoURLString) {
                self.performSegue(withIdentifier: IDENTIFIER_SEGUE_PLAYER, sender: videoURL)
            }
        }
    }
    
    func adapter(adapter: MITVideoCollectionViewAdapter, handleShareForVideo video: Video)
    {
        print("HANDLE SHARE")
        
        if let appLinkURL = URL(string: "https://fb.me/1717667415199470") {
            
            var linkContent = LinkShareContent(url: appLinkURL)
            linkContent.taggedPeopleIds = ["AaL-AjaBzLgY9ZaI4rFzFHSExDOGyCieObP774k83t32sO3Fn-Hyvlk57dFukM9r_S20crRA4Rycw6euIzANw_ReAFrRg40zQhR6KkEYjcfrFg"]
            
            let dialog = ShareDialog(content: linkContent)
            dialog.mode = .automatic
            
            dialog.completion = { result in
                switch result {
                case .success: print("\n\nsuccessful share\n")
                case .cancelled: print("\n\ncancelled share\n")
                case .failed(let error): print("\n\nError sharing: \(error)\n")
                }
            }
            
            do {
                try dialog.show()
            }
            catch let error {
                print(error)
            }
        }
    }
    
    //MARK: MITVideoCollectionViewAdapterInfiniteScrollDelegate
    
    func fetchNewVideos(for adapter: MITVideoCollectionViewAdapter, completion: @escaping () -> Void)
    {
        self.videoList.fetchNextCommunityVideos { (_, videos, error) in
            
            if let error = error {
                print(error)
            }
            
            if let newVideos = videos {
                self.adapter.videos += newVideos
            }
            
            self.adapter.allowsInfiniteScrolling = self.videoList.hasNextPage
            completion()
        }
    }
    
    // MARK: Refresh
    
    @objc private func refresh()
    {
        self.fetchCommunityVideos()
    }
    
    private func fetchCommunityVideos()
    {
        self.videoList.fetchCommunityVideos { list, error in
            
            self.refreshControl.endRefreshing()
            
            if let error = error {
                print(error)
            }
            
            self.spinner.stopAnimating()
            self.adapter.videos = self.videoList.videos
            self.adapter.allowsInfiniteScrolling = true
        }
    }
    
    //MARK: Utilities
    
    private func checkForUser(completion: @escaping () -> Void)
    {
        guard AccessToken.current != nil else {
            
            if let loginController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginController") as?LoginController {
                
                loginController.loginCompletionHandler = {
                    loginController.presentingViewController?.dismiss(animated: true) {
                        completion()
                    }
                }
                
                self.present(loginController, animated: true, completion: nil)
            }
            
            return
        }
        
        /**
         * LoginController will only call completion upon successful login, so at this point,
         * we are all set with a current user (AccessToken.current is no longer nil...)
         */
        completion()
    }
    
    private func setupCollectionView()
    {
        if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumLineSpacing = 0
            flowLayout.sectionInset = .zero
        }
        
        self.collectionView.contentInset.top = 12
        self.collectionView?.addSubview(self.refreshControl)
    }
}

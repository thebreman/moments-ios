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

private let KEY_ACCEPTED_TERMS_OF_SERVICE = "didAcceptTermsOfService"
private let IDENTIFIER_STORYBOARD_TERMS_NAV_CONTROLLER = "TermsOfServiceStoryboardID"

private let REQUIRE_FB_LOGIN_ON_LAUNCH = false 
private let OPTIONS_ALLOWS_SHARE = false

private let FREQUENCY_ACCESSORY_VIEW = 2
private let IDENTIFIER_SEGUE_PLAYER = "communityToPlayer"

class CommunityController: UIViewController, MITMomentCollectionViewAdapterDelegate, MITMomentCollectionViewAdapterMomentDelegate, MITMomentCollectionViewAdapterInfiniteScrollDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    lazy var momentList = MomentList()
    
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
    
    private lazy var adapter: MITMomentCollectionViewAdapter = {
        let adapter = MITMomentCollectionViewAdapter(withCollectionView: self.collectionView,
                                                   moments: self.momentList.moments,
                                                   emptyStateView: UIView(frame: .zero),
                                                   bannerView: nil)
        adapter.allowsEmptyStateScrolling = true
        adapter.accessoryViewDelegate = self
        adapter.momentDelegate = self
        adapter.infiniteScrollDelegate = self
        adapter.allowsInfiniteScrolling = true
        return adapter
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.spinner.startAnimating()
        self.setupCollectionView()
        self.fetchCommunityMoments()
        
        //on first launch display modal terms of service:
        self.handleTermsOfService {
            
            //successful terms agreement, so indicate in UserDefaults:
            UserDefaults.standard.set(true, forKey: KEY_ACCEPTED_TERMS_OF_SERVICE)
            
            //check FB login:
            if REQUIRE_FB_LOGIN_ON_LAUNCH {
                self.checkForUser {
                    print("We have a user!")
                }
            }
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
        let interviewInviteSheet = InterviewInviteAlertSheet()
        interviewInviteSheet.showFrom(viewController: self, sender: sender)
    }
    
    //need to retain this for MFMailComposeViewController delegation:
    private let ratingsAlert = HowAreWeDoingAlertView()

    @IBAction func starOfDavidTapped(_ sender: UIButton)
    {
        self.ratingsAlert.showFrom(viewController: self)
    }
    
//MARK: MITMomentCollectionViewAdapterDelegate
    
    func accessoryViewFrequency(forAdaptor adapter: MITMomentCollectionViewAdapter) -> Int
    {
        return 7
    }
    
    func accessoryView(for adapter: MITMomentCollectionViewAdapter) -> UIView
    {
        let textActionView = MITTextActionView.mitAskToInterviewView()
        textActionView.actionButton.addTarget(self, action: #selector(handleAskToInterview), for: .touchUpInside)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textActionView)
        textActionView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0))
        
        return containerView
    }
    
    //MARK: MITMomentCollectionViewAdapterMomentDelegate
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handlePlayForMoment moment: Moment, sender: UIButton)
    {
        self.playVideo(forMoment: moment)
    }
    
    func didSelectMoment(_ moment: Moment)
    {
        self.playVideo(forMoment: moment)
    }
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handleShareForMoment moment: Moment, sender: UIButton)
    {
        let shareSheet = ShareAlertSheet()
        shareSheet.showFrom(viewController: self, sender: sender, moment: moment)
    }
    
    //need to retain this for MFMailComposeViewController delegation:
    private let optionsSheet = CommunityMomentOptionsAlertSheet()

    func adapter(adapter: MITMomentCollectionViewAdapter, handleOptionsForMoment moment: Moment, sender: UIButton)
    {
        self.optionsSheet.allowsSharing = OPTIONS_ALLOWS_SHARE
        self.optionsSheet.showFrom(viewController: self, sender: sender, forMoment: moment)
    }
    
    //MARK: MITMomentCollectionViewAdapterInfiniteScrollDelegate
    
    func fetchNewMoments(for adapter: MITMomentCollectionViewAdapter, completion: @escaping () -> Void)
    {
        self.momentList.fetchNextCommunityMoments { (_, moments, error) in
            
            if let error = error {
                print(error)
            }
            
            if let newMoments = moments {
                self.adapter.moments += newMoments
                self.adapter.refreshData(shouldReload: true)
            }
            
            self.adapter.allowsInfiniteScrolling = self.momentList.hasNextPage
            completion()
        }
    }
    
    // MARK: Refresh
    
    @objc private func refresh()
    {
        self.fetchCommunityMoments()
    }
    
    private func fetchCommunityMoments()
    {
        self.momentList.fetchCommunityMoments { list, error in
            
            self.refreshControl.endRefreshing()
            
            if let error = error {
                print(error)
            }
            
            self.spinner.stopAnimating()
            self.adapter.moments = self.momentList.moments
            self.adapter.refreshData(shouldReload: true)
            self.adapter.allowsInfiniteScrolling = self.momentList.hasNextPage
        }
    }
    
    //MARK: Utilities
    
    private func playVideo(forMoment moment: Moment)
    {
        guard let video = moment.video else { return }
        
        video.fetchPlaybackURL { (urlString, error) in
            
            guard error == nil else { return }
            
            if let videoURLString = urlString, let videoURL = URL(string: videoURLString) {
                self.performSegue(withIdentifier: IDENTIFIER_SEGUE_PLAYER, sender: videoURL)
            }
        }
    }
    
    private func checkForUser(completion: @escaping () -> Void)
    {
        guard AccessToken.current != nil else {
            
            if let loginController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginController") as? LoginController {
                
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
    
    private func handleTermsOfService(completion: TermsOfServiceSuccessCompletion? = nil)
    {
        let didAcceptTermsOfService: Bool = UserDefaults.standard.bool(forKey: KEY_ACCEPTED_TERMS_OF_SERVICE)
        
        if !didAcceptTermsOfService {
            self.showTermsOfService(completion: completion)
        }
        else {
            completion?()
        }
    }
    
    private func showTermsOfService(completion: TermsOfServiceSuccessCompletion? = nil)
    {
        if let termsNavController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: IDENTIFIER_STORYBOARD_TERMS_NAV_CONTROLLER) as? UINavigationController,
            let termsOfServiceController = termsNavController.viewControllers.first as? TermsOfServiceController {
            
            termsOfServiceController.successCompletionHandler = completion
            
            self.tabBarController?.present(termsNavController, animated: true, completion: nil)
        }
    }
}

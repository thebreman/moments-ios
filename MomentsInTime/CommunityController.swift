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

private let KEY_ACCEPTED_TERMS_OF_SERVICE = "didAcceptTermsOfService"
private let IDENTIFIER_STORYBOARD_TERMS_NAV_CONTROLLER = "TermsOfServiceStoryboardID"

private let KEY_CLOSED_WELCOME_HEADER = "didCloseWelcomeHeader"

private let OPTIONS_ALLOWS_SHARE = false

private let FREQUENCY_ACCESSORY_VIEW = 5
private let IDENTIFIER_SEGUE_PLAYER = "communityToPlayer"
private let INDEX_TAB_MY_MOMENTS = 1

private let HEIGHT_ACCESSORY_VIEW: CGFloat = 108

class CommunityController: UIViewController, MITMomentCollectionViewAdapterDelegate, MITMomentCollectionViewAdapterMomentDelegate, MITMomentCollectionViewAdapterInfiniteScrollDelegate, MITHeaderViewDelegate, CommunityOptionsDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    //if we are displaying search results, we will have a name and flag will be set to true...
    var searchName: String?
    var isDisplayingSearchResults = false
    
    lazy var momentList = MomentList()
    
    private lazy var refreshControl: UIRefreshControl? = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    private lazy var welcomeView: WelcomeHeaderView = {
        let welcomeHeaderView = WelcomeHeaderView()
        welcomeHeaderView.delegate = self
        return welcomeHeaderView
    }()
    
    private var emptyStateView: MITTextActionView = {
        let view = MITTextActionView.communityEmptyStateView()
        view.actionButton.addTarget(self, action: #selector(handleNewMoment), for: .touchUpInside)
        view.autoSetDimension(.width, toSize: 320.0)
        return view
    }()
    
    private lazy var adapter: MITMomentCollectionViewAdapter = {
        let adapter = MITMomentCollectionViewAdapter(withCollectionView: self.collectionView,
                                                   moments: self.momentList.moments,
                                                   emptyStateView: self.emptyStateView,
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
        
        self.verifyWelcomeHeader()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //need this in case we rotate, switch tabs, then rotate back...
        //when we come back to this screen, the layout will be where we left it
        //even though viewWilTransition: gets called on all VCs in the tab bar controller,
        //when we come back on screen the collectinView width is no longer valid.
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        //update navBar:
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.mitText
        ]
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
            self.navigationItem.largeTitleDisplayMode = self.isDisplayingSearchResults ? .never : .always
            
            self.navigationController?.navigationBar.largeTitleTextAttributes = [
                NSAttributedStringKey.foregroundColor: UIColor.mitText
            ]
        }
    }
    
    private var didVerifyTerms = false
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(true)
        
        if !didVerifyTerms {
            self.verifyTermsOfService()
            self.didVerifyTerms = true
        }
    }
    
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
    
    @objc private func handleNewMoment(_ sender: BouncingButton)
    {
        // switch tabs
        self.tabBarController?.selectedIndex = INDEX_TAB_MY_MOMENTS
        
        // tell the My Moments controller to start a new one
        if  let myMomentsNavigation = self.tabBarController?.selectedViewController as? UINavigationController,
            let myMomentsController = myMomentsNavigation.topViewController as? MyMomentsController {
            wait(seconds: 0.4) {
                myMomentsController.createNewMomentAnimated()
            }
        }
    }
    
    //need to retain this for MFMailComposeViewController delegation:
    private let ratingsAlert = HowAreWeDoingAlertView()

    @IBAction func starOfDavidTapped(_ sender: UIButton)
    {
        self.ratingsAlert.showFrom(viewController: self)
    }
    
//MARK: WelcomeHeaderViewDelegate
    
    //For both cases we will just close the header so user can browse through Community Moments:
    
    func handleAction(forHeaderView headerView: MITHeaderView, sender: UIButton)
    {
        self.closeWelcomeHeaderView()
    }
    
    func handleClose(forHeaderView headerView: MITHeaderView)
    {
        self.closeWelcomeHeaderView()
    }
    
//MARK: MITMomentCollectionViewAdapterDelegate
    
    func accessoryViewFrequency(forAdaptor adapter: MITMomentCollectionViewAdapter) -> Int
    {
        return FREQUENCY_ACCESSORY_VIEW
    }
    
    func accessoryView(for adapter: MITMomentCollectionViewAdapter) -> UIView
    {
        let textActionView = MITTextActionView.mitAskToInterviewView()
        textActionView.actionButton.addTarget(self, action: #selector(handleNewMoment), for: .touchUpInside)
        textActionView.heightAnchor.constraint(greaterThanOrEqualToConstant: HEIGHT_ACCESSORY_VIEW).isActive = true
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textActionView)
        textActionView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0))
        
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
        self.optionsSheet.delegate = self
        self.optionsSheet.allowsSharing = OPTIONS_ALLOWS_SHARE
        self.optionsSheet.allowsRelatedVideos = !self.isDisplayingSearchResults
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
    
//MARK: CommunityOptionsDelegate
    
    func communityOptionsSelectedMoreUserVideos(name: String)
    {
        print("\nname to search: \(name)")
        
        let communityController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CommunityController") as! CommunityController
        communityController.title = name
        communityController.searchName = name
        communityController.isDisplayingSearchResults = true
        communityController.refreshControl = nil
        
        self.navigationController!.pushViewController(communityController, animated: true)
    }

// MARK: Refresh
    
    @objc private func refresh()
    {
        self.fetchCommunityMoments()
    }
    
    //TODO: might need to factor out some of this code:
    private func fetchCommunityMoments()
    {
        //check if we are displaying video results or all community videos:
        if self.isDisplayingSearchResults {
            
            guard let nameToSearch = self.searchName else { return }
            
            //get just the search result list:
            self.momentList.fetchCommunityMoments(forUsername: nameToSearch) { (list, error) in
                
                if let error = error {
                    print(error)
                }
                
                self.spinner.stopAnimating()
                self.adapter.moments = self.momentList.moments
                self.adapter.refreshData(shouldReload: true)
                self.adapter.allowsInfiniteScrolling = self.momentList.hasNextPage
            }
        }
        else {
            
            //get the all community list:
            self.momentList.fetchCommunityMoments { list, error in
                
                self.refreshControl?.endRefreshing()
                
                if let error = error {
                    print(error)
                }
                
                self.spinner.stopAnimating()
                self.adapter.moments = self.momentList.moments
                self.adapter.refreshData(shouldReload: true)
                self.adapter.allowsInfiniteScrolling = self.momentList.hasNextPage
            }
        }
    }
    
//MARK: Utilities
    
    private func verifyTermsOfService()
    {
        //on first launch display modal terms of service:
        self.handleTermsOfService {
            
            //successful terms agreement, so indicate in UserDefaults:
            UserDefaults.standard.set(true, forKey: KEY_ACCEPTED_TERMS_OF_SERVICE)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func verifyWelcomeHeader()
    {
        //add welcome header view if user has not already closed it:
        if UserDefaults.standard.bool(forKey: KEY_CLOSED_WELCOME_HEADER) == false {
            self.adapter.bannerView = self.welcomeView
            self.adapter.refreshData(shouldReload: true)
        }
    }
    
    private func closeWelcomeHeaderView()
    {
        self.adapter.closeBannerView()
        UserDefaults.standard.set(true, forKey: KEY_CLOSED_WELCOME_HEADER)
    }
    
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
    
    private func setupCollectionView()
    {
        if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumLineSpacing = 0
            flowLayout.sectionInset = .zero
        }
        
        self.collectionView.contentInset.top = 12
        
        if let pullToRefresh = self.refreshControl {
            self.collectionView.refreshControl = pullToRefresh
        }
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
            
            //need to ensure that we wait until next run loop to display in case self is not finished being animated yet:
            DispatchQueue.main.async {
                self.tabBarController?.present(termsNavController, animated: true, completion: nil)
            }
        }
    }
}

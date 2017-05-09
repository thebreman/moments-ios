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

typealias NewMomentCompletion = (Moment, _ justCreated: Bool) -> Void

class MyMomentsController: UIViewController, MITMomentCollectionViewAdapterMomentDelegate
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

    override func viewDidLoad()
    {
        super.viewDidLoad()
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
                
                newMomentController.completion = { moment, justCreated in
                    self.handleNewMomentCompletion(withMoment: moment, justCreated: justCreated)
                }
                
                //pass along moment if we have one:
                if let selectedMoment = sender as? Moment {
                    newMomentController.moment = selectedMoment
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
        print("handle share")
    }
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handlePlayForMoment moment: Moment, sender: UIButton)
    {
        guard let video = moment.video else { return }
        
        //for now just grab the local url:
        if video.isLocal {
            if let localVideoURL = video.localPlaybackURL {
                self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_PLAYER, sender: localVideoURL)
            }
        }
    }
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handleOptionsForMoment moment: Moment, sender: UIButton)
    {
        UIAlertController.showDeleteSheet(withPresenter: self, sender: sender, title: "Moment") { action in
            self.adapter.removeMoment(moment)
            moment.deleteLocally()
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
        
        self.collectionView?.addSubview(self.refreshControl)
        self.collectionView.contentInset.top = 12
    }
    
    //MARK: Utilities
    
    private func handleNewMomentCompletion(withMoment moment: Moment, justCreated: Bool)
    {
        if justCreated {
            self.adapter.insertNewMoment(moment)
        }
        else {
            self.adapter.refreshMoment(moment)
        }
    }
    
    @objc private func refresh()
    {
        self.adapter.moments = self.momentList.getLocalMoments()
        self.adapter.refreshData(shouldReload: true)
        self.refreshControl.endRefreshing()
    }
}

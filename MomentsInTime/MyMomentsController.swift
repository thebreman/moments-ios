//
//  MyMomentsController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import RealmSwift

private let IDENTIFIER_SEGUE_NEW_MOMENT = "NewMoment"
private let IDENTIFIER_SEGUE_PLAYER = "myMomentsToPlayer"

class MyMomentsController: UIViewController, MITVideoCollectionViewAdapterVideoDelegate
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
    
    private lazy var adapter: MITVideoCollectionViewAdapter = {
        let adapter = MITVideoCollectionViewAdapter(withCollectionView: self.collectionView,
                                                    videos: self.momentList.momentVideos,
                                                    emptyStateView: self.emptyStateView,
                                                    bannerView: nil)
        return adapter
    }()

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setupCollectionView()
        
        self.adapter.videoDelegate = self
        
        if let realm = try? Realm() {
            if realm.isEmpty {
                print("Realm is Empty")
            }
            else {
                print("Realm is NOT empty")
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if self.collectionView != nil {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    //MARK: Actions
    
    @objc private func handleNewMoment()
    {
        self.performSegue(withIdentifier: IDENTIFIER_SEGUE_NEW_MOMENT, sender: nil)
    }
    
    //MARK: MITVideoCollectionViewAdapterVideoDelegate
    
    func adapter(adapter: MITVideoCollectionViewAdapter, handleShareForVideo video: Video)
    {
        //
    }
    
    func adapter(adapter: MITVideoCollectionViewAdapter, handlePlayForVideo video: Video)
    {
        //
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
    }
    
    //MARK: Refresh
    
    @objc private func refresh()
    {
        print("refreshing")
        
        wait(seconds: 2) {
            self.refreshControl.endRefreshing()
        }
    }
}

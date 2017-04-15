//
//  MyMomentsController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class MyMomentsController: UIViewController
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    lazy var videoList = VideoList()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    private var emptyStateView: MITEmptyStateView = {
        let view = MITEmptyStateView()
        view.title = "Where are all the moments?"
        view.message = "Even if you're not ready to film, you can create the plans for an interview now."
        view.actionButton.setTitle("Let's make a moment", for: .normal)
        view.actionButton.addTarget(self, action: #selector(handleNewMoment), for: .touchUpInside)
        return view
    }()
    
    private lazy var adapter: MITVideoCollectionViewAdapter = {
        let adapter = MITVideoCollectionViewAdapter(withCollectionView: self.collectionView,
                                                    videos: self.videoList.videos,
                                                    emptyStateView: self.emptyStateView,
                                                    accessoryView: nil)
        return adapter
    }()

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setupCollectionView()
        
        //fetch videos here
        //for now just pass something so that adapter gets instantiated and returns the empty state view:
        self.adapter.videos = self.videoList.videos        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
    
    //MARK: Actions
    
    @objc private func handleNewMoment()
    {
        print("handle new moment")
    }
    
    //MARK: CollectionView
    
    private func setupCollectionView()
    {
        if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumLineSpacing = 0
        }
        
        self.collectionView?.addSubview(self.refreshControl)
    }
    
    //MARK: Refresh
    
    @objc private func refresh()
    {
        print("refreshing")
        
        wait(seconds: 3) {
            self.refreshControl.endRefreshing()
        }
        
        print(self.emptyStateView.frame)
        if let emptyView = self.emptyStateView as? MITEmptyStateView {
            print(emptyView.actionButton.frame)
        }
    }
}

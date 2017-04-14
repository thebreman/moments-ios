//
//  CommunityController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class CommunityController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private struct Constants {
        static let IDENTIFIER_REUSE_VIDEO_CELL = "videoCell"
        static let IDENTIFIER_NIB_VIDEO_CELL = "VideoCell"
    }
    
    lazy var videoList = VideoList()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.spinner.startAnimating()
        
        self.setupCollectionView()
        self.fetchCommunityVideos()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
    
//MARK: CollectionView
    
    private func setupCollectionView()
    {
        if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumLineSpacing = 0
        }
        
        self.collectionView?.register(UINib(nibName: Constants.IDENTIFIER_NIB_VIDEO_CELL, bundle: nil), forCellWithReuseIdentifier: Constants.IDENTIFIER_REUSE_VIDEO_CELL)
        self.collectionView?.addSubview(self.refreshControl)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.videoList.videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.IDENTIFIER_REUSE_VIDEO_CELL, for: indexPath) as? VideoCell {
            cell.video = self.videoList.videos[indexPath.item]
            cell.setNeedsUpdateConstraints()
            return cell
        }
        
        assert(false, "dequeued cell was of an unknown type!")
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let video = self.videoList.videos[indexPath.item]
        
        let size = VideoCell.sizeForVideo(video, width: collectionView.bounds.width)

        return size
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
            self.collectionView?.reloadData()
        }
    }
}

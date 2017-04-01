//
//  CommunityController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class CommunityController: UICollectionViewController, UICollectionViewDelegateFlowLayout
{
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
        self.setupCollectionView()
        self.fetchCommunityVideos()
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
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.videoList.videos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.IDENTIFIER_REUSE_VIDEO_CELL, for: indexPath) as? VideoCell {
            cell.video = self.videoList.videos[indexPath.item]
            cell.setNeedsUpdateConstraints()
            return cell
        }
        
        assert(false, "dequeued cell was of an unknown type!")
        return UICollectionViewCell()
    }
    
    //offscreen cell for height calculation
    private lazy var offscreenCell: VideoCell? = {
        let topLevelObjects = Bundle.main.loadNibNamed(Constants.IDENTIFIER_NIB_VIDEO_CELL, owner: nil, options: nil)
        if let cell = topLevelObjects?[0] as? VideoCell {
            cell.translatesAutoresizingMaskIntoConstraints = false
            return cell
        }
        return nil
    }()
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        if let cell = self.offscreenCell {
            cell.video = self.videoList.videos[indexPath.item]
            cell.bounds = CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: 1000)
            
            cell.updateConstraintsIfNeeded()
            cell.layoutIfNeeded()
            
            let height = cell.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            return CGSize(width: collectionView.bounds.width, height: height)
        }
        
        assert(false, "unable to size offscreen cell")
        return CGSize.zero
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
            
            self.collectionView?.reloadData()
        }
    }
}

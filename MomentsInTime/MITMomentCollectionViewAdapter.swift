//
//  MITMomentCollectionViewAdapter.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/14/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import PureLayout
import RealmSwift

private let SECTION_BANNER_TOP = 0
private let SECTION_MOMENT_FEED = 1
private let SECTION_MOMENT_FETCH = 2

fileprivate let momentCellHeightCache = NSCache<NSString, NSNumber>()

//delegate for optional accessoryView to be displayed every nth cell (n is frequency):
protocol MITMomentCollectionViewAdapterDelegate: class
{
    func accessoryViewFrequency(forAdaptor adapter: MITMomentCollectionViewAdapter) -> Int
    func accessoryView(for adapter: MITMomentCollectionViewAdapter) -> UIView
}

//delegate to pass which moment needs to be played after user taps playButton:
@objc protocol MITMomentCollectionViewAdapterMomentDelegate: class
{
    func adapter(adapter: MITMomentCollectionViewAdapter, handlePlayForMoment moment: Moment, sender: UIButton)
    func adapter(adapter:  MITMomentCollectionViewAdapter, handleShareForMoment moment: Moment, sender: UIButton)
    func adapter(adapter: MITMomentCollectionViewAdapter, handleOptionsForMoment moment: Moment, sender: UIButton)
    @objc optional func didSelectMoment(_ moment: Moment)
}

//delegate for fetch/ infinite scroll provides view to be displayed while fetching and handles fetching more content:
protocol MITMomentCollectionViewAdapterInfiniteScrollDelegate: class
{
    //fetch new moments and call completion w/ those moments:
    func fetchNewMoments(for adapter: MITMomentCollectionViewAdapter, completion: @escaping () -> Void)
}

/**
 * Manages UICollectionViews throughout the app that display MomentCells...
 * The collectionViews are still responsible for loading and refreshing their content (MomentList),
 * but this class manages displaying the [Moment].
 */
class MITMomentCollectionViewAdapter: NSObject, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MomentCellDelegate
{
    var allowsEmptyStateScrolling = false
    var allowsInfiniteScrolling = false
    
    weak var accessoryViewDelegate: MITMomentCollectionViewAdapterDelegate? {
        didSet {
            self.collectionView.register(ContainerCell.self, forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL)
        }
    }
    
    weak var momentDelegate: MITMomentCollectionViewAdapterMomentDelegate?
    
    weak var infiniteScrollDelegate: MITMomentCollectionViewAdapterInfiniteScrollDelegate? {
        didSet {
            self.collectionView.register(UINib(nibName: String(describing: SpinnerCell.self), bundle: nil), forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_SPINNER_CELL)
        }
    }
    
    var moments = [Moment]()
    
    private enum Identifiers
    {
        static let IDENTIFIER_REUSE_MOMENT_CELL = "MomentCell"
        static let IDENTIFIER_REUSE_CONTAINER_CELL = "containerCell"
        static let IDENTIFIER_REUSE_SPINNER_CELL = "spinnerCell"
    }
    
    private var collectionView: UICollectionView!
    
    private var momentsAndAccessoryViews = [Any]()
    
    private var emptyStateView = UIView()
    
    //optional top view that will be contained in a cell in section 0 at the top:
    //good for announcements, ads etc.
    //if it becomes necessary we could allow for an array of these views...
    private var bannerView: UIView?
    
    init(withCollectionView collectionView: UICollectionView, moments: [Moment], emptyStateView: UIView, bannerView: UIView?)
    {
        super.init()
        
        self.collectionView = collectionView
        self.moments = moments
        self.emptyStateView = emptyStateView
        self.bannerView = bannerView
        
        if self.bannerView != nil {
            self.collectionView.register(ContainerCell.self, forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL)
        }
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: String(describing: MomentCell.self), bundle: nil), forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_MOMENT_CELL)
        
        self.collectionView.emptyDataSetDelegate = self
        self.collectionView.emptyDataSetSource = self
    }
    
    func insertNewMoment(_ newMoment: Moment)
    {
        self.moments.insert(newMoment, at: 0)
        self.populateData()
        
        let newPath = IndexPath(item: 0, section: SECTION_MOMENT_FEED)
        
        self.collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: [newPath])
            self.collectionView.reloadEmptyDataSet()
        }, completion: nil)
    }
    
    func refreshMoment(_ moment: Moment)
    {
        //not supporting this right now with accessory views:
        if let indexToRefresh = self.moments.index(of: moment) {
            
            //reset cache height if necessary:
            if momentCellHeightCache.object(forKey: moment.momentID as NSString) != nil {
                momentCellHeightCache.removeObject(forKey: moment.momentID as NSString)
            }
            
            let pathToRefresh = IndexPath(item: indexToRefresh, section: SECTION_MOMENT_FEED)
            
            self.collectionView.performBatchUpdates({
                self.collectionView.reloadItems(at: [pathToRefresh])
            }, completion: nil)
        }
    }
    
    func removeMoment(_ moment: Moment)
    {
        //not supporting this right now with accessory views:
        guard self.accessoryViewDelegate == nil else { return }
        
        if let indexToRemove = self.moments.index(of: moment) {
            self.moments.remove(at: indexToRemove)
            self.populateData()
            
            let pathToRemove = IndexPath(item: indexToRemove, section: SECTION_MOMENT_FEED)
            
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [pathToRemove])
                self.collectionView.reloadEmptyDataSet()

            }, completion: nil)
        }
    }
    
    func refreshData(shouldReload: Bool)
    {
        print("refreshing Data")
        self.populateData()
        
        if shouldReload {
            self.collectionView.reloadData()
        }
    }
    
    //MARK: CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 3 //bannerCell, content, fetchCell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        switch section {
            
        case SECTION_BANNER_TOP:
            let count = self.bannerView != nil ? 1 : 0
            return count
        
        case SECTION_MOMENT_FEED:
            return self.momentsAndAccessoryViews.count
            
        case SECTION_MOMENT_FETCH:
            let count = self.infiniteScrollDelegate != nil && self.allowsInfiniteScrolling ? 1 : 0
            return count
            
        default:
            assert(false, "unknown section in collectionView!")
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        switch indexPath.section {
            
        case SECTION_BANNER_TOP:
            
            if let bannerView = self.bannerView {
                return self.containerCell(forView: bannerView, atIndexPath: indexPath, withCollectionView: collectionView)
            }
            
            return UICollectionViewCell()
            
        case SECTION_MOMENT_FEED:
            
            if let moment = self.momentsAndAccessoryViews[indexPath.item] as? Moment {
                return self.momentCell(forMoment: moment, atIndexPath: indexPath, withCollectionView: collectionView)
            }
            else if let accessoryView = self.momentsAndAccessoryViews[indexPath.item] as? UIView {
                return self.containerCell(forView: accessoryView, atIndexPath: indexPath, withCollectionView: collectionView)
            }
            
            assert(false, "unknown object in dataSource")
            return UICollectionViewCell()
            
        case SECTION_MOMENT_FETCH:
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_SPINNER_CELL, for: indexPath) as? SpinnerCell {
                cell.spinner.startAnimating()
                cell.rasterizeShadow()
                return cell
            }
            
            assert(false, "dequeued cell was of an unknown type!")
            return UICollectionViewCell()
            
        default:
            
            assert(false, "unknown section in collectionView!")
            return UICollectionViewCell()
        }
    }
    
    private var fetching = false
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        if indexPath.section == SECTION_MOMENT_FETCH {
            
            guard !self.fetching else { return }
            
            self.fetching = true
            self.infiniteScrollDelegate?.fetchNewMoments(for: self) {
                self.fetching = false
                if let spinnerCell = cell as? SpinnerCell {
                    spinnerCell.spinner.stopAnimating()
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        switch indexPath.section {
        
        case SECTION_BANNER_TOP:
            
            if let viewToDisplay = self.bannerView {
                let size = ContainerCell.sizeForCell(withWidth: collectionView.bounds.width, containedView: viewToDisplay)
                return size
            }
            
            return .zero
            
        case SECTION_MOMENT_FEED:
            
            if let moment = self.momentsAndAccessoryViews[indexPath.item] as? Moment {
                
                var height = CGFloat(0)
                
                if let cachedHeight = momentCellHeightCache.object(forKey: moment.momentID as NSString) as? CGFloat {
                    height = cachedHeight
                }
                else {
                    let fittedSize = MomentCell.sizeForMoment(moment, width: collectionView.bounds.width)
                    height = fittedSize.height
                    momentCellHeightCache.setObject(height as NSNumber, forKey: moment.momentID as NSString)
                }

                return CGSize(width: self.collectionView.bounds.width, height: height)
            }
            else if let accessoryView = self.momentsAndAccessoryViews[indexPath.item] as? UIView {
                return ContainerCell.sizeForCell(withWidth: collectionView.bounds.width, containedView: accessoryView)
            }
            
            assert(false, "unknown object in dataSource")
            return .zero
            
        case SECTION_MOMENT_FETCH:
            
            let size = SpinnerCell.sizeForSpinnerCell(withWidth: collectionView.bounds.width)
            return size
            
        default:
            
            assert(false, "unknown section in collectionView!")
            return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        guard indexPath.section == SECTION_MOMENT_FEED else { return }
        
        if let selectedMoment = self.momentsAndAccessoryViews[indexPath.item] as? Moment {
            self.momentDelegate?.didSelectMoment?(selectedMoment)
        }
    }
    
    //MARK: DZNEmptyDataSet
    
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView!
    {
        return self.emptyStateView
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool
    {
        return self.allowsEmptyStateScrolling
    }
    
    //MARK: MomentCellDelegate
    
    func momentCell(_ momentCell: MomentCell, playButtonWasTappedForMoment moment: Moment, sender: UIButton)
    {
        self.momentDelegate?.adapter(adapter: self, handlePlayForMoment: moment, sender: sender)
    }
    
    func momentCell(_ momentCell: MomentCell, shareButtonWasTappedForMoment moment: Moment, sender: UIButton)
    {
        self.momentDelegate?.adapter(adapter: self, handleShareForMoment: moment, sender: sender)
    }
    
    func momentCell(_ momentCell: MomentCell, handleOptionsForMoment moment: Moment, sender: UIButton)
    {
        self.momentDelegate?.adapter(adapter: self, handleOptionsForMoment: moment, sender: sender)
    }
    
    //MARK: Utilities
    
    private func populateData()
    {
        //instantiate array to hold both moments and accessoryViews:
        self.momentsAndAccessoryViews = [Any]()
        
        //if we have a delegate, setup the array with the corresponding data and return it,
        //otherwise just copy self.moments:
        guard let dataDelegate = self.accessoryViewDelegate else {
            self.momentsAndAccessoryViews = self.moments
            return
        }
        
        let frequency = dataDelegate.accessoryViewFrequency(forAdaptor: self)
        
        //Go through self.moments, moving each object 1 by 1 into self.momentsAndAccessoryViews,
        //append an accessoryView every nth index (n being frequency):
        for (index, moment) in moments.enumerated() {
            
            self.momentsAndAccessoryViews.append(moment)
            
            if (index % frequency) == (frequency - 1) {
                self.momentsAndAccessoryViews.append(dataDelegate.accessoryView(for: self))
            }
        }
    }
    
    private func containerCell(forView view: UIView, atIndexPath indexPath: IndexPath, withCollectionView: UICollectionView) -> ContainerCell
    {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL, for: indexPath) as? ContainerCell {
            cell.containedView = view
            return cell
        }
        
        assert(false, "dequeued cell was of an unknown type!")
        return ContainerCell()
    }
    
    private func momentCell(forMoment moment: Moment, atIndexPath indexPath: IndexPath,  withCollectionView: UICollectionView) -> MomentCell
    {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_MOMENT_CELL, for: indexPath) as? MomentCell {
            cell.moment = moment
            cell.delegate = self
            return cell
        }
        
        assert(false, "dequeued cell was of an unknown type!")
        return MomentCell()
    }
}


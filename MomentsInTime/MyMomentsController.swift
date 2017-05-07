//
//  MyMomentsController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import RealmSwift

typealias NewMomentCompletion = (Moment) -> Void

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
        //self.adapter.moments = self.momentList.getLocalMoments()
        
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
                
                newMomentController.completion = { moment in
                    self.handleNewMomentCompletion(withMoment: moment)
                }
                
                //pass along moment if we have one:
                if let selectedMoment = sender as? Moment {
                    newMomentController.moment = selectedMoment
                }
            }
            
        case Identifiers.IDENTIFIER_SEGUE_PLAYER:
            //create a player with the url and pass it to destination
            break
            
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
    }
    
    //MARK: MITMomentCollectionViewAdapterMomentDelegate
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handleShareForMoment moment: Moment)
    {
        print("handle share")
    }
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handlePlayForMoment moment: Moment)
    {
        //fetch URL, could be from Vimeo, could be local...
        //then segue to the player
    }
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handleOptionsForMoment moment: Moment)
    {
        //
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
    
    private func handleNewMomentCompletion(withMoment moment: Moment)
    {
        self.adapter.insertNewMoment(moment)
    }
    
    @objc private func refresh()
    {
        self.adapter.moments = self.momentList.getLocalMoments()
        self.adapter.refreshData(shouldReload: true)
        self.refreshControl.endRefreshing()
    }
}

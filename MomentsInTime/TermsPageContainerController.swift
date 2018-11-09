//
//  TermsPageContainerController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 12/18/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

private let IDENTIFIER_STORYBOARD_TERMS_NAV_CONTROLLER = "TermsOfServiceStoryboardID"
private let IDENTIFIER_STORYBOARD_PRIVACY_NAV_CONTROLLER = "PrivacyPolicyStoryboardID"

protocol TermsPrivacyHandler
{
    var successCompletionHandler: TermsOfServiceSuccessCompletion? { get set }
}

class TermsPageContainerController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, TermsPrivacyHandler
{
    @IBOutlet weak var toolBar: UIView!
    @IBOutlet weak var toolBarTopSeparatorHeight: NSLayoutConstraint!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var agreeButton: UIButton!
    
    var pageController: UIPageViewController!
    
    // Track the current index
    var currentIndex: Int?
    private var pendingIndex: Int?
    
    var successCompletionHandler: TermsOfServiceSuccessCompletion?
    
    private lazy var orderedViewControllers: [UIViewController] = {
        return [
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: IDENTIFIER_STORYBOARD_TERMS_NAV_CONTROLLER),
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: IDENTIFIER_STORYBOARD_PRIVACY_NAV_CONTROLLER)
        ]
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setupViews()
        
        // We want to have each view loaded and ready to go so when we swipe there is no delay:
        self.orderedViewControllers.forEach {
            $0.loadViewIfNeeded()
            $0.childViewControllers.forEach { $0.loadViewIfNeeded() }
        }
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        self.view.bringSubview(toFront: self.toolBar)
    }
    
    @IBAction func handleAgree(_ sender: UIButton)
    {
        // confirm with user before calling successCompletion:
        let acceptAlertView = TermsOfServiceAcceptAlertView()
        
        // only dismiss if user agrees to Terms and Conditions:
        acceptAlertView.showFrom(viewController: self) { success in
            
            if success {
                self.successCompletionHandler?()
            }
        }
    }
    
// MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        guard let currentIndex = self.orderedViewControllers.index(of: viewController) else { return nil }
        
        let previousIndex = currentIndex - 1
        
        if previousIndex >= 0 {
            return self.orderedViewControllers[previousIndex]
        }
        
        // we are back on the first one so nothing else before:
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        guard let currentIndex = self.orderedViewControllers.index(of: viewController) else { return nil }
        
        let nextIndex = currentIndex + 1
        
        if nextIndex < self.orderedViewControllers.count {
            return self.orderedViewControllers[nextIndex]
        }
        
        // there are no additional controllers:
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    {
        self.pendingIndex = self.orderedViewControllers.index(of: pendingViewControllers.first!)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        if completed {
            
            self.currentIndex = self.pendingIndex
            
            if let index = currentIndex {
                self.pageControl.currentPage = index
            }
        }
    }
    
// MARK: - Utilities
    
    func setupViews()
    {
        self.view.backgroundColor = UIColor.white
        self.agreeButton.setTitleColor(UIColor.mitActionblue, for: .normal)

        // setup pageController:
        self.pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.dataSource = self
        pageController.delegate = self
        
        if let firstController = self.orderedViewControllers.first {
            self.pageController.setViewControllers([firstController], direction: .forward, animated: true, completion: nil)
        }
        
        // UIPageViewController is fickle and not meant to be customized or subclasses really,
        // so we'll use view controller containment to hold onto it and add other views like out tabBar:
        self.addChildViewController(self.pageController)
        self.view.addSubview(self.pageController.view)
        self.pageController.view.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        self.pageController.view.autoPinEdge(.bottom, to: .top, of: self.toolBar)
        self.pageController.didMove(toParentViewController: self)
        
        // add pageControl to toolBar:
        self.toolBar.addSubview(self.pageControl)
        self.pageControl.autoCenterInSuperview()
        self.pageControl.currentPageIndicatorTintColor = UIColor.mitActionblue
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        
        // update the height of the top separator:
        self.toolBarTopSeparatorHeight.constant = 1.0 / UIScreen.main.scale
        
        // keep toolBar on top:
        self.view.bringSubview(toFront: self.toolBar)
    }
}

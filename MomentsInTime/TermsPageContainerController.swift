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

class TermsPageContainerController: UIViewController, UIPageViewControllerDataSource, TermsPrivacyHandler
{
    @IBOutlet weak var toolBar: UIToolbar!
    
    var pageController: UIPageViewController!
    
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
        self.view.backgroundColor = UIColor.mitBackground
        self.setupPageController()
        
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
    
    @IBAction func handleAgree(_ sender: UIBarButtonItem)
    {
        //confirm with user before calling successCompletion:
        let acceptAlertView = TermsOfServiceAcceptAlertView()
        
        //only dismiss if user agrees to Terms and Conditions:
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
    
// MARK: - Utilities
    
    func setupPageController()
    {
        // setup pageController:
        self.pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.dataSource = self
        
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
        
        // keep toolBar on top:
        self.view.bringSubview(toFront: self.toolBar)
    }
}

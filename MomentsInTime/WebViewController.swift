//
//  WebViewController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 12/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import WebKit
import PureLayout

class WebViewController: UIViewController
{
    lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        webView.scrollView.alwaysBounceHorizontal = false
        return webView
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setupViews()
        
        //no large title for iOS 11:
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }
    }

    func loadLocalURL(url: URL)
    {
        self.webView.loadFileURL(url, allowingReadAccessTo: url)
    }
    
    func setupViews()
    {
        self.view.addSubview(self.webView)
        self.webView.autoPinEdgesToSuperviewEdges()
    }
}



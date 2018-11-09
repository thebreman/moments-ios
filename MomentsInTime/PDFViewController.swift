//
//  PDFViewController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 11/8/18.
//  Copyright © 2018 Tikkun Olam. All rights reserved.
//

import UIKit
import PDFKit
import PureLayout

class PDFViewController: UIViewController
{
    lazy var pdfView: PDFView = {
        let view = PDFView()
        view.autoScales = true
        return view
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setupViews()
    }
    
    func loadDocument(url: URL)
    {
        let document = PDFDocument(url: url)
        self.pdfView.document = document
    }
    
    func setupViews()
    {
        self.view.addSubview(self.pdfView)
        self.pdfView.autoPinEdgesToSuperviewEdges()
    }
}

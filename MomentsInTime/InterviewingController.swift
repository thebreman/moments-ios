//
//  InterviewingController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/26/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let COPY_TITLE_BUTTON_SELECT_PICTURE = "Select from camera roll"

enum InterviewingSection: Int
{
    case name = 0
    case role = 1
    case picture = 2
    
    static var titles: [String] {
        return ["Name", "Role", "Picture (optional)"]
    }
}

class InterviewingController: UIViewController, UITableViewDelegate, UITableViewDataSource, ActiveLinkCellDelegate
{
    @IBOutlet weak var saveButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    private enum Identifiers
    {
        static let IDENTIFIER_CELL_ACTIVE_LINK = "activeLink"
        static let IDENTIFIER_VIEW_SECTION_HEADER = "sectionHeaderView"
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.saveButton.isEnabled = false
        self.setupTableView()
    }
    
    //MARK: Actions
    
    @IBAction func handleSave(_ sender: BouncingButton)
    {
        print("save Interviewing info")
    }
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    //MARK: TableView
    
    private func setupTableView()
    {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.contentInset.top = 12
        
        //setup sectionHeaderViews:
        self.tableView.register(UINib(nibName: String(describing: MITSectionHeaderView.self), bundle: nil), forHeaderFooterViewReuseIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER)
        self.tableView.estimatedSectionHeaderHeight = 64
        self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        self.tableView.sectionFooterHeight = 0
        
        //setup ActiveLinkCells:
        self.tableView.register(UINib(nibName: String(describing: ActiveLinkCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return InterviewingSection.titles.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER) as? MITSectionHeaderView {
            sectionHeaderView.title = NewMomentSetting.titles[section]
            return sectionHeaderView
        }
        
        assert(false, "Unknown SectionHeaderView dequeued")
        return MITSectionHeaderView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        switch indexPath.section {
            
        case InterviewingSection.name.rawValue:
            
            return UITableViewCell() //TextFieldCell
            
        case InterviewingSection.role.rawValue:
            
            return UITableViewCell() //TextFieldCell
            
        case InterviewingSection.picture.rawValue:
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK) as? ActiveLinkCell {
                cell.activeLabel.text = COPY_TITLE_BUTTON_SELECT_PICTURE
                cell.activeLinks = [COPY_TITLE_BUTTON_SELECT_PICTURE]
                cell.delegate = self
            }
            
            assert(false, "dequeued cell was of unknown type")
            return ActiveLinkCell()
            
        default:
            
            assert(false, "indexPath section is unknown")
            return UITableViewCell()
        }
    }
    
    //MARK: ActiveLinkCellDelegate
    
    func activeLinkCell(_ activeLinkCell: ActiveLinkCell, handleSelection selection: String)
    {
        guard selection == COPY_TITLE_BUTTON_SELECT_PICTURE else { return }
        self.openPhotos(fromView: activeLinkCell.activeLabel) //move all of this into CameraMan
    }
    
    //MARK: Utilities
    
    private func openPhotos(fromView sender: UIView)
    {
        print("open Photos")
    }
}

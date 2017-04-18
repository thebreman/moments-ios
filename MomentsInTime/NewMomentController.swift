//
//  NewMomentController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let _sectionTitles = ["Interviewing", "Description", "Video", "Notes"]

class NewMomentController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var submitButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    
//    enum NewMomentSection
//    {
//        case interviewing
//        case description
//        case video
//        case notes
//    }
    
    private struct Identifiers
    {
        static let IDENTIFIER_CELL_ACTIVE_LINK = "activeLink"
        static let IDENTIFIER_CELL_NOTE = "note"
        static let IDENTIFIER_VIEW_SECTION_HEADER = "sectionHeaderView"
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.submitButton.isEnabled = false
        self.setupTableView()
    }
    
//MARK: Actions
    
    @IBAction func handleSubmit(_ sender: BouncingButton)
    {
        print("handle Submit")
    }
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
        //end editing/ first responders then dismiss
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
//MARK: tableView
    
    private func setupTableView()
    {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.contentInset.top = 10
        
        self.tableView.register(UINib(nibName: String(describing: MITSectionHeaderView.self), bundle: nil), forHeaderFooterViewReuseIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER)
        self.tableView.estimatedSectionHeaderHeight = 64
        self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        self.tableView.sectionFooterHeight = 0
        
        self.tableView.register(UINib(nibName: String(describing: ActiveLinkCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK)
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.register(UINib(nibName: String(describing: MITNoteCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_NOTE)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return _sectionTitles.count
    }
    
    //rewrite this shit with switch statements and clean it up:
    //try making an enum where the associated value is the string for the active label...
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER) as? MITSectionHeaderView {
            sectionHeaderView.title = _sectionTitles[section]
            return sectionHeaderView
        }
        
        assert(false, "Unknown SectionHeaderView dequeued")
        return MITSectionHeaderView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 3 {
            return 5
        }
        else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        //notes section:
        if indexPath.section == 3 {
            
            //first cell is create new note link:
            if indexPath.row == 0 {
                if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK) as? ActiveLinkCell {
                    cell.activeLabel.text = "Add a new note"
                    cell.detailDisclosureButton.isHidden = true
                    return cell
                }
                
                return ActiveLinkCell()
            }
            
            //note cells:
            if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_NOTE) as? MITNoteCell {
                cell.noteTextLabel.text = "This is a note about an interesting question that someone might want to ask when they are interviewing someone. There will be stock notes and user-created notes."
                return cell
            }
            
            return MITNoteCell()
        }
        
        //active link cells for everything else:
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK) as? ActiveLinkCell {
            cell.activeLabel.text = "Select a special person to interview"
            cell.detailDisclosureButton.isHidden = (indexPath.section == 2 ? false : true)
            return cell
        }
        
        return ActiveLinkCell()
    }
}

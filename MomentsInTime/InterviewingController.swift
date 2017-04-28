//
//  InterviewingController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/26/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let COPY_TEXT_PLACEHOLDER_NAME_FIELD = "Enter name"
private let COPY_TEXT_PLACEHOLDER_ROLE_FIELD = "Enter role"
private let COPY_TITLE_BUTTON_SELECT_PICTURE = "Select from camera roll"

//find out if this is weird and whether or not it should be in InterviewingController, or even in its own file?
enum InterviewingSection: Int
{
    case name = 0
    case role = 1
    case picture = 2
    
    static var titles: [String] {
        return ["Name", "Role", "Picture (optional)"]
    }
    
    //for name and role return textField placeholder text
    //for picture return activeLabel text
    var cellContentText: String {
        switch self {
        case .name: return COPY_TEXT_PLACEHOLDER_NAME_FIELD
        case .role: return COPY_TEXT_PLACEHOLDER_ROLE_FIELD
        case .picture: return COPY_TITLE_BUTTON_SELECT_PICTURE
        }
    }
}

class InterviewingController: UIViewController, UITableViewDelegate, UITableViewDataSource, ActiveLinkCellDelegate, UITextFieldDelegate
{
    @IBOutlet weak var saveButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    private enum Identifiers
    {
        static let IDENTIFIER_CELL_ACTIVE_LINK = "activeLink"
        static let IDENTIFIER_CELL_TEXT_FIELD = "textFieldCell"
        static let IDENTIFIER_VIEW_SECTION_HEADER = "sectionHeaderView"
    }
    
    private lazy var cameraMan: CameraMan = {
        let cameraMan = CameraMan()
        return cameraMan
    }()
    
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
        self.tableView.sectionFooterHeight = 16
        
        //setup TextFieldCells:
        self.tableView.register(UINib(nibName: String(describing: TextFieldCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_TEXT_FIELD)
        
        //setup ActiveLinkCells:
        self.tableView.register(UINib(nibName: String(describing: ActiveLinkCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK)
        
        self.tableView.estimatedRowHeight = 200
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return InterviewingSection.titles.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER) as? MITSectionHeaderView {
            sectionHeaderView.title = InterviewingSection.titles[section]
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
        guard let section = InterviewingSection(rawValue: indexPath.section) else {
            assert(false, "InterviewingSection invalid")
            return UITableViewCell()
        }
        
        switch indexPath.section {
        
        case InterviewingSection.name.rawValue, InterviewingSection.role.rawValue:
            return self.textFieldCell(forSection: section, withTableView: tableView)
            
        case InterviewingSection.picture.rawValue:
            return self.activeLinkCell(forSection: section, withTableView: tableView)
            
        default:
            assert(false, "indexPath section is unknown")
            return UITableViewCell()
        }
    }
    
    //MARK: ActiveLinkCellDelegate
    
    func activeLinkCell(_ activeLinkCell: ActiveLinkCell, handleSelection selection: String)
    {
        guard selection == COPY_TITLE_BUTTON_SELECT_PICTURE else { return }
        self.openPhotoPicker(fromView: activeLinkCell.activeLabel)
    }
    
    //MARK: Utilities
    
    private func textFieldCell(forSection section: InterviewingSection, withTableView tableView: UITableView) -> TextFieldCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_TEXT_FIELD) as? TextFieldCell {
            cell.textField.placeholder = section.cellContentText
            cell.textField.delegate = self
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return TextFieldCell()
    }
    
    private func activeLinkCell(forSection section: InterviewingSection, withTableView tableView: UITableView) -> ActiveLinkCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK) as? ActiveLinkCell {
            cell.activeLabel.text = section.cellContentText
            cell.activeLinks = [section.cellContentText]
            cell.delegate = self
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return ActiveLinkCell()
    }
    
    private func openPhotoPicker(fromView sender: UIView)
    {
        //must configure popover for iPad support,
        //iphone will adapt to fullscreen modal automatically:
        self.cameraMan.pickerController.modalPresentationStyle = .popover
        self.cameraMan.pickerController.popoverPresentationController?.sourceView = sender
        self.cameraMan.pickerController.popoverPresentationController?.sourceRect = sender.bounds
        self.cameraMan.pickerController.popoverPresentationController?.permittedArrowDirections = [.up]
        
        self.cameraMan.getPhotoFromLibrary(withPresenter: self) { image in
            
            if let interviewSubjectImage = image {
                print("success we got the image for the interview subject")
            }
        }
    }
}

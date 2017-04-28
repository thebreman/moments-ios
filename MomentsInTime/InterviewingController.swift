//
//  InterviewingController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/26/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

private let COPY_TEXT_PLACEHOLDER_NAME_FIELD = "Enter name"
private let COPY_TEXT_PLACEHOLDER_ROLE_FIELD = "Enter role"
private let COPY_TITLE_BUTTON_SELECT_PICTURE = "Select from camera roll"

private let MIN_CHARACTERS_NAME = 10
private let MAX_CHARACTERS = 100

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

class InterviewingController: UIViewController, UITableViewDelegate, UITableViewDataSource, ActiveLinkCellDelegate, UITextFieldDelegate, KeyboardMover
{
    @IBOutlet weak var saveButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    
    private lazy var nameFieldView: TextFieldView = {
        let view = TextFieldView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textField.translatesAutoresizingMaskIntoConstraints = false
        view.textField.textColor = UIColor.mitText
        view.textField.font = UIFont.systemFont(ofSize: 16.0)
        view.textField.placeholder = InterviewingSection.name.cellContentText
        view.textField.tintColor = UIColor.mitActionblue
        view.textField.delegate = self
        return view
    }()
    
    private lazy var roleFieldView: TextFieldView = {
        let view = TextFieldView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textField.textColor = UIColor.mitText
        view.textField.font = UIFont.systemFont(ofSize: 16.0)
        view.textField.placeholder = InterviewingSection.role.cellContentText
        view.textField.tintColor = UIColor.mitActionblue
        view.textField.delegate = self
        return view
    }()
    
    private enum Identifiers
    {
        static let IDENTIFIER_CELL_ACTIVE_LINK = "activeLink"
        static let IDENTIFIER_CELL_CONTAINER = "containerCell"
        static let IDENTIFIER_VIEW_SECTION_HEADER = "sectionHeaderView"
    }
    
    private lazy var cameraMan: CameraMan = {
        let cameraMan = CameraMan()
        return cameraMan
    }()
    
    //private var justLoaded = true
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.saveButton.isEnabled = false
        self.setupTableView()
        self.listenForKeyboardNotifications(shouldListen: true)
        self.nameFieldView.textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.listenForKeyboardNotifications(shouldListen: false)
    }
    
    //MARK: Actions
    
    @IBAction func handleSave(_ sender: BouncingButton)
    {
        print("save Interviewing info")
        
        //persist name, role, and photo then:
        self.tableView.endEditing(true)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
        self.tableView.endEditing(true)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    private var currentEditingSection = InterviewingSection.name
    
    //MARK: UITextFieldDelegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        if textField == self.nameFieldView.textField {
            self.currentEditingSection = InterviewingSection.name
        }
        else if textField == self.roleFieldView.textField {
            self.currentEditingSection = InterviewingSection.role
        }
        
        self.tableView.scrollRectToVisible(textField.frame, animated: true)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        let currentText = textField.text as NSString?
        let newText = currentText?.replacingCharacters(in: range, with: string)
        
        guard let count = newText?.characters.count else { return true }
        
        self.saveButton.isEnabled = count >= MIN_CHARACTERS_NAME && textField == self.nameFieldView.textField
        return count <= MAX_CHARACTERS
    }
    
    //MARK: KeyboardMover
    
    func keyboardMoved(notification: Notification)
    {
        self.view.layoutIfNeeded() //update pending layout changes then animate:
        
        UIView.animateWithKeyboardNotification(notification: notification) { (keyboardHeight, keyboardWindowY) in
            
            //first adjust scrollView content:
            self.tableView.contentInset.bottom = keyboardHeight
            self.tableView.scrollIndicatorInsets.bottom = keyboardHeight
            
            //now make sure that the appropriate section is visible:
            var pathToScroll = IndexPath()
            
            switch self.currentEditingSection {
            case .name: pathToScroll = IndexPath(row: 0, section: InterviewingSection.name.rawValue)
            case .role: pathToScroll = IndexPath(row: 0, section: InterviewingSection.role.rawValue)
            default: break
            }
            
            self.tableView.scrollToRow(at: pathToScroll, at: UITableViewScrollPosition.top, animated: false)
            self.view.layoutIfNeeded()
        }
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
        
        //setup ContainerCells:
        self.tableView.register(ContainerTableViewCell.self, forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_CONTAINER)
        
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
        
        case InterviewingSection.name.rawValue:
            return self.containerCell(forView: self.nameFieldView, withTableView: tableView)
            
        case InterviewingSection.role.rawValue:
            return self.containerCell(forView: self.roleFieldView, withTableView: tableView)
            
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
    
    private func containerCell(forView view: UIView, withTableView tableView: UITableView) -> ContainerTableViewCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_CONTAINER) as? ContainerTableViewCell {
            cell.containedView = view
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return ContainerTableViewCell()
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

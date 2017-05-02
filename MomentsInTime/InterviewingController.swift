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
private let COPY_TITLE_BUTTON_SELECT_PICTURE = "Select photo (optional)"

private let MIN_CHARACTERS_NAME = 10
private let MAX_CHARACTERS = 100

//find out if this is weird and whether or not it should be in InterviewingController, or even in its own file?
enum InterviewingSection: Int
{
    case picture = 0
    case name = 1
    case role = 2
    
    static var titles: [String] {
        return ["Picture (optional)", "Name", "Role"]
    }
    
    //for name and role return textField placeholder text
    //for picture return activeLabel text
    var cellContentText: String {
        switch self {
        case .picture: return COPY_TITLE_BUTTON_SELECT_PICTURE
        case .name: return COPY_TEXT_PLACEHOLDER_NAME_FIELD
        case .role: return COPY_TEXT_PLACEHOLDER_ROLE_FIELD
        }
    }
}

class InterviewingController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, KeyboardMover
{
    @IBOutlet weak var saveButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    
    var interviewSubject = Subject()
    
    var completion: InterviewingCompletion?
    
    private lazy var profileImageView: ProfileImageView = {
        let view = ProfileImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.actionFont = UIFont.systemFont(ofSize: 16.0)
        view.actionButton.setTitleColor(.mitActionblue, for: .normal)
        view.actionButton.addTarget(self, action: #selector(handleProfileImage), for: .touchUpInside)
        view.actionButton.setTitle(InterviewingSection.picture.cellContentText, for: .normal)
        return view
    }()
    
    private lazy var nameFieldView: TextFieldView = {
        let view = TextFieldView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textField.textColor = UIColor.mitText
        view.textField.font = UIFont.systemFont(ofSize: 16.0)
        view.textField.placeholder = InterviewingSection.name.cellContentText
        view.textField.tintColor = UIColor.mitActionblue
        view.textField.delegate = self
        view.textField.autocapitalizationType = UITextAutocapitalizationType.words
        view.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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
        static let IDENTIFIER_CELL_MIT_CONTAINER = "mitContainerCell"
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
        self.listenForKeyboardNotifications(shouldListen: true)
        self.updateSubject()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(true)
        self.updateSaveButton()
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
        guard let subjectName = self.nameFieldView.textField.text else { return }
        
        self.interviewSubject.name = subjectName
        
        if let role = self.roleFieldView.textField.text {
            self.interviewSubject.role = role.characters.count > 0 ? role : nil
        }
        
        self.tableView.endEditing(true)
        
        self.presentingViewController?.dismiss(animated: true) {
            self.completion?(self.interviewSubject)
        }
    }
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
        self.tableView.endEditing(true)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleProfileImage(_ sender: BouncingButton)
    {
        self.openPhotoPicker(fromView: sender)
    }
    
    /**
     * The next sections are textFieldDelegate and keyboardMover,
     * So... the var below: currentEditingSection is either name or role and when the respective section
     * begins editing, we will update this var, so that anytime the keyboard changes, we will scroll the appropriate
     * section to visible, we also scroll the appropriate section to visible anytime one of them begins editing...
     */
    
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
        
        return count <= MAX_CHARACTERS
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField)
    {
        self.updateSaveButton()
    }
    
    private func updateSaveButton()
    {
        if let nameFieldCount = self.nameFieldView.textField.text?.characters.count {
            self.saveButton.isEnabled = nameFieldCount >= MIN_CHARACTERS_NAME
        }
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
        self.tableView.contentInset.top = 8
        
        //setup sectionHeaderViews:
        self.tableView.register(UINib(nibName: String(describing: MITSectionHeaderView.self), bundle: nil), forHeaderFooterViewReuseIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER)
        self.tableView.estimatedSectionHeaderHeight = 64
        //self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        self.tableView.sectionFooterHeight = 16
        
        //setup ContainerCells:
        self.tableView.register(MITContainerTableViewCell.self, forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_MIT_CONTAINER)
        
        self.tableView.estimatedRowHeight = 64
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return InterviewingSection.titles.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if section == InterviewingSection.picture.rawValue {
            return 0
        }
        
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        //no section header for picture section:
        if section == InterviewingSection.picture.rawValue {
            return UIView(frame: .zero)
        }
        
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
        switch indexPath.section {
            
        case InterviewingSection.picture.rawValue:
            let cell = self.mitContainerCell(forView: self.profileImageView, withTableView: tableView)
            cell.lowerSeparatorColor = .clear
            cell.upperSeparatorColor = .clear
            cell.backgroundColor = .clear
            return cell
        
        case InterviewingSection.name.rawValue:
            return self.mitContainerCell(forView: self.nameFieldView, withTableView: tableView)
            
        case InterviewingSection.role.rawValue:
            return self.mitContainerCell(forView: self.roleFieldView, withTableView: tableView)
            
        default:
            assert(false, "indexPath section is unknown")
            return UITableViewCell()
        }
    }
    
    //MARK: Utilities
    
    private func mitContainerCell(forView view: UIView, withTableView tableView: UITableView) -> MITContainerTableViewCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_MIT_CONTAINER) as? MITContainerTableViewCell {
            cell.containedView = view
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return MITContainerTableViewCell()
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
                self.profileImageView.profileImage = interviewSubjectImage
                self.interviewSubject.profileImageURL = self.persistImage(interviewSubjectImage)?.absoluteString
            }
        }
    }
    
    private func persistImage(_ image: UIImage) -> URL?
    {
        var imageFileName: URL
        
        //if we have previously saved an image we want to overwrite it:
        if let urlString = self.interviewSubject.profileImageURL, let imageFile = URL(string: urlString) {
            imageFileName = imageFile
        }
        else {
            
            //otherwise create a url:
            let imageName = UUID().uuidString
            imageFileName = FileManager.getDocumentsDirectory().appendingPathComponent("\(imageName).jpeg")
        }
        
        guard let imageData = UIImageJPEGRepresentation(image, 0.2) else {
            return nil
        }
        
        try? imageData.write(to: imageFileName)
        
        return imageFileName
    }
    
    private func updateSubject()
    {
        self.profileImageView.profileImageURL = self.interviewSubject.profileImageURL
        self.nameFieldView.textField.text = self.interviewSubject.name
        self.roleFieldView.textField.text = self.interviewSubject.role
    }
}

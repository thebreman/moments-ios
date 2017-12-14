//
//  DescriptionController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/26/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import UITextView_Placeholder
import PureLayout

private let MAX_CHARACTERS_DESCRIPTION = 300
private let MIN_CHARACTERS_DESCRIPTION = 1
private let MAX_CHARACTERS_TITLE = 100
private let MIN_CHARACTERS_TITLE = 1

class CreateTopicController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, KeyboardMover
{
    @IBOutlet weak var saveButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    
    var videoTitle = String()
    var videoDescription = String()
    
    var completion: TopicCompletion?
    
    var shouldDismissTwice = false
    
    private lazy var titleFieldView: TextFieldView = {
        let view = TextFieldView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textField.translatesAutoresizingMaskIntoConstraints = false
        view.textField.textColor = UIColor.mitText
        view.textField.font = UIFont.systemFont(ofSize: 16.0)
        view.textField.placeholder = CreateTopicSection.title.placeholderText
        view.textField.tintColor = UIColor.mitActionblue
        view.textField.delegate = self
        view.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        return view
    }()
    
    @objc private func textFieldDidChange(_ textField: UITextField)
    {
        self.updateUI()
    }
    
    private lazy var descriptionFieldView: TextViewView = {
        let view = TextViewView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textView.textColor = UIColor.gray
        view.textView.font = UIFont.systemFont(ofSize: 16.0)
        view.textView.placeholder = CreateTopicSection.description.placeholderText
        view.textView.tintColor = UIColor.mitActionblue
        view.textView.delegate = self
        NSLayoutConstraint.autoSetPriority(UILayoutPriority(rawValue: 999), forConstraints: {
            view.textView.autoSetDimension(.height, toSize: 160.0)
        })
        return view
    }()
    
    private enum Identifiers
    {
        static let IDENTIFIER_CELL_MIT_CONTAINER = "mitContainerCell"
        static let IDENTIFIER_VIEW_SECTION_HEADER = "sectionHeaderView"
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.saveButton.isEnabled = false
        self.setupTableView()
        self.listenForKeyboardNotifications(shouldListen: true)
        self.updateLabels()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        self.updateUI()
        self.titleFieldView.textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.listenForKeyboardNotifications(shouldListen: false)
    }
    
    //MARK: Actions
    
    @IBAction func handleSave(_ sender: BouncingButton)
    {
        guard let videoName = self.titleFieldView.textField.text else { return }
        
        self.videoTitle = videoName
        self.videoDescription = self.descriptionFieldView.textView.text
        
        self.tableView.endEditing(true)
        
        if self.shouldDismissTwice {
            self.presentingViewController?.presentingViewController?.dismiss(animated: true) {
                self.completion?(self.videoTitle, self.videoDescription, true)
            }
        }
        else {
            self.presentingViewController?.dismiss(animated: true) {
                self.completion?(self.videoTitle, self.videoDescription, true)
            }
        }
    }
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
        self.tableView.endEditing(true)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    /**
     * The next sections are textViewDelegate, textFieldDelegate, and keyboardMover,
     * So, the var below: currentEditingSection is either title or description and when the respective section
     * begins editing, we will update this var, so that anytime the keyboard changes, we will scroll the appropriate 
     * section to visible, we also scroll the appropriate section to visible anytime one of them begins editing...
     */
    
    private var currentEditingSection = CreateTopicSection.title //title starts off as the first responder
    
    //MARK: UITextViewDelegate
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    {
        self.currentEditingSection = CreateTopicSection.description
        
        //scroll textView cell to visible:
        let path = IndexPath(row: 0, section: CreateTopicSection.description.rawValue)
        self.tableView.scrollToRow(at: path, at: UITableViewScrollPosition.top, animated: true)
        
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        let totalPotentialCharacters = textView.text.count + (text.count - range.length)
        return totalPotentialCharacters <= MAX_CHARACTERS_DESCRIPTION
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        self.updateUI()
    }
    
    //MARK: UITextFieldDelegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        self.currentEditingSection = CreateTopicSection.title
       
        //scroll textView cell to visible:
        let path = IndexPath(row: 0, section: CreateTopicSection.title.rawValue)
        self.tableView.scrollToRow(at: path, at: UITableViewScrollPosition.top, animated: true)
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        let currentText = textField.text as NSString?
        let newText = currentText?.replacingCharacters(in: range, with: string)
        
        guard let count = newText?.count else { return true }
        
        return count <= MAX_CHARACTERS_TITLE
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
            case .title: pathToScroll = IndexPath(row: 0, section: CreateTopicSection.title.rawValue)
            case .description: pathToScroll = IndexPath(row: 0, section: CreateTopicSection.description.rawValue)
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
        self.tableView.register(MITContainerTableViewCell.self, forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_MIT_CONTAINER)
        
        self.tableView.estimatedRowHeight = 200
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return CreateTopicSection.titles.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER) as? MITSectionHeaderView {
            sectionHeaderView.title = CreateTopicSection.titles[section]
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
            
        case CreateTopicSection.title.rawValue:
            return self.containerCell(forView: self.titleFieldView, withTableView: tableView)
            
        case CreateTopicSection.description.rawValue:
            return self.containerCell(forView: self.descriptionFieldView, withTableView: tableView)
            
        default:
            assert(false, "indexPath section is unknown")
            return UITableViewCell()
        }
    }
    
    //MARK: Utilities
    
    private func containerCell(forView view: UIView, withTableView tableView: UITableView) -> MITContainerTableViewCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_MIT_CONTAINER) as? MITContainerTableViewCell {
            cell.containedView = view
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return MITContainerTableViewCell()
    }
    
    private func updateUI()
    {
        var readyToSave = false
        
        if let titleText = self.titleFieldView.textField.text, let descriptionText = self.descriptionFieldView.textView.text {
            if titleText.count >= MIN_CHARACTERS_TITLE && descriptionText.count >= MIN_CHARACTERS_DESCRIPTION {
                readyToSave = true
            }
        }
        
        self.saveButton.isEnabled = readyToSave
    }
    
    private func updateLabels()
    {
        self.titleFieldView.textField.text = self.videoTitle
        self.descriptionFieldView.textView.text = self.videoDescription
    }
}

//
//  NewMomentController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import Photos

typealias InterviewingCompletion = (Subject?) -> Void
typealias DescriptionCompletion = (_ name: String?, _ description: String?) -> Void
typealias NoteCompletion = (Note?) -> Void

class NewMomentController: UIViewController, UITableViewDelegate, UITableViewDataSource, ActiveLinkCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    @IBOutlet weak var submitButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    
    private enum Identifiers
    {
        static let IDENTIFIER_CELL_ACTIVE_LINK = "activeLinkCell"
        static let IDENTIFIER_CELL_IMAGE_TITLE_SUBTITLE = "imageTitleSubtitleCell"
        static let IDENTIFIER_CELL_NOTE = "noteCell"
        static let IDENTIFIER_VIEW_SECTION_HEADER = "sectionHeaderView"
        
        enum Segues
        {
            static let ENTER_INTERVIEW_SUBJECT = "newMomentToInterviewing"
            static let ENTER_INTERVIEW_DESCRIPTION = "newMomentToDescription"
            static let ENTER_NEW_NOTE = "newMomentToNote"
        }
    }
    
    private lazy var newMoment = Moment()
    private lazy var newMomentVideo = Video()
    private var newMomentNotes: [Note]?
    
    private var cameraMan: CameraMan = {
        let cameraMan = CameraMan()
        cameraMan.maxVideoDurationMinutes = 20
        return cameraMan
    }()
    
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
        //end editing/ resign first responders then dismiss
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
//MARK: tableView
    
    private func setupTableView()
    {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.contentInset.top = 12
        
        //setup sectionHeaderViews:
        self.tableView.register(UINib(nibName: String(describing: MITSectionHeaderView.self), bundle: nil), forHeaderFooterViewReuseIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER)
        self.tableView.estimatedSectionHeaderHeight = 64
        self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        self.tableView.sectionFooterHeight = 8
        
        //setup ActiveLinkCells:
        self.tableView.register(UINib(nibName: String(describing: ActiveLinkCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK)
        
        //setup InterviewingSubjectCells:
        self.tableView.register(UINib(nibName: String(describing: ImageTitleSubtitleCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_IMAGE_TITLE_SUBTITLE)
        
        //setup NoteCells:
        self.tableView.register(UINib(nibName: String(describing: MITNoteCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_NOTE)
        
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return NewMomentSetting.titles.count
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
        //Notes section must have all the notes + the top Add a new note activeLinkCell:
        if section == NewMomentSetting.notes.rawValue {
            return NewMomentSetting.defaultNotes.count + 1
        }
        
        //just 1 activeLinkCell for all other sections:
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        //get NewMomentSetting for corresponding section:
        guard let setting = NewMomentSetting(rawValue: indexPath.section) else {
            assert(false, "NewMomentSetting invalid")
            return UITableViewCell()
        }
        
        switch indexPath.section {
            
        case NewMomentSetting.interviewing.rawValue:
            
            if let interviewingSubject = self.newMoment.subject {
                return self.interviewingSubjectCell(forSubject: interviewingSubject, withTableView: tableView)
            }
            
            return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            
        case NewMomentSetting.description.rawValue:
            return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            
        case NewMomentSetting.video.rawValue:
            return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            
        case NewMomentSetting.notes.rawValue:
            
            //first cell is activeLinkCell:
            if indexPath.row == 0 {
                return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            }
            
            //the rest of the cells are MITNoteCells:
            //but since cell at row 0 is not a note cell (activeLinkCell) we need to subtract 1 from the index:
            let note = NewMomentSetting.defaultNotes[indexPath.row - 1]
            return self.noteCell(forNote: note, withTableView: tableView)
            
        default:
            assert(false, "indexPath section is unknown")
            return UITableViewCell()
        }
    }
    
    //MARK: ActiveLinkCellDelegate:
    
    func activeLinkCell(_ activeLinkCell: ActiveLinkCell, handleSelection selection: String)
    {
        switch selection {
        
        case COPY_SELECT_INTERVIEW_SUBJECT:
            self.handleInterviewSubject(fromView: activeLinkCell.activeLabel)
            
        case COPY_CREATE_DESCRIPTION:
            self.handleInterviewDescription()
            
        case COPY_LINK_START_FILMING:
            self.handleVideoCamera()
            
        case COPY_LINK_UPLOAD_VIDEO:
            self.handlePhotos(fromView: activeLinkCell.detailDisclosureButton)
            
        case COPY_CREATE_NOTE:
            self.handleNoteCreation()
            
        default:
            break
        }
    }
    
    //MARK: Navigation
    
    private func reloadRows(forIndexPaths paths: [IndexPath], withTableView tableView: UITableView)
    {
        tableView.beginUpdates()
        tableView.reloadRows(at: paths, with: .automatic)
        tableView.endUpdates()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard let id = segue.identifier else { return }
        
        switch id {
            
        case Identifiers.Segues.ENTER_INTERVIEW_SUBJECT:
            
            if let interviewingController = segue.destination.contentViewController as? InterviewingController {
                interviewingController.completion = { interviewSubject in
                    self.newMoment.subject = interviewSubject
                    self.updateUI()
                    
                    //animate interviewingSubject cell in:
                    let newPath = IndexPath(row: 0, section: NewMomentSetting.interviewing.rawValue)
                    self.reloadRows(forIndexPaths: [newPath], withTableView: self.tableView)
                }
            }
            
        case Identifiers.Segues.ENTER_INTERVIEW_DESCRIPTION:
            
            if let descriptionController = segue.destination.contentViewController as? DescriptionController {
                descriptionController.completion = { (videoTitle, videoDescription) in
                    self.newMomentVideo.name = videoTitle
                    self.newMomentVideo.videoDescription = videoDescription
                    self.updateUI()
                }
            }
            
        case Identifiers.Segues.ENTER_NEW_NOTE:
            
            if let newNoteController = segue.destination.contentViewController as? NewNoteController {
                newNoteController.completion = { note in
                    
                    guard let newNote = note else { return }
                    
                    if self.newMomentNotes == nil {
                        self.newMomentNotes = [Note]()
                    }
                    
                    self.newMomentNotes?.append(newNote)
                }
            }
            
        default:
            break
        }
    }
    
    //MARK: Utilities:
    
    private func handleVideoCamera()
    {
        self.cameraMan.getVideoFromCamera(withPresenter: self) { url in
            
            if let videoURL = url {
                print("YES we have the video url from the camera!!!! \(videoURL)")
                self.newMomentVideo.localURL = videoURL.absoluteString
                self.updateUI()
            }
        }
    }
    
    private func handlePhotos(fromView sender: UIView)
    {
        //must configure popover for iPad support,
        //iphone will adapt to fullscreen modal automatically:
        self.cameraMan.pickerController.modalPresentationStyle = .popover
        self.cameraMan.pickerController.popoverPresentationController?.sourceView = sender
        self.cameraMan.pickerController.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: sender.bounds.midX, y: sender.bounds.minY), size: sender.bounds.size)
        self.cameraMan.pickerController.popoverPresentationController?.permittedArrowDirections = [.left]
        
        self.cameraMan.getVideoFromLibrary(withPresenter: self) { url in
            
            if let videoURL = url {
                print("YES we have the video url from the picker!!!! \(videoURL)")
                self.newMomentVideo.localURL = videoURL.absoluteString
                self.updateUI()
            }
        }
    }
    
    private func handleInterviewSubject(fromView sender: UIView)
    {
        let controller = UIAlertController(title: "Interviewee", message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up]
        
        let facebookAction = UIAlertAction(title: "Pick from Facebook", style: .default) { action in
            self.handleFacebookInterviewSelection()
        }
        controller.addAction(facebookAction)
        
        let manualAction = UIAlertAction(title: "Enter Manually", style: .default) { action in
            self.handleManualInterviewSelection()
        }
        controller.addAction(manualAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        self.present(controller, animated: true, completion: nil)
    }
    
    private func handleFacebookInterviewSelection()
    {
        print("Pick from Facebook")
        //make sure to use InterviewingCompletion to get the Subject
    }
    
    private func handleManualInterviewSelection()
    {
        self.performSegue(withIdentifier: Identifiers.Segues.ENTER_INTERVIEW_SUBJECT, sender: nil)
    }
    
    private func handleInterviewDescription()
    {
        self.performSegue(withIdentifier: Identifiers.Segues.ENTER_INTERVIEW_DESCRIPTION, sender: nil)
    }
    
    private func handleNoteCreation()
    {
        self.performSegue(withIdentifier: Identifiers.Segues.ENTER_NEW_NOTE, sender: nil)
    }
    
    private func interviewingSubjectCell(forSubject subject: Subject, withTableView tableView: UITableView) -> ImageTitleSubtitleCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_IMAGE_TITLE_SUBTITLE) as? ImageTitleSubtitleCell {
            cell.titleText = subject.name
            cell.subtitleText = subject.role
            cell.imageURL = subject.profileImageURL
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return ImageTitleSubtitleCell()
    }
    
    private func activeLinkCell(forSetting setting: NewMomentSetting, withTableView tableView: UITableView) -> ActiveLinkCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK) as? ActiveLinkCell {
            cell.activeLabel.text = setting.text
            cell.activeLinks = setting.activeLinks
            cell.detailDisclosureButton.isHidden = (setting == .video ? false : true)
            cell.delegate = self
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return ActiveLinkCell()
    }
    
    private func noteCell(forNote note: Note, withTableView tableView: UITableView) -> MITNoteCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_NOTE) as? MITNoteCell {
            cell.noteTextLabel.text = note.text
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return MITNoteCell()
    }
    
    private func updateUI()
    {
        let readyToSubmit = self.newMoment.subject?.name != nil
            && self.newMomentVideo.name != nil
            && self.newMomentVideo.videoDescription != nil
            && self.newMomentVideo.localURL != nil
        
        self.submitButton.isEnabled = readyToSubmit
    }
}

//
//  NewMomentController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Photos
import RealmSwift

private let COPY_TITLE_VIDEO_QUESTION_ALERT = "Camera shy? Don't worry."
private let COPY_MESSAGE_VIDEO_QUESTION_ALERT = "You don't have to get it first try. When you film a video, we'll save it to your camera roll so you can edit with your favorite tools. Upload a new video at any time before submitting."
private let COPY_TITLE_SAVE_CHANGES = "Save Changes?"
private let COPY_MESSAGE_SAVE_CHANGES = "Would you like to save this moment? You can always come back and edit it later."
private let COPY_TITLE_BUTTON_SAVE_CHANGES = "Save changes"

let COPY_TITLE_BUTTON_DELETE = "Delete"
let COPY_TITLE_BUTTON_SUBMIT = "Submit"
let COPY_TITLE_BUTTON_CANCEL = "Cancel"
let COPY_TITLE_BUTTON_OK = "OK"

private let COPY_TITLE_BUTTON_DONE = "Done"
private let COPY_TITLE_BUTTON_TRY_AGAIN = "Try Again"

private let COPY_TITLE_VIDEO_OPTIONS = "Video"
private let COPY_TITLE_NOTE_OPTIONS = "Note"

private let COPY_TITLE_INTERVIEWEE_OPTIONS = "Interviewee"
private let COPY_BUTTON_TITLE_MANUAL_ENTRY = "Enter Manually"
private let COPY_BUTTON_TITLE_FACEBOOK_ENTRY = "Select from Facebook"

private let COPY_TITLE_EDIT_VIDEO = "Edit Video"
private let COPY_TITLE_EDIT_VIDEO_ALERT = "Edit until your heart is content"
private let COPY_MESSAGE_EDIT_VIDEO_ALERT = "The video has been saved to your camera roll. You can edit the video with your favorite tools and update this Moment with the new video when you're ready. Nothing will be uploaded until you say so."
private let COPY_TITLE_BUTTON_REMOVE_VIDEO = "Delete Video"

typealias InterviewingCompletion = (UIImage?, _ name: String?, _ role: String?) -> Void
typealias TopicCompletion = (_ videoTitle: String, _ videoDescription: String, _ isCustom: Bool) -> Void
typealias NoteCompletion = (String?) -> Void

class NewMomentController: UIViewController, UITableViewDelegate, UITableViewDataSource, ActiveLinkCellDelegate, MITNoteCellDelegate, VideoPreviewCellDelegate
{
    @IBOutlet weak var submitButton: BouncingButton!
    @IBOutlet weak var cancelButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    
     var moment: Moment = {
        let newMoment = Moment()
            newMoment.subject = Subject()
            newMoment.video = Video()
            newMoment.notes.append(objectsIn: NewMomentSetting.defaultNotes)
        return newMoment
    }()
    
    var completion: NewMomentCompletion?
    
    private var cameraMan: CameraMan = {
        let cameraMan = CameraMan()
        cameraMan.maxVideoDurationMinutes = 20
        return cameraMan
    }()
    
    private enum Identifiers
    {
        static let IDENTIFIER_CELL_ACTIVE_LINK = "activeLinkCell"
        static let IDENTIFIER_CELL_IMAGE_TITLE_SUBTITLE = "imageTitleSubtitleCell"
        static let IDENTIFIER_CELL_VIDEO_PREVIEW = "videoPreviewCell"
        static let IDENTIFIER_CELL_NOTE = "noteCell"
        static let IDENTIFIER_VIEW_SECTION_HEADER = "sectionHeaderView"
        
        enum Segues
        {
            static let ENTER_INTERVIEW_SUBJECT = "newMomentToInterviewing"
            static let ENTER_INTERVIEW_TOPIC = "newMomentToTopic"
            static let EDIT_INTERVIEW_TOPIC = "newMomentToCreateTopic"
            static let ENTER_NEW_NOTE = "newMomentToNote"
            static let PLAY_VIDEO = "newMomentToPlayer"
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.configureInitialButtonStates()
        self.updateUI()
        self.setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if self.moment.momentStatus == .live {
            self.tableView.allowsSelection = false
        }
    }
    
//MARK: Actions
    
    @IBAction func handleSubmit(_ sender: BouncingButton)
    {
        let justCreated = self.moment.momentStatus == .new
        
        if justCreated {
            self.persistMoment()
        }
        
        self.presentingViewController?.dismiss(animated: true) {
            self.completion?(self.moment, justCreated, true)
        }
    }
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
        if self.moment.momentStatus == .new {
            
            let controller = UIAlertController(title: COPY_TITLE_SAVE_CHANGES, message: COPY_MESSAGE_SAVE_CHANGES, preferredStyle: .alert)
            
            let persistAction = UIAlertAction(title: COPY_TITLE_BUTTON_SAVE_CHANGES, style: .default) { action in
                self.presentingViewController?.dismiss(animated: true) {
                    self.persistMoment()
                    self.completion?(self.moment, true, false)
                }
            }
            controller.addAction(persistAction)
            
            let deleteAction = UIAlertAction(title: COPY_TITLE_BUTTON_DELETE, style: .destructive) { action in
                self.deleteMoment()
            }
            controller.addAction(deleteAction)
            
            self.present(controller, animated: true, completion: nil)
        }
        else {
            self.presentingViewController?.dismiss(animated: true) {
                self.completion?(self.moment, false, false)
            }
        }
    }
    
    private func persistMoment()
    {
        let momentToPersist = Moment()
        momentToPersist.create() //add To Realm then add properties:
        
        Moment.writeToRealm {
            momentToPersist.subject = self.moment.subject
            momentToPersist.video = self.moment.video
            momentToPersist.notes.append(objectsIn: self.moment.notes)
            
            if let topic = self.moment.topic {
                momentToPersist.topic = topic
            }
        }

        self.moment = momentToPersist
    }
    
    private func deleteMoment()
    {
        print("not saving moment")
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    

//MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard let id = segue.identifier else { return }
        
        switch id {
            
        case Identifiers.Segues.ENTER_INTERVIEW_SUBJECT:
            
            if let interviewingController = segue.destination.contentViewController as? InterviewingController {
                
                var isUpdating = false
                
                //pass along data if we have any:
                if let subject = self.moment.subject, subject.isValid {
                    interviewingController.profileImage = subject.profileImage
                    interviewingController.name = subject.name
                    interviewingController.role = subject.role
                    isUpdating = true
                }
                
                //set completionHandler:
                interviewingController.completion = { image, name, role in
                    self.handleInterviewingSubjectCompletion(withImage: image, name: name, role: role, isUpdating: isUpdating)
                }
            }
            
        case Identifiers.Segues.ENTER_INTERVIEW_TOPIC:
            
            if let topicController = segue.destination.contentViewController as? TopicController {
                
                let isUpdating = self.moment.topic != nil
                
                //set completionHandler:
                topicController.completion = { (videoTitle, videoDescription, isCustom) in
                    self.handleTopicCompletion(withVideoTitle: videoTitle, videoDescription: videoDescription, isCustom: isCustom, isUpdating: isUpdating)
                }
            }
            
        case Identifiers.Segues.EDIT_INTERVIEW_TOPIC:
            
            if let createTopicController = segue.destination.contentViewController as? CreateTopicController {
                
                //pass along data if we have any (we should):
                if let videoTitle = self.moment.topic?.title, let videoDescription = self.moment.topic?.topicDescription {
                    createTopicController.videoTitle = videoTitle
                    createTopicController.videoDescription = videoDescription
                }
                
                createTopicController.completion = { (videoTitle, videoDescription, isCustom) in
                    self.handleTopicCompletion(withVideoTitle: videoTitle, videoDescription: videoDescription, isCustom: true, isUpdating: true)
                }
            }
            
        case Identifiers.Segues.ENTER_NEW_NOTE:
            
            if let noteController = segue.destination.contentViewController as? NewNoteController {
                
                var isUpdating = false
                
                //pass along data if we have any:
                if let noteToUpdate = sender as? Note {
                    noteController.text = noteToUpdate.text
                    isUpdating = true
                }
                
                //set completionHandler:
                noteController.completion = { noteText in
                    self.handleNoteCompletion(withText: noteText, isUpdating: isUpdating)
                }
            }
            
        case Identifiers.Segues.PLAY_VIDEO:
            
            if let playerController = segue.destination as? AVPlayerViewController, let videoURL = sender as? URL {
                playerController.player = AVPlayer(url: videoURL)
                playerController.player?.play()
            }
            
        default:
            break
        }
    }
    
//MARK: UITableViewDelegate
    
    private func setupTableView()
    {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.contentInset.top = 12
        
        //setup sectionHeaderViews:
        self.tableView.register(UINib(nibName: String(describing: MITSectionHeaderView.self), bundle: nil), forHeaderFooterViewReuseIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER)
        self.tableView.estimatedSectionHeaderHeight = 44
        self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        self.tableView.sectionFooterHeight = 8
        
        //setup ActiveLinkCells:
        self.tableView.register(UINib(nibName: String(describing: ActiveLinkCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK)
        
        //setup ImageTitleSubtitleCells:
        self.tableView.register(UINib(nibName: String(describing: ImageTitleSubtitleCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_IMAGE_TITLE_SUBTITLE)
        
        //setup VideoPreviewCells:
        self.tableView.register(UINib(nibName: String(describing: VideoPreviewCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_VIDEO_PREVIEW)
        
        //setup NoteCells:
        self.tableView.register(UINib(nibName: String(describing: MITNoteCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_NOTE)
        
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    //In NewMomentSetting.notes, cell at row 0 is not a note cell (activeLinkCell) we need to subtract 1 from the index:
    private func note(forIndexPath indexPath: IndexPath) -> Note
    {
        return self.moment.notes[indexPath.row - 1]
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
        //If we have a localVideo we need VideoPreviewCell and editVideo activeLinkCell:
        if section == NewMomentSetting.video.rawValue {
            return self.moment.video?.isLocal ?? false ? 2 : 1
        }
        
        //Notes section must have all the notes + the top Add a new note activeLinkCell:
        if section == NewMomentSetting.notes.rawValue {
            return self.moment.notes.count + 1
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
            
            if let interviewingSubject = self.moment.subject, interviewingSubject.isValid {
                return self.interviewingSubjectCell(forSubject: interviewingSubject, withTableView: tableView)
            }
            
            return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            
        case NewMomentSetting.topic.rawValue:
            
            if let videoName = self.moment.video?.name, let videoDescription = self.moment.video?.videoDescription {
                return self.descriptionCell(forName: videoName, description: videoDescription, withTableView: tableView)
            }
            
            return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            
        case NewMomentSetting.video.rawValue:
            
            //first cell is videoPreview or activeLink
            if indexPath.row == 0 {
                if let video = self.moment.video, video.isLocal {
                    return self.videoPreviewCell(forVideo: video, withTableView: tableView)
                }
                
                return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            }
            else if indexPath.row == 1 {
                
                //if we have a second row it must be the editVideo activeLinkCell:
                if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK) as? ActiveLinkCell {
                    cell.shouldCenterLabel = true
                    cell.activeLabel.text = COPY_TITLE_EDIT_VIDEO
                    cell.activeLinks = [COPY_TITLE_EDIT_VIDEO]
                    cell.delegate = self
                    cell.detailDisclosureButton.isHidden = true
                    return cell
                }
                
                assert(false, "unknown cell dequeued")
                return UITableViewCell()
            }
            
            assert(false, "unknown row in Video section")
            return UITableViewCell()
            
        case NewMomentSetting.notes.rawValue:
            
            //first cell is activeLinkCell:
            if indexPath.row == 0 {
                return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            }
            
            //the rest of the cells are MITNoteCells:
            let note = self.note(forIndexPath: indexPath)
            return self.noteCell(forNote: note, withTableView: tableView)
            
        default:
            assert(false, "indexPath section is unknown")
            return UITableViewCell()
        }
    }
    
    //set this in didSelectRow...
    //make sure to nil it out after you use it in prepareForSegue:
    private var lastSelectedPath: IndexPath?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //only navigate if cell is not activeLink and not video:
        if tableView.cellForRow(at: indexPath) is ActiveLinkCell { return }
        
        self.lastSelectedPath = indexPath
        
        switch indexPath.section {
            
        case NewMomentSetting.interviewing.rawValue:
            self.performSegue(withIdentifier: Identifiers.Segues.ENTER_INTERVIEW_SUBJECT, sender: nil)
        
        case NewMomentSetting.topic.rawValue:
            if let momentTopic = self.moment.topic, momentTopic.isCustom {
                self.performSegue(withIdentifier: Identifiers.Segues.EDIT_INTERVIEW_TOPIC, sender: nil)
            }
            else {
                self.performSegue(withIdentifier: Identifiers.Segues.ENTER_INTERVIEW_TOPIC, sender: nil)
            }
            
        case NewMomentSetting.notes.rawValue:
            let note = self.note(forIndexPath: indexPath)
            self.performSegue(withIdentifier: Identifiers.Segues.ENTER_NEW_NOTE, sender: note)
        
        default:
            return
        }
    }
    
    //MARK: ActiveLinkCellDelegate:
    
    func activeLinkCell(_ activeLinkCell: ActiveLinkCell, handleSelection selection: String)
    {
        guard self.moment.momentStatus != .live else { return }
        
        switch selection {
        case COPY_SELECT_INTERVIEW_SUBJECT:
            self.handleInterviewSubject(fromView: activeLinkCell.activeLabel)
            
        case COPY_CREATE_TOPIC:
            self.handleInterviewTopic()
            
        case COPY_LINK_START_FILMING:
            self.handleVideoCamera()
            
        case COPY_LINK_UPLOAD_VIDEO:
            self.handlePhotos(fromView: activeLinkCell.detailDisclosureButton)
            
        case COPY_CREATE_NOTE:
            self.handleNoteCreation()
            
        case COPY_TITLE_EDIT_VIDEO:
            self.handleEditVideo()
            
        default:
            break
        }
    }
    
    func activeLinkCell(_ activeLinkCell: ActiveLinkCell, detailDisclosureButtonTapped sender: UIButton)
    {
        guard self.moment.momentStatus != .live else { return }
        
        if self.tableView.cellForRow(at: IndexPath(row: 0, section: NewMomentSetting.video.rawValue)) == activeLinkCell {
            UIAlertController.explain(withPresenter: self, title: COPY_TITLE_VIDEO_QUESTION_ALERT, message: COPY_MESSAGE_VIDEO_QUESTION_ALERT)
        }
    }
    
    //MARK: MITNoteCellDelegate
    
    func noteCell(_ noteCell: MITNoteCell, handleOptions sender: BouncingButton)
    {
        guard let note = noteCell.note, self.moment.momentStatus != .live else { return }
        
        UIAlertController.showDeleteSheet(withPresenter: self, sender: sender, title: nil, itemToDeleteTitle: COPY_TITLE_NOTE_OPTIONS) { action in
            self.deleteNote(note)
        }
    }
    
    private func deleteNote(_ note: Note)
    {
        if self.moment.notes.contains(note), let indexToDelete = self.moment.notes.index(of: note) {
            
            Moment.writeToRealm {
                self.moment.notes.remove(objectAtIndex: indexToDelete)
                let pathToDelete = IndexPath(row: indexToDelete + 1, section: NewMomentSetting.notes.rawValue)
                self.tableView.removeRows(forIndexPaths: [pathToDelete])
            }
        }
    }
    
    //MARK: VideoPreviewCellDelegate
    
    func videoPreviewCell(_ videoPreviewCell: VideoPreviewCell, handlePlay video: Video)
    {
        guard let url = video.localPlaybackURL else { return }
        self.performSegue(withIdentifier: Identifiers.Segues.PLAY_VIDEO, sender: url)
    }
    
    func videoPreviewCell(_ videoPreviewCell: VideoPreviewCell, handleOptions sender: BouncingButton)
    {
        guard let video = videoPreviewCell.video, self.moment.momentStatus != .live else { return }
        
        UIAlertController.showDeleteSheet(withPresenter: self, sender: sender, title: nil, itemToDeleteTitle: COPY_TITLE_VIDEO_OPTIONS) { action in
            self.deleteVideo(video)
        }
    }
    
    private func deleteVideo(_ video: Video)
    {
        Moment.writeToRealm {
            
            //delete local thumbnailImage:
            if let localRelativeImageURLString = video.localThumbnailImageURL {
                Assistant.removeImageFromDisk(atRelativeURLString: localRelativeImageURLString)
                video.localThumbnailImageURL = nil
                video.localThumbnailImage = nil
            }
            
            //delete local video:
            if let localRelativeVideoURLString = video.localURL {
                Assistant.removeVideoFromDisk(atRelativeURLString: localRelativeVideoURLString)
                video.localURL = nil
            }
            
            let videoPath = IndexPath(row: 0, section: NewMomentSetting.video.rawValue)
            let editVideoPath = IndexPath(row: 1, section: NewMomentSetting.video.rawValue)
            self.tableView.removeRows(forIndexPaths: [editVideoPath])
            self.tableView.refreshRows(forIndexPaths: [videoPath])
        }
    }
    
    //MARK: Utilities:
    
    private func handleInterviewingSubjectCompletion(withImage image: UIImage?, name: String?, role: String?, isUpdating: Bool)
    {
        Moment.writeToRealm {
            if let newProfileImage = image {
                self.moment.subject?.profileImage = newProfileImage
                self.moment.subject?.profileImageURL = Assistant.persistImage(newProfileImage, compressionQuality: 0.2, atRelativeURLString: self.moment.subject?.profileImageURL)
                print("\nJust persisted and compressed profile image")
            }
            
            self.moment.subject?.name = name
            self.moment.subject?.role = role
            
            //animate interviewingSubject cell in:
            let newPath = IndexPath(row: 0, section: NewMomentSetting.interviewing.rawValue)
            
            if isUpdating {
                self.tableView.updateRows(forIndexPaths: [newPath])
            }
            else {
                self.tableView.refreshRows(forIndexPaths: [newPath])
            }
        }
        
        self.updateUI()
    }
    
    private func handleTopicCompletion(withVideoTitle videoTitle: String, videoDescription: String, isCustom: Bool, isUpdating: Bool)
    {
        Moment.writeToRealm {
            self.moment.video?.name = videoTitle
            self.moment.video?.videoDescription = videoDescription
            self.moment.topic = Topic(title: videoTitle, description: videoDescription)
            self.moment.topic?.isCustom = isCustom
            
            //animate TitleDescription cell in:
            let newPath = IndexPath(row: 0, section: NewMomentSetting.topic.rawValue)
            
            if isUpdating {
                self.tableView.updateRows(forIndexPaths: [newPath])
            }
            else {
                self.tableView.refreshRows(forIndexPaths: [newPath])
            }
        }
        
        self.updateUI()
    }
    
    private func handleNoteCompletion(withText noteText: String?, isUpdating: Bool)
    {
        Moment.writeToRealm {
            if isUpdating {
                if let path = self.lastSelectedPath {
                    self.note(forIndexPath: path).text = noteText
                    self.tableView.updateRows(forIndexPaths: [path])
                    self.lastSelectedPath = nil
                }
            }
            else {
                if let newNoteText = noteText {
                    let newNote = Note(withText: newNoteText)
                    self.moment.notes.insert(newNote, at: 0)
                    let newPath = IndexPath(row: 1, section: NewMomentSetting.notes.rawValue)
                    self.tableView.insertNewRows(forIndexPaths: [newPath])
                }
            }
        }
    }
    
    private func handleVideoCamera()
    {
        //we need to check Photos permission before user starts filming so that we can persist the video to their photo library:
        PHPhotoLibrary.verifyAuthorization(authorizedHandler: { 
            
            self.cameraMan.getVideoFromCamera(withPresenter: self) { url in
                
                if let videoURL = url {
                    self.updateWithVideoURL(videoURL)
                    
                    //persist the url to user's Photos:
                    self.cameraMan.saveVideoURLToPhotos(videoURL, withPresenter: self)
                }
            }
            
        }, notAuthorizedHandler: {
            UIAlertController.alertUser(withPresenter: self, title: COPY_TITLE_ALERT, message: COPY_DENIED_PHOTO_LIBRARY_ACCESS_MESSAGE, okButton: true, settingsButton: true)
        })
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
                self.updateWithVideoURL(videoURL)
            }
        }
    }
    
    private func handleInterviewSubject(fromView sender: UIView)
    {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up]
        
        let facebookAction = UIAlertAction(title: COPY_BUTTON_TITLE_FACEBOOK_ENTRY, style: .default) { action in
            self.handleFacebookInterviewSelection()
        }
        controller.addAction(facebookAction)
        
        let manualAction = UIAlertAction(title: COPY_BUTTON_TITLE_MANUAL_ENTRY, style: .default) { action in
            self.handleManualInterviewSelection()
        }
        controller.addAction(manualAction)
        
        let cancelAction = UIAlertAction(title: COPY_TITLE_BUTTON_CANCEL, style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        self.present(controller, animated: true, completion: nil)
    }
    
    private func handleFacebookInterviewSelection()
    {
        print("Select from Facebook")
        
        //make sure to use InterviewingCompletion to get the Subject
        let comingSoon = ComingSoonAlertView()
        comingSoon.showFrom(viewController: self) { 
            print("coming soon!")
        }
    }
    
    private func handleManualInterviewSelection()
    {
        self.performSegue(withIdentifier: Identifiers.Segues.ENTER_INTERVIEW_SUBJECT, sender: nil)
    }
    
    private func handleInterviewTopic()
    {
        self.performSegue(withIdentifier: Identifiers.Segues.ENTER_INTERVIEW_TOPIC, sender: nil)
    }
    
    private func handleNoteCreation()
    {
        self.performSegue(withIdentifier: Identifiers.Segues.ENTER_NEW_NOTE, sender: nil)
    }
    
    private func handleEditVideo()
    {
        let controller = UIAlertController(title: COPY_TITLE_EDIT_VIDEO_ALERT, message: COPY_MESSAGE_EDIT_VIDEO_ALERT, preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: COPY_TITLE_BUTTON_REMOVE_VIDEO, style: .destructive) { action in
            
            guard let video = self.moment.video, video.isLocal else { return }
            
            self.deleteVideo(video)
        }
        controller.addAction(deleteAction)
        
        let okAction = UIAlertAction(title: COPY_TITLE_BUTTON_OK, style: .cancel, handler: nil)
        controller.addAction(okAction)
        
        self.present(controller, animated: true, completion: nil)
        
    }
    
    private func interviewingSubjectCell(forSubject subject: Subject, withTableView tableView: UITableView) -> ImageTitleSubtitleCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_IMAGE_TITLE_SUBTITLE) as? ImageTitleSubtitleCell {
            cell.titleText = subject.name
            cell.subtitleText = subject.role
            cell.roundImage = subject.profileImage
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return ImageTitleSubtitleCell()
    }
    
    private func descriptionCell(forName name: String, description: String, withTableView tableView: UITableView) -> ImageTitleSubtitleCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_IMAGE_TITLE_SUBTITLE) as? ImageTitleSubtitleCell {
            cell.titleText = name
            cell.subtitleText = description
            cell.roundImage = nil
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return ImageTitleSubtitleCell()
    }
    
    private func videoPreviewCell(forVideo video: Video, withTableView tableView: UITableView) -> VideoPreviewCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_VIDEO_PREVIEW) as? VideoPreviewCell {
            cell.video = video
            cell.delegate = self
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return VideoPreviewCell()
    }
    
    private func activeLinkCell(forSetting setting: NewMomentSetting, withTableView tableView: UITableView) -> ActiveLinkCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK) as? ActiveLinkCell {
            cell.shouldCenterLabel = false
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
            cell.note = note
            cell.delegate = self
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return MITNoteCell()
    }
    
    private func updateVideoSection()
    {
        let videoPath = IndexPath(row: 0, section: NewMomentSetting.video.rawValue)
        let editVideoPath = IndexPath(row: 1, section: NewMomentSetting.video.rawValue)
        self.tableView.insertNewRows(forIndexPaths: [editVideoPath])
        self.tableView.refreshRows(forIndexPaths: [videoPath])
    }
    
    private func configureInitialButtonStates()
    {
        let status = self.moment.momentStatus
        
        let submitButtonTitle = status == .uploadFailed ? COPY_TITLE_BUTTON_TRY_AGAIN : COPY_TITLE_BUTTON_SUBMIT
        self.submitButton.setTitle(submitButtonTitle, for: .normal)
        self.submitButton.isHidden = status == .uploading || status == .processing || status == .live
        self.submitButton.isEnabled = status == .uploadFailed
        
        let cancelButtonTitle = status == .new ? COPY_TITLE_BUTTON_CANCEL : COPY_TITLE_BUTTON_DONE
        self.cancelButton.setTitle(cancelButtonTitle, for: .normal)
        self.cancelButton.isHidden = false
    }
    
    private func updateUI()
    {
        self.submitButton.isEnabled = self.moment.isReadyToSubmit
    }
    
    private let assistant = Assistant()
    
    private func updateWithVideoURL(_ url: URL)
    {
        guard let video = self.moment.video else { return }
        
        self.assistant.copyVideo(withURL: url) { newURL in
            Moment.writeToRealm {
                video.localURL = newURL
            }
        }
        
        //generate video preview thumbnail image asynchronously:
        self.getThumbnailImage(forVideoURL: url) { thumbnailImage in
            
            video.localThumbnailImage = thumbnailImage
            
            if let videoPreviewImage = video.localThumbnailImage,
                let imageURL = Assistant.persistImage(videoPreviewImage, compressionQuality: 0.5, atRelativeURLString: video.localThumbnailImageURL) {
                Moment.writeToRealm {
                    video.localThumbnailImageURL = imageURL
                    self.updateVideoSection()
                    self.updateUI()
                }
            }
        }
        
        self.updateUI()
    }

    private func getThumbnailImage(forVideoURL url: URL, completion: @escaping (UIImage?) -> Void)
    {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true //so that the image is not rotated in portrait
        
        //get 1st frame:
        imageGenerator.generateCGImagesAsynchronously(forTimes: [CMTimeMake(1, 60) as NSValue]) { (requestedTime, image, actualTime, result, error) in
            
            DispatchQueue.main.async {
                guard let responseImage = image else {
                    completion(nil)
                    return
                }
                
                let newImage = UIImage(cgImage: responseImage)
                completion(newImage)
            }
        }
    }
}

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

typealias InterviewingCompletion = (Subject) -> Void
typealias DescriptionCompletion = (_ name: String, _ description: String) -> Void
typealias NoteCompletion = (Note) -> Void

class NewMomentController: UIViewController, UITableViewDelegate, UITableViewDataSource, ActiveLinkCellDelegate, MITNoteCellDelegate, VideoPreviewCellDelegate
{
    @IBOutlet weak var submitButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    
    private lazy var moment: Moment = {
        let newMoment = Moment()
        newMoment.subject = Subject()
        newMoment.video = Video()
        
        if let realm = try? Realm() {
            try? realm.write {
                newMoment.notes.append(objectsIn: NewMomentSetting.defaultNotes)
            }
        }
        
        return newMoment
    }()
    
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
            static let ENTER_INTERVIEW_DESCRIPTION = "newMomentToDescription"
            static let ENTER_NEW_NOTE = "newMomentToNote"
            static let PLAY_VIDEO = "newMomentToPlayer"
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.submitButton.isEnabled = false
        self.setupTableView()
        
        //make sure moment is fully loaded...
    }
    
//MARK: Actions
    
    @IBAction func handleSubmit(_ sender: BouncingButton)
    {
        print("handle Submit: \(self.moment)")
        
        if let realm = try? Realm() {
            if realm.isEmpty {
                print("\nrealm is empty")
            }
        }
    }
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
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
                    interviewingController.interviewSubject = subject
                    isUpdating = true
                }
                
                //set completionHandler:
                interviewingController.completion = { interviewSubject in
                    self.handleInterviewingSubjectCompletion(withSubject: interviewSubject, isUpdating: isUpdating)
                }
            }
            
        case Identifiers.Segues.ENTER_INTERVIEW_DESCRIPTION:
            
            if let descriptionController = segue.destination.contentViewController as? DescriptionController {
                
                var isUpdating = false
                
                //pass along data if we have any:
                if let videoTitle = self.moment.video?.name, let videoDescription = self.moment.video?.videoDescription {
                    descriptionController.videoTitle = videoTitle
                    descriptionController.videoDescription = videoDescription
                    isUpdating = true
                }
                
                //set completionHandler:
                descriptionController.completion = { (videoTitle, videoDescription) in
                    self.handleDescriptionCompletion(withVideoTitle: videoTitle, videoDescription: videoDescription, isUpdating: isUpdating)
                }
            }
            
        case Identifiers.Segues.ENTER_NEW_NOTE:
            
            if let noteController = segue.destination.contentViewController as? NewNoteController {
                
                var isUpdating = false
                
                //pass along data if we have any:
                if let noteToUpdate = sender as? Note {
                    noteController.note = noteToUpdate
                    isUpdating = true
                }
                
                //set completionHandler:
                noteController.completion = { note in
                    self.handleNoteCompletion(withNote: note, isUpdating: isUpdating)
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
        self.tableView.estimatedSectionHeaderHeight = 64
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
            
        case NewMomentSetting.description.rawValue:
            
            if let videoName = self.moment.video?.name, let videoDescription = self.moment.video?.videoDescription {
                return self.descriptionCell(forName: videoName, description: videoDescription, withTableView: tableView)
            }
            
            return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            
        case NewMomentSetting.video.rawValue:
            
            if let video = self.moment.video, video.localURL != nil {
                return self.videoPreviewCell(forVideo: video, withTableView: tableView)
            }
            
            return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            
        case NewMomentSetting.notes.rawValue:
            
            //first cell is activeLinkCell:
            if indexPath.row == 0 {
                return self.activeLinkCell(forSetting: setting, withTableView: tableView)
            }
            
            //the rest of the cells are MITNoteCells:
            //but since cell at row 0 is not a note cell (activeLinkCell) we need to subtract 1 from the index:
            let note = self.moment.notes[indexPath.row - 1]
            return self.noteCell(forNote: note, withTableView: tableView)
            
        default:
            assert(false, "indexPath section is unknown")
            return UITableViewCell()
        }
    }
    
    //set this in didSelectRow...
    //make sure to nil it out after you use it in the prepareForSegue:
    private var lastSelectedPath: IndexPath?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //only navigate if cell is not activeLink and not video:
        if tableView.cellForRow(at: indexPath) is ActiveLinkCell { return }
        
        self.lastSelectedPath = indexPath
        
        switch indexPath.section {
        case NewMomentSetting.interviewing.rawValue:
            self.performSegue(withIdentifier: Identifiers.Segues.ENTER_INTERVIEW_SUBJECT, sender: nil)
        
        case NewMomentSetting.description.rawValue:
            self.performSegue(withIdentifier: Identifiers.Segues.ENTER_INTERVIEW_DESCRIPTION, sender: nil)
        
        case NewMomentSetting.notes.rawValue:
            let note = self.moment.notes[indexPath.row - 1]
            self.performSegue(withIdentifier: Identifiers.Segues.ENTER_NEW_NOTE, sender: note)
        
        default:
            return
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
    
    func activeLinkCell(_ activeLinkCell: ActiveLinkCell, detailDisclosureButtonTapped sender: UIButton)
    {
        if self.tableView.cellForRow(at: IndexPath(row: 0, section: NewMomentSetting.video.rawValue)) == activeLinkCell {
            UIAlertController.explain(withPresenter: self, title: COPY_TITLE_VIDEO_QUESTION_ALERT, message: COPY_MESSAGE_VIDEO_QUESTION_ALERT)
        }
    }
    
    //MARK: MITNoteCellDelegate
    
    func noteCell(_ noteCell: MITNoteCell, handleOptions sender: BouncingButton)
    {
        guard let note = noteCell.note else { return }
        
        let controller = UIAlertController(title: "Note", message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { action in
            self.deleteNote(note)
        }
        controller.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        self.present(controller, animated: true, completion: nil)
    }
    
    private func deleteNote(_ note: Note)
    {
        if self.moment.notes.contains(note), let indexToDelete = self.moment.notes.index(of: note) {
            
            self.writeToRealm {
                self.moment.notes.remove(objectAtIndex: indexToDelete)
                let pathToDelete = IndexPath(row: indexToDelete + 1, section: NewMomentSetting.notes.rawValue)
                self.tableView.removeRows(forIndexPaths: [pathToDelete])
            }
        }
    }
    
    //MARK: VideoPreviewCellDelegate
    
    func videoPreviewCell(_ videoPreviewCell: VideoPreviewCell, handlePlay video: Video)
    {
        guard let urlString = video.localURL else { return }
        
        if let url = URL(string: urlString) {
            self.performSegue(withIdentifier: Identifiers.Segues.PLAY_VIDEO, sender: url)
        }
    }
    
    func videoPreviewCell(_ videoPreviewCell: VideoPreviewCell, handleOptions sender: BouncingButton)
    {
        guard let video = videoPreviewCell.video else { return }
        
        let controller = UIAlertController(title: "Video", message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { action in
            self.deleteVideo(video)
        }
        controller.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        self.present(controller, animated: true, completion: nil)
    }
    
    private func deleteVideo(_ video: Video)
    {
        video.localURL = nil
        let pathToDelete = IndexPath(row: 0, section: NewMomentSetting.video.rawValue)
        self.tableView.refreshRows(forIndexPaths: [pathToDelete])
    }
    
    //MARK: Utilities:
    
    private func handleInterviewingSubjectCompletion(withSubject subject: Subject, isUpdating: Bool)
    {
        self.writeToRealm {
            if let newProfileImage = subject.profileImage {
                subject.profileImageURL = self.persistImage(newProfileImage)?.absoluteString
            }
            
            self.moment.subject = subject
            
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
    
    private func handleDescriptionCompletion(withVideoTitle videoTitle: String, videoDescription: String, isUpdating: Bool)
    {
        self.writeToRealm {
            self.moment.video?.name = videoTitle
            self.moment.video?.videoDescription = videoDescription
            
            //animate TitleDescription cell in:
            let newPath = IndexPath(row: 0, section: NewMomentSetting.description.rawValue)
            
            if isUpdating {
                self.tableView.updateRows(forIndexPaths: [newPath])
            }
            else {
                self.tableView.refreshRows(forIndexPaths: [newPath])
            }
        }
        
        self.updateUI()
    }
    
    private func handleNoteCompletion(withNote note: Note, isUpdating: Bool)
    {
        self.writeToRealm {
            if isUpdating {
                if let path = self.lastSelectedPath {
                    self.moment.notes[path.row - 1] = note
                    self.tableView.updateRows(forIndexPaths: [path])
                    self.lastSelectedPath = nil
                }
            }
            else {
                self.moment.notes.insert(note, at: 0)
                let newPath = IndexPath(row: 1, section: NewMomentSetting.notes.rawValue)
                self.tableView.insertNewRows(forIndexPaths: [newPath])
            }
        }
    }
    
    //modify objects and perform any UI updates in handler:
    private func writeToRealm(withHandler handler: () -> Void)
    {
        if let realm = try? Realm() {
            realm.beginWrite()
            handler()
            try? realm.commitWrite()
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
    
    private func updateVideoRow()
    {
        let newPath = IndexPath(row: 0, section: NewMomentSetting.video.rawValue)
        self.tableView.refreshRows(forIndexPaths: [newPath])
    }
    
    private func updateUI()
    {
        let readyToSubmit = self.moment.subject?.name != nil
            && self.moment.video?.name != nil
            && self.moment.video?.videoDescription != nil
            && self.moment.video?.localURL != nil
        
        self.submitButton.isEnabled = readyToSubmit
    }
    
    private func loadImageFromDisk(withUrlString urlString: String) -> UIImage?
    {
        if let imageURL = URL(string: urlString),
            let imageData = try? Data.init(contentsOf: imageURL, options: []) {
            return UIImage(data: imageData)
        }
        
        return nil
    }
    
    private func persistImage(_ image: UIImage) -> URL?
    {
        var imageFileName: URL
        
        //if we have previously saved an image we want to overwrite it:
        if let urlString = self.moment.subject?.profileImageURL, let imageFile = URL(string: urlString) {
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
    
    private func updateWithVideoURL(_ url: URL)
    {
        guard let video = self.moment.video else { return }
        
        video.localURL = url.absoluteString
        video.localThumbnailImage = self.thumbnailImage(forVideo: video)
        
        self.updateVideoRow()
        self.updateUI()
    }
    
    fileprivate func thumbnailImage(forVideo video: Video) -> UIImage?
    {
        guard let urlString = video.localURL, let assetURL = URL(string: urlString) else {
            return nil
        }
        
        //otherwise generate a thumbnail image for the video:
        let asset = AVAsset(url: assetURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true //so that the image is not rotated in portrait
        
        //get 1st frame:
        if let thumbnailCGImage = try? imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil) {
            let newImage = UIImage(cgImage: thumbnailCGImage)
            return newImage
        }
        
        return nil
    }
}

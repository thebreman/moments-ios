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

private let COPY_TITLE_ALERT = "Oh No!"
private let COPY_DENIED_PHOTO_LIBRARY_ACCESS_MESSAGE = "We need permission to access your Photos, please change privacy settings."
private let COPY_DENIED_CAMERA_ACCESS_MESSAGE = "We need permission to use the Camera and the Microphone, please change privacy settings."
private let COPY_CAMERA_UNAVAILABLE_MESSAGE = "It looks like the Video Camera is unavailable. You can upload a video from you Photos Library instead."
private let COPY_VIDEO_MEDIA_TYPE_UNAVAILABLE_PHOTO_LIBRARY_MESSAGE = "There are no available videos in your Photo Library."

private let DURATION_MAX_VIDEO_MINUTES = 20

class NewMomentController: UIViewController, UITableViewDelegate, UITableViewDataSource, ActiveLinkCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    @IBOutlet weak var submitButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    
    private enum Identifiers
    {
        static let IDENTIFIER_CELL_ACTIVE_LINK = "activeLink"
        static let IDENTIFIER_CELL_NOTE = "note"
        static let IDENTIFIER_VIEW_SECTION_HEADER = "sectionHeaderView"
    }
    
    private var maxVideoDuration: TimeInterval {
        let minute: TimeInterval = 60.0
        let seconds: TimeInterval = Double(DURATION_MAX_VIDEO_MINUTES) * minute
        return seconds
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
        self.tableView.sectionFooterHeight = 0
        
        //setup ActiveLinkCells:
        self.tableView.register(UINib(nibName: String(describing: ActiveLinkCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK)
        
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
            
        case NewMomentSetting.interviewing.rawValue, NewMomentSetting.description.rawValue, NewMomentSetting.video.rawValue:
            
            //all activeLinkCells:
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
            print("select interview subject")
            break
            
        case COPY_CREATE_DESCRIPTION:
            print("create description")
            break
            
        case COPY_LINK_START_FILMING:
            self.openCamera(fromView: activeLinkCell.activeLabel)
            
        case COPY_LINK_UPLOAD_VIDEO:
            self.openPhotos(fromView: activeLinkCell.detailDisclosureButton)
            
        case COPY_CREATE_NOTE:
            print("add note")
            break
            
        default:
            break
        }
    }
    
    //MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        print("user just selected a video")
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Utilities:
    
    private func openCamera(fromView sender: UIView)
    {
        let sourceType = UIImagePickerControllerSourceType.camera
        let mediaType = kUTTypeMovie as String
        
        //check that we have a camera that can record video and verify mediaType:
        guard UIImagePickerController.isSourceTypeAvailable(sourceType),
            let mediaTypes = UIImagePickerController.availableMediaTypes(for: sourceType),
            mediaTypes.contains(mediaType) else {
                UIAlertController.explain(withPresenter: self, title: COPY_TITLE_ALERT, message: COPY_CAMERA_UNAVAILABLE_MESSAGE)
                return
        }
        
        AVCaptureDevice.verifyVideoAndAudioAuthorization(authorizedHandler: {
            
            self.showImagePicker(forSourceType: sourceType, mediaTypes: [mediaType], fromView: sender)
            
        }, notAuthorizedHandler: {
            
            UIAlertController.alertUser(withPresenter: self, title: COPY_TITLE_ALERT, message: COPY_DENIED_CAMERA_ACCESS_MESSAGE, okButton: true, settingsButton: true)
        })
    }
    
    private func openPhotos(fromView sender: UIView)
    {
        let sourceType = UIImagePickerControllerSourceType.photoLibrary
        let mediaType = kUTTypeMovie as String
        
        //verify mediaType:
        guard let mediaTypes = UIImagePickerController.availableMediaTypes(for: sourceType), mediaTypes.contains(mediaType) else {
            UIAlertController.explain(withPresenter: self, title: COPY_TITLE_ALERT, message: COPY_VIDEO_MEDIA_TYPE_UNAVAILABLE_PHOTO_LIBRARY_MESSAGE)
            return
        }
        
        //verify Photo Library authorization and proceed accordingly:
        PHPhotoLibrary.verifyAuthorization(authorizedHandler: {
            
            self.showImagePicker(forSourceType: .photoLibrary, mediaTypes: [mediaType], fromView: sender)

        }, notAuthorizedHandler: {
            
            UIAlertController.alertUser(withPresenter: self, title: COPY_TITLE_ALERT, message: COPY_DENIED_PHOTO_LIBRARY_ACCESS_MESSAGE, okButton: true, settingsButton: true)
        })
    }
    
    private func showImagePicker(forSourceType sourceType: UIImagePickerControllerSourceType, mediaTypes: [String], fromView sender: UIView)
    {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = sourceType
        pickerController.mediaTypes = mediaTypes
        pickerController.allowsEditing = true
        pickerController.delegate = self
        
        //for photoLibrary sourceType, iPad must use popover (for camera it should be fullscreeen).
        //on iPhone, default popover adapts to modal fullscreen automatically:
        pickerController.modalPresentationStyle = (sourceType == .camera ? .fullScreen : .popover)
        
        let presentationController = pickerController.popoverPresentationController
        presentationController?.sourceView = sender
        presentationController?.sourceRect = CGRect(origin: CGPoint(x: sender.bounds.midX, y: sender.bounds.minY), size: sender.bounds.size)
        presentationController?.permittedArrowDirections = [.left]
        
        self.present(pickerController, animated: true, completion: nil)
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
}

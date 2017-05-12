//
//  TopicController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/11/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class TopicController: UIViewController, UITableViewDelegate, UITableViewDataSource, ActiveLinkCellDelegate
{
    @IBOutlet weak var tableView: UITableView!
    
    var videoTitle = String()
    var videoDescription = String()
    
    private lazy var topics: [Topic] = {
        if let cachedTopics = Topic.topicsFromJSON() {
            return cachedTopics
        }
        else {
            return [Topic]()
        }
    }()
    
    var completion: TopicCompletion?
    
    private enum Identifiers
    {
        static let IDENTIFIER_CELL_ACTIVE_LINK = "activeLinkCell"
        static let IDENTIFIER_CELL_IMAGE_TITLE_SUBTITLE = "imageTitleSubtitleCell"
        static let SEGUE_CREATE_TOPIC = "createTopic"
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setupTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard let identifier = segue.identifier else { return }
        
        if identifier == Identifiers.SEGUE_CREATE_TOPIC {
            
            //pass along the completion handler:
            if let createTopicController = segue.destination.contentViewController as? CreateTopicController {
                createTopicController.completion = self.completion
                createTopicController.shouldDismissTwice = true
            }
        }
    }
    
    //MARK: Actions
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    //MARK: UITableViewDelegate
    
    private func setupTableView()
    {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        //setup ActiveLinkCells:
        self.tableView.register(UINib(nibName: String(describing: ActiveLinkCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK)
        
        //setup ImageTitleSubtitleCells:
        self.tableView.register(UINib(nibName: String(describing: ImageTitleSubtitleCell.self), bundle: nil), forCellReuseIdentifier: Identifiers.IDENTIFIER_CELL_IMAGE_TITLE_SUBTITLE)
        
        self.tableView.estimatedRowHeight = 200
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.topics.count + 1 //for the activeLinkCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        switch indexPath.row {
        case 0:
            return self.activeLinkCellForHeader()
        
        default:
            let topic = self.topics[indexPath.row - 1]
            return self.topicCell(forTopic: topic)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let selectedTopic = self.topics[indexPath.row - 1]
        self.presentingViewController?.dismiss(animated: true) {
            self.completion?(selectedTopic.title, selectedTopic.topicDescription, false)
        }
    }
    
    //MARK: ActiveLinkCellDelegate
    
    func activeLinkCell(_ activeLinkCell: ActiveLinkCell, handleSelection selection: String)
    {
        if selection == COPY_LINK_MAKE_YOUR_OWN {
            self.handleCreateMoment()
        }
    }
    
    func activeLinkCell(_ activeLinkCell: ActiveLinkCell, detailDisclosureButtonTapped sender: UIButton)
    {
        //do nothing... we don't have one of these buttons...
    }
    
    //probably are going to want to pass along the completion as sender
    private func handleCreateMoment()
    {
        self.performSegue(withIdentifier: Identifiers.SEGUE_CREATE_TOPIC, sender: nil)
    }
    
    //MARK: Utilities
    
    private func activeLinkCellForHeader() -> ActiveLinkCell
    {
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_ACTIVE_LINK) as? ActiveLinkCell {
            cell.activeLabel.text = TopicSectionHeader.text
            cell.activeLabel.textColor = UIColor.mitText
            cell.activeLinks = TopicSectionHeader.activeLinks
            cell.detailDisclosureButton.isHidden = true
            cell.delegate = self
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return ActiveLinkCell()
    }
    
    private func topicCell(forTopic topic: Topic) -> ImageTitleSubtitleCell
    {
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: Identifiers.IDENTIFIER_CELL_IMAGE_TITLE_SUBTITLE) as? ImageTitleSubtitleCell {
            cell.titleText = topic.title
            cell.subtitleText = topic.topicDescription
            cell.roundImage = nil
            return cell
        }
        
        assert(false, "dequeued cell was of unknown type")
        return ImageTitleSubtitleCell()
    }
}

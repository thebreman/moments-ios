//
//  NewNoteController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/26/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let MAX_CHARACTERS_NOTE = 300

class NewNoteController: UIViewController, UITextViewDelegate, KeyboardMover
{
    @IBOutlet weak var saveButton: BouncingButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.saveButton.isEnabled = false
        self.listenForKeyboardNotifications(shouldListen: true)
        self.textView.contentInset.bottom = 8.0
        self.textView.becomeFirstResponder()
        self.textView.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.listenForKeyboardNotifications(shouldListen: false)
    }
    
    //MARK: Actions
    
    @IBAction func handleSave(_ sender: BouncingButton)
    {
        print("save new note")
        
        //persist the new note then:
        self.textView.endEditing(true)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
        self.textView.endEditing(true)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    //MARK: UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        let totalPotentialCharacters = textView.text.characters.count + (text.characters.count - range.length)
        self.saveButton.isEnabled = totalPotentialCharacters > 0
        return totalPotentialCharacters <= MAX_CHARACTERS_NOTE
    }
    
    //MARK; KeyboardMover
    
    func keyboardMoved(notification: Notification)
    {
        self.view.layoutIfNeeded() //update pending layout changes then animate:
        
        UIView.animateWithKeyboardNotification(notification: notification) { (keyboardHeight, keyboardWindowY) in

            self.textViewBottomConstraint.constant = keyboardHeight
            self.view.layoutIfNeeded()
        }
    }
}

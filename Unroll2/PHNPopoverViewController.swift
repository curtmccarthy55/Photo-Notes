//
//  PHNPopoverViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/3/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

protocol PHNPopoverDelegate: class {
    func editTappedForIndexPath(_ indexPath: IndexPath)
}

class PHNPopoverViewController: UIViewController {
    //MARK: - Properties
    weak var delegate: PHNPopoverDelegate?
    var name: String?
    var note: String?
    var indexPath: IndexPath?
    
    //MARK: - Outlets
    @IBOutlet private weak var lblName: UILabel!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var btnEdit: UIButton!

    //MARK: - Set Up
    
    override func viewDidLoad() {
        super.viewDidLoad()

        lblName.text = name
        
        if let cNote = note, cNote.isEmpty {
            textView.text = "No album note created."
        } else {
            textView.text = note
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView.setContentOffset(.zero, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if name == "Favorites" {
            btnEdit.isHidden = true
        }
        
        let fixedWidth: CGFloat = 300
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: CGFloat(fmaxf(Float(newSize.width), Float(fixedWidth))), height: newSize.height - 10.0)
        textView.frame = newFrame
        
        let fontDic = [ NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17.0) ]
        var titleSize: CGFloat = 0.0
        if name != nil {
            titleSize = name!.boundingRect(with: CGSize(width: 240.0, height: 2000.0), options: .usesLineFragmentOrigin, attributes: fontDic, context: nil).size.height
        }
        let textViewHeight = textView.bounds.size.height
        let height = titleSize + textViewHeight + 24.0
        
        if height > 300.0 {
            textView.isScrollEnabled = true
            preferredContentSize = CGSize(width: 300.0, height: 330.0)
        } else {
            preferredContentSize = CGSize(width: 300.0, height: height)
        }
    }
    
    @IBAction func btnEditAction() {
        delegate?.editTappedForIndexPath(indexPath!)
    }
}

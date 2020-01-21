//
//  ImageCell.swift
//  ImagePicker
//
//  Created by Alex Paul on 1/20/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit

// step1: creating custom delegation:
protocol ImageCellDelegate: AnyObject { // AnyObject requires ImageCellDelegate only works with class types
    // list required funcs, initializers, variebles
    func didLongPress(_ imageCell: ImageCell)
}

class ImageCell: UICollectionViewCell {
    
    
  
  @IBOutlet weak var imageView: UIImageView!
    
    //step2: creating custom delegation: - define optional delegate variable
    weak var delegate: ImageCellDelegate?
    
    
    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer()
        gesture.addTarget(self, action: #selector(longPressAction(gesture:)))
        return gesture
    }()
  
  override func layoutSubviews() {
    super.layoutSubviews()
    //making layer of thr cell rounded
    layer.cornerRadius = 20.0
    backgroundColor = .orange
    
    addGestureRecognizer(longPressGesture)
  }
    
    @objc
    private func longPressAction(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { // if gesture is active
            gesture.state = .cancelled
            return
            
        }
       // print("long press activated")
        
       // step3: creating custom delegation - explicitly use delegate object to notify of updates e.g
        // notifying the ImagesViewController when the user long presses on the cell
        delegate?.didLongPress(self)
        // cell.delegate = self
        // imageViewController.didLongPress(:)
    }
    
    public func configureCell(imageObject: ImageObject) {
        
        // convert data to UIImage
        guard let image = UIImage(data: imageObject.imageData) else {
            return
        }
        imageView.image = image
    }
}

//
//  ViewController.swift
//  ImagePicker
//
//  Created by Alex Paul on 1/20/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//
// Topics Covered Today

/*
 * Used UIAlertController to present and action sheet
 *Acces user photo library
 * access user camera
 * add the NSCameraUsageDescription key to the info.plist
 * Resize UIImage using UIGraphicImageRenderer
 * Implemenr UILongPressGestureRecognizer() to presemt action sheet for deletion
 * Maintained aspect ratio of the image using AVMakeRect (AVFoundtion framework)
 * Created a custom delegate to notify the ImageVioewController about long press from ImageCell
 
 Other fetures we can add:
 * Share an image along with text to a user via SMS, Facebook, etc
 * Automatically save originalmimage taken tonthe Photo Library UIImageWriteToPhotosAlbum
 
 */

import UIKit
import AVFoundation // we want to use AVMakeRect(0 to maintain image aspect ratio

class ImagesViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var imageObjects = [ImageObject]()
    
    private var imagePickerController = UIImagePickerController()
    
    private let dataPersistance = PersistenceHelper(filename: "images.plist")
    
    private var selectedImage: UIImage? {
        didSet {
            // gets called when new image is selected
            // collectionView.reloadData()
            appendNewPhotoToCollection()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self 
        collectionView.delegate = self
        
        // set UIImagePickerCintri=oller delegate as this viewcontroller
        imagePickerController.delegate = self
        
        loadImageObjects()
    }
    // function to load saved data
    private func loadImageObjects() {
        do {
            imageObjects = try dataPersistance.loadEvents()
        } catch {
            print("loading objects error \(error)")
        }
    }
    
    private func appendNewPhotoToCollection() {
        guard let image = selectedImage
            //jpegData(compressionQuality: 1.0) converts UIImage to data
            else {
                print("image is nil")
                return
        }
        
        print("original image size is \(image.size)")
        
        // resize image because it is too large
        // the size for resizing of image
        let size = UIScreen.main.bounds.size
        
        // we will maintain the aspect ratio of the image
        let rect = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: CGPoint.zero, size: size))
        
        // resize image
        let resizedImage = image.resizeImage(to: rect.size.width, height: rect.size.height)
        
        print("original image size is \(resizedImage.size)")
        
        guard let resizedImagemageData = resizedImage.jpegData(compressionQuality: 1.0) else {
            return
        }
        
        // create an image object using the image selected
        let imageObject = ImageObject(imageData: resizedImagemageData, date: Date())
        
        //insert new image object into image objects
        imageObjects.insert(imageObject, at: 0)
        
        // create indexPath for insertion into collection
        let indexPath = IndexPath(row: 0, section: 0)
        
        //insert new cell into coleection view
        collectionView.insertItems(at: [indexPath])
        
        // persist imageObject to documents directory
        do {
            try dataPersistance.create(item: imageObject)
        } catch {
            print("saving error: \(error)")
        }
    }
    
    @IBAction func addPictureButtonPressed(_ sender: UIBarButtonItem) {
        // present an action sheet to the user
        // actions: camera, photo library, cancel
        // preferredStyle: .alert(will show actions in the middle of the screen)
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] alertAction in
            self?.showImageController(isCameraSelected: true)
        }
        
        // closure
        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) { [weak self] alertAction in self?.showImageController(isCameraSelected: false)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // check if camaera is available. If camera is not available and you attampt to show the camera the app will crash
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(cameraAction)
        }
        alertController.addAction(photoLibrary)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    private func showImageController(isCameraSelected: Bool) {
        // source type default will be .photoLibrary
        imagePickerController.sourceType = .photoLibrary
        
        if isCameraSelected {
            imagePickerController.sourceType = .camera
        }
        present(imagePickerController, animated: true)
    }
    
}

// MARK: - UICollectionViewDataSource
extension ImagesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageObjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // step5: creating custom delegation: - must have an instance of object B
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? ImageCell else {
            fatalError("could not downcast to an ImageCell")
        }
        let imageObject = imageObjects[indexPath.row]
        cell.configureCell(imageObject: imageObject)
        // step5: creating custom delegation: - set delegate object
        cell.delegate = self
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ImagesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // width of the device
        let maxWidth: CGFloat = UIScreen.main.bounds.size.width
        // cell width is 80% of device width
        let itemWidth: CGFloat = maxWidth * 0.80
        return CGSize(width: itemWidth, height: itemWidth)  }
}

extension ImagesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // we need to access the UIImagePickerController.infokey.original image key to get the UIImage that was selected
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            print("image selected not found")
            return
        }
        selectedImage = image
        dismiss(animated: true)
        
    }
}

// step6: creating custom delegation: - conform to delegate
extension ImagesViewController: ImageCellDelegate {
    func didLongPress(_ imageCell: ImageCell) {
        print("cell was selected")
        guard let indexPath = collectionView.indexPath(for: imageCell) else {
            return
        }
        // present an action sheet
        // actions: delete, cancel
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] alertAction in
            self?.deleteImageObject(indexPath: indexPath)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
        //  print(indexPath.row)
    }
    
    private func deleteImageObject(indexPath: IndexPath) {
        // delete image from document directory
        do {
            
            try dataPersistance.delete(event: indexPath.row)
            
            // delete image object from imageObjects
            imageObjects.remove(at: indexPath.row)
            
            collectionView.deleteItems(at: [indexPath])
            
        } catch {
            print("error deleting item \(error)")
        }
    }
}

// more here: https://nshipster.com/image-resizing/
// MARK: - UIImage extension
extension UIImage {
    func resizeImage(to width: CGFloat, height: CGFloat) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}


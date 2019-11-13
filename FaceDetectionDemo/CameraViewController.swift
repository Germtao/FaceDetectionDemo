//
//  CameraViewController.swift
//  FaceDetectionDemo
//
//  Created by QDSG on 2019/11/11.
//  Copyright © 2019 unitTao. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {
    
    private let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()

        initImagePicker()
    }
    
    private func initImagePicker() {
        imagePicker.delegate = self
    }
    
    private func gotoImagePicker() {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) { return }
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        gotoImagePicker()
    }
    
    private func faceDetect() {
        let imageOptions = NSDictionary(object: NSNumber(value: 5), forKey: CIDetectorImageOrientation as NSString)
        let ciImage = CIImage(cgImage: imageView.image!.cgImage!)
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: ciImage, options: imageOptions as? [String : Any])
        
        if let face = faces?.first as? CIFaceFeature {
            print("发现的人脸的位置 \(face.bounds)")
            
            let alert = UIAlertController(title: "茄子", message: "检测到人脸", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            if face.hasSmile {
                print("正在笑...")
            }
            
            if face.hasLeftEyePosition {
                print("左眼位置 \(face.leftEyePosition)")
            }
            
            if face.hasRightEyePosition {
                print("右眼位置 \(face.rightEyePosition)")
            }
        } else {
            let alert = UIAlertController(title: "无", message: "没有检测到人脸", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
        }
        
        dismiss(animated: true, completion: nil)
        faceDetect()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

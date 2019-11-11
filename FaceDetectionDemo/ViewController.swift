//
//  ViewController.swift
//  FaceDetectionDemo
//
//  Created by QDSG on 2019/11/11.
//  Copyright © 2019 unitTao. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        faceDetect()
    }

    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.image = UIImage(named: "face-1")
        }
    }
    
    /// 人脸检测
    private func faceDetect() {
        // 1. UIImage 转 CIImage
        guard let ciImage = CIImage(image: imageView.image!) else { return }
        
        // 2. 创建一个 accuracy 变量并设置为 CIDetectorAccuracyHigh 高精度
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        
        // 3. 创建一个 faceDetector 变量并设置为 CIDetector 的实例
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        
        // 4. 通过调用 faceDetector 的 features(in:) 方法可检测出给定图像的所有人脸，最终以数组的形式返回所有人脸
        guard let faces = faceDetector?.features(in: ciImage) as? [CIFaceFeature] else { return }
        
        // 5. 遍历数组中所有的人脸，并将其转换为 CIFaceFeature 类型
        for face in faces {
            print("发现的人脸的位置 \(face.bounds)")
            
            // 5.1 创建一个 UIView 实例并命名为 faceBox，然后根据 faces.first 设置其大小。这将画一个方框用于高亮检测到的人脸
            let faceBox = UIView(frame: face.bounds)
            faceBox.layer.borderWidth = 3
            faceBox.layer.borderColor = UIColor.red.cgColor
            faceBox.backgroundColor = .clear
            imageView.addSubview(faceBox)
            
            // 5.2 如有左眼, 获取左眼位置
            if face.hasLeftEyePosition {
                print("左眼位置 \(face.leftEyePosition)")
            }
            
            // 5.3 如有右眼, 获取右眼位置
            if face.hasRightEyePosition {
                print("右眼位置 \(face.rightEyePosition)")
            }
        }
    }
}


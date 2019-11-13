//
//  DynamicFaceDetectionView.swift
//  FaceDetectionDemo
//
//  Created by QDSG on 2019/11/12.
//  Copyright © 2019 unitTao. All rights reserved.
//

import UIKit
import AVFoundation

/// 处理识别出来的人脸
protocol HandleMetadataOutputDelegate {
    func handleOutput(didDetected faceObjects: [AVMetadataObject], previewLayer: AVCaptureVideoPreviewLayer)
}

class DynamicFaceDetectionView: UIView {

    private var overLayer = CALayer()
    
    /// 存放每一张脸的字典[faceID: id]
    private var faceLayers = [String: Any]()
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        frame.size.height = UIScreen.main.bounds.height - 64 - 50
        backgroundColor = UIColor.black
        
        overLayer.frame = frame
        overLayer.sublayerTransform = CATransform3DMakePerspective(eyePosition: 1000)
        layer.addSublayer(overLayer)
    }

}

extension DynamicFaceDetectionView: HandleMetadataOutputDelegate {
    func handleOutput(didDetected faceObjects: [AVMetadataObject], previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        
        // 1. 获取预览图层的人脸数组
        let transformFaces = self.transformFaces(faceObjects: faceObjects)
        
        // 2. 拷贝一份所有人脸faceId字典
        var lostFaces = [String]()
        for faceId in faceLayers.keys {
            lostFaces.append(faceId)
        }
        
        // 3. 遍历所有face
        for i in 0..<transformFaces.count {
            guard let face = transformFaces[i] as? AVMetadataFaceObject else { return }
            
            // 3.1 判断是否包含该faceId
            if lostFaces.contains("\(face.faceID)") && lostFaces.count > i {
                lostFaces.remove(at: i)
            }
            
            // 3.2 获取图层
            var faceLayer = faceLayers["\(face.faceID)"] as? CALayer
            if faceLayer == nil {
                // 创建图层
                faceLayer = createLayer()
                overLayer.addSublayer(faceLayer!)
                // 添加到字典中
                faceLayers["\(face.faceID)"] = faceLayer
            }
            
            // 3.3 设置layer属性
            faceLayer?.transform = CATransform3DIdentity
            faceLayer?.frame = face.bounds
            
            // 3.4 设置偏转角(左右摇头)
            if face.hasYawAngle {
                let transform3D = transformDegress(yawAngle: face.yawAngle)
                
                // 矩阵处理
                faceLayer?.transform = CATransform3DConcat(faceLayer!.transform, transform3D)
            }
            
            // 3.5 设置倾斜角(左右歪头)
            if face.hasRollAngle {
                let transform3D = transformDegress(rollAngle: face.rollAngle)
                faceLayer?.transform = CATransform3DConcat(faceLayer!.transform, transform3D)
            }
            
            // 3.6 移除小时的layer
            for faceIdStr in lostFaces {
                let faceIdLayer = faceLayers[faceIdStr] as? CALayer
                faceIdLayer?.removeFromSuperlayer()
                faceLayers.removeValue(forKey: faceIdStr)
            }
        }
    }
}

// MARK: - 距离和偏转角计算
private extension DynamicFaceDetectionView {
    /// 返回的人脸数组处理
    func transformFaces(faceObjects: [AVMetadataObject]) -> [AVMetadataObject] {
        var faces = [AVMetadataObject]()
        for face in faceObjects {
            // 将扫描的人脸对象转成在预览图层的人脸对象(主要是坐标的转换)
            if let transformFace = previewLayer.transformedMetadataObject(for: face) {
                faces.append(transformFace)
            }
        }
        return faces
    }
    
    /// 创建图层
    func createLayer() -> CALayer {
        let layer = CALayer()
        layer.borderColor = UIColor.red.cgColor
        layer.borderWidth = 3
        return layer
    }
    
    /// 处理偏转角问题
    func transformDegress(yawAngle: CGFloat) -> CATransform3D {
        let yaw = degreesToRadians(degress: yawAngle)
        // 围绕y轴旋转
        let yawTransform = CATransform3DMakeRotation(yaw, 0, -1, 0)
        // 红框旋转问题
        return CATransform3DConcat(yawTransform, CATransform3DIdentity)
    }
    
    /// 角度转换
    func degreesToRadians(degress: CGFloat) -> CGFloat {
        return degress * CGFloat.pi / 180
    }
    
    /// 处理倾斜角问题
    func transformDegress(rollAngle: CGFloat) -> CATransform3D {
        let roll = degreesToRadians(degress: rollAngle)
        // 围绕z轴旋转
        return CATransform3DMakeRotation(roll, 0, 0, 1)
    }
    
    
    /// 眼睛到物体的距离
    func CATransform3DMakePerspective(eyePosition: CGFloat) -> CATransform3D {
        var transform = CATransform3DIdentity
        // m34: 透视效果; 近大远小
        transform.m34 = -1 / eyePosition
        return transform
    }
}

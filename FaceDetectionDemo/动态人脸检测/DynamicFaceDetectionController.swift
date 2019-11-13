//
//  DynamicFaceDetectionController.swift
//  FaceDetectionDemo
//
//  Created by QDSG on 2019/11/12.
//  Copyright © 2019 unitTao. All rights reserved.
//

import UIKit
import AVFoundation

class DynamicFaceDetectionController: UIViewController {

    private var session = AVCaptureSession() // 媒体（音、视频）捕捉会话
    private var deviceInput: AVCaptureDeviceInput? // 设备输入数据管理对象(麦克风、相机)
    private var previewLayer = AVCaptureVideoPreviewLayer() // 图片预览层
    
    var faceDelegate: HandleMetadataOutputDelegate?

    @IBOutlet weak var preview: DynamicFaceDetectionView!
}

// MARK: - Life Cycle
extension DynamicFaceDetectionController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addScaningVideo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 10. 开始扫描
        startScaning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopScaning()
    }
}

private extension DynamicFaceDetectionController {
    /// 添加扫描设备
    func addScaningVideo() {
        // 1. 获取输入设备(摄像头)
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        // 2. 根据输入设备创建输入对象
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else { return }
        self.deviceInput = deviceInput
        
        // 3. 创建原数据的输出对象
        let metadataOutput = AVCaptureMetadataOutput()
        
        // 4.1 设置代理监听输出对象输出的数据，在主线程中刷新
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        // 4.2 设置输出代理
        faceDelegate = preview
        
        // 5. 设置输出质量(高像素输出)
        session.sessionPreset = .high
        
        // 6. 添加输入和输出到会话
        if session.canAddInput(self.deviceInput!) {
            session.addInput(self.deviceInput!)
        }
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
        }
        
        // 7. 告诉输出对象要输出什么样的数据,识别人脸, 最多可识别10张人脸
        metadataOutput.metadataObjectTypes = [.face]
        
        // 8. 创建预览图层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        preview.layer.insertSublayer(previewLayer, at: 0)
        
        // 9. 设置有效扫描区域(默认整个屏幕区域)（每个取值0~1, 以屏幕右上角为坐标原点）
        metadataOutput.rectOfInterest = preview.bounds
    }
    
    func startScaning() {
        if !session.isRunning {
            DispatchQueue.global().async {
                self.session.startRunning()
            }
        }
    }
    
    func stopScaning() {
        session.stopRunning()
    }
}

// MARK: - 事件监听
extension DynamicFaceDetectionController {
    @IBAction func switchCamera() {
        // 1. 执行转场动画
        let anim = CATransition()
        anim.type = CATransitionType(rawValue: "olgFlip")
        anim.subtype = .fromLeft
        anim.duration = 0.5
        view.layer.add(anim, forKey: "flip")
        
        // 2. 获取当前摄像头
        guard let deviceInput = self.deviceInput else { return }
        let position: AVCaptureDevice.Position = deviceInput.device.position == .back ? .front : .back
        
        // 3. 创建新的input
        let deviceSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                             mediaType: .video,
                                                             position: position)
        guard let newDevice = deviceSession.devices.filter({ $0.position == position }).first else { return }
        guard let newVideoInput = try? AVCaptureDeviceInput(device: newDevice) else { return }
        
        // 4. 移除旧输入, 添加新输入
        // 4.1 设备加锁
        session.beginConfiguration()
        // 4.2 移除旧设备
        session.removeInput(deviceInput)
        // 4.3 添加新设备
        session.addInput(newVideoInput)
        // 4.4 设备解锁
        session.commitConfiguration()
        
        // 5. 保存最新输入
        self.deviceInput = newVideoInput
    }
}

// MARK: - AV代理
extension DynamicFaceDetectionController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for face in metadataObjects {
            let faceObj = face as? AVMetadataFaceObject
            let faceId = faceObj?.faceID ?? 0
            let faceRoll = faceObj?.rollAngle ?? 0.0
            print("\(faceId) - \(faceRoll)")
        }
        
//        faceDelegate?.handleOutput(didDetected: metadataObjects, previewLayer: previewLayer)
        
        if let face = metadataObjects.first as? AVMetadataFaceObject {
            print("发现的人脸的位置 \(face.bounds)")
            
            stopScaning()
            
            let alert = UIAlertController(title: "茄子", message: "检测到人脸", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: { (_) in
                self.startScaning()
            }))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            let alert = UIAlertController(title: "无", message: "没有检测到人脸", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

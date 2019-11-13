//
//  VideoFaceDetectionController.swift
//  FaceDetectionDemo
//
//  Created by QDSG on 2019/11/12.
//  Copyright © 2019 unitTao. All rights reserved.
//

import UIKit
import AVFoundation

class VideoFaceDetectionController: UIViewController {
    private lazy var session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        return session
    }()
    private var deviceInput: AVCaptureDeviceInput?
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    @IBOutlet weak var imageView: UIImageView!
    
    private var isFaceDetected = true
}

extension VideoFaceDetectionController {
    override func viewDidLoad() {
        super.viewDidLoad()

        beginSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        
        startScaning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopScaning()
    }
}

// MARK: - 摄像头设置
private extension VideoFaceDetectionController {
    func beginSession() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else { return }
        self.deviceInput = deviceInput
        
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        session.beginConfiguration()
        if session.canAddInput(self.deviceInput!) {
            session.addInput(self.deviceInput!)
        }
        if session.canAddOutput(deviceOutput) {
            session.addOutput(deviceOutput)
        }
        session.commitConfiguration()
        
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    func startScaning() {
        if !session.isRunning {
            self.session.startRunning()
        }
    }
    
    func stopScaning() {
        if session.isRunning {
            session.stopRunning()
        }
    }
}

extension VideoFaceDetectionController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 在这里你收集每一帧并处理它
        sampleBufferToImage(sampleBuffer: sampleBuffer)
    }
}

// MARK: - Helpers
private extension VideoFaceDetectionController {
    func sampleBufferToImage(sampleBuffer: CMSampleBuffer) {
        // 为媒体数据获取CMSampleBuffer的核心视频图像缓冲区
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        DispatchQueue.main.async {
            self.faceDetect(imageBuffer: imageBuffer)
        }
    }
    
    /// 人脸检测
    private func faceDetect(imageBuffer: CVImageBuffer) {
        // 1. 创建CIImage对象
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        
        // 2. 创建一个 accuracy 变量并设置为 CIDetectorAccuracyHigh 高精度
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        
        // 3. 创建一个 faceDetector 变量并设置为 CIDetector 的实例
        let ctx = CIContext(options: nil)
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: ctx, options: accuracy)
        
        // 4. 通过调用 faceDetector 的 features(in:) 方法可检测出给定图像的所有人脸，最终以数组的形式返回所有人脸
        guard let faces = faceDetector?.features(in: ciImage) as? [CIFaceFeature] else { return }
        
        
        if faces.count > 1 {
            stopScaning()
            let alert = UIAlertController(title: "提示", message: "人脸太多，重新检测", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .default, handler: { (_) in
                self.startScaning()
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // 6. 遍历数组中所有的人脸，并将其转换为 CIFaceFeature 类型
        if let face = faces.first {
            print("发现的人脸的位置 \(face.bounds)")
            
            if face.hasLeftEyePosition && face.hasRightEyePosition && face.hasMouthPosition {
                // 判断检测到人脸后，获取到人脸照片，不用再进行持续检测
                if isFaceDetected {
                    // 因为刚开始扫描到的人脸是模糊照片，所以延迟几秒获取
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                        if let cgImage = ctx.createCGImage(ciImage, from: face.bounds) {
                            let faceImage = UIImage(cgImage: cgImage, scale: 0.1, orientation: .leftMirrored)
                            self.imageView.image = faceImage
                            self.isFaceDetected = false
                        }
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.isFaceDetected = true
            }
        }
    }
}

extension VideoFaceDetectionController {
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

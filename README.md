# 使用`Core Image`在`iOS`中进行人脸检测

[原文地址](https://www.appcoda.com/face-detection-core-image/)

`Core Image` 是 `Cocoa Touch` 框架提供的功能强大的 `API`，是 `iOS SDK` 中经常被忽略的关键部分。在本教程中将研究 `Core Image` 提供 的人脸检测功能，以及如何应用到 `iOS App` 中。

> 注：这是中高级iOS教程，本教程假设你已经使用过类似 UIImagePicker，Core Image 等技术。如果您还不熟悉这些技术，请先查看[我们优秀的iOS课程系列](https://www.appcoda.com/ios-programming-course)，准备好后再返回阅读这篇文章。

## 接下来要做的事

自iOS 5（大约在2011年）问世以来，iOS已经支持人脸检测，但它经常被忽略。人脸检测 `API` 使开发者不仅可以进行人脸检测，还能识别微笑、眨眼等表情。

首先，将创建一个简单的应用程序，探索一下 `Core Image` 的人脸检测技术，该应用可以识别出照片中的人脸并用方框将人脸框起来突出显示。在第二个示例中，我们将通过创建一个应用来查看更详细的用例，用户可以拍照并检测照片是否有人脸出现，如果有则提取人脸坐标。这样，将学会iOS上所有有关人脸检测的技术，并充分利用它强大却经常被忽视的功能。

## 设置工程

该工程中的 `Storyboard` 仅包含一个已连接到代码的 `IBOutlet` 和 `imageView`。在开始使用 `Core Image` 进行人脸识别之前，需要将 `Core Image` 库导入项目中。

```
import CoreImage
```

## 用 `Core Image` 实现人脸检测

在起始工程的 storyboard 里包含一个通过 IBOutlet 连接到代码中的 imageView。

实现人脸检测的代码如下：

```
/// 人脸检测
func faceDetect() {
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
```

编译并运行程序，可以看到如下效果：

[image-1]()

根据控制台的输出结果，似乎可以检测出人脸：

```
发现的人脸的位置 (211.0031711576319, 416.1835848681309, 321.70255450827415, 327.43893540974625)
```

还有几个问题没有处理：

- 人脸检测程序应用于原始图像上，而原始图像有着比 `imageView` 更高的分辨率。另外，工程中 `imageView` 的 `content mode` 被设置为 `aspect fit`。为了正确地画出检测框，还需要计算出 `imageView` 中检测到的人脸的实际位置和尺寸。

- 此外，`Core Image` 和 `UIView（或UIKit）` 使用两个不同的坐标系（请参见下图）。因此还需要实现 `Core Image` 坐标到 `UIView` 坐标的转换。

[image-2]()

## 实现 `Core Image` 坐标到 `UIView` 坐标的转换

```
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
    
    // 5. 将 Core Image 坐标转换成 UIView 坐标
    let ciImageSize = ciImage.extent.size
    var transform = CGAffineTransform(scaleX: 1, y: -1)
    transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
    
    // 6. 遍历数组中所有的人脸，并将其转换为 CIFaceFeature 类型
    for face in faces {
        print("发现的人脸的位置 \(face.bounds)")
        
        // 5.1 实现坐标转换
        var faceViewBounds = face.bounds.applying(transform)
        
        // 5.2 计算实际的位置和大小
        let viewSize = imageView.bounds.size
        let scale = min(viewSize.width / ciImageSize.width,
                        viewSize.height / ciImageSize.height)
        let offsetX = (viewSize.width - ciImageSize.width * scale) / 2
        let offsetY = (viewSize.height - ciImageSize.height * scale) / 2
        
        faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
        faceViewBounds.origin.x += offsetX
        faceViewBounds.origin.y += offsetY
        
        // 6.1 创建一个 UIView 实例并命名为 faceBox，然后根据 faces.first 设置其大小。这将画一个方框用于高亮检测到的人脸
        let faceBox = UIView(frame: faceViewBounds)
        faceBox.layer.borderWidth = 3
        faceBox.layer.borderColor = UIColor.red.cgColor
        faceBox.backgroundColor = .clear
        imageView.addSubview(faceBox)
        
        // 6.2 如有左眼, 获取左眼位置
        if face.hasLeftEyePosition {
            print("左眼位置 \(face.leftEyePosition)")
        }
        
        // 6.3 如有右眼, 获取右眼位置
        if face.hasRightEyePosition {
            print("右眼位置 \(face.rightEyePosition)")
        }
    }
}
```

首先，上面的代码使用放射变换将 `Core Image` 坐标转换成了 `UIKit` 坐标。然后，添加了一些额外的代码用于计算框视图的实际位置和尺寸。

现在再一次运行程序，应该可以看到检测框将识别出的人脸框起来了，这样就成功地用 Core Image 检测到人脸了。

[image-3]()

---

## 开发一个支持人脸识别的摄像应用

假设有一个用于摄像或拍照的应用程序，我们希望在拍照后检测是否有人脸出现。如果出现了人脸，可能想将这张照片打上一些标签并对其分类。下面结合 `UIImagePicker` 类，拍照完成时立刻运行上面的人脸检测代码。

上面的起始工程中已经创建了一个 `CameraViewController` 类，将其代码更新成下面这样，用以实现摄像功能：

```
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
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
```

这里的 `faceDetect()` 函数和之前的实现非常相似，不过这一次我们使用的是临时拍到的图像。根据检测结果会显示一个提示框，提示是否检测到人脸。运行程序来快速测试一下：


[image-4]()

`CIFaceFeature` 中的一些属性和方法前面已经尝试过了。例如，若要判断照片中的人是否正在微笑，可以通过 `hasSmile` 属性判断。还可以通过 `hasLeftEyePosition` （或`hasRightEyePosition`）属性检查是否有左眼（或右眼）出现（希望有）。

还可以通过 `hasMouthPosition` 来判断是否出现了嘴巴。如果出现了，可以通过 `mouthPosition` 属性得到其坐标，代码如下：

```
if (face.hasMouthPosition) {
     print("mouth detected")
}
```

如你所见，通过 `Core Image` 进行人脸识别极其简单。除了检测嘴、微笑、眼睛位置等，还可以通过 `leftEyeClosed` （或`rightEyeClosed`）判断左眼（或右眼）是否睁开。

---

## 结语

本教程探索了 `Core Image` 提供的人脸识别 `API`，并展示了如何在摄像机应用中使用该功能。本文通过 `UIImagePicker` 拍摄图像，并检测该图像中是否有人的出现。

如你所见，`Core Image` 的人脸识别 `API` 有着非常多的用处！希望你能觉得本教程有所帮助，让你了解到了这一鲜为人知的 `iOS API`！

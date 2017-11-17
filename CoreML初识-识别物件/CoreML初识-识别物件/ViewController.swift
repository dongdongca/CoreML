//
//  ViewController.swift
//  CoreML初识-识别物件
//
//  Created by Mac on 2017/11/16.
//  Copyright © 2017年 lidong. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

import Vision

class ViewController: UIViewController, ARSCNViewDelegate {
    //拿到模型
    var resentModel = Resnet50()
    //点击之后的效果
    var hitTestResult: ARHitTestResult!
    //分析的结果
    var visionRequests = [VNRequest]()

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        //调用创建手势的方法
        regiterGestureRecognizers()
    }
    //创建点击手势
    func regiterGestureRecognizers(){
        
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        self.sceneView.addGestureRecognizer(tapGes)
    }
    //手势的点击方法,方法前面添加@objc
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        //拿到当前的屏幕的画面===截图
        let sceneView = recognizer.view as! ARSCNView
        //拿到图片的中心位置,以作为点击的位置
        let touchLoaction = self.sceneView.center
        //判別当前是否有像素
        guard let currentFrame = sceneView.session.currentFrame else {return}
        //识别物件的特征点
        let hitTestResults = sceneView.hitTest(touchLoaction, types: .featurePoint)
        //判断点击结果是否为空
        if hitTestResults.isEmpty {return}
        // 拿到第一个结果，判断是否为空
        guard let hitTestResult = hitTestResults.first else { return }
         //记录拿到点击的结果
        self.hitTestResult = hitTestResult
        // 拿到的图片转换成像素
        let pixelBuffer = currentFrame.capturedImage
        //识别图片像素
        perfomVisionRequest(pixelBuffer: pixelBuffer)
        
    }
    
    //识别图片像素
    func perfomVisionRequest(pixelBuffer: CVPixelBuffer) {
        // 拿出mlmodel
        let visionModel = try! VNCoreMLModel(for: self.resentModel.model)
        //创建CoreMLRequest
        let request = VNCoreMLRequest(model: visionModel) { (request, error) in
            //处理识别结果，如果存在error直接返回
            if error != nil {return}
            //判断结果是否为空
            guard let observations = request.results else {return}
            //把结果中的第一位拿出來分析
            let observation = observations.first as! VNClassificationObservation
            print("Name \(observation.identifier) and confidence is \(observation.confidence)")
            //回到主线程更新UI
            DispatchQueue.main.async {
                self.displayPredictions(text: observation.identifier)
            }
            
        }
        //进行喂食，设置请求识别图片的样式
        request.imageCropAndScaleOption = .centerCrop
        //记录请求数组
        self.visionRequests = [request]
        //创建图片请求
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: [:])
        //异步处理所有请求
        DispatchQueue.global().async {
            try! imageRequestHandler.perform(self.visionRequests)
        }
    }
    
    //展示預測的結果
    func displayPredictions(text: String) {
        //创建node
        let node = createText(text: text)
        //设置位置，// 把模型展示在我們点击位置（中央）
        node.position = SCNVector3(self.hitTestResult.worldTransform.columns.3.x,
                                   self.hitTestResult.worldTransform.columns.3.y,
                                   self.hitTestResult.worldTransform.columns.3.z)
        //将父节点放到sceneView上
        self.sceneView.scene.rootNode.addChildNode(node) // 把ＡＲ结果展示出來
    }
    
    //根据传入的文字创建AR展示文字以及底座
    func createText(text: String) -> SCNNode {
        //创建父节点
        let parentNode = SCNNode()
        //创建底座圆球，1 cm 的小球幾何形狀
        let sphere = SCNSphere(radius: 0.01)
        //创建渲染器
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.red
        sphere.firstMaterial = sphereMaterial
        //创建底座节点
        let sphereNode = SCNNode(geometry: sphere)
        
        //创建文字
        let textGeo = SCNText(string: text, extrusionDepth: 0)
        textGeo.alignmentMode = kCAAlignmentCenter
        textGeo.firstMaterial?.diffuse.contents = UIColor.red
        textGeo.firstMaterial?.specular.contents = UIColor.white
        textGeo.firstMaterial?.isDoubleSided = true
        textGeo.font = UIFont(name: "Futura", size: 0.15)
        
        //创建节点
        let textNode = SCNNode(geometry: textGeo)
        textNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        //将底座以及文字添加父节点
        parentNode.addChildNode(sphereNode)
        parentNode.addChildNode(textNode)
        
        return parentNode;
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

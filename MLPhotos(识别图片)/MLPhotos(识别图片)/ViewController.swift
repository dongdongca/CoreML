//
//  ViewController.swift
//  MLPhotos(识别图片)
//
//  Created by Mac on 2017/11/24.
//  Copyright © 2017年 lidong. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

    //创建建模型model
    //let model = GoogLeNetPlaces()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        startIdentifyingPictures()
    }
    
    func startIdentifyingPictures() {
        //拖入素材，拿到图片URL
        let path = Bundle.main.path(forResource: "111", ofType: "png")
        let imageUrl = NSURL.fileURL(withPath: path!)
        //拿到模型文件
        let fileModel = Resnet50()//GoogLeNetPlaces()
        // 把模型拿來做视觉处理
        let model = try! VNCoreMLModel(for: fileModel.model)
        //创建识别图片的请求头
        let handler = VNImageRequestHandler(url: imageUrl)
        //创建请求,completionHandler请求回调
        let request = VNCoreMLRequest(model: model) { (request, error) in
            //拿到识别结果
            //1、判别结果是否存在
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("识别结果为空")
            }
            //什么东西
            var bestPrediction = ""
            //相似度
            var bestConfidence: VNConfidence = 0
            //for遍历results
            for classfication in results {
                if classfication.confidence > bestConfidence {
                    bestPrediction = classfication.identifier
                    bestConfidence = classfication.confidence
                }
                //print("預測結果\(classfication.identifier) 可信度\(classfication.confidence)")
            }
            print("最終預測結果\(bestPrediction) 可信度\(bestConfidence)")
        }
        try! handler.perform([request])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


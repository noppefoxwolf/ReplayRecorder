//
//  ViewController.swift
//  ReplayRecorder
//
//  Created by noppefoxwolf on 01/01/2019.
//  Copyright (c) 2019 noppefoxwolf. All rights reserved.
//

import UIKit
import ReplayRecorder
import Photos

class ViewController: UIViewController {
  
  lazy var configuration: ReplayRecorder.Configuration = {
    var configuration = ReplayRecorder.Configuration()
    configuration.videoSize = toggleSwitch.bounds.size.applying(.init(scaleX: 6, y: 6)).roundedEven() //偶数・scale適用がオススメ
    return configuration
  }()
  lazy var recorder: ReplayRecorder = .init(configuration: configuration)
  @IBOutlet weak var toggleSwitch: UISwitch!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    recorder.isMicrophoneEnabled = true
    
    //この時点ではStoryboardの座標
    let viewFrame = toggleSwitch.convert(toggleSwitch.bounds, to: view)
    recorder.cropRect = .init(x: viewFrame.minX / view.bounds.width,
                              y: viewFrame.minY / view.bounds.height,
                              width: viewFrame.width / view.bounds.width,
                              height: viewFrame.height / view.bounds.height)
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if recorder.isRecording {
      recorder.stopRecording { (url, error) in
        print(url, error)
        if let url = url {
          PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
          }, completionHandler: { (grant, error) in
            print(grant, error)
          })
        }
      }
    } else {
      recorder.startRecording { (error) in
        print(error)
      }
    }
  }
}


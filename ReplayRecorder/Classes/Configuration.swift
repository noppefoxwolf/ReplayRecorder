//
//  Configuration.swift
//  ReplayRecorder
//
//  Created by Tomoya Hirano on 2019/01/03.
//

import Foundation
import AVFoundation

extension ReplayRecorder {
  public struct Configuration {
    public var codec: AVVideoCodecType = .h264
    public var fileType: AVFileType = .mp4
    public var videoSize: CGSize = CGSize(width: UIScreen.main.bounds.size.width * UIScreen.main.scale, height: UIScreen.main.bounds.size.height * UIScreen.main.scale)
    public var audioQuality: AVAudioQuality = AVAudioQuality.medium
    public var audioFormatID: AudioFormatID = kAudioFormatMPEG4AAC
    public var numberOfChannels: UInt = 2
    public var sampleRate: Double = 44100.0
    public var bitrate: UInt = 16
    
    public init() {}
  }
}

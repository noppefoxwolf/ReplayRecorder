//
//  ReplayRecorder.swift
//  ReplayRecorder
//
//  Created by Tomoya Hirano on 2019/01/03.
//

import ReplayKit
import AVFoundation

public class ReplayRecorder {
  private let recorder: RPScreenRecorder = .shared()
  let configuration: Configuration
  public init(configuration: Configuration) {
    self.configuration = configuration
  }
  
  private var assetWriter: AVAssetWriter?
  
  private var videoAssetWriterInput: AVAssetWriterInput?
  private var audioAssetWriterInput: AVAssetWriterInput?
  private var micAssetWriterInput: AVAssetWriterInput?
  
  private var writerInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
  
  private let writerQueue: DispatchQueue = DispatchQueue.init(label: "com.ReplayRecorder.writer")
  private var _isRecording: Bool = false
  private let context: CIContext = .init()
  public var filter: CIFilter? = nil
  public var cropRect: CGRect = .init(x: 0, y: 0, width: 1, height: 1)
  
  private func setUp() throws {
    try FileManager.default.createCacheDirectoryIfNeeded()
    try FileManager.default.removeOldCachedFile()
    
    guard let cacheURL = FileManager.cacheFileURL else {
      throw ReplayRecorder.Error.invalidURL
    }
    
    let assetWriter = try AVAssetWriter(url: cacheURL, fileType: configuration.fileType)
    
    let videoSetting: [String: Any] = [
      AVVideoCodecKey: configuration.codec,
      AVVideoWidthKey: UInt(configuration.videoSize.width),
      AVVideoHeightKey: UInt(configuration.videoSize.height),
      ]
    let videoAssetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSetting)
    videoAssetWriterInput.expectsMediaDataInRealTime = true
    
    if assetWriter.canAdd(videoAssetWriterInput) {
      assetWriter.add(videoAssetWriterInput)
    }
    
    let audioSetting: [String : Any] = [
      AVFormatIDKey : configuration.audioFormatID,
      AVSampleRateKey : configuration.sampleRate,
      AVNumberOfChannelsKey : configuration.numberOfChannels,
      ]
    
    let audioAssetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSetting)
    audioAssetWriterInput.expectsMediaDataInRealTime = true
    if assetWriter.canAdd(audioAssetWriterInput) {
      assetWriter.add(audioAssetWriterInput)
    }
    let micAssetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSetting)
    micAssetWriterInput.expectsMediaDataInRealTime = true
    if assetWriter.canAdd(micAssetWriterInput) {
      assetWriter.add(micAssetWriterInput)
    }
    
    self.assetWriter = assetWriter
    self.videoAssetWriterInput = videoAssetWriterInput
    self.audioAssetWriterInput = audioAssetWriterInput
    self.micAssetWriterInput = micAssetWriterInput
    self.writerInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoAssetWriterInput, sourcePixelBufferAttributes: [
      kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB)
      ])
  }
  
  private func appendVideo(sampleBuffer: CMSampleBuffer) {
    guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    CVPixelBufferLockBaseAddress(pb, [])
    defer { CVPixelBufferUnlockBaseAddress(pb, []) }
    guard let pixelBuffer = process(pb) else { return }
    
    let currentTime: CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    
    if writerInputPixelBufferAdaptor?.assetWriterInput.isReadyForMoreMediaData ?? false {
      writerInputPixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: currentTime)
    }
  }
  
  private func process(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let cropRect: CGRect = CGRect(x: (CGFloat(width) * self.cropRect.minX).rounded(.toNearestOrEven),
                                  y: (CGFloat(height) * (1.0 - self.cropRect.maxY)).rounded(.toNearestOrEven),
                                  width: (CGFloat(width) * self.cropRect.width).rounded(.toNearestOrEven),
                                  height: (CGFloat(height) * self.cropRect.height).rounded(.toNearestOrEven))
    let transform = CGAffineTransform(translationX: -cropRect.minX.rounded(.toNearestOrEven),
                                      y: -cropRect.minY.rounded(.toNearestOrEven))
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
      .cropped(to: cropRect)
      .transformed(by: transform)
    let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
    var pixelBufferOut: CVPixelBuffer? = nil
    CVPixelBufferCreate(kCFAllocatorDefault,
                        Int(ciImage.extent.width),
                        Int(ciImage.extent.height),
                        pixelFormatType,
                        nil,
                        &pixelBufferOut)
    guard let pixelBufferDst = pixelBufferOut else { return nil }
    
    if let filter = filter {
      filter.setValue(ciImage, forKey: kCIInputImageKey)
      guard let outputImage = filter.outputImage else { return nil }
      context.render(outputImage, to: pixelBufferDst)
      return pixelBufferDst
    } else {
      context.render(ciImage, to: pixelBufferDst)
      return pixelBufferDst
    }
  }
}

// ReplayKit interface
extension ReplayRecorder {
  public func startRecording(handler: ((Swift.Error?) -> Void)? = nil) {
    guard recorder.isAvailable else {
      handler?(ReplayRecorder.Error.notAvailable)
      return
    }
    
    guard !recorder.isRecording else {
      handler?(ReplayRecorder.Error.alreadyRunning)
      return
    }
    
    do {
      try setUp()
    } catch {
      handler?(error)
      return
    }
    
    _isRecording = false
    
    recorder.startCapture(handler: { [weak self] (sampleBuffer, bufferType, error) in
      self?.writerQueue.async { [weak self] in
        if let error = error {
          handler?(error)
          return
        }
        
        if self?._isRecording == false {
          self?._isRecording = true
          self?.assetWriter?.startWriting()
          self?.assetWriter?.startSession(atSourceTime: CMClockGetTime(CMClockGetHostTimeClock()))
        }
        
        switch bufferType {
        case .video:
          self?.appendVideo(sampleBuffer: sampleBuffer)
        case .audioMic:
          self?.audioAssetWriterInput?.append(sampleBuffer)
        case .audioApp:
          self?.micAssetWriterInput?.append(sampleBuffer)
        }
      }
    }) { (error) in
      // これは再起動で直る
      //      Optional(Error Domain=com.apple.ReplayKit.RPRecordingErrorDomain Code=-5807 "Recording interrupted by multitasking and content resizing" UserInfo={NSLocalizedDescription=Recording interrupted by multitasking and content resizing})
      handler?(error)
    }
  }
  
  public func stopRecording(handler: ((URL?, Swift.Error?) -> Void)? = nil) {
    guard recorder.isRecording else {
      handler?(nil, ReplayRecorder.Error.notRunning)
      return
    }
    
    videoAssetWriterInput?.markAsFinished()
    audioAssetWriterInput?.markAsFinished()
    micAssetWriterInput?.markAsFinished()
    
    assetWriter?.finishWriting { [weak self] in
      self?.recorder.stopCapture { (error) in
        if let error = error {
          handler?(nil, error)
        } else {
          handler?(FileManager.cacheFileURL, nil)
        }
      }
    }
  }
  
  public func discardRecording(handler: @escaping () -> Void) {
    recorder.discardRecording(handler: handler)
  }
  
  public var isAvailable: Bool {
    return recorder.isAvailable
  }
  
  public var isRecording: Bool {
    return recorder.isRecording
  }
  
  public var isMicrophoneEnabled: Bool {
    get { return recorder.isMicrophoneEnabled }
    set { recorder.isMicrophoneEnabled = newValue }
  }
  
  public var isCameraEnabled: Bool {
    get { return recorder.isCameraEnabled }
    set { recorder.isCameraEnabled = newValue }
  }
  
  public var cameraPosition: RPCameraPosition {
    get { return recorder.cameraPosition }
    set { recorder.cameraPosition = newValue }
  }
  
  public var cameraPreviewView: UIView? {
    return recorder.cameraPreviewView
  }
}


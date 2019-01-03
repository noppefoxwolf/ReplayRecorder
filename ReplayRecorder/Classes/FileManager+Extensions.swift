//
//  FileManager+Extensions.swift
//  ReplayRecorder
//
//  Created by Tomoya Hirano on 2019/01/03.
//

import Foundation

extension FileManager {
  internal static var cacheDirectoryURL: URL? = {
    guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
      return nil
    }
    return URL(fileURLWithPath: path).appendingPathComponent("ReplayRecorder")
  }()
  
  internal static var cacheFileURL: URL? {
    guard let cacheDirectoryURL = cacheDirectoryURL else { return nil }
    
    return cacheDirectoryURL.appendingPathComponent("screenrecord.mp4")
  }
  
  internal func createCacheDirectoryIfNeeded() throws {
    guard let cacheDirectoryURL = FileManager.cacheDirectoryURL else { return }
    
    guard !fileExists(atPath: cacheDirectoryURL.path) else {
      return
    }
    
    try createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true, attributes: nil)
  }
  
  internal func removeOldCachedFile() throws {
    guard let cacheURL = FileManager.cacheFileURL else { return }
    
    guard fileExists(atPath: cacheURL.path) else { return }
    try removeItem(at: cacheURL)
  }
}

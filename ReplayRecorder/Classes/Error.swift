//
//  Error.swift
//  ReplayRecorder
//
//  Created by Tomoya Hirano on 2019/01/03.
//

import Foundation

extension ReplayRecorder {
  public enum Error: Swift.Error {
    case notAvailable
    case alreadyRunning
    case notRunning
    case invalidURL
  }
}

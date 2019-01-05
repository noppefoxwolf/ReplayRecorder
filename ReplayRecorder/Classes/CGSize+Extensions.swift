//
//  CGSize+Extensions.swift
//  ReplayRecorder
//
//  Created by Tomoya Hirano on 2019/01/06.
//

import Foundation

extension CGSize {
  public func roundedEven() -> CGSize {
    var width = Int(self.width)
    if width % 2 != 0 {
      width += 1
    }
    var height = Int(self.height)
    if height % 2 != 0 {
      height += 1
    }
    return CGSize(width: width, height: height)
  }
}


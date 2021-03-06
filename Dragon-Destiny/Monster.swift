//
//  Monster.swift
//  DragoMerc
//
//  Created by Daniel Liebeskind on 8/11/15.
//  Copyright (c) 2015 Cybenex LLC. All rights reserved.
//

import Foundation
import SpriteKit


class Monster: SKSpriteNode {
  var playerPosition: CGPoint?
  var moveDuration: CGFloat?
  var leftPoint: CGFloat?
  var realDest: CGPoint?
  
  override init(texture: SKTexture?, color: SKColor, size: CGSize) {
    self.playerPosition = CGPoint()
    super.init(texture: texture, color: color, size: size)
  }
  
  convenience init(color: SKColor, size: CGSize, playerPosition: CGPoint) {
    self.init(texture:nil, color: color, size: size)
    self.playerPosition = playerPosition
  }
  
  required init?(coder aDecoder: NSCoder) {
    // Decoding length here would be nice...
    super.init(coder: aDecoder)
  }
}
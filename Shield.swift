//
//  Shield.swift
//  Dragon-Destiny
//
//  Created by Daniel Liebeskind on 8/30/15.
//  Copyright (c) 2015 Cybenex LLC. All rights reserved.
//

import Foundation
import SpriteKit


class Shield: SKSpriteNode {
  var playerPosition: CGPoint?
  var health = 100
  var purchased = false
  
  override init(texture: SKTexture!, color: SKColor!, size: CGSize) {
    self.playerPosition = CGPoint()
    super.init(texture: texture, color: color, size: size)
  }
  
  convenience init(color: SKColor, size: CGSize, playerPosition: CGPoint) {
    self.init(texture:nil, color: color, size: size)
    self.playerPosition = playerPosition
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
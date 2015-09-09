//
//  GameOverScene.swift
//  SpriteKitSimpleGame
//
//  Created by Main Account on 9/30/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
  
  let restartButton = SKSpriteNode(imageNamed: "RestartButton")
  var twitterButton = SKSpriteNode(imageNamed: "RestartButton")
  
  init(size: CGSize, won:Bool, score: Int) {
    
    super.init(size: size)
    
    NSNotificationCenter.defaultCenter().postNotificationName("showInterstitialAdsID", object: nil)

    backgroundColor = SKColor.whiteColor()

    
    restartButton.position = CGPoint(x: size.width/2, y: size.height/2)
    restartButton.size = CGSize(width: 228.0, height: 69.0)
    restartButton.name = "restart"
    addChild(restartButton)
    
//    twitterButton.position = CGPoint(x: self.size.width/2, y: restartButton.position.y - restartButton.size.height - 15)
//    twitterButton.size = CGSize(width: 228.0, height: 69.0)
//    addChild(twitterButton)
    
//    facebookButton = SKLabelNode(fontNamed: "Arial Regular")
//    facebookButton.fontSize = 21
//    facebookButton.fontColor = SKColor.blackColor()
//    facebookButton.position = CGPoint(x: self.size.width/2, y: restartButton.position.y - restartButton.size.height - 15)
//    facebookButton.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
//    facebookButton.text = "FACEBOOK"
//    addChild(facebookButton)
    
    var tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "GameOverScene")
    
    var builder = GAIDictionaryBuilder.createScreenView()
    tracker.send(builder.build() as [NSObject : AnyObject])
    
    var coinsCollected = GAIDictionaryBuilder.createEventWithCategory("coinsCollectedAtDeath", action: "Collected", label: "Coins", value: score)
    tracker.send(coinsCollected.build() as [NSObject: AnyObject])

    if score > 50 {
      var coinsCollected = GAIDictionaryBuilder.createEventWithCategory("coinsCollectedAtDeath", action: "Collected", label: "Over50Coins", value: score)
      tracker.send(coinsCollected.build() as [NSObject: AnyObject])
    }
    
    var message = won ? "You Won!" : "Game Over!  You collected \(score) coins."
    let label = SKLabelNode(fontNamed: "Avenir")
    label.text = message
    label.fontSize = 30
    label.fontColor = SKColor.blackColor()
    label.position = CGPoint(x: size.width/2, y: restartButton.position.y + restartButton.size.height/2 + label.fontSize)
    addChild(label)
    
    message = "Dragon Destiny"
    let dragonDestinyLabel = SKLabelNode(fontNamed: "Chalkduster")
    dragonDestinyLabel.text = message
    dragonDestinyLabel.fontSize = 30
    dragonDestinyLabel.fontColor = SKColor.blackColor()
    dragonDestinyLabel.position = CGPoint(x: size.width/2, y: label.position.y + dragonDestinyLabel.fontSize + label.fontSize/2)
    addChild(dragonDestinyLabel)
    
  }
  
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    for touch in (touches as! Set<UITouch>) {
      let touchLocation = touch.locationInNode(self)
      if restartButton.containsPoint(touchLocation) {
        restartButton.runAction(SKAction.scaleTo(1.25, duration: 0.5))
      }
    }
  }
  
  override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
    for touch in (touches as! Set<UITouch>) {
      
      let touchLocation = touch.locationInNode(self)
      if restartButton.containsPoint(touchLocation) {
        restartGame()
      }
      if !restartButton.containsPoint(touchLocation) {
        let scaleBack = SKAction.scaleTo(1.0, duration: 0.2)
        restartButton.runAction(scaleBack)
      }
      if twitterButton.containsPoint(touchLocation) {
        NSNotificationCenter.defaultCenter().postNotificationName("TwitterNotification", object: nil)
      }
    }
  }
  
  func restartGame() {
    let scaleBack = SKAction.scaleTo(1.0, duration: 0.2)
    let pushRestart = SKAction.runBlock() {
      let reveal = SKTransition.flipHorizontalWithDuration(0.5)
      let scene = GameScene(size: self.size, level: 1, coinsCollected: 0, shield: Shield())
      self.view?.presentScene(scene, transition:reveal)
    }
    restartButton.runAction(SKAction.sequence([scaleBack, pushRestart]))
  }


  // 6
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
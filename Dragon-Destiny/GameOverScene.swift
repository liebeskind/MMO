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
  
  init(size: CGSize, won:Bool, score: Int, monstersDestroyed: Int, levelReached: Int) {
    
    super.init(size: size)
    
    NSNotificationCenter.defaultCenter().postNotificationName("showInterstitialAdsID", object: nil)

    backgroundColor = SKColor.whiteColor()

    restartButton.size = CGSize(width: 228.0, height: 69.0)
    restartButton.position = CGPoint(x: size.width/2, y: 8 + restartButton.size.height/2)
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
    
    var message = "Dragon Destiny"
    let dragonDestinyLabel = SKLabelNode(fontNamed: "Chalkduster")
    dragonDestinyLabel.text = message
    dragonDestinyLabel.fontSize = 30
    dragonDestinyLabel.fontColor = SKColor.blackColor()
    dragonDestinyLabel.position = CGPoint(x: size.width/2, y: self.size.height - 8 - dragonDestinyLabel.fontSize)
    addChild(dragonDestinyLabel)
    
    message = "Coins Collected: \(score) (\(Int(Float(Float(score) / Float(levelReached * 30))*100))%)"
    let coinsLabel = SKLabelNode(fontNamed: "Avenir")
    coinsLabel.text = message
    coinsLabel.fontSize = 20
    coinsLabel.fontColor = SKColor.blackColor()
    coinsLabel.position = CGPoint(x: size.width/2, y: dragonDestinyLabel.position.y - dragonDestinyLabel.fontSize)
    addChild(coinsLabel)
    
//    message = "% Coins Collected: \(Int(Float(Float(score) / Float(levelReached * 30))*100))%"
//    let percentageLabel = SKLabelNode(fontNamed: "Avenir")
//    percentageLabel.text = message
//    percentageLabel.fontSize = 20
//    percentageLabel.fontColor = SKColor.blackColor()
//    percentageLabel.position = CGPoint(x: size.width/2, y: coinsLabel.position.y - coinsLabel.fontSize)
//    addChild(percentageLabel)
 
    message = "Arrows Shot Down: \(monstersDestroyed)"
    let monstersLabel = SKLabelNode(fontNamed: "Avenir")
    monstersLabel.text = message
    monstersLabel.fontSize = 20
    monstersLabel.fontColor = SKColor.blackColor()
    monstersLabel.position = CGPoint(x: size.width/2, y: coinsLabel.position.y - coinsLabel.fontSize)
    addChild(monstersLabel)

    message = "Level Reached: \(levelReached)"
    let levelLabel = SKLabelNode(fontNamed: "Avenir")
    levelLabel.text = message
    levelLabel.fontSize = 20
    levelLabel.fontColor = SKColor.blackColor()
    levelLabel.position = CGPoint(x: size.width/2, y: monstersLabel.position.y - monstersLabel.fontSize)
    addChild(levelLabel)
    
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
      let scene = GameScene(size: self.size, level: 1, coinsCollected: 0, shield: Shield(), dragonType: 0)
      self.view?.presentScene(scene, transition:reveal)
    }
    restartButton.runAction(SKAction.sequence([scaleBack, pushRestart]))
  }


  // 6
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
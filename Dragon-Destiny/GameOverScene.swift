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
  
  let dragonDestinyLabel = SKLabelNode(fontNamed: "Chalkduster")
  
  let birthdayPickerLabel = SKLabelNode()
  
  var dragonSelected: Int!
  var birthdayMode = false
  
  let blueDragon = SKSpriteNode(imageNamed: "BlueDragonChooser")
  let redDragon = SKSpriteNode(imageNamed: "RedDragonChooser")
  let greenDragon = SKSpriteNode(imageNamed: "GreenDragonChooser")
  let yellowDragon = SKSpriteNode(imageNamed: "YellowDragonChooser")
  let flame = SKSpriteNode(imageNamed: "FlameChooser")
  let fireball = SKSpriteNode(imageNamed: "FireballChooser")
  let laser1 = SKSpriteNode(imageNamed: "LaserChooser")
  let laser2 = SKSpriteNode(imageNamed: "LaserChooser")
  
  init(size: CGSize, won:Bool, score: Int, monstersDestroyed: Int, levelReached: Int, dragonSelected: Int, birthdayMode: Bool) {
    
    self.dragonSelected = dragonSelected
    self.birthdayMode = birthdayMode
    
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
    if birthdayMode { message = "Birthday Destiny" }

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
    
    blueDragon.size = CGSize(width: 50, height: 30)
    blueDragon.position = CGPoint(x: self.size.width * 6/24, y: restartButton.position.y + restartButton.size.height / 2 + blueDragon.size.height)
    self.addChild(blueDragon)
    
    redDragon.size = CGSize(width: 50, height: 30)
    redDragon.position = CGPoint(x: self.size.width * 10/24, y: restartButton.position.y + restartButton.size.height / 2 + redDragon.size.height)
    self.addChild(redDragon)
    
    greenDragon.size = CGSize(width: 50, height: 30)
    greenDragon.position = CGPoint(x: self.size.width * 14/24, y: restartButton.position.y + restartButton.size.height / 2 + greenDragon.size.height)
    self.addChild(greenDragon)
    
    yellowDragon.size = CGSize(width: 50, height: 30)
    yellowDragon.position = CGPoint(x: self.size.width * 18/24, y: restartButton.position.y + restartButton.size.height / 2 + yellowDragon.size.height)
    self.addChild(yellowDragon)
    
    flame.size = CGSize(width: 26, height: 48)
    flame.position = CGPoint(x: redDragon.position.x, y: redDragon.position.y + redDragon.size.height/2 + flame.size.height/2 - 1)
    
    fireball.size = CGSize(width: 15, height: 15)
    fireball.position = CGPoint(x: blueDragon.position.x, y: blueDragon.position.y + blueDragon.size.height/2 + flame.size.height/2 - 1)
    
    laser1.size = CGSize(width: 9, height: 20)
    laser1.position = CGPoint(x: greenDragon.position.x, y: greenDragon.position.y + greenDragon.size.height/2 + flame.size.height/2 - 1)

    laser2.size = CGSize(width: 9, height: 48)
    laser2.position = CGPoint(x: yellowDragon.position.x, y: yellowDragon.position.y + yellowDragon.size.height/2 + flame.size.height/2 - 1)


    switch dragonSelected {
    case 0:
      self.addChild(fireball)
    case 1:
      self.addChild(flame)
    case 2:
      self.addChild(laser1)
    case 3:
      self.addChild(laser2)
    default:
      self.addChild(fireball)
    }
    
    let dragonLabel = SKLabelNode(fontNamed: "Avenir")
    dragonLabel.position = CGPoint(x: self.size.width/2, y: flame.position.y + flame.size.height)
    dragonLabel.fontSize = 20
    dragonLabel.text = "Choose Dragon"
    self.addChild(dragonLabel)
    
//    if birthdayMode {
//      birthdayPickerLabel.text = " Mode"
//    } else {
//      birthdayPickerLabel.text = "Dragon Mode"
//    }
    
    birthdayPickerLabel.text = "Change Mode"
    
    birthdayPickerLabel.fontName = "MarkerFelt-Thin"
    birthdayPickerLabel.fontSize = 25
    birthdayPickerLabel.fontColor = UIColor.blueColor()
    birthdayPickerLabel.position = CGPoint(x: size.width - birthdayPickerLabel.frame.width/2, y: size.height - birthdayPickerLabel.fontSize)
    self.addChild(birthdayPickerLabel)
  }
  
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    for touch in (touches as! Set<UITouch>) {
      let touchLocation = touch.locationInNode(self)
      
      let blueDragonExtendedRect = CGRectMake(blueDragon.position.x - blueDragon.size.width/2, blueDragon.position.y - blueDragon.size.height/2, blueDragon.size.width, blueDragon.size.height * 4)

      let redDragonExtendedRect = CGRectMake(redDragon.position.x - redDragon.size.width/2, redDragon.position.y - redDragon.size.height/2, redDragon.size.width, redDragon.size.height * 4)
      
      let greenDragonExtendedRect = CGRectMake(greenDragon.position.x - greenDragon.size.width/2, greenDragon.position.y - greenDragon.size.height/2, greenDragon.size.width, greenDragon.size.height * 4)
      
      let yellowDragonExtendedRect = CGRectMake(yellowDragon.position.x - yellowDragon.size.width/2, yellowDragon.position.y - yellowDragon.size.height/2, yellowDragon.size.width, yellowDragon.size.height * 4)
      
      if restartButton.containsPoint(touchLocation) {
        restartButton.runAction(SKAction.scaleTo(1.25, duration: 0.5))
      }
      if (CGRectContainsPoint(blueDragonExtendedRect, touchLocation)) {
        self.dragonSelected = 0
        fireball.removeFromParent()
        flame.removeFromParent()
        laser1.removeFromParent()
        laser2.removeFromParent()
        self.addChild(fireball)
      } else if (CGRectContainsPoint(redDragonExtendedRect, touchLocation)) {
        self.dragonSelected = 1
        fireball.removeFromParent()
        flame.removeFromParent()
        laser1.removeFromParent()
        laser2.removeFromParent()
        self.addChild(flame)
      } else if (CGRectContainsPoint(greenDragonExtendedRect, touchLocation)) {
        self.dragonSelected = 2
        fireball.removeFromParent()
        flame.removeFromParent()
        laser1.removeFromParent()
        laser2.removeFromParent()
        self.addChild(laser1)
      } else if (CGRectContainsPoint(yellowDragonExtendedRect, touchLocation)) {
        self.dragonSelected = 3
        fireball.removeFromParent()
        flame.removeFromParent()
        laser1.removeFromParent()
        laser2.removeFromParent()
        self.addChild(laser2)
      } else if (CGRectContainsPoint(birthdayPickerLabel.frame, touchLocation)) {
        if birthdayMode {
          birthdayMode = false
//          birthdayPickerLabel.text = "Dragon Mode"
          dragonDestinyLabel.text = "Dragon Destiny"
        } else {
          birthdayMode = true
//          birthdayPickerLabel.text = "Birthday Mode"
          dragonDestinyLabel.text = "Birthday Destiny"
        }
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
      let scene = GameScene(size: self.size, level: 1, coinsCollected: 0, shield: Shield(), dragonType: self.dragonSelected, birthdayMode: self.birthdayMode)
      self.view?.presentScene(scene, transition:reveal)
    }
    restartButton.runAction(SKAction.sequence([scaleBack, pushRestart]))
  }


  // 6
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
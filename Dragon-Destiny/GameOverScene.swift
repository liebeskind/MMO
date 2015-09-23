//
//  GameOverScene.swift
//  SpriteKitSimpleGame
//
//  Created by Main Account on 9/30/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import SpriteKit
import MediaPlayer
import AudioToolbox
import GameKit
import StoreKit

class GameOverScene: SKScene, SKPaymentTransactionObserver, SKProductsRequestDelegate {
  
  var tracker: GAITracker!
  
  var restartButton = SKShapeNode()
  var twitterButton = SKSpriteNode(imageNamed: "RestartButton")
  
  let dragonDestinyLabel = SKLabelNode(fontNamed: "Chalkduster")
  let totalCoinsLabel = SKLabelNode(fontNamed: "Copperplate")
  
  let birthdayPickerLabel = SKLabelNode()
  var birthdayPicture = UIImage()
  
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
  
  let lockFlame = SKSpriteNode(imageNamed: "gray_lock")
  let lockLaserBall = SKSpriteNode(imageNamed: "gray_lock")
  let lockLaserBeam = SKSpriteNode(imageNamed: "gray_lock")
  
  let flameCostLabel = SKLabelNode(fontNamed: "Copperplate")
  let laserBallCostLabel = SKLabelNode(fontNamed: "Copperplate")
  let laserBeamCostLabel = SKLabelNode(fontNamed: "Copperplate")
  
  var moviePlayer: MPMoviePlayerController!
  
  var totalCoins: Int?
  var coinsPerLevelMultiplier = 15
  
  var flameDragonPurchased = NSUserDefaults.standardUserDefaults().objectForKey("flameDragonPurchased") as? Bool
  var laserBallDragonPurchased = NSUserDefaults.standardUserDefaults().objectForKey("laserBallDragonPurchased") as? Bool
  var laserBeamDragonPurchased = NSUserDefaults.standardUserDefaults().objectForKey("laserBeamDragonPurchased") as? Bool
  
  let flameDragonCost = 200
  let laserBallDragonCost = 600
  let laserBeamDragonCost = 1200
  
  var gcEnabled = Bool() // Stores if the user has Game Center enabled
  var gcDefaultLeaderBoard = String() // Stores the default leaderboardID
  
  var muted = false
  
  let eliminateAdsButton = SKSpriteNode(imageNamed: "eliminateAdsButton")
  
  init(size: CGSize, muted: Bool, won:Bool, score: Int, monstersDestroyed: Int, levelReached: Int, coinsPerLevelMultiplier: Int, dragonSelected: Int, birthdayMode: Bool, birthdayPicture: UIImage, highScoreAchieved: Bool) {
    
    super.init(size: size)
    
    self.muted = muted
    self.dragonSelected = dragonSelected
    self.birthdayMode = birthdayMode
    self.birthdayPicture = birthdayPicture
    self.coinsPerLevelMultiplier = coinsPerLevelMultiplier
    self.totalCoins = NSUserDefaults.standardUserDefaults().objectForKey("TotalCoins") as? Int
    
    NSNotificationCenter.defaultCenter().postNotificationName("showInterstitialAdsID", object: nil)

    backgroundColor = SKColor.whiteColor()
    let backgroundImage = SKSpriteNode(imageNamed: "dragonMainScreenBackground")
    backgroundImage.position = CGPoint(x: size.width/2, y: size.height/2)
    let aspectRatio = CGFloat(1128/754)
    backgroundImage.size = CGSize(width: (size.width + 20) * aspectRatio, height: (size.height + 20) * (1/aspectRatio))
    backgroundImage.zPosition = -1
    addChild(backgroundImage)
    
    
    self.authenticateLocalPlayer()

    restartButton = SKShapeNode(rect: CGRect(x: self.size.width / 2 - 130/2, y: 30, width: 130, height: 43), cornerRadius: 10)
//    restartButton.position = CGPoint(x: size.width/2, y: 8 + restartButton.size.height/2)
    restartButton.name = "restart"
    restartButton.fillColor = UIColor(red:0.02, green:0.38, blue:0.71, alpha:1.0)
    addChild(restartButton)
    
    let playLabel = SKLabelNode(fontNamed: "Copperplate")
    playLabel.fontSize = 30
    playLabel.text = "PLAY"
    playLabel.fontColor = UIColor.whiteColor()
    playLabel.position = CGPoint(x: self.size.width / 2 , y: 43)
    restartButton.addChild(playLabel)
    
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
    
    tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "GameOverScene")
    
    var builder = GAIDictionaryBuilder.createScreenView()
    tracker.send(builder.build() as [NSObject : AnyObject])
    
    var coinsCollected = GAIDictionaryBuilder.createEventWithCategory("AtDeath", action: "Collected", label: "Coins", value: score)
    tracker.send(coinsCollected.build() as [NSObject: AnyObject])
    
    var monstDestroyed = GAIDictionaryBuilder.createEventWithCategory("AtDeath", action: "Destroyed", label: "Monsters", value: monstersDestroyed)
    tracker.send(monstDestroyed.build() as [NSObject: AnyObject])
    
    var levelReach = GAIDictionaryBuilder.createEventWithCategory("AtDeath", action: "LevelReached", label: "Level", value: levelReached)
    tracker.send(levelReach.build() as [NSObject: AnyObject])

    if score > 50 {
      var coinsCollected = GAIDictionaryBuilder.createEventWithCategory("AtDeath", action: "Collected", label: "Over50Coins", value: score)
      tracker.send(coinsCollected.build() as [NSObject: AnyObject])
    }
    
    if highScoreAchieved == true {
      var highScoreAchievedEvent = GAIDictionaryBuilder.createEventWithCategory("AtDeath", action: "Collected", label: "HighScore", value: score)
      tracker.send(highScoreAchievedEvent.build() as [NSObject: AnyObject])
      
      var leaderboardID = "DragonDestinyLeaderboard"
      var sScore = GKScore(leaderboardIdentifier: leaderboardID)
      sScore.value = Int64(score)
      
      let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
      
      GKScore.reportScores([sScore], withCompletionHandler: { (error: NSError!) -> Void in
        if error != nil {
          println(error.localizedDescription)
        } else {
          println("Highscore submitted")
          
        }
      })
    }
    
    var message = "Dragon Destiny"
    if birthdayMode { message = "Birthday Destiny" }

    dragonDestinyLabel.text = message
    dragonDestinyLabel.fontSize = 30
    dragonDestinyLabel.fontColor = SKColor.blackColor()
    dragonDestinyLabel.position = CGPoint(x: size.width/2, y: self.size.height - 8 - dragonDestinyLabel.fontSize)
//    addChild(dragonDestinyLabel)
    
    var totalCoins = 0
    for i in 0...levelReached {
      totalCoins += i * self.coinsPerLevelMultiplier
    }
    
    message = "Score: \(score) (\(Int(Float(Float(score) / Float(totalCoins)*100)))%)"
    let coinsLabel = SKLabelNode(fontNamed: "Copperplate")
    coinsLabel.text = message
    coinsLabel.fontSize = 20
    coinsLabel.fontColor = SKColor.blackColor()
    coinsLabel.position = CGPoint(x: size.width/2, y: self.size.height - 10 - dragonDestinyLabel.fontSize)
    addChild(coinsLabel)
    
//    message = "% Coins Collected: \(Int(Float(Float(score) / Float(levelReached * 30))*100))%"
//    let percentageLabel = SKLabelNode(fontNamed: "Avenir")
//    percentageLabel.text = message
//    percentageLabel.fontSize = 20
//    percentageLabel.fontColor = SKColor.blackColor()
//    percentageLabel.position = CGPoint(x: size.width/2, y: coinsLabel.position.y - coinsLabel.fontSize)
//    addChild(percentageLabel)
 
    var monstersLabel = SKLabelNode()
    
    if let highScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
      message = "High Score: \(highScore)"
      let highScoreLabel = SKLabelNode(fontNamed: "Copperplate")
      highScoreLabel.text = message
      highScoreLabel.fontSize = 20
      highScoreLabel.fontColor = SKColor.blackColor()
      highScoreLabel.position = CGPoint(x: size.width/2, y: coinsLabel.position.y - coinsLabel.fontSize)
      addChild(highScoreLabel)
      
      monstersLabel = SKLabelNode(fontNamed: "Copperplate")
      monstersLabel.position = CGPoint(x: size.width/2, y: highScoreLabel.position.y - highScoreLabel.fontSize)
    } else {
      monstersLabel = SKLabelNode(fontNamed: "Copperplate")
      monstersLabel.position = CGPoint(x: size.width/2, y: coinsLabel.position.y - coinsLabel.fontSize)
    }
    
    message = "Arrows Destroyed: \(monstersDestroyed)"
    monstersLabel.text = message
    monstersLabel.fontSize = 20
    monstersLabel.fontColor = SKColor.blackColor()
    addChild(monstersLabel)

    message = "Level: \(levelReached)"
    let levelLabel = SKLabelNode(fontNamed: "Copperplate")
    levelLabel.text = message
    levelLabel.fontSize = 20
    levelLabel.fontColor = SKColor.blackColor()
    levelLabel.position = CGPoint(x: size.width/2, y: monstersLabel.position.y - monstersLabel.fontSize)
    addChild(levelLabel)
    
    
    blueDragon.size = CGSize(width: 50, height: 30)
    blueDragon.position = CGPoint(x: self.size.width * 6/24, y: 43 + restartButton.frame.height / 2 + blueDragon.size.height / 2 + 20)
    self.addChild(blueDragon)
    
    redDragon.size = CGSize(width: 50, height: 30)
    redDragon.position = CGPoint(x: self.size.width * 10/24, y: 43 + restartButton.frame.height / 2 + redDragon.size.height / 2 + 20)
    self.addChild(redDragon)
    
    greenDragon.size = CGSize(width: 50, height: 30)
    greenDragon.position = CGPoint(x: self.size.width * 14/24, y: 43 + restartButton.frame.height / 2 + greenDragon.size.height / 2 + 20)
    self.addChild(greenDragon)
    
    yellowDragon.size = CGSize(width: 50, height: 30)
    yellowDragon.position = CGPoint(x: self.size.width * 18/24, y: 43 + restartButton.frame.height / 2 + yellowDragon.size.height / 2 + 20)
    self.addChild(yellowDragon)
    
    flame.size = CGSize(width: 26, height: 48)
    flame.position = CGPoint(x: redDragon.position.x, y: redDragon.position.y + redDragon.size.height/2 + flame.size.height/2 - 1)
    
    fireball.size = CGSize(width: 15, height: 15)
    fireball.position = CGPoint(x: blueDragon.position.x, y: blueDragon.position.y + blueDragon.size.height/2 + flame.size.height/2 - 1)
    
    laser1.size = CGSize(width: 9, height: 20)
    laser1.position = CGPoint(x: greenDragon.position.x, y: greenDragon.position.y + greenDragon.size.height/2 + flame.size.height/2 - 1)

    laser2.size = CGSize(width: 9, height: 48)
    laser2.position = CGPoint(x: yellowDragon.position.x, y: yellowDragon.position.y + yellowDragon.size.height/2 + flame.size.height/2 - 1)
    
    message = "Choose Dragon of Destiny"
    let chooseDragonLabel = SKLabelNode(fontNamed: "Copperplate")
    chooseDragonLabel.text = message
    chooseDragonLabel.fontSize = 30
    chooseDragonLabel.fontColor = SKColor.blackColor()
    chooseDragonLabel.position = CGPoint(x: size.width/2, y: blueDragon.position.y + blueDragon.size.height + chooseDragonLabel.fontSize + 8)
    addChild(chooseDragonLabel)


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
    
//    let dragonLabel = SKLabelNode(fontNamed: "Copperplate")
//    dragonLabel.position = CGPoint(x: self.size.width/2, y: flame.position.y + flame.size.height)
//    dragonLabel.fontSize = 20
//    dragonLabel.text = "Choose Dragon of Destiny"
//    self.addChild(dragonLabel)
    
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
//    self.addChild(birthdayPickerLabel)
    
    let lockHeight = yellowDragon.size.height + flame.size.height
    
    lockFlame.position = CGPoint(x: redDragon.position.x, y: redDragon.position.y + 20)
    lockFlame.size = CGSize(width: 0.7 * lockHeight, height: lockHeight)
    lockFlame.zPosition = 10
    self.addChild(lockFlame)
    
    flameCostLabel.position = CGPoint(x: 0, y: -lockHeight/4)
    flameCostLabel.zPosition = 11
    flameCostLabel.text = "200 Coins"
    flameCostLabel.fontSize = 10
    lockFlame.addChild(flameCostLabel)
    
    lockLaserBall.position = CGPoint(x: greenDragon.position.x, y: greenDragon.position.y + 20)
    lockLaserBall.size = CGSize(width: 0.7 * lockHeight, height: lockHeight)
    lockLaserBall.zPosition = 10
    self.addChild(lockLaserBall)
    
    laserBallCostLabel.position = CGPoint(x: 0, y: -lockHeight/4)
    laserBallCostLabel.zPosition = 11
    laserBallCostLabel.text = "600 Coins"
    laserBallCostLabel.fontSize = 10
    lockLaserBall.addChild(laserBallCostLabel)

    lockLaserBeam.position = CGPoint(x: yellowDragon.position.x, y: yellowDragon.position.y + 20)
    lockLaserBeam.size = CGSize(width: 0.7 * lockHeight, height: lockHeight)
    lockLaserBeam.zPosition = 10
    self.addChild(lockLaserBeam)
    
    laserBeamCostLabel.position = CGPoint(x: 0, y: -lockHeight/4)
    laserBeamCostLabel.zPosition = 11
    laserBeamCostLabel.text = "1200 Coins"
    laserBeamCostLabel.fontSize = 10
    lockLaserBeam.addChild(laserBeamCostLabel)
    
    if let coinsUnwrapped = self.totalCoins {
      totalCoinsLabel.text = "Total Coins: \(coinsUnwrapped)"
    } else {
      totalCoinsLabel.text = "No Coins Yet"
    }

    totalCoinsLabel.fontSize = 12
    totalCoinsLabel.position = CGPoint(x: totalCoinsLabel.frame.width/2 + 10, y: self.size.height - 20)
    totalCoinsLabel.fontColor = UIColor.blackColor()
    self.addChild(totalCoinsLabel)
    
    if flameDragonPurchased == true {
      lockFlame.hidden = true
      flameCostLabel.hidden = true
    } else {
    }
    
    if laserBallDragonPurchased == true {
      lockLaserBall.hidden = true
      laserBallCostLabel.hidden = true
    } else {
    }
    
    if laserBeamDragonPurchased == true {
      lockLaserBeam.hidden = true
      laserBeamCostLabel.hidden = true
    } else {
    }
    
  }
  
  override func didMoveToView(view: SKView) {
    // Set IAPS
    if(SKPaymentQueue.canMakePayments()) {
      println("IAP is enabled, loading")
      var productID:NSSet = NSSet(objects: "Put IAP id here")
      var request: SKProductsRequest = SKProductsRequest(productIdentifiers: productID as Set<NSObject>)
      request.delegate = self
      request.start()
    } else {
      println("please enable IAPS")
    }
  }
  
  func authenticateLocalPlayer() {
    let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
    
    localPlayer.authenticateHandler = {(ViewController, error) -> Void in
      if((ViewController) != nil) {
        // 1 Show login if player is not logged in
//        self.presentViewController(ViewController, animated: true, completion: nil)
      } else if (localPlayer.authenticated) {
        // 2 Player is already euthenticated & logged in, load game center
        self.gcEnabled = true
        
        // Get the default leaderboard ID
        localPlayer.loadDefaultLeaderboardIdentifierWithCompletionHandler({ (leaderboardIdentifer: String!, error: NSError!) -> Void in
          if error != nil {
            println(error)
          } else {
            self.gcDefaultLeaderBoard = leaderboardIdentifer
          }
        })
      } else {
        // 3 Game center is not enabled on the users device
        self.gcEnabled = false
        println("Local player could not be authenticated, disabling game center")
        println(error)
      }
    }
  }
  
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    for touch in (touches as! Set<UITouch>) {
      let touchLocation = touch.locationInNode(self)
      
      let blueDragonExtendedRect = CGRectMake(blueDragon.position.x - blueDragon.size.width/2, blueDragon.position.y - blueDragon.size.height/2, blueDragon.size.width, blueDragon.size.height * 4)

      let redDragonExtendedRect = CGRectMake(redDragon.position.x - redDragon.size.width/2, redDragon.position.y - redDragon.size.height/2, redDragon.size.width, redDragon.size.height * 4)
      
      let greenDragonExtendedRect = CGRectMake(greenDragon.position.x - greenDragon.size.width/2, greenDragon.position.y - greenDragon.size.height/2, greenDragon.size.width, greenDragon.size.height * 4)
      
      let yellowDragonExtendedRect = CGRectMake(yellowDragon.position.x - yellowDragon.size.width/2, yellowDragon.position.y - yellowDragon.size.height/2, yellowDragon.size.width, yellowDragon.size.height * 4)
      
      if eliminateAdsButton.containsPoint(touchLocation) {
        for product in list {
          var prodID = product.productIdentifier
          if(prodID == "iAp id here") {
            p = product
            buyProduct()  //This is one of the functions we added earlier
            break;
          }
        }
      }
      
      if restartButton.containsPoint(touchLocation) {
//        restartButton.runAction(SKAction.scaleTo(1.25, duration: 0.5))
      }
      if (CGRectContainsPoint(blueDragonExtendedRect, touchLocation)) {
        self.dragonSelected = 0
        fireball.removeFromParent()
        flame.removeFromParent()
        laser1.removeFromParent()
        laser2.removeFromParent()
        self.addChild(fireball)
      } else if (CGRectContainsPoint(redDragonExtendedRect, touchLocation)) {
        if flameDragonPurchased == true {
          self.dragonSelected = 1
          fireball.removeFromParent()
          flame.removeFromParent()
          laser1.removeFromParent()
          laser2.removeFromParent()
          self.addChild(flame)
        } else {
          if let enoughCoins = self.totalCoins {
            if enoughCoins < flameDragonCost {
              AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            } else if enoughCoins >= flameDragonCost {
              let purchaseDragonAlert = UIAlertController(title: "Purchase Flame Dragon", message: "Spend 200 coins to unlock flame dragon?", preferredStyle: UIAlertControllerStyle.Alert)
              
              purchaseDragonAlert.addAction(UIAlertAction(title: "YES!", style: .Default, handler: { (action: UIAlertAction!) in
                println("flame dragon purchased")
                self.flameDragonPurchased = true
                self.fireball.removeFromParent()
                self.flame.removeFromParent()
                self.laser1.removeFromParent()
                self.laser2.removeFromParent()
                self.lockFlame.removeFromParent()
                self.addChild(self.flame)
                self.dragonSelected = 1
                NSUserDefaults.standardUserDefaults().setObject(true,forKey:"flameDragonPurchased")
                
                self.totalCoins! -= self.flameDragonCost
                self.totalCoinsLabel.text = "Total Coins: \(self.totalCoins!)"
                NSUserDefaults.standardUserDefaults().setObject(self.totalCoins,forKey:"TotalCoins")
                
                let path = NSBundle.mainBundle().pathForResource("flameVideo", ofType:"mov")
                let url = NSURL.fileURLWithPath(path!)
                self.moviePlayer = MPMoviePlayerController(contentURL: url)
                if let player = self.moviePlayer {
                  player.view?.frame = CGRect(x: self.size.width/10, y: self.size.height/10, width: self.size.width - 2 * self.size.width/10, height: self.size.height - 2 * self.size.height/10)
                  player.scalingMode = MPMovieScalingMode.AspectFit
                  player.fullscreen = true
                  player.controlStyle = MPMovieControlStyle.None
                  player.movieSourceType = MPMovieSourceType.File
                  player.repeatMode = MPMovieRepeatMode.None
                  player.prepareToPlay()
                  player.play()
                  
                  self.view?.addSubview(player.view)
                  
                  let flameDragonPurchasedEvent = GAIDictionaryBuilder.createEventWithCategory("PermanentUpgradePurchased", action: "dragonPurchased", label: "FlameDragonPurchased", value: self.flameDragonCost)
                  self.tracker.send(flameDragonPurchasedEvent.build() as [NSObject: AnyObject])
                  
                  NSNotificationCenter.defaultCenter().addObserver(self, selector: "doneButtonClick:", name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
                }
              }))
              
              purchaseDragonAlert.addAction(UIAlertAction(title: "I changed my mind", style: .Default, handler: { (action: UIAlertAction!) in
                println("Handle Cancel Logic here")
              }))
              
              self.view?.window?.rootViewController?.presentViewController(purchaseDragonAlert, animated: true, completion: nil)
            }
          }
        }
      } else if (CGRectContainsPoint(greenDragonExtendedRect, touchLocation)) {
        if laserBallDragonPurchased == true {
          self.dragonSelected = 2
          fireball.removeFromParent()
          flame.removeFromParent()
          laser1.removeFromParent()
          laser2.removeFromParent()
          self.addChild(laser1)
        } else {
          if let enoughCoins = self.totalCoins {
            if enoughCoins < laserBallDragonCost {
              AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            } else if enoughCoins >= laserBallDragonCost {
              let purchaseDragonAlert = UIAlertController(title: "Purchase Laser Dragon", message: "Spend 600 coins to unlock laser dragon?", preferredStyle: UIAlertControllerStyle.Alert)
              
              purchaseDragonAlert.addAction(UIAlertAction(title: "YES!", style: .Default, handler: { (action: UIAlertAction!) in
                println("laser ball dragon purchased")
                self.laserBallDragonPurchased = true
                self.fireball.removeFromParent()
                self.flame.removeFromParent()
                self.laser1.removeFromParent()
                self.laser2.removeFromParent()
                self.lockLaserBall.removeFromParent()
                self.addChild(self.laser1)
                self.dragonSelected = 2
                NSUserDefaults.standardUserDefaults().setObject(true,forKey:"laserBallDragonPurchased")
                
                self.totalCoins! -= self.laserBallDragonCost
                self.totalCoinsLabel.text = "Total Coins: \(self.totalCoins!)"
                NSUserDefaults.standardUserDefaults().setObject(self.totalCoins,forKey:"TotalCoins")
                
                let path = NSBundle.mainBundle().pathForResource("laserBallVideo", ofType:"mov")
                let url = NSURL.fileURLWithPath(path!)
                self.moviePlayer = MPMoviePlayerController(contentURL: url)
                if let player = self.moviePlayer {
                  player.view?.frame = CGRect(x: self.size.width/10, y: self.size.height/10, width: self.size.width - 2 * self.size.width/10, height: self.size.height - 2 * self.size.height/10)
                  player.scalingMode = MPMovieScalingMode.AspectFit
                  player.fullscreen = true
                  player.controlStyle = MPMovieControlStyle.None
                  player.movieSourceType = MPMovieSourceType.File
                  player.repeatMode = MPMovieRepeatMode.None
                  player.prepareToPlay()
                  player.play()
                  
                  self.view?.addSubview(player.view)
                  
                  let laserBallDragonPurchasedEvent = GAIDictionaryBuilder.createEventWithCategory("PermanentUpgradePurchased", action: "dragonPurchased", label: "laserBallDragonPurchased", value: self.laserBallDragonCost)
                  self.tracker.send(laserBallDragonPurchasedEvent.build() as [NSObject: AnyObject])
                  
                  NSNotificationCenter.defaultCenter().addObserver(self, selector: "doneButtonClick:", name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
                }
              }))
              
              purchaseDragonAlert.addAction(UIAlertAction(title: "I changed my mind", style: .Default, handler: { (action: UIAlertAction!) in
                println("Handle Cancel Logic here")
              }))
              
              self.view?.window?.rootViewController?.presentViewController(purchaseDragonAlert, animated: true, completion: nil)
            }
          }
        }
      } else if (CGRectContainsPoint(yellowDragonExtendedRect, touchLocation)) {
        if laserBeamDragonPurchased == true {
          self.dragonSelected = 3
          fireball.removeFromParent()
          flame.removeFromParent()
          laser1.removeFromParent()
          laser2.removeFromParent()
          self.addChild(laser2)
        } else {
          if let enoughCoins = self.totalCoins {
            if enoughCoins < laserBeamDragonCost {
              AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            } else if enoughCoins >= laserBeamDragonCost {
              let purchaseDragonAlert = UIAlertController(title: "Purchase Laser Beam Dragon", message: "Spend 1,200 coins to unlock laser beam dragon?", preferredStyle: UIAlertControllerStyle.Alert)
              
              purchaseDragonAlert.addAction(UIAlertAction(title: "YES!", style: .Default, handler: { (action: UIAlertAction!) in
                println("laser beam dragon purchased")
                self.laserBeamDragonPurchased = true
                self.fireball.removeFromParent()
                self.flame.removeFromParent()
                self.laser1.removeFromParent()
                self.laser2.removeFromParent()
                self.lockLaserBeam.removeFromParent()
                self.addChild(self.laser2)
                self.dragonSelected = 3
                NSUserDefaults.standardUserDefaults().setObject(true,forKey:"laserBeamDragonPurchased")
                
                self.totalCoins! -= self.laserBeamDragonCost
                self.totalCoinsLabel.text = "Total Coins: \(self.totalCoins!)"
                NSUserDefaults.standardUserDefaults().setObject(self.totalCoins,forKey:"TotalCoins")
                
                let path = NSBundle.mainBundle().pathForResource("laserBeamVideo", ofType:"mov")
                let url = NSURL.fileURLWithPath(path!)
                self.moviePlayer = MPMoviePlayerController(contentURL: url)
                if let player = self.moviePlayer {
                  player.view?.frame = CGRect(x: self.size.width/10, y: self.size.height/10, width: self.size.width - 2 * self.size.width/10, height: self.size.height - 2 * self.size.height/10)
                  player.scalingMode = MPMovieScalingMode.AspectFit
                  player.fullscreen = true
                  player.controlStyle = MPMovieControlStyle.None
                  player.movieSourceType = MPMovieSourceType.File
                  player.repeatMode = MPMovieRepeatMode.None
                  player.prepareToPlay()
                  player.play()
                  
                  self.view?.addSubview(player.view)
                  
                  let laserBeamDragonPurchasedEvent = GAIDictionaryBuilder.createEventWithCategory("PermanentUpgradePurchased", action: "dragonPurchased", label: "LaserBeamDragonPurchased", value: self.laserBeamDragonCost)
                  self.tracker.send(laserBeamDragonPurchasedEvent.build() as [NSObject: AnyObject])
                  
                  NSNotificationCenter.defaultCenter().addObserver(self, selector: "doneButtonClick:", name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
                }
              }))
              
              purchaseDragonAlert.addAction(UIAlertAction(title: "I changed my mind", style: .Default, handler: { (action: UIAlertAction!) in
                println("Handle Cancel Logic here")
              }))
              
              self.view?.window?.rootViewController?.presentViewController(purchaseDragonAlert, animated: true, completion: nil)
            }
          } 
        }
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
  
  func doneButtonClick(sender:NSNotification?){
    let value = UIInterfaceOrientation.Portrait.rawValue
    UIDevice.currentDevice().setValue(value, forKey: "orientation")
    self.moviePlayer.stop()
    self.moviePlayer.view.removeFromSuperview()
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

      var dragonSelected = GAIDictionaryBuilder.createEventWithCategory("GameOptionsSelected", action: "dragonSelected", label: "dragonSelected", value: self.dragonSelected)
      self.tracker.send(dragonSelected.build() as [NSObject: AnyObject])

      let scene = GameScene(size: self.size, level: 1, muted: self.muted, coinsCollected: 0, monstersDestroyed: 0, shield: Shield(), dragonType: self.dragonSelected, birthdayMode: self.birthdayMode, birthdayPicture: self.birthdayPicture)
      self.view?.presentScene(scene, transition:reveal)
    }
    restartButton.runAction(SKAction.sequence([scaleBack, pushRestart]))
  }
//  
//  func eliminateAdsButtonPushed() {
//    buyProduct()
//  }
  
  //In App Purchases
  var list = [SKProduct]()
  var p = SKProduct()
  
  func buyProduct() {
    println("buy " + p.productIdentifier)
    var pay = SKPayment(product: p)
    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    SKPaymentQueue.defaultQueue().addPayment(pay as SKPayment)
  }
  
  func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
    var myProduct = response.products
    println("Received \(myProduct.count) products in IAP response")
    
    for product in myProduct {
      println("product added")
      println(product.productIdentifier)
      println(product.localizedTitle)
      println(product.localizedDescription)
//      println(product.price)
      
      list.append(product as! SKProduct)
      
      if product.productIdentifier == "eliminateAds" {
        let eliminateAdsButtonSize = CGFloat(40)
        eliminateAdsButton.size = CGSize(width: eliminateAdsButtonSize, height: eliminateAdsButtonSize)
        eliminateAdsButton.position = CGPoint(x: size.width - eliminateAdsButtonSize/1.5, y: size.height - eliminateAdsButtonSize/1.5)
        eliminateAdsButton.name = "eliminateAdsButton"
        if !NSUserDefaults.standardUserDefaults().boolForKey("eliminateAdsPurchased") {
          addChild(eliminateAdsButton)
        }

      }
    }
  }
  
  func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue!) {
    println("transactions restored")
    
    var purchasedItemIDS = []
    for transaction in queue.transactions {
      var t: SKPaymentTransaction = transaction as! SKPaymentTransaction
      
      let prodID = t.payment.productIdentifier as String
      
      switch prodID {
      case "eliminateAds":
        NSUserDefaults.standardUserDefaults().setBool(true , forKey: "eliminateAdsPurchased")
        
        let eliminateAdsPurchasedEvent = GAIDictionaryBuilder.createEventWithCategory("InAppPurchase", action: "eliminateAds", label: "eliminateAdsPurchased", value: 1.99)
        self.tracker.send(eliminateAdsPurchasedEvent.build() as [NSObject: AnyObject])

        
        //Right here is where you should put the function that you want to execute when your in app purchase is complete
      default:
        println("IAP not setup")
      }
      
    }
    
    var alert = UIAlertView(title: "Thank You", message: "Your purchase(s) were restored. You may have to restart the app before ads are removed.", delegate: nil, cancelButtonTitle: "OK")
    alert.show()
  }
  
  
  func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
    println("add paymnet")
    
    for transaction:AnyObject in transactions {
      var trans = transaction as! SKPaymentTransaction
      println(trans.error)
      
      switch trans.transactionState {
        
      case .Purchased, .Restored:
        println("buy, ok unlock iap here")
        println(p.productIdentifier)
        
        let prodID = p.productIdentifier as String
        switch prodID {
        case "eliminateAds":
          
          //Here you should put the function you want to execute when the purchase is complete
          var alert = UIAlertView(title: "Thank You", message: "You may have to restart the app before the banner ads are removed.", delegate: nil, cancelButtonTitle: "OK")
          alert.show()
        default:
          println("IAP not setup")
        }
        
        queue.finishTransaction(trans)
        break;
      case .Failed:
        println("buy error")
        queue.finishTransaction(trans)
        break;
      default:
        println("default")
        break;
        
      }
    }
  }
  
  func finishTransaction(trans:SKPaymentTransaction)
  {
    println("finish trans")
  }
  func paymentQueue(queue: SKPaymentQueue!, removedTransactions transactions: [AnyObject]!)
  {
    println("remove trans");
  }

  // 6
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
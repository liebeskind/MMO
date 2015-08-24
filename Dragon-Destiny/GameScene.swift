//
//  GameScene.swift
//  SpriteKitSimpleGame
//
//  Created by Main Account on 9/30/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import AVFoundation
import SpriteKit

func + (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
  return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}

enum PhysicsCategory : UInt32 {
  case None   = 0
  case All    = 0xFFFFFFFF
  case Monster  = 0b001
  case Projectile = 0b010
  case Player = 0b100
  case Coin = 01000
}

//enum BodyType:UInt32 {
//  
//  case player = 1
//  case ground = 2
//  case anotherBody1 = 4
//  case anotherBody2 = 8
//  case anotherBody3 = 16
//  
//}

enum MoveStates:Int {
  
  case N,S,E,W,NE,NW,SE,SW
}

class GameScene: SKScene, SKPhysicsContactDelegate{
  
  let musicController = MusicController()
  
  let backgroundMovePointsPerSec: CGFloat = 5.0
  let backgroundLayer = SKNode()
  var backgroundWidth = CGFloat()
  var totalBackgrounds = Int()
  var leftPoint = CGFloat(0)
  var rightPoint = CGFloat()
  var movePoint = CGFloat()
  
  var player = SKSpriteNode(imageNamed: "BlueDragonFlap0")
  var playerFlyingScenes: [SKTexture]!
  var flyingSpeed = 0.05
  var playerDead = false
  
  var fireballScenes: [SKTexture]!
  var arrowScenes: [SKTexture]!
  
  var monstersDestroyed = 0
  var coinsCollected = 0
  var coinCount = 0
  var totalCoins = Int()
  let totalCoinsBoard = SKLabelNode(fontNamed: "Avenir")
  let scoreBoard = SKLabelNode(fontNamed: "Avenir")
  let highScoreBoard = SKLabelNode(fontNamed: "Avenir")
  
  var currentState = MoveStates.N
  
  let base = SKSpriteNode(imageNamed:"aSBgImg")
  let ball = SKSpriteNode(imageNamed:"aSThumbImg")
  let baseSize = CGFloat(75.0)
  
  var stickActive:Bool = false
  var playerMoving: Bool = false
  
  var shipSpeedX:CGFloat = 0.0
  var shipSpeedY:CGFloat = 0.0
  var strictCompassMovements:Bool = false

  let attackButton = SKSpriteNode(imageNamed: "AttackButton")
  var mostRecentBallPosition = CGPoint() // Used for aiming attack when not moving
  var mostRecentBasePosition = CGPoint() // Used for aiming attack when not moving
  
  var purchaseFlame = SKSpriteNode(imageNamed: "FlameUpgradeButton")
  let flameUpgradeCost = 20
  var flamePurchased = false
  
  var purchaseSlowmo = SKSpriteNode(imageNamed: "SlowmoUpgradeButton")
  let slowmoUpgradeCost = 10
  var slowmoPurchased = false
  var slowmoSpeedModifier = CGFloat(4.0)
  let slowmoDuration = 10.0
  
  var flame = SKSpriteNode()
  var flameScenes: [SKTexture]!
  var flameStartScenes: [SKTexture]!
  
  let navigationBox = SKSpriteNode(color: UIColor.grayColor(), size: CGSize(width: 200.0, height: 150.0))

  var projectile = SKSpriteNode()
  
  var dt: NSTimeInterval = 0
  
  override func didMoveToView(view: SKView) {
    if let highScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
    } else {
      NSUserDefaults.standardUserDefaults().setObject(0,forKey:"HighestScore")
    }
    
    if let coins: Int = NSUserDefaults.standardUserDefaults().objectForKey("TotalCoins") as? Int {
      totalCoins = coins
    } else {
      NSUserDefaults.standardUserDefaults().setObject(0,forKey:"TotalCoins")
    }
    
    physicsWorld.gravity = CGVectorMake(0, 0)
    physicsWorld.contactDelegate = self
  
    musicController.loadSoundEffect("FireballSound.wav")
    musicController.playBackgroundMusic("epicMusic.mp3")
    
    navigationBox.position = CGPoint(x: 0.0, y: 0.0)
    navigationBox.anchorPoint = CGPoint(x: 0, y: 0)
    navigationBox.alpha = 0.8
    navigationBox.zPosition = 1
    navigationBox.size = CGSize(width: frame.size.width, height: baseSize)
    addChild(navigationBox)
    
    backgroundLayer.zPosition = -1
    addChild(backgroundLayer)
  
    for i in 0...20 {
      totalBackgrounds = i
      let background = backgroundNode()
      background.anchorPoint = CGPointZero
      background.position =
      CGPoint(x: CGFloat(i)*background.size.width, y: 0)
      background.name = "background"
//      addChild(background)
      backgroundLayer.addChild(background)
    }
    
    rightPoint = self.frame.width
    movePoint = rightPoint / 1.5
    
////    backgroundColor = SKColor.whiteColor()
//    background.size = frame.size
//    background.zPosition = -1
//    background.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
//    self.addChild(background)
    
    let playerAnimatedAtlas = SKTextureAtlas(named: "playerImages")
    var flyFrames = [SKTexture]()
    
    let numImages = playerAnimatedAtlas.textureNames.count
    for var i=0; i<numImages; i++ {
      let playerTextureName = "BlueDragonFlap\(i)"
      flyFrames.append(playerAnimatedAtlas.textureNamed(playerTextureName))
    }
    
    //Makes wing flapping animation more fluid as doesn't just reset at end
    for var i=numImages-1; i>=0; i-- {
      let playerTextureName = "BlueDragonFlap\(i)"
      flyFrames.append(playerAnimatedAtlas.textureNamed(playerTextureName))
    }
    
    playerFlyingScenes = flyFrames
    
    let firstFrame = playerFlyingScenes[0]
    player = SKSpriteNode(texture: firstFrame)
    
    backgroundLayer.addChild(player)
    
    player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    player.size = CGSize(width: 50, height: 33)
    player.zPosition = 10
    player.zRotation = -1.57079633 //Start off facing right
    var playerCenter = CGPoint(x: player.position.x, y: player.position.y)

    player.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: player.size.width-35, height: player.size.height-20))
    player.physicsBody?.dynamic = true
    player.physicsBody?.categoryBitMask = PhysicsCategory.Player.rawValue
    player.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue
    player.physicsBody?.contactTestBitMask = PhysicsCategory.Coin.rawValue
    player.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
    
    flyingPlayer()
    
    let fireballAnimatedAtlas = SKTextureAtlas(named: "fireballImages")
    var fireballFrames = [SKTexture]()
    
    let numFireballImages = fireballAnimatedAtlas.textureNames.count
    for var i=0; i<numFireballImages; i++ {
      let fireballTextureName = "Fireball\(i)"
      fireballFrames.append(fireballAnimatedAtlas.textureNamed(fireballTextureName))
    }
    
    fireballScenes = fireballFrames
    
    let firstFireballFrame = fireballScenes[0]
    projectile = SKSpriteNode(texture: firstFireballFrame) // Not sure this does anything.  Meant to cache so no delay.
    
    let arrowAnimatedAtlas = SKTextureAtlas(named: "arrowImages")
    var arrowFrames = [SKTexture]()
    
    let numArrowImages = arrowAnimatedAtlas.textureNames.count
    for var i=0; i<numArrowImages; i++ {
      let arrowTextureName = "Arrow\(i)"
      arrowFrames.append(arrowAnimatedAtlas.textureNamed(arrowTextureName))
    }
    
    arrowScenes = arrowFrames
    
    let flameAnimatedAtlas = SKTextureAtlas(named: "fullFlameImages")
    var flameFrames = [SKTexture]()
    
    let numFlameImages = flameAnimatedAtlas.textureNames.count
    for var i=0; i<numFlameImages; i++ {
      let flameTextureName = "FullFlame\(i)"
      flameFrames.append(flameAnimatedAtlas.textureNamed(flameTextureName))
    }
    
    flameScenes = flameFrames
    
    let flameStartAnimatedAtlas = SKTextureAtlas(named: "flameImages")
    var flameStartFrames = [SKTexture]()
    
    let numFlameStartImages = flameStartAnimatedAtlas.textureNames.count
    for var i=0; i<numFlameStartImages; i++ {
      let flameStartTextureName = "Flame\(i)"
      flameStartFrames.append(flameStartAnimatedAtlas.textureNamed(flameStartTextureName))
    }
    
    flameStartScenes = flameStartFrames

    addMonster()
    addCoins()
    
    self.addCoinBlock(500)
    
    self.addMonsterBlock(1.0)
    
//    runAction(SKAction.repeatAction(
//      SKAction.runBlock(addCoin), count: 10)
//    )
    
    totalCoinsBoard.position = CGPoint(x: size.width - 50, y: size.height-30)
    totalCoinsBoard.fontColor = UIColor.blackColor()
    totalCoinsBoard.fontSize = 15
    totalCoinsBoard.horizontalAlignmentMode = .Right
    //    scoreBoard.frame = CGRect(x: 200, y: 10, width: 100, height: 40)
    //    scoreBoard.font = UIFont.systemFontOfSize(20)
    totalCoinsBoard.text = "Total Coins: \(totalCoins)"
    
    addChild(totalCoinsBoard)
    
    scoreBoard.position = CGPoint(x: 10, y: size.height-30)
    scoreBoard.fontColor = UIColor.blackColor()
    scoreBoard.fontSize = 15
    scoreBoard.horizontalAlignmentMode = .Left
//    scoreBoard.frame = CGRect(x: 200, y: 10, width: 100, height: 40)
//    scoreBoard.font = UIFont.systemFontOfSize(20)
    scoreBoard.text = "Score: \(coinsCollected)"
    
    addChild(scoreBoard)
    
    highScoreBoard.position = CGPoint(x: 10, y: size.height-50)
    highScoreBoard.fontColor = UIColor.blackColor()
    highScoreBoard.fontSize = 15
    highScoreBoard.horizontalAlignmentMode = .Left
    //    scoreBoard.frame = CGRect(x: 200, y: 10, width: 100, height: 40)
    //    scoreBoard.font = UIFont.systemFontOfSize(20)
    if let savedScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
      highScoreBoard.text = "High Score: \(savedScore)"
    } else {
      highScoreBoard.text = "High Score: \(0)"
    }
    
    addChild(highScoreBoard)
    
    addChild(base)
    base.position = CGPointMake(10.0 + baseSize/2, baseSize/2)
    base.size = CGSize(width: baseSize, height: baseSize)
    base.zPosition = 2
    base.alpha = 0.8
    
    addChild(ball)
    ball.position = CGPointMake(base.position.x + 1, base.position.y) //Makes player face right and fireballs shoot right if don't move first
    ball.size = CGSize(width: baseSize/2, height: baseSize/2)
    ball.zPosition = 3
    ball.alpha = 0.8

    attackButton.size = CGSize(width: baseSize * 1.3, height: baseSize * 0.9)
    attackButton.position = CGPoint(x: self.frame.width - attackButton.size.width/2 - 5, y: attackButton.size.height/1.8)
    attackButton.alpha = 0.8
    attackButton.zPosition = 2
    self.addChild(attackButton)
    
//    purchaseSlowmo.size = CGSize(width: 100.0, height: 26.0)
    purchaseSlowmo.size = attackButton.size
    purchaseSlowmo.alpha = attackButton.alpha
    purchaseSlowmo.position = CGPoint(x: attackButton.position.x - attackButton.size.width - 12, y: attackButton.position.y)
    purchaseSlowmo.zPosition = 2
    self.addChild(purchaseSlowmo)
    
    purchaseFlame.size = CGSize(width: 100.0, height: 26.0)
    purchaseFlame.position = CGPoint(x: size.width - 100, y: size.height-80)
//    self.addChild(purchaseFlame)
    
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }

  func random(#min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }
  
  func backgroundNode() -> SKSpriteNode{
    let backgroundNode = SKSpriteNode()
    backgroundNode.anchorPoint = CGPointZero
    backgroundNode.name = "background"

    let background1 = SKSpriteNode(imageNamed: "sky")
    background1.size = frame.size
    background1.anchorPoint = CGPointZero
    background1.position = CGPoint(x: 0, y: 0)
    backgroundNode.addChild(background1)
    
    rightPoint = background1.frame.width

    let background2 = SKSpriteNode(imageNamed: "sky2")
    background2.size = frame.size
    background2.anchorPoint = CGPointZero
    background2.position =
      CGPoint(x: background1.size.width, y: 0)
    backgroundNode.addChild(background2)
  
    backgroundNode.size = CGSize(
      width: background1.size.width + background2.size.width,
      height: frame.size.height)
    backgroundWidth = backgroundNode.size.width * CGFloat(totalBackgrounds)
    return backgroundNode
  }
  
  func moveBackgroundRight(speed: CGFloat) {
//    enumerateChildNodesWithName("background") { node, _ in
//    let background = node as! SKSpriteNode
    self.backgroundLayer.position.x -= speed
    
    backgroundLayer.enumerateChildNodesWithName("background") {
      node, _ in
      let background = node as! SKSpriteNode
      if background.position.x <= -background.size.width {
        background.position = CGPoint(
        x: background.position.x + background.size.width*2,
        y: background.position.y)
      }
    }
    rightPoint += speed
    leftPoint += speed
    movePoint += speed
  }
  
  func moveBackgroundLeft() {
      enumerateChildNodesWithName("background") { node, _ in
      let background = node as! SKSpriteNode
      let backgroundVelocity = CGPoint(x: self.backgroundMovePointsPerSec, y: 0)
      
      let amountToMove = backgroundVelocity
      background.position = background.position + amountToMove
      if background.position.x <= -background.size.width {
      background.position = CGPoint(
      x: background.position.x + background.size.width*2,
      y: background.position.y)
      }
      }
  }
  
  func flyingPlayer() {
    
//    while playerMoving == true {
//      let fly = SKAction.animateWithTextures(playerFlyingScenes, timePerFrame: 0.05)
//      player.runAction(fly)
//    }
  
    player.runAction(SKAction.repeatActionForever(
      
      SKAction.animateWithTextures(playerFlyingScenes,
        timePerFrame: flyingSpeed,
        resize: false,
        restore: true)),
      withKey:"playerFlappingWings")
  }
  
  func addCoinBlock(numCoins: Int) {
        self.runAction(SKAction.repeatAction(
//          SKAction.sequence([
          SKAction.runBlock(self.addCoins),
//          SKAction.waitForDuration(speed)
           count: numCoins)
//          ), withKey: "addingMonsters"
        )
  }
  
  func addCoins() {
//    while coinCount < 11 {
      let coin = SKSpriteNode(imageNamed: "coin")
      coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.width/2)
      coin.physicsBody?.dynamic = true
      coin.physicsBody?.categoryBitMask = PhysicsCategory.Coin.rawValue
  //    coin.physicsBody?.contactTestBitMask = PhysicsCategory.Player.rawValue
      coin.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
      
      // Determine where to spawn the coin along the Y axis
      let actualY = random(min: coin.size.height + baseSize, max: self.frame.size.height - coin.size.height)
      let actualX = random(min: coin.size.width, max: backgroundWidth - coin.size.width)
      
      coin.position = CGPoint(x: actualX, y: actualY)

      backgroundLayer.addChild(coin)
      coinCount++
//    }
  }

  func addMonsterBlock(speed: Double) {
    self.runAction(SKAction.repeatActionForever(
      SKAction.sequence([
        SKAction.runBlock(self.addMonster),
        SKAction.waitForDuration(speed)
        ])
      ), withKey: "addingMonsters"
    )
  }
  
  func addMonster() {

    // Create sprite
    let monster = Monster(texture: arrowScenes[0])
    monster.size = CGSize(width: 50.0, height: 10.0)
    monster.name = "arrow"
    monster.playerPosition = CGPoint(x: player.position.x, y: player.position.y)
    monster.leftPoint = leftPoint
    
    monster.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: monster.size.width, height: monster.size.height))
//    monster.physicsBody = SKPhysicsBody(circleOfRadius: monster.size.width/2)
    monster.physicsBody?.dynamic = true
    monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster.rawValue
    monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile.rawValue
    monster.physicsBody?.contactTestBitMask = PhysicsCategory.Player.rawValue
    monster.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
    
    // Determine where to spawn the monster along the Y axis
    let actualY = random(min: monster.size.height/2 + baseSize, max: size.height - monster.size.height/2)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    monster.position = CGPoint(x: rightPoint + monster.size.height, y: actualY)
    
//    let v = CGVector(dx: monster.position.x - player.position.x, dy:  monster.position.y - player.position.y)
//    let angle = atan2(v.dy, v.dx)
//    
//    monster.zRotation = angle
    
    // Add the monster to the scene
    backgroundLayer.addChild(monster)
    
    // Determine speed of the monster
    let minimum = max(Double(3 - (coinsCollected)/20), 0.5)
    let maximum = minimum + 1.5
    var actualDuration = random(min: CGFloat(minimum), max: CGFloat(maximum))
    if slowmoPurchased {
      monster.moveDuration = actualDuration
      actualDuration += slowmoSpeedModifier
    }
    
    // Create the actions
    let actionMove = SKAction.moveTo(CGPoint(x: leftPoint - monster.size.width/2, y: player.position.y), duration: NSTimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()

    monster.runAction(SKAction.sequence([actionMove, actionMoveDone]), withKey: "moveSequence")
  }
  
  func upgradePurchased(upgrade: SKSpriteNode) {
    switch upgrade {
    case purchaseFlame:
      if totalCoins < flameUpgradeCost {return}
      if flamePurchased == true {return}
      totalCoins -= flameUpgradeCost
      totalCoinsBoard.text = "Total Coins: \(totalCoins)"
      let shrink = SKAction.scaleTo(0, duration: 0.6)
      purchaseFlame.runAction(SKAction.sequence([shrink, SKAction.removeFromParent()]))
      flamePurchased = true
    case purchaseSlowmo:
      if totalCoins < slowmoUpgradeCost {return}
      if slowmoPurchased == true {return}
      totalCoins -= slowmoUpgradeCost
      totalCoinsBoard.text = "Total Coins: \(totalCoins)"
      
      let playUpgrade = SKAction.runBlock {
        self.musicController.pauseBackgroundMusic()
        self.musicController.playUpgradeMusic("dubstepMusic.mp3")
      }
      
      let returnToBackgroundMusic = SKAction.runBlock {
        self.musicController.stopUpgradeMusic()
        self.musicController.resumeBackgroundMusic()
      }
      
      runAction(SKAction.sequence([playUpgrade, SKAction.waitForDuration(slowmoDuration), returnToBackgroundMusic]))
      
      self.slowmoPurchased = true
      let quickPop = SKAction.scaleTo(1.1, duration: 0.1)
      let shrink = SKAction.scaleTo(0, duration: slowmoDuration)
      let grow = SKAction.scaleTo(1.0, duration: 0.1)
      
      var countDown = 10
      let count = SKLabelNode(fontNamed: "Chalkduster")
      count.position = CGPoint(x: 0, y: 0)
      count.fontColor = UIColor.whiteColor()
      count.text = String(countDown)
      count.fontSize = 30.0
      count.zPosition = 2
      purchaseSlowmo.addChild(count)

      let wait = SKAction.waitForDuration(1.0)
      let keepCount = SKAction.runBlock {
        countDown = self.reduceByOne(countDown)
        count.text = String(countDown)
        if (countDown < 2) {
          count.removeFromParent()
        }
      }
      
      self.removeActionForKey("addingMonsters")
      self.addMonsterBlock(2.0)
      
      backgroundLayer.enumerateChildNodesWithName("arrow") {
        node, stop in
        node.removeAllActions()
        
        let monster = node as! Monster
        
        var actionMove = SKAction()
        
        // Create the actions
        if let monsterExistingMoveDuration = monster.moveDuration {
          actionMove = SKAction.moveTo(CGPoint(x: monster.leftPoint! - monster.size.width/2, y: monster.playerPosition!.y), duration: NSTimeInterval(self.slowmoSpeedModifier + monsterExistingMoveDuration))
        } else {
          actionMove = SKAction.moveTo(CGPoint(x: monster.leftPoint! - monster.size.width/2, y: monster.playerPosition!.y), duration: NSTimeInterval(self.slowmoSpeedModifier))
        }
//        let actionMove = SKAction.moveTo(CGPoint(x: -100.0, y: monster.playerPosition!.y), duration: NSTimeInterval(self.slowmoSpeedModifier + monster.moveDuration!))
        let actionMoveDone = SKAction.removeFromParent()
        
        monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
      }
      
      let returnToNormalSpeed = SKAction.runBlock {
        self.slowmoPurchased = false
        
        self.removeActionForKey("addingMonsters")
        if self.coinsCollected < 50 {
          self.addMonsterBlock(1.0)
        } else {
          self.addMonsterBlock(0.5)
        }
        
        self.backgroundLayer.enumerateChildNodesWithName("arrow") {
          node, stop in
          node.removeAllActions()
          
          let monster = node as! Monster
          
          // Create the actions
          let actionMove = SKAction.moveTo(CGPoint(x: monster.leftPoint! - monster.size.width/2, y: monster.playerPosition!.y), duration: NSTimeInterval(monster.moveDuration!))
          let actionMoveDone = SKAction.removeFromParent()
          
          monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        }
      }
    
      let countDownSequence = SKAction.repeatAction(SKAction.sequence([wait, keepCount]), count: 10)
      let shrinkAndCountGroup = SKAction.group([shrink, countDownSequence])
      
      purchaseSlowmo.runAction(SKAction.sequence([quickPop, shrinkAndCountGroup, grow, returnToNormalSpeed]))
      
    default: return
    }
  }
  
  func reduceByOne(toReduce: Int) -> Int {
    let toReturn = toReduce - 1
    return toReturn
  }
  
  func convertAngleToVector(radians: Double) ->CGVector {
    var vector = CGVector()
    let floatRadians = CGFloat(radians)
    vector.dx = cos(floatRadians) * (flame.size.width/2 + 14)
    vector.dy = sin(floatRadians) * (flame.size.width/2 + 14)
    return vector
  }
  
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    for touch in (touches as! Set<UITouch>) {
      let touchLocation = touch.locationInNode(self)
      if (CGRectContainsPoint(attackButton.frame, touchLocation)) && playerDead == false {
        attackButtonPushed()
        if flamePurchased == true {
          flame = SKSpriteNode(texture: flameScenes[0])
          flame.size = CGSize(width: player.size.width/2, height: player.size.width/4)
          flame.zPosition = 1
          
          let animateFlame = SKAction.animateWithTextures(flameScenes, timePerFrame: 0.07)
          let flameStart = SKAction.group([ animateFlame, SKAction.scaleBy(4.0, duration: 0.5) ])
          let repeatForever = SKAction.repeatActionForever(animateFlame)
          flame.runAction(SKAction.sequence([flameStart, repeatForever]))
          
          flame.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: flame.size.width, height: flame.size.height))
          flame.physicsBody?.dynamic = true
          flame.physicsBody?.categoryBitMask = PhysicsCategory.Projectile.rawValue
          flame.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue
          flame.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
          
          backgroundLayer.addChild(flame)
        } 
      } else if (CGRectContainsPoint(purchaseFlame.frame, touchLocation)) && playerDead == false {
        upgradePurchased(purchaseFlame)
      } else if (CGRectContainsPoint(purchaseSlowmo.frame, touchLocation)) && playerDead == false {
        upgradePurchased(purchaseSlowmo)
      }  else if stickActive != true {
//        stickActive = true
      
//        ball.alpha = 0.4
//        base.alpha = 0.4
        
//        base.position = CGPoint(x: min(max(touchLocation.x, baseSize/2), self.frame.width/2), y: baseSize/2)
//        ball.position = base.position
        mostRecentBasePosition = base.position
        mostRecentBallPosition = ball.position
      }
    }
  }
  
  override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
    if playerDead == false {
      for touch in (touches as! Set<UITouch>) {
      let touchLocation = touch.locationInNode(self)
        playerMoving = true
        stickActive = true
        
        let v = CGVector(dx: touchLocation.x - base.position.x, dy:  touchLocation.y - base.position.y)
        let angle = atan2(v.dy, v.dx)
        
        let deg = angle * CGFloat( 180 / M_PI)
        
        self.figureOutDirection( deg + 180)
        
        let length:CGFloat = base.frame.size.height / 2
        let xDist:CGFloat = sin(angle - 1.57079633) * length
        let yDist:CGFloat = cos(angle - 1.57079633) * length
        
        if (CGRectContainsPoint(base.frame, touchLocation)) {
          
          ball.position = touchLocation
          mostRecentBasePosition = base.position
          mostRecentBallPosition = ball.position
          
        } else if (CGRectContainsPoint(attackButton.frame, touchLocation)) {
          return

        } else {
          ball.position = CGPointMake( base.position.x - xDist, base.position.y + yDist)
          mostRecentBasePosition = base.position
          mostRecentBallPosition = ball.position
        }
        
        player.zRotation = angle - 1.57079633
  //        let flamePosVector = convertAngleToVector(Double(player.zRotation) + M_PI_2)
  //        flame.position = CGPoint(x: player.position.x + flamePosVector.dx, y: player.position.y + flamePosVector.dy)
  ////        flame.position = CGPoint(x: player.position.x, y: player.position.y + player.size.height/2)
  //        flame.zRotation = player.zRotation + 1.57079633
      
        // set up the speed
        let multiplier:CGFloat = 0.08
        
        shipSpeedX = max(min(v.dx * multiplier, 2.2), -2.2)
        shipSpeedY = max(min(v.dy * multiplier, 2.2), -2.2)
        
  //        stickActive = false
      
      } // ends stickActive test
  //    }
    }
  }
  
  override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
    for touch in (touches as! Set<UITouch>) {
      let touchLocation = touch.locationInNode(self)
      if (CGRectContainsPoint(attackButton.frame, touchLocation)) {
        flame.removeFromParent()
      }
    }
    
    stickActive = false
//    flame.hidden = true
    
    if (stickActive == true) {
//      stickActive = false
//      playerMoving = false
//      stickActive = false
//
//      let move:SKAction = SKAction.moveTo(base.position, duration: 0.2)
//      move.timingMode = .EaseOut
//      
//      ball.runAction(move)
//      
//      let fade:SKAction = SKAction.fadeAlphaTo(0, duration: 0.3)
//      
//      ball.runAction(fade)
//      base.runAction(fade)
      
//      shipSpeedX /= 2
//      shipSpeedY /= 2
      
//      shipSpeedX = 0
//      shipSpeedY = 0
    }
  }
  
  func attackButtonPushed() {
    println("attack")
    
    var offset = CGPoint()
    
    // 2 - Set up initial location of projectile
    var projectile = SKSpriteNode(texture: fireballScenes[0])
    
    projectile.position = player.position
    projectile.size = CGSize(width: 25.0, height: 25.0)
    
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    projectile.physicsBody?.dynamic = true
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile.rawValue
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
    projectile.physicsBody?.usesPreciseCollisionDetection = true
    
    var vector = CGVector()
    
    if ball.position != base.position {
      offset = ball.position - base.position
    } else {
      offset = mostRecentBallPosition - mostRecentBasePosition
    }
    
    backgroundLayer.addChild(projectile)
    
    let direction = offset.normalized()
    let shootAmount = direction * 200
    let realDest = shootAmount + projectile.position
    
    let actionMove = SKAction.moveTo(realDest, duration: 0.4)
    let actionMoveDone = SKAction.removeFromParent()
    let shootFireball = SKAction.animateWithTextures(fireballScenes, timePerFrame: 0.05)
    let shrink = SKAction.scaleTo(0.0, duration: 0.6)
    let shootFireballGroup = SKAction.group([shootFireball, shrink])
  
    projectile.runAction(SKAction.repeatActionForever(shootFireballGroup))
    projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    
    self.musicController.playSoundEffect("FireballSound.wav")
    
//    let v = CGVector(dx: base.position.x - player.position.x, dy:  base.position.y - player.position.y)
//    let angle = atan2(v.dy, v.dx)
//    player.zRotation = angle - 1.57079633
  }

  
  func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
    println("Hit")
    
    projectile.removeFromParent()
    
    monster.size = CGSize(width: 50.0, height: 30.0)
    monster.texture = arrowScenes[2]
    monster.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 0.1, height: 0.1))
    monster.physicsBody?.dynamic = true
    monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster.rawValue
    monster.physicsBody?.contactTestBitMask = PhysicsCategory.None.rawValue
    monster.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
    
    var burningArrowScenes = arrowScenes
    burningArrowScenes.removeAtIndex(0)
    
    let arrowHit = SKAction.animateWithTextures(burningArrowScenes, timePerFrame: 0.05)
    let removeArrow = SKAction.removeFromParent()
    monster.runAction(SKAction.sequence([arrowHit, removeArrow]))
    
    monstersDestroyed++
  }
  
  func monsterDidCollideWithPlayer() {
    println("Monster got the player!")
    if playerDead == false {
      playerDead = true
      
      self.musicController.stopBackgroundMusic()
      self.musicController.stopUpgradeMusic()
      self.musicController.playSoundEffect("PlayerDeath.wav")
      let gameOverTransition = SKAction.runBlock {
        let gameOverScene = GameOverScene(size: self.size, won: false, score: self.coinsCollected)
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        self.view?.presentScene(gameOverScene, transition: reveal)
        self.playerDead = false
      }
      
      player.removeActionForKey("playerFlappingWings")
      let freezeTexture = SKAction.setTexture(playerFlyingScenes[0])
      let spinShrinkDuration = 1.5
      let spinPlayer = SKAction.rotateByAngle(10.0, duration: spinShrinkDuration)
      let shrinkPlayer = SKAction.scaleTo(0.0, duration: spinShrinkDuration)
      
      let spinAndShrinkGroup = SKAction.group([spinPlayer, shrinkPlayer])
      
      player.runAction(SKAction.sequence([freezeTexture, spinAndShrinkGroup, gameOverTransition]))
    }
  }
  
  func playerCollectedCoin(player:SKSpriteNode, coin: SKSpriteNode) {
    println("Collected coin")
    
    coin.removeFromParent()
    coinCount--
    
    coinsCollected++
    totalCoins++
    NSUserDefaults.standardUserDefaults().setObject(totalCoins,forKey:"TotalCoins")
    
    scoreBoard.text = "Score: \(coinsCollected)"
    totalCoinsBoard.text = "Total Coins: \(totalCoins)"
    
    if let savedScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
      if coinsCollected > savedScore {
        NSUserDefaults.standardUserDefaults().setObject(coinsCollected,forKey:"HighestScore")
        highScoreBoard.text = "High Score: \(coinsCollected)"
      }
    }
    
    // Adds additional monsters when collect coins to maintain number of arrows being fired at higher levels.
    if self.coinsCollected >= 50 && slowmoPurchased == false {
      self.removeActionForKey("addingMonsters")
      self.addMonsterBlock(0.5)
    }
  }
  
  func didBeginContact(contact: SKPhysicsContact) {
    
    // Step 1. Bitiwse OR the bodies' categories to find out what kind of contact we have
    let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
    switch contactMask {
      
    case PhysicsCategory.Monster.rawValue | PhysicsCategory.Projectile.rawValue:
      
      // Step 2. Disambiguate the bodies in the contact
      
      if let bodyB = contact.bodyB.node as? SKSpriteNode {
        if let bodyA = contact.bodyA.node as? SKSpriteNode {
          if contact.bodyA.categoryBitMask == PhysicsCategory.Monster.rawValue {
            projectileDidCollideWithMonster(bodyB, monster: bodyA)
          } else {
            projectileDidCollideWithMonster(bodyA, monster: bodyB)
          }
        }
      }
      
    case PhysicsCategory.Monster.rawValue | PhysicsCategory.Player.rawValue:
      
      // Here we don't care which body is which, the scene is ending
      monsterDidCollideWithPlayer()
      
    case PhysicsCategory.Player.rawValue | PhysicsCategory.Coin.rawValue:
      
      // Here we don't care which body is which, the scene is ending
      if let bodyB = contact.bodyB.node as? SKSpriteNode {
        if let bodyA = contact.bodyA.node as? SKSpriteNode {
          if contact.bodyA.categoryBitMask == PhysicsCategory.Coin.rawValue {
            playerCollectedCoin(bodyB, coin: bodyA)
          } else {
            playerCollectedCoin(bodyA, coin: bodyB)
          }
        }
      }

    case PhysicsCategory.Projectile.rawValue | PhysicsCategory.Player.rawValue:
      println("projectile + player")
    
    case PhysicsCategory.Projectile.rawValue | PhysicsCategory.Coin.rawValue:
      println("projectile + coin")

    case PhysicsCategory.Monster.rawValue | PhysicsCategory.Coin.rawValue:
      println("monster + coin")
      
    default:
      fatalError("other collision: \(contactMask)")
    }
  }
  
  func figureOutDirection(degree:CGFloat) {
    if (degree <= 360 && degree >= 335) {
      currentState = MoveStates.W
    } else if (degree <= 334 && degree >= 290) {
      currentState = MoveStates.NW
    } else if (degree <= 289 && degree >= 245) {
      currentState = MoveStates.N
    } else if (degree <= 244 && degree >= 200) {
      currentState = MoveStates.NE
    } else if (degree <= 199 && degree >= 155) {
      currentState = MoveStates.E
    } else if (degree <= 154 && degree >= 110) {
      currentState = MoveStates.SE
    } else if (degree <= 109 && degree >= 65) {
      currentState = MoveStates.S
    } else if (degree <= 64 && degree >= 20) {
      currentState = MoveStates.SW
    } else if (degree <= 19 && degree <= 0) {
      currentState = MoveStates.W
    }
  }
  
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
    
    if player.position.x >= backgroundWidth {
      player.position.x = backgroundWidth - 1
      
    } else if player.position.x <= leftPoint {
      player.position.x = leftPoint + 1
    
    } else if player.position.y >= self.frame.height {
      player.position.y = self.frame.height - 1
    
    } else if player.position.y <= baseSize + player.size.height / 2 {
      player.position.y = baseSize + player.size.height/2 + 1
    
    } else {
      player.position = CGPointMake(player.position.x + shipSpeedX, player.position.y + shipSpeedY)
      moveBackgroundRight(1)

      if player.position.x > movePoint && shipSpeedX > 0{
        moveBackgroundRight(shipSpeedX)
      }
//        if player.position.x < self.frame.width/3 {
//        moveBackgroundLeft()
//        }
    }
    
    let flamePosVector = convertAngleToVector(Double(player.zRotation) + M_PI_2)
    flame.position = CGPoint(x: player.position.x + flamePosVector.dx, y: player.position.y + flamePosVector.dy)
    flame.zRotation = player.zRotation + 1.57079633

  }
}
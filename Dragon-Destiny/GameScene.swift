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
  case Crossbow = 00100
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
  
  var pausedButton = SKSpriteNode(imageNamed: "pause-button")
  let pausedLabel = SKLabelNode(text: "Paused")
  
  var tracker = GAI.sharedInstance().defaultTracker
  
  var levelLabel = SKLabelNode(fontNamed: "Chalkduster")
  var levelReached = 1
  
//  let crossbowEnemy = Boss(imageNamed: "crossbowFired")
  
  init(size: CGSize, level: Int, coinsCollected: Int) {
    super.init(size: size)
    self.levelReached = level
    self.coinsCollected = coinsCollected
  }
  
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
    
    tracker.set(kGAIScreenName, value: "GameScene")
    
    physicsWorld.gravity = CGVectorMake(0, 0)
    physicsWorld.contactDelegate = self
    
    navigationBox.position = CGPoint(x: 0.0, y: 0.0)
    navigationBox.anchorPoint = CGPoint(x: 0, y: 0)
    navigationBox.alpha = 0.8
    navigationBox.zPosition = 1
    navigationBox.size = CGSize(width: frame.size.width, height: baseSize)
    addChild(navigationBox)
    
    backgroundLayer.zPosition = -1
    addChild(backgroundLayer)
    
    musicController.playBackgroundMusic("epicMusic.mp3")
  
    for i in 0...3 {
      totalBackgrounds = i
      let background = backgroundNode()
      background.anchorPoint = CGPointZero
      background.position = CGPoint(x: CGFloat(i)*background.size.width, y: 0)
      background.name = "background"
      backgroundLayer.addChild(background)
    }
    
    rightPoint = self.frame.width
    movePoint = rightPoint / 1.5
    
    addCrossbows()
    
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
//
//    addMonster()
//    addCoins()
    
    self.addCoinBlock(50 + self.levelReached * 5)
    self.addMonsterBlock(1.0)
    
//    runAction(SKAction.repeatAction(
//      SKAction.runBlock(addCoin), count: 10)
//    )
    
    pausedButton.size = CGSize(width: 51.0, height: 51.0)
    pausedButton.position = CGPoint(x: size.width - pausedButton.size.width/2, y: size.height - pausedButton.size.height/2)
    pausedButton.zPosition = 2
    pausedButton.alpha = 0.9
    self.addChild(pausedButton)
    
    pausedLabel.position = CGPoint(x: size.width/2, y: size.height/2)
    pausedLabel.fontColor = UIColor.orangeColor()
    pausedLabel.fontName = "Chalkduster"
    pausedLabel.fontSize = 90
    
    scoreBoard.fontColor = UIColor.blackColor()
    scoreBoard.fontSize = 15
    scoreBoard.position = CGPoint(x: 5, y: size.height - scoreBoard.fontSize - 5)
    scoreBoard.horizontalAlignmentMode = .Left
    scoreBoard.text = "Score: \(coinsCollected)"
    self.addChild(scoreBoard)
    
    highScoreBoard.position = CGPoint(x: 5, y: scoreBoard.position.y - scoreBoard.fontSize - 5)
    highScoreBoard.fontColor = UIColor.blackColor()
    highScoreBoard.fontSize = scoreBoard.fontSize
    highScoreBoard.horizontalAlignmentMode = .Left
    if let savedScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
      highScoreBoard.text = "High Score: \(savedScore)"
    } else {
      highScoreBoard.text = "High Score: \(0)"
    }
    self.addChild(highScoreBoard)
    
    totalCoinsBoard.position = CGPoint(x: 5, y: highScoreBoard.position.y - highScoreBoard.fontSize - 5)
    totalCoinsBoard.fontColor = UIColor.blackColor()
    totalCoinsBoard.fontSize = scoreBoard.fontSize
    totalCoinsBoard.horizontalAlignmentMode = .Left
    totalCoinsBoard.text = "Total Coins: \(totalCoins)"
    self.addChild(totalCoinsBoard)
    
    levelLabel.text = "Level \(levelReached)"
    levelLabel.fontSize = 30
    levelLabel.position = CGPoint(x: size.width/2, y: size.height-levelLabel.fontSize)
    levelLabel.fontColor = UIColor.blackColor()
    self.addChild(levelLabel)
    
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
    
    musicController.loadSoundEffect("FireballSound.wav")
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
    backgroundNode.zPosition = -1

    let background1 = SKSpriteNode(imageNamed: "sky")
    background1.size = frame.size
    background1.anchorPoint = CGPointZero
    background1.position = CGPoint(x: 0, y: 0)
    background1.zPosition = -1
    backgroundNode.addChild(background1)
    
    rightPoint = background1.frame.width

    let background2 = SKSpriteNode(imageNamed: "sky2")
    background2.size = frame.size
    background2.anchorPoint = CGPointZero
    background2.position = CGPoint(x: background1.size.width, y: 0)
    background2.zPosition = -1
    backgroundNode.addChild(background2)
    
    switch (levelReached + 2) % 3  {
    case 0:
      background1.texture = SKTexture(imageNamed: "sky")
      background2.texture = SKTexture(imageNamed: "sky2")
    case 1:
      background1.texture = SKTexture(imageNamed: "skyNight")
      background2.texture = SKTexture(imageNamed: "skyNight2")
    case 2:
      background1.texture = SKTexture(imageNamed: "skyGrass")
      background2.texture = SKTexture(imageNamed: "skyGrass2")
    default:
      background1.texture = SKTexture(imageNamed: "sky")
      background2.texture = SKTexture(imageNamed: "sky2")
    }
  
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
      coin.name = "coin"
      
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
  
  func addCrossbows() {
    for i in 1...self.levelReached {
      let crossbowEnemy = Boss(imageNamed: "CrossbowFired")
      crossbowEnemy.name = "boss"
      let yPos = i * Int(self.size.height) / (self.levelReached + 1)
      crossbowEnemy.position = CGPoint(x: backgroundWidth, y: CGFloat(yPos))
      crossbowEnemy.size = CGSize(width: 88.0, height: 90.0)
      crossbowEnemy.zPosition = 2
      backgroundLayer.addChild(crossbowEnemy)
      
      crossbowEnemy.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: crossbowEnemy.size.width, height: crossbowEnemy.size.height))
      crossbowEnemy.physicsBody?.dynamic = true
      crossbowEnemy.physicsBody?.categoryBitMask = PhysicsCategory.Crossbow.rawValue
      crossbowEnemy.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile.rawValue
      crossbowEnemy.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
    }
    
//    crossbowEnemy.name = "boss"
//    crossbowEnemy.position = CGPoint(x: backgroundWidth, y: size.height/2)
//    crossbowEnemy.size = CGSize(width: 88.0, height: 90.0)
//    crossbowEnemy.zPosition = 3
//    backgroundLayer.addChild(crossbowEnemy)
//    
//    crossbowEnemy.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: crossbowEnemy.size.width, height: crossbowEnemy.size.height))
//    crossbowEnemy.physicsBody?.dynamic = true
//    crossbowEnemy.physicsBody?.categoryBitMask = PhysicsCategory.Crossbow.rawValue
//    crossbowEnemy.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile.rawValue
//    crossbowEnemy.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
//    
//    let crossbowEnemy2 = SKSpriteNode(imageNamed: "CrossbowFired")
//    crossbowEnemy2.name = "boss"
//    crossbowEnemy2.position = CGPoint(x: backgroundWidth, y: size.height/3)
//    crossbowEnemy2.size = CGSize(width: 88.0, height: 90.0)
//    crossbowEnemy2.zPosition = 3
//    backgroundLayer.addChild(crossbowEnemy2)
//    
//    crossbowEnemy2.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: crossbowEnemy.size.width, height: crossbowEnemy.size.height))
//    crossbowEnemy2.physicsBody?.dynamic = true
//    crossbowEnemy2.physicsBody?.categoryBitMask = PhysicsCategory.Crossbow.rawValue
//    crossbowEnemy2.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile.rawValue
//    crossbowEnemy2.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
  }
  
  func addMonster() {
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    if rightPoint < backgroundWidth {
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
      
      // Add the monster to the scene
      backgroundLayer.addChild(monster)
      
      // Determine speed of the monster
//      let minimum = max(Double(3 - (coinsCollected)/20), 0.5)
      let minimum = max(Double(3 - self.levelReached/3), 0.5)
      let maximum = minimum + 1.5
      var actualDuration = random(min: CGFloat(minimum), max: CGFloat(maximum))
      if slowmoPurchased {
        monster.moveDuration = actualDuration
        actualDuration += slowmoSpeedModifier
      }
      
      // Determine where to spawn the monster along the Y axis
      let actualY = random(min: monster.size.height/2 + baseSize, max: size.height - monster.size.height/2)
      monster.position = CGPoint(x: rightPoint + monster.size.height, y: actualY)
      // Create the actions
      let actionMove = SKAction.moveTo(CGPoint(x: leftPoint - monster.size.width/2, y: player.position.y), duration: NSTimeInterval(actualDuration))
      let actionMoveDone = SKAction.removeFromParent()
      monster.runAction(SKAction.sequence([actionMove, actionMoveDone]), withKey: "moveSequence")

    } else {
      backgroundLayer.enumerateChildNodesWithName("boss") {
        node, stop in

        let monster = Monster(texture: self.arrowScenes[0])
        monster.size = CGSize(width: 50.0, height: 10.0)
        monster.name = "arrow"
        monster.zPosition = 3
        monster.playerPosition = CGPoint(x: self.player.position.x, y: self.player.position.y)
        monster.leftPoint = self.leftPoint
        
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: monster.size.width, height: monster.size.height))
        //    monster.physicsBody = SKPhysicsBody(circleOfRadius: monster.size.width/2)
        monster.physicsBody?.dynamic = true
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster.rawValue
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile.rawValue
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Player.rawValue
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
        
        // Add the monster to the scene
        self.backgroundLayer.addChild(monster)
        
        // Determine speed of the monster
//        let minimum = max(Double(3 - (self.coinsCollected)/20), 0.5)
        let minimum = max(Double(3 - self.levelReached/3), 0.5)
        let maximum = minimum + 1.5
        var actualDuration = self.random(min: CGFloat(minimum), max: CGFloat(maximum))
        if self.slowmoPurchased {
          monster.moveDuration = actualDuration
          actualDuration += self.slowmoSpeedModifier
        }
        
        monster.position = CGPoint(x: self.rightPoint + monster.size.height, y: node.position.y)
        let v = CGVector(dx: monster.position.x - self.player.position.x, dy:  monster.position.y - self.player.position.y)
        let angle = atan2(v.dy, v.dx)
        
        node.zRotation = angle
        
        var vector = CGVector()
        var offset = self.player.position - node.position
        
  //      if ball.position != base.position {
  //        offset = ball.position - base.position
  //      } else {
  //        offset = mostRecentBallPosition - mostRecentBasePosition
  //      }
        
        let direction = offset.normalized()
        let shootAmount = direction * self.size.width
        let realDest = shootAmount + node.position
        
        monster.zRotation = angle
        let actionMove = SKAction.moveTo(realDest, duration: NSTimeInterval(actualDuration))
        
        let actionMoveDone = SKAction.removeFromParent()
        monster.runAction(SKAction.sequence([actionMove, actionMoveDone]), withKey: "moveSequence")
        
        let fireArrow = SKAction.setTexture(SKTexture(imageNamed: "CrossbowFired"))
        let pause = SKAction.waitForDuration(0.12)
        let resetBow = SKAction.setTexture(SKTexture(imageNamed: "CrossbowResetting"))
        let stringBack = SKAction.setTexture(SKTexture(imageNamed: "CrossbowStringBack"))
        let stringBack2 = SKAction.setTexture(SKTexture(imageNamed: "CrossbowStringBack2"))
        node.runAction(SKAction.sequence([fireArrow, pause, resetBow, pause, stringBack, pause, stringBack2]))
      }
    }
//
//    monster.zRotation = angle
    
//    let actionMoveDone = SKAction.removeFromParent()
//
//    monster.runAction(SKAction.sequence([actionMove, actionMoveDone]), withKey: "moveSequence")
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
//        if self.coinsCollected < 50 {
        self.addMonsterBlock(1.0)
//        }
//        else {
//          self.addMonsterBlock(0.5)
//        }
        
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
      
      var slowmoPurchasedEvent = GAIDictionaryBuilder.createEventWithCategory("UpgradePurchased", action: "slowmo", label: "slowmoPurchased", value: slowmoUpgradeCost)
      tracker.send(slowmoPurchasedEvent.build() as [NSObject: AnyObject])
      
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
      let attackExtendedRect = CGRectMake(attackButton.position.x - attackButton.size.width/2, attackButton.position.y - attackButton.size.height/2, attackButton.size.width,  attackButton.size.height * 2)
      if (CGRectContainsPoint(attackExtendedRect, touchLocation)) && playerDead == false {
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
      } else if (CGRectContainsPoint(pausedButton.frame, touchLocation)) && playerDead == false {
        pausedButtonPushed()
      } else if (CGRectContainsPoint(base.frame, touchLocation)) && playerDead == false {
        mostRecentBasePosition = base.position
        mostRecentBallPosition = ball.position
      }
    }
  }
  
  override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
    if playerDead == false && !paused {
      for touch in (touches as! Set<UITouch>) {
        let touchLocation = touch.locationInNode(self)
          
        if (CGRectContainsPoint(attackButton.frame, touchLocation)) {
          return
        }

        if touchLocation.x < size.width / 2 {
          
    //      playerMoving = true
    //      stickActive = true
          
          let v = CGVector(dx: touchLocation.x - base.position.x, dy:  touchLocation.y - base.position.y)
          let angle = atan2(v.dy, v.dx)
          
          let deg = angle * CGFloat( 180 / M_PI)
          
          self.figureOutDirection( deg + 180)
          
          let length:CGFloat = base.frame.size.height / 2
          let xDist:CGFloat = sin(angle - 1.57079633) * length
          let yDist:CGFloat = cos(angle - 1.57079633) * length
            
          player.zRotation = angle - 1.57079633
            
          // set up the speed
          let multiplier:CGFloat = 0.08
          
          shipSpeedX = max(min(v.dx * multiplier, 2.2), -2.2)
          shipSpeedY = max(min(v.dy * multiplier, 2.2), -2.2)
            
          mostRecentBasePosition = base.position
          mostRecentBallPosition = ball.position
          
          if (CGRectContainsPoint(base.frame, touchLocation)) { ball.position = touchLocation }
          else { ball.position = CGPointMake(base.position.x - xDist, base.position.y + yDist) }
        }
      }
    }
  }
  
  override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
    for touch in (touches as! Set<UITouch>) {
      let touchLocation = touch.locationInNode(self)
      if (CGRectContainsPoint(attackButton.frame, touchLocation)) {
        flame.removeFromParent()
      }
    }
    
//    stickActive = false
//    flame.hidden = true
    
//    if (stickActive == true) {
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
//    }
  }
  
  func pausedButtonPushed() {
    if !paused {
      pausedButton.texture = SKTexture(imageNamed: "paused-pushed")
      paused = true
      self.addChild(pausedLabel)
    } else if paused {
      pausedButton.texture = SKTexture(imageNamed: "pause-button")
      paused = false
      pausedLabel.removeFromParent()
    }
  }
  
  func attackButtonPushed() {
//    println("attack")
    
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
  }

  
  func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
    projectile.removeFromParent()
    
//    coinsCollected++
//    totalCoins++
//    NSUserDefaults.standardUserDefaults().setObject(totalCoins,forKey:"TotalCoins")
//    
//    scoreBoard.text = "Score: \(coinsCollected)"
//    totalCoinsBoard.text = "Total Coins: \(totalCoins)"
//    
//    if let savedScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
//      if coinsCollected > savedScore {
//        NSUserDefaults.standardUserDefaults().setObject(coinsCollected,forKey:"HighestScore")
//        highScoreBoard.text = "High Score: \(coinsCollected)"
//      }
//    }
    
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
  
  func playerShotCrossbow(crossbowHit: SKSpriteNode) {
    if let boss = crossbowHit as? Boss {
      boss.health -= 50
      
      if boss.health > 0 {
        crossbowHit.texture = SKTexture(imageNamed: "CrossbowBroken1")
        println("player shot the crossbow!")
      }
      
      if boss.health <= 0 {
        let crossbowFire1 = SKTexture(imageNamed: "CrossbowBroken2")
        let crossbowFire2 = SKTexture(imageNamed: "CrossbowBroken3")
        
        let crossbowOnFireAnimation = SKAction.animateWithTextures([crossbowFire1, crossbowFire2, crossbowFire1, crossbowFire2, crossbowFire1, crossbowFire2, crossbowFire1, crossbowFire2, crossbowFire1, crossbowFire2], timePerFrame: 0.1)
//        let crossbowOnFireRepeater = SKAction.repeatAction(crossbowOnFireAnimation, count: 5)
        boss.runAction(SKAction.sequence([crossbowOnFireAnimation, SKAction.removeFromParent()]))
      }
    }
    
    var crossbowsWithHealthLeft = false
    backgroundLayer.enumerateChildNodesWithName("boss") {
      node, stop in
      if let crossbow = node as? Boss {
        if crossbow.health > 0 {
          crossbowsWithHealthLeft = true
        }
      }
    }
    
    if crossbowsWithHealthLeft == false {
      let wonLevelLabel = SKLabelNode(fontNamed: "Chalkduster")
      wonLevelLabel.position = CGPoint(x: size.width/2, y: size.height/2)
      wonLevelLabel.fontColor = UIColor.orangeColor()
      wonLevelLabel.text = "You beat level \(levelReached)"
      wonLevelLabel.fontSize = 50
      self.addChild(wonLevelLabel)
      
      self.removeActionForKey("addingMonsters")
      backgroundLayer.enumerateChildNodesWithName("coin") {
        node, _ in
        node.removeFromParent()
      }
      
      let pause = SKAction.waitForDuration(1.0)
      let fadeAway = SKAction.fadeOutWithDuration(1.0)
      let startNextLevel = SKAction.runBlock() {
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        let scene = GameScene(size: self.size, level: self.levelReached+1, coinsCollected: self.coinsCollected)
        self.backgroundLayer.removeFromParent()
        self.musicController.stopBackgroundMusic()
        self.musicController.stopUpgradeMusic()
        self.view?.presentScene(scene, transition:reveal)
      }
      
      wonLevelLabel.runAction(SKAction.sequence([pause, fadeAway, startNextLevel]))
    }
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
    
//    // Adds additional monsters when collect coins to maintain number of arrows being fired at higher levels.
//    if self.coinsCollected >= 50 && slowmoPurchased == false {
//      self.removeActionForKey("addingMonsters")
//      self.addMonsterBlock(0.5)
//    }
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
      if let bodyB = contact.bodyB.node as? SKSpriteNode {
        if let bodyA = contact.bodyA.node as? SKSpriteNode {
          if contact.bodyA.categoryBitMask == PhysicsCategory.Coin.rawValue {
            playerCollectedCoin(bodyB, coin: bodyA)
          } else {
            playerCollectedCoin(bodyA, coin: bodyB)
          }
        }
      }

    case PhysicsCategory.Crossbow.rawValue | PhysicsCategory.Projectile.rawValue:
      if let bodyB = contact.bodyB.node as? SKSpriteNode {
        if let bodyA = contact.bodyA.node as? SKSpriteNode {
          if contact.bodyA.categoryBitMask == PhysicsCategory.Crossbow.rawValue {
            self.playerShotCrossbow(bodyA)
          } else {
            self.playerShotCrossbow(bodyB)
          }
        }
      }
      
    case PhysicsCategory.Crossbow.rawValue | PhysicsCategory.Coin.rawValue:
      break

    case PhysicsCategory.Crossbow.rawValue | PhysicsCategory.Player.rawValue:
      break
      
    case PhysicsCategory.Crossbow.rawValue | PhysicsCategory.Monster.rawValue:
      break
      
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
    if !paused {
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
        if rightPoint < backgroundWidth {
          moveBackgroundRight(1)
        }

        if player.position.x > movePoint && shipSpeedX > 0 && rightPoint < backgroundWidth {
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
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
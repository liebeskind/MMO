//
//  GameScene.swift
//  SpriteKitSimpleGame
//
//  Created by Main Account on 9/30/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import AVFoundation

var backgroundMusicPlayer: AVAudioPlayer!

func playBackgroundMusic(filename: String) {
  let url = NSBundle.mainBundle().URLForResource(
    filename, withExtension: nil)
  if (url == nil) {
    println("Could not find file: \(filename)")
    return
  }

  var error: NSError? = nil
  backgroundMusicPlayer = 
    AVAudioPlayer(contentsOfURL: url, error: &error)
  if backgroundMusicPlayer == nil {
    println("Could not create audio player: \(error!)")
    return
  }

  backgroundMusicPlayer.numberOfLoops = -1
  backgroundMusicPlayer.prepareToPlay()
  backgroundMusicPlayer.play()
}

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
  
  let player = SKSpriteNode(imageNamed: "player")
  var monstersDestroyed = 0
  var coinsCollected = 0
  let scoreBoard = SKLabelNode(fontNamed: "Avenir")
  let highScoreBoard = SKLabelNode(fontNamed: "Avenir")
  
  var currentState = MoveStates.N
  
  let base = SKSpriteNode(imageNamed:"aSBgImg")
  let ball = SKSpriteNode(imageNamed:"aSThumbImg")
  
  var stickActive:Bool = false
  var playerMoving: Bool = false
  
  var shipSpeedX:CGFloat = 0.0
  var shipSpeedY:CGFloat = 0.0
  var strictCompassMovements:Bool = false

  let attackButton = SKSpriteNode(imageNamed: "AttackButton")
  var mostRecentBallPosition = CGPoint() // Used for aiming attack when not moving
  var mostRecentBasePosition = CGPoint() // Used for aiming attack when not moving
  
  var coinCount = 0
  
  override func didMoveToView(view: SKView) {
    if let highScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
    } else {
      NSUserDefaults.standardUserDefaults().setObject(0,forKey:"HighestScore")
    }
  
//    playBackgroundMusic("background-music-aac.caf")
  
    backgroundColor = SKColor.whiteColor()
    player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    var playerCenter = CGPoint(x: player.position.x, y: player.position.y)

    
//    player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size)

    player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/4)
    player.physicsBody?.dynamic = true
    player.physicsBody?.categoryBitMask = PhysicsCategory.Player.rawValue
    player.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue
    player.physicsBody?.contactTestBitMask = PhysicsCategory.Coin.rawValue
    player.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
    
    addChild(player)
    
    physicsWorld.gravity = CGVectorMake(0, 0)
    physicsWorld.contactDelegate = self
    
    addMonster()
    addCoins()
    
    runAction(SKAction.repeatActionForever(
      SKAction.sequence([
        SKAction.runBlock(addMonster),
        SKAction.waitForDuration(1.0)
      ])
    ))
    
//    runAction(SKAction.repeatAction(
//      SKAction.runBlock(addCoin), count: 10)
//    )
    
    scoreBoard.position = CGPoint(x: size.width - 50, y: size.height-30)
    scoreBoard.fontColor = UIColor.blackColor()
    scoreBoard.fontSize = 15
    scoreBoard.horizontalAlignmentMode = .Right
//    scoreBoard.frame = CGRect(x: 200, y: 10, width: 100, height: 40)
//    scoreBoard.font = UIFont.systemFontOfSize(20)
    scoreBoard.text = "Score: \(coinsCollected)"
    
    addChild(scoreBoard)
    
    highScoreBoard.position = CGPoint(x: size.width - 50, y: size.height-50)
    highScoreBoard.fontColor = UIColor.blackColor()
    highScoreBoard.fontSize = 15
    highScoreBoard.horizontalAlignmentMode = .Right
    //    scoreBoard.frame = CGRect(x: 200, y: 10, width: 100, height: 40)
    //    scoreBoard.font = UIFont.systemFontOfSize(20)
    if let savedScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
      highScoreBoard.text = "High Score: \(savedScore)"
    } else {
      highScoreBoard.text = "High Score: \(0)"
    }
    
    addChild(highScoreBoard)
    
//    // Analog Joystick setup
//    let bgDiametr: CGFloat = 120
//    let thumbDiametr: CGFloat = 60
//    let joysticksRadius = bgDiametr / 2
//    moveAnalogStick.bgNodeDiametr = bgDiametr
//    moveAnalogStick.thumbNodeDiametr = thumbDiametr
//    moveAnalogStick.position = CGPointMake(joysticksRadius + 15, joysticksRadius + 15)
//    moveAnalogStick.delegate = self
//    self.addChild(moveAnalogStick)
    
    //Can add rotation joystick, but probably not necessary
//    rotateAnalogStick.bgNodeDiametr = bgDiametr
//    rotateAnalogStick.thumbNodeDiametr = thumbDiametr
//    rotateAnalogStick.position = CGPointMake(CGRectGetMaxX(self.frame) - joysticksRadius - 15, joysticksRadius + 15)
//    rotateAnalogStick.delegate = self
//    self.addChild(rotateAnalogStick)
    
//    self.anchorPoint = CGPointMake(0.5, 0.5)
    
    addChild(base)
    base.position = CGPointMake(0, -100)
    base.size = CGSize(width: 100.0, height: 100.0)
    
    addChild(ball)
    ball.position = base.position
    ball.size = CGSize(width: 25.0, height: 25.0)
    
    ball.alpha = 0.4
    base.alpha = 0.4

    attackButton.position = CGPoint(x: self.frame.width - 100, y: 75)
  
    self.addChild(attackButton)
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }

  func random(#min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }
  
  func addCoins() {
    while coinCount < 11 {
      let coin = SKSpriteNode(imageNamed: "coin")
      coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.width/2)
      coin.physicsBody?.dynamic = true
      coin.physicsBody?.categoryBitMask = PhysicsCategory.Coin.rawValue
  //    coin.physicsBody?.contactTestBitMask = PhysicsCategory.Player.rawValue
      coin.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
      
      // Determine where to spawn the coin along the Y axis
      let actualY = random(min: coin.size.height, max: self.frame.size.height - coin.size.height)
      let actualX = random(min: coin.size.width, max: self.frame.size.width - coin.size.width)
      
      coin.position = CGPoint(x: actualX, y: actualY)

      self.addChild(coin)
      coinCount++
    }
  }

  func addMonster() {

    // Create sprite
    let monster = SKSpriteNode(imageNamed: "monster")
    monster.physicsBody = SKPhysicsBody(circleOfRadius: monster.size.width/2)
    monster.physicsBody?.dynamic = true
    monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster.rawValue
    monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile.rawValue
    monster.physicsBody?.contactTestBitMask = PhysicsCategory.Player.rawValue
    monster.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
    
    // Determine where to spawn the monster along the Y axis
    let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
    
    // Add the monster to the scene
    addChild(monster)
    
    // Determine speed of the monster
    let minimum = max(Double(3 - coinsCollected/20), 0.5)
    let maximum = minimum + 1.5
    let actualDuration = random(min: CGFloat(minimum), max: CGFloat(maximum))
    
    // Create the actions
    let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: player.position.y), duration: NSTimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()

    monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
  }
  
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    for touch in (touches as! Set<UITouch>) {
    stickActive = true
    
      let touchLocation = touch.locationInNode(self)
      let spriteLocation = player.position
    
      if (CGRectContainsPoint(attackButton.frame, touchLocation)) {
        attackButtonPushed()
      } else {
        ball.alpha = 0.4
        base.alpha = 0.4
      
        base.position = touchLocation
        ball.position = touchLocation
        mostRecentBasePosition = base.position
        mostRecentBallPosition = ball.position
      }
    }
  }
  
  override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
    for touch in (touches as! Set<UITouch>) {
    let touchLocation = touch.locationInNode(self)
      if (stickActive == true) {
        playerMoving = true
        
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
        
        // set up the speed
        let multiplier:CGFloat = 0.04
        
        shipSpeedX = min(v.dx * multiplier, 2.0)
        shipSpeedY = min(v.dy * multiplier, 2.0)
        
      } // ends stickActive test
    }
  }
  
  override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
    if (stickActive == true) {
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
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = player.position
    
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
    
    addChild(projectile)
    
    let direction = offset.normalized()
    let shootAmount = direction * 200
    let realDest = shootAmount + projectile.position
    
    let actionMove = SKAction.moveTo(realDest, duration: 0.4)
    let actionMoveDone = SKAction.removeFromParent()
    projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    
//    let v = CGVector(dx: base.position.x - player.position.x, dy:  base.position.y - player.position.y)
//    let angle = atan2(v.dy, v.dx)
//    player.zRotation = angle - 1.57079633
  }

  
  func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
    println("Hit")
    projectile.removeFromParent()
    monster.removeFromParent()
    
    monstersDestroyed++
  }
  
  func monsterDidCollideWithPlayer() {
    println("Monster got the player!")
    
      let reveal = SKTransition.flipHorizontalWithDuration(0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)

  }
  
  func playerCollectedCoin(player:SKSpriteNode, coin: SKSpriteNode) {
    println("Collected coin")
    
    coin.removeFromParent()
    coinCount--
    
    coinsCollected++
    scoreBoard.text = "Score: \(coinsCollected)"
    
    if let savedScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
      if coinsCollected > savedScore {
        NSUserDefaults.standardUserDefaults().setObject(coinsCollected,forKey:"HighestScore")
        highScoreBoard.text = "High Score: \(coinsCollected)"
      }
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
      
    }
    else if (degree <= 334 && degree >= 290) {
      
      currentState = MoveStates.NW
      
    }
    else if (degree <= 289 && degree >= 245) {
      
      currentState = MoveStates.N
      
    }
    else if (degree <= 244 && degree >= 200) {
      
      currentState = MoveStates.NE
      
    }
    else if (degree <= 199 && degree >= 155) {
      
      currentState = MoveStates.E
      
    }
    else if (degree <= 154 && degree >= 110) {
      
      currentState = MoveStates.SE
      
    }
    else if (degree <= 109 && degree >= 65) {
      
      currentState = MoveStates.S
      
    }
    else if (degree <= 64 && degree >= 20) {
      
      currentState = MoveStates.SW
      
    }
    else if (degree <= 19 && degree <= 0) {
      
      currentState = MoveStates.W
      
    }
  }
  
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
    
    addCoins()
    
    if ( strictCompassMovements == true) {

      var xMove:CGFloat = 0
      var yMove:CGFloat = 0
      
      switch (currentState) {
        
      case .N:
        yMove = 0.1
      case .S:
        yMove = -0.1
      case .E:
        xMove = 0.1
      case .W:
        xMove = -0.1
      case .NE:
        yMove = 0.1
        xMove = 0.1
      case .SE:
        yMove = -0.1
        xMove = 0.1
      case .NW:
        xMove = -0.1
        yMove = 0.1
      case .SW:
        xMove = -0.1
        yMove = -0.1
        
      default:
        break
        
      }
      
      if player.position.x > self.frame.width {
        player.position.x = self.frame.width
      
      } else if player.position.x < 0 {
        player.position.x = 0
      
      } else if player.position.y > self.frame.height {
        player.position.y = self.frame.height
      
      } else if player.position.y < 0 {
        player.position.y = 0
      
      } else {
        player.position = CGPointMake(player.position.x + xMove, player.position.y + yMove)
      }
      
      
    } else {
      
      if player.position.x >= self.frame.width {
        player.position.x = self.frame.width - 1
        
      } else if player.position.x <= 0 {
        player.position.x = 1
      
      } else if player.position.y >= self.frame.height {
        player.position.y = self.frame.height - 1
      
      } else if player.position.y <= 0 {
        player.position.y = 1
      
      } else {
        player.position = CGPointMake(player.position.x + shipSpeedX, player.position.y + shipSpeedY)
      }
    }
  }
}
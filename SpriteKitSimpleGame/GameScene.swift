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

//struct PhysicsCategory {
//  static let None      : UInt32 = 0
//  static let All       : UInt32 = UInt32.max
//  static let Monster   : UInt32 = 0b1       // 1
//  static let Projectile: UInt32 = 0b10      // 2
//  static let Player: UInt32 = 0b110 // 3
//}

enum PhysicsCategory : UInt32 {
  case None   = 0
  case All    = 0xFFFFFFFF
  case Monster  = 0b001
  case Projectile = 0b010
  case Player = 0b100
}

class GameScene: SKScene, SKPhysicsContactDelegate {
  
  let player = SKSpriteNode(imageNamed: "player")
  var monstersDestroyed = 0
  let scoreBoard = SKLabelNode(fontNamed: "Avenir")
  
  override func didMoveToView(view: SKView) {
  
//    playBackgroundMusic("background-music-aac.caf")
  
    backgroundColor = SKColor.whiteColor()
    player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    
//    player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size)
    player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/3)
    player.physicsBody?.dynamic = true
    player.physicsBody?.categoryBitMask = PhysicsCategory.Player.rawValue
    player.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue
    player.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
    
    addChild(player)
    
    physicsWorld.gravity = CGVectorMake(0, 0)
    physicsWorld.contactDelegate = self
    
    addMonster()
    
    runAction(SKAction.repeatActionForever(
      SKAction.sequence([
        SKAction.runBlock(addMonster),
        SKAction.waitForDuration(1.0)
      ])
    ))
    
    scoreBoard.position = CGPoint(x: size.width / 2, y: size.height-40)
    scoreBoard.fontColor = UIColor.blackColor()
    scoreBoard.fontSize = 40
//    scoreBoard.frame = CGRect(x: 200, y: 10, width: 100, height: 40)
//    scoreBoard.font = UIFont.systemFontOfSize(20)
    scoreBoard.text = "Score: \(monstersDestroyed)"
    
    addChild(scoreBoard)
    
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }

  func random(#min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
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
    let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
    
    // Create the actions
    let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()
    let loseAction = SKAction.runBlock() {
      let reveal = SKTransition.flipHorizontalWithDuration(0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
    monster.runAction(SKAction.sequence([
      actionMove,
//      loseAction,
      actionMoveDone]))

  }
  
  override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
    for touch in (touches as! Set<UITouch>) {
      
      let touchLocation = touch.locationInNode(self)
      let spriteLocation = player.position
      
      let angle = atan2(spriteLocation.y - touchLocation.y, spriteLocation.x - touchLocation.x)
      
      var moveAction = SKAction.moveTo(touchLocation, duration: 1)
      let rotateAction = SKAction.rotateToAngle(angle + CGFloat(M_PI*0.5), duration: 0.0)
      
      player.runAction(SKAction.sequence([rotateAction, moveAction]))
    }
  }
  
  override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {

//    runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))

    // 1 - Choose one of the touches to work with
    let touch = touches.first as! UITouch
    let touchLocation = touch.locationInNode(self)
    
    // 2 - Set up initial location of projectile
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = player.position
    
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    projectile.physicsBody?.dynamic = true
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile.rawValue
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
    projectile.physicsBody?.usesPreciseCollisionDetection = true
    
    // 3 - Determine offset of location to projectile
    let offset = touchLocation - projectile.position
    
    // 4 - Bail out if you are shooting down or backwards
//    if (offset.x < 0) { return }
    
    // 5 - OK to add now - you've double checked position
    addChild(projectile)
    
    // 6 - Get the direction of where to shoot
    let direction = offset.normalized()
    
    // 7 - Setting the shoot distance so doesn't go too far
    let shootAmount = direction * 200
    
    // 8 - Add the shoot amount to the current position
    let realDest = shootAmount + projectile.position
    
    // 9 - Create the actions
    let actionMove = SKAction.moveTo(realDest, duration: 0.4)
    let actionMoveDone = SKAction.removeFromParent()
    projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
  }

  
  func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
    println("Hit")
    projectile.removeFromParent()
    monster.removeFromParent()
    
    monstersDestroyed++
    scoreBoard.text = "Score: \(monstersDestroyed)"
    if (monstersDestroyed > 30) {
      let reveal = SKTransition.flipHorizontalWithDuration(0.5)
      let gameOverScene = GameOverScene(size: self.size, won: true)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
    
  }
  
  func monsterDidCollideWithPlayer() {
    println("Monster got the player!")
    
//    let loseAction = SKAction.runBlock() {
      let reveal = SKTransition.flipHorizontalWithDuration(0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)
//    }
    
//    player.runAction(loseAction)
  }
  
  func didBeginContact(contact: SKPhysicsContact) {
    println(contact)

//    // 1
//    var firstBody: SKPhysicsBody
//    var secondBody: SKPhysicsBody
//    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
//      firstBody = contact.bodyA
//      secondBody = contact.bodyB
//    } else {
//      firstBody = contact.bodyB
//      secondBody = contact.bodyA
//    }
//    
//    // 2
//    if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
//        (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
//      projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, monster: secondBody.node as! SKSpriteNode)
//    }
//    
//    // Deal with monster hitting player
//    if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
//        (secondBody.categoryBitMask & PhysicsCategory.Player != 0)) {
//      monsterDidCollideWithPlayer()
//    }
    
    // Step 1. Bitiwse OR the bodies' categories to find out what kind of contact we have
    let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
    switch contactMask {
      
    case PhysicsCategory.Monster.rawValue | PhysicsCategory.Projectile.rawValue:
      
      // Step 2. Disambiguate the bodies in the contact
      if contact.bodyA.categoryBitMask == PhysicsCategory.Monster.rawValue {
        projectileDidCollideWithMonster(contact.bodyB.node as! SKSpriteNode, monster: contact.bodyA.node as! SKSpriteNode)
      } else {
        projectileDidCollideWithMonster(contact.bodyA.node as! SKSpriteNode, monster: contact.bodyB.node as! SKSpriteNode)
      }
      
    case PhysicsCategory.Monster.rawValue | PhysicsCategory.Player.rawValue:
      
      // Here we don't care which body is which, the scene is ending
      monsterDidCollideWithPlayer()
      
    case PhysicsCategory.Projectile.rawValue | PhysicsCategory.Player.rawValue:
      println("projectile + player")
    default:
      fatalError("other collision: \(contactMask)")
    }
  }
}
import AVFoundation
import SpriteKit
import AudioToolbox

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

public extension SKAction {
  public class func playSoundFileNamed(fileName: String, atVolume: Float, waitForCompletion: Bool) -> SKAction {
    
    let url = NSBundle.mainBundle().URLForResource(fileName, withExtension: nil)
    if (url == nil) {
//      print("Could not find file: \(fileName)")
      return SKAction()
    }
    
    var error: NSError? = nil
    let player: AVAudioPlayer!
    do {
      player = try AVAudioPlayer(contentsOfURL: url!)
    } catch let error1 as NSError {
      error = error1
      player = nil
    }
    if player == nil {
      print("Could not create audio player: \(error!)")
      return SKAction()
    }
    
    player.volume = atVolume
    player.numberOfLoops = 0
    player.prepareToPlay()
    
    let playAction: SKAction = SKAction.runBlock { player.play() }
    
//    if(waitForCompletion){
//      let waitAction = SKAction.waitForDuration(player.duration)
//      let groupAction: SKAction = SKAction.group([playAction, waitAction])
//      return groupAction
//    }
    
    return playAction
  }
}

enum PhysicsCategory : UInt32 {
  case None   = 0
  case All    = 0xFFFFFFFF
  case Monster  = 1
  case Projectile = 2
  case Player = 4
  case Coin = 8
  case Crossbow = 16
  case Shield = 32
  case Laser = 64
}

enum MoveStates:Int {
  
  case N,S,E,W,NE,NW,SE,SW
}

//func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
//  let context = CIContext(options: nil)
//  if context != nil {
//    return context.createCGImage(inputImage, fromRect: inputImage.extent)
//  }
//  return nil
//}

class GameScene: SKScene, SKPhysicsContactDelegate, ChartboostDelegate {
  
  let musicController = MusicController()
  
  var birthdayMode = true
  var birthdayPicture = UIImage()
  
  var dragonSelected: Int!
  
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
  var firstFireballFrame: SKTexture?
  let fireballSoundEffect = SKAction.playSoundFileNamed("FireballSound.wav", atVolume: 0.5, waitForCompletion: false)
  
  var laserBallScenes: [SKTexture]!
  var firstLaserBallFrame: SKTexture?
  let laserBallSoundEffect = SKAction.playSoundFileNamed("laserBallSound.wav", atVolume: 0.5, waitForCompletion: false)
  
  var monstersDestroyed = 0
  var coinsCollected = 0
  var coinCount = 0
  var totalCoins = Int()
  let totalCoinsBoard = SKLabelNode(fontNamed: "Copperplate")
  let scoreBoard = SKLabelNode(fontNamed: "Copperplate")
  let highScoreBoard = SKLabelNode(fontNamed: "Copperplate")
  let monstersKilledBoard = SKLabelNode(fontNamed: "Copperplate")
  var highScoreAchieved = false
  
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
  
//  var purchaseFlame = SKSpriteNode(imageNamed: "FlameUpgradeButton")
//  let flameUpgradeCost = 20
//  var flamePurchased = false
  var flame = SKSpriteNode()
  var flameScenes: [SKTexture]!
  var flameStartScenes: [SKTexture]!
  
  var laser = SKSpriteNode()
  var laserScenes: [SKTexture]!
  var laserStartScenes: [SKTexture]!
  
  var purchaseSlowmo = SKSpriteNode(imageNamed: "SlowmoUpgradeButton")
  let slowmoUpgradeCost = 10
  var slowmoPurchased = false
  var slowmoSpeedModifier = CGFloat(6.0)
  let slowmoDuration = 10.0
  
  var purchaseShield = SKSpriteNode(imageNamed: "ShieldUpgradeButton")
  let shieldUpgradeCost = 25
  var shield = Shield()
  let shieldHitSoundEffect = SKAction.playSoundFileNamed("ShieldHit.wav", atVolume: 0.5, waitForCompletion: false)
  let shieldDestroyedSoundEffect = SKAction.playSoundFileNamed("ShieldDestroyed.wav", atVolume: 0.5, waitForCompletion: false)
  
  let navigationBox = SKSpriteNode(color: UIColor.grayColor(), size: CGSize(width: 200.0, height: 150.0))
  
  var dt: NSTimeInterval = 0
  
  var pausedButton = SKSpriteNode(imageNamed: "pause-button")
  let pausedLabel = SKLabelNode(text: "Paused")
  
  let muteButton = SKSpriteNode(imageNamed: "soundIcon")
  var muted = false
  
  var tracker: GAITracker!
  
  var levelLabel = SKLabelNode(fontNamed: "Copperplate")
  var levelReached = 1
  let coinsPerLevelMultiplier = 15
  
  let leftThumbExplanation = SKSpriteNode(imageNamed: "LeftThumbExplanation")
  let rightThumbExplanation = SKSpriteNode(imageNamed: "RightThumbExplanation")
  let collectCoinsExplanation = SKSpriteNode(imageNamed: "CollectCoinsExplanation")
  let killCrossbowExplanation = SKSpriteNode(imageNamed: "KillCrossbowExplanation")
  let purchaseSlowmoExplanation = SKSpriteNode(imageNamed: "PurchaseSlowmoExplanation")
  let purchaseShieldExplanation = SKSpriteNode(imageNamed: "PurchaseShieldExplanation")
  var leftExplanationActive = false
  var rightExplanationActive = false
  var collectCoinsExplanationActive = false
  var killCrossbowExplanationActive = false
  var purchaseShieldExplanationActive = false
  var purchaseSlowmoExplanationActive = false
  
  let coinsEverCollected = NSUserDefaults.standardUserDefaults().integerForKey("totalCoinsEverCollected")
  
  let fadeAlphaSequence = SKAction.sequence([SKAction.fadeAlphaTo(1.0, duration: 0.5), SKAction.waitForDuration(0.5), SKAction.fadeAlphaTo(0.0, duration: 0.5)])
  
//  let crossbowEnemy = Boss(imageNamed: "crossbowFired")
  
  init(size: CGSize, level: Int, muted: Bool, coinsCollected: Int, monstersDestroyed: Int, shield: Shield, dragonType: Int, birthdayMode: Bool, birthdayPicture: UIImage) {
    super.init(size: size)
    self.levelReached = level
    self.coinsCollected = coinsCollected
    self.shield = shield
    self.dragonSelected = dragonType
    self.birthdayMode = birthdayMode
    self.muted = muted
    self.monstersDestroyed = monstersDestroyed
  }
  
  override func didMoveToView(view: SKView) {
    
    self.view?.multipleTouchEnabled = true
    
    if let _: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
    } else {
      NSUserDefaults.standardUserDefaults().setObject(0,forKey:"HighestScore")
    }
    
    if let coins: Int = NSUserDefaults.standardUserDefaults().objectForKey("TotalCoins") as? Int {
      totalCoins = coins
    } else {
      NSUserDefaults.standardUserDefaults().setObject(0,forKey:"TotalCoins")
    }
    
    tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "GameScene")
    
    physicsWorld.gravity = CGVectorMake(0, 0)
    physicsWorld.contactDelegate = self
    
    navigationBox.position = CGPoint(x: 0.0, y: 0.0)
    navigationBox.anchorPoint = CGPoint(x: 0, y: 0)
    navigationBox.alpha = 0.8
    navigationBox.zPosition = 1
    navigationBox.size = CGSize(width: frame.size.width, height: baseSize)
    addChild(navigationBox)
    
    let playerAnimatedAtlas = SKTextureAtlas(named: "playerImages")
    var flyFrames = [SKTexture]()
    
    let numImages = playerAnimatedAtlas.textureNames.count/4 //Number changes based on # of dragons available
    for var i=0; i<numImages; i++ {
      
      var playerTextureName: String
      switch dragonSelected {
      case 0: playerTextureName = "BlueDragonFlap\(i)"
      case 1: playerTextureName = "RedDragonFlap\(i)"
      case 2: playerTextureName = "GreenDragonFlap\(i)"
      case 3: playerTextureName = "YellowDragonFlap\(i)"
      default: playerTextureName = "BlueDragonFlap\(i)"
      }
      
      flyFrames.append(playerAnimatedAtlas.textureNamed(playerTextureName))
      flyFrames.insert(playerAnimatedAtlas.textureNamed(playerTextureName), atIndex: 0) //Makes wing flapping animation more fluid as doesn't just reset at end
    }
    
    playerFlyingScenes = flyFrames
    
    SKTexture.preloadTextures(playerFlyingScenes, withCompletionHandler: { () -> Void in})
    
    let firstFrame = playerFlyingScenes[0]
    player = SKSpriteNode(texture: firstFrame)
    
    if birthdayMode {
      player.texture = SKTexture(image: self.birthdayPicture)
    }
    
    backgroundLayer.addChild(player)
    
    player.position = CGPoint(x: size.width/3, y: size.height * 0.5)
    player.size = CGSize(width: 50, height: 33)
    player.zPosition = 10
    player.zRotation = -1.57079633 //Start off facing right
//    var playerCenter = CGPoint(x: player.position.x, y: player.position.y)

    player.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: player.size.width-35, height: player.size.height-20))
    player.physicsBody?.dynamic = true
    player.physicsBody?.categoryBitMask = PhysicsCategory.Player.rawValue
    player.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue
    player.physicsBody?.contactTestBitMask = PhysicsCategory.Coin.rawValue
    player.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
    
    if !birthdayMode {
      flyingPlayer()
    }
    
//    musicController.playSoundEffect("FireballSound.wav", atVolume: 0.0) //Loads the sound, so don't have lag first time fire
    
    let arrowAnimatedAtlas = SKTextureAtlas(named: "arrowImages")
    var arrowFrames = [SKTexture]()
    
    let numArrowImages = arrowAnimatedAtlas.textureNames.count
    for var i=0; i<numArrowImages; i++ {
      let arrowTextureName = "Arrow\(i)"
      arrowFrames.append(arrowAnimatedAtlas.textureNamed(arrowTextureName))
    }
    
    arrowScenes = arrowFrames
    
    if dragonSelected == 0 || dragonSelected == 1 {
      let fireballAnimatedAtlas = SKTextureAtlas(named: "fireballImages")
      var fireballFrames = [SKTexture]()
      
      let numFireballImages = fireballAnimatedAtlas.textureNames.count
      for var i=0; i<numFireballImages; i++ {
        let fireballTextureName = "Fireball\(i)"
        fireballFrames.append(fireballAnimatedAtlas.textureNamed(fireballTextureName))
      }
      
      fireballScenes = fireballFrames
      
      firstFireballFrame = fireballScenes[0]
      SKTexture.preloadTextures(fireballScenes, withCompletionHandler: { () -> Void in})

    }
//    projectile = SKSpriteNode(texture: firstFireballFrame) // Not sure this does anything.  Meant to cache so no delay.
    
    if dragonSelected == 1 {
      let flameAnimatedAtlas = SKTextureAtlas(named: "fullFlameImages")
      var flameFrames = [SKTexture]()
      
      let numFlameImages = flameAnimatedAtlas.textureNames.count
      for var i=0; i<numFlameImages; i++ {
        let flameTextureName = "FullFlame\(i)"
        flameFrames.append(flameAnimatedAtlas.textureNamed(flameTextureName))
      }
      flameScenes = flameFrames
      SKTexture.preloadTextures(flameScenes, withCompletionHandler: { () -> Void in})
    
    
      let flameStartAnimatedAtlas = SKTextureAtlas(named: "flameImages")
      var flameStartFrames = [SKTexture]()
      
      let numFlameStartImages = flameStartAnimatedAtlas.textureNames.count
      for var i=0; i<numFlameStartImages; i++ {
        let flameStartTextureName = "Flame\(i)"
        flameStartFrames.append(flameStartAnimatedAtlas.textureNamed(flameStartTextureName))
      }
      flameStartScenes = flameStartFrames
      SKTexture.preloadTextures(flameStartScenes, withCompletionHandler: { () -> Void in})
    }
    
    if dragonSelected == 2 || dragonSelected == 3 {
      let laserBallAnimatedAtlas = SKTextureAtlas(named: "laserBallImages")
      var laserBallFrames = [SKTexture]()
      
      let numLaserBallImages = laserBallAnimatedAtlas.textureNames.count
      for var i=0; i<numLaserBallImages; i++ {
        let laserBallTextureName = "LaserBall\(i)"
        laserBallFrames.append(laserBallAnimatedAtlas.textureNamed(laserBallTextureName))
      }
      
      laserBallScenes = laserBallFrames
      firstLaserBallFrame = laserBallScenes[0]
      SKTexture.preloadTextures(laserBallScenes, withCompletionHandler: { () -> Void in})
    }
    
    if dragonSelected == 3 {
      let laserStartAnimatedAtlas = SKTextureAtlas(named: "laserImages")
      var laserStartFrames = [SKTexture]()
      
      let numLaserStartImages = laserStartAnimatedAtlas.textureNames.count
      for var i=0; i<numLaserStartImages; i++ {
        let laserStartTextureName = "Laser\(i)"
        laserStartFrames.append(laserStartAnimatedAtlas.textureNamed(laserStartTextureName))
      }
      
      laserStartScenes = laserStartFrames
      SKTexture.preloadTextures(laserStartScenes, withCompletionHandler: { () -> Void in})
      
      let laserAnimatedAtlas = SKTextureAtlas(named: "fullLaserImages")
      var laserFrames = [SKTexture]()
      
      let numLaserImages = laserAnimatedAtlas.textureNames.count
      for var i=0; i<numLaserImages; i++ {
        let laserTextureName = "FullLaser\(i)"
        laserFrames.append(laserAnimatedAtlas.textureNamed(laserTextureName))
      }
      
      laserScenes = laserFrames
      SKTexture.preloadTextures(laserScenes, withCompletionHandler: { () -> Void in})
    }
    
    self.addMonsterBlock(1.0)
    
    pausedButton.size = CGSize(width: 40.0, height: 40.0)
    pausedButton.position = CGPoint(x: size.width - pausedButton.size.width/2, y: size.height - pausedButton.size.height/2)
    pausedButton.zPosition = 2
    pausedButton.alpha = 0.9
    self.addChild(pausedButton)
    
    pausedLabel.position = CGPoint(x: size.width/2, y: size.height/2)
    pausedLabel.fontColor = UIColor.orangeColor()
    pausedLabel.fontName = "Coppertone"
    pausedLabel.fontSize = 90
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("returnFromBackground"), name: "BackFromBackground", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("goingToBackground"), name: "GoingToBackground", object: nil)
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("finishedShowingRewardedVideo:"), name: "DisplayedChartboostRewardedVideo", object: nil)
    
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("rewardVideoClosed:"), name: "RewardVideoClosed", object: nil)
    
    muteButton.size = CGSize(width: 35.0, height: 35.0)
    muteButton.position = CGPoint(x: size.width - muteButton.size.width/2 - pausedButton.size.width, y: size.height - muteButton.size.height/2)
    muteButton.zPosition = 2
    muteButton.alpha = 0.9
    self.addChild(muteButton)
    
    if muted {
      muteButton.texture = SKTexture(imageNamed: "muteSoundIcon")
      muted = true
      musicController.muteAllSound()
      musicController.pauseBackgroundMusic()
    } else if birthdayMode {
      musicController.playBackgroundMusic("BeautifulBirthday.mp3")
    } else {
      musicController.playBackgroundMusic("epicMusic.mp3")
    }
    
    levelLabel.text = "Level \(levelReached)"
    levelLabel.fontSize = 30
    levelLabel.position = CGPoint(x: size.width/2, y: size.height - levelLabel.fontSize)
    levelLabel.fontColor = UIColor.blackColor()
    levelLabel.zPosition = 2
    self.addChild(levelLabel)
    
    scoreBoard.fontColor = UIColor.blackColor()
    scoreBoard.fontSize = 12
    scoreBoard.position = CGPoint(x: 15, y: size.height - scoreBoard.fontSize - 5)
    scoreBoard.horizontalAlignmentMode = .Left
    scoreBoard.text = "Score: \(coinsCollected)"
    scoreBoard.zPosition = 2
    self.addChild(scoreBoard)
    
    monstersKilledBoard.fontColor = UIColor.blackColor()
    monstersKilledBoard.fontSize = scoreBoard.fontSize
    monstersKilledBoard.position = CGPoint(x: 15, y: scoreBoard.position.y - scoreBoard.fontSize)
    monstersKilledBoard.horizontalAlignmentMode = .Left
    monstersKilledBoard.text = "Arrows Destroyed: \(monstersDestroyed)"
    monstersKilledBoard.zPosition = 2
    self.addChild(monstersKilledBoard)
    
    highScoreBoard.position = CGPoint(x: 15, y: monstersKilledBoard.position.y - scoreBoard.fontSize)
    highScoreBoard.fontColor = UIColor.blackColor()
    highScoreBoard.fontSize = scoreBoard.fontSize
    highScoreBoard.horizontalAlignmentMode = .Left
    highScoreBoard.zPosition = 2
    if let savedScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
      highScoreBoard.text = "High Score: \(savedScore)"
    } else {
      highScoreBoard.text = "High Score: \(0)"
    }
//    self.addChild(highScoreBoard)
    
    totalCoinsBoard.position = CGPoint(x: 15, y: monstersKilledBoard.position.y - monstersKilledBoard.fontSize)
    totalCoinsBoard.fontColor = UIColor.blackColor()
    totalCoinsBoard.fontSize = scoreBoard.fontSize
    totalCoinsBoard.horizontalAlignmentMode = .Left
    totalCoinsBoard.text = "Total Coins: \(totalCoins)"
    totalCoinsBoard.zPosition = 2
    self.addChild(totalCoinsBoard)
    
    let scoreBoardBackground = SKShapeNode(rect: CGRect(x: 5, y: totalCoinsBoard.position.y - 5, width: monstersKilledBoard.frame.width + 25, height: size.height - totalCoinsBoard.position.y + 1), cornerRadius: 15.0)
    scoreBoardBackground.fillColor = UIColor.lightGrayColor()
//    scoreBoardBackground.fillTexture = SKTexture(imageNamed: "grayTexture")
    scoreBoardBackground.zPosition = 1
    scoreBoardBackground.alpha = 0.5
//    self.addChild(scoreBoardBackground)
    
    backgroundLayer.zPosition = -1
    addChild(backgroundLayer)
    
    for i in 0...self.levelReached {
      totalBackgrounds = i
      let background = backgroundNode()
      background.anchorPoint = CGPointZero
      background.position = CGPoint(x: CGFloat(i)*background.size.width, y: 0)
      background.name = "background"
      backgroundLayer.addChild(background)
    }
    
    rightPoint = self.frame.width
    movePoint = rightPoint / 1.5
    
    self.addCoinBlock(self.levelReached * self.coinsPerLevelMultiplier)
    self.addCrossbows()
    
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
    if self.totalCoins < slowmoUpgradeCost {
      purchaseSlowmo.runAction(SKAction.scaleTo(0.0, duration: 0.3))
    }
    self.addChild(purchaseSlowmo)
    
    purchaseShield.size = attackButton.size
    purchaseShield.alpha = attackButton.alpha
    purchaseShield.position = CGPoint(x: purchaseSlowmo.position.x - purchaseSlowmo.size.width - 12, y: attackButton.position.y)
    purchaseShield.zPosition = 2
    if self.totalCoins < shieldUpgradeCost {
      purchaseShield.runAction(SKAction.scaleTo(0.0, duration: 0.3))
    }
    self.addChild(purchaseShield)
    if shield.purchased {
      purchaseShield.runAction(SKAction.scaleTo(0.0, duration: 0.0), withKey: "shrinking")
      backgroundLayer.addChild(shield)
    }
    if !Chartboost.hasRewardedVideo(CBLocationGameScreen) {
      Chartboost.cacheRewardedVideo(CBLocationGameScreen)
    }
    
    
    if self.coinsEverCollected + self.coinsCollected <= 30 && self.levelReached < 3 {
      leftExplanationActive = true
      leftThumbExplanation.size = CGSize(width: 100.0, height: 100.0)
      leftThumbExplanation.position = CGPoint(x: base.position.x + 30, y: navigationBox.position.y + navigationBox.size.height + leftThumbExplanation.size.height/2)
      self.addChild(leftThumbExplanation)
      leftThumbExplanation.runAction(SKAction.repeatActionForever(fadeAlphaSequence))
    }
    
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  override func willMoveFromView(view: SKView) {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }

  func random(min min: CGFloat, max: CGFloat) -> CGFloat {
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
    
    var labelColors = UIColor.blackColor()
    
    switch (levelReached + 11) % 12  {
    case 0:
      labelColors = UIColor.blackColor()
      background1.texture = SKTexture(imageNamed: "sky")
      background2.texture = SKTexture(imageNamed: "sky2")
    case 1:
      labelColors = UIColor.whiteColor()
      background1.texture = SKTexture(imageNamed: "sharkAttack1")
      background2.texture = SKTexture(imageNamed: "sharkAttack2")
    case 2:
      labelColors = UIColor.yellowColor()
      background1.texture = SKTexture(imageNamed: "desertNasa1")
      background2.texture = SKTexture(imageNamed: "desertNasa2")
    case 3:
      labelColors = UIColor.whiteColor()
      background1.texture = SKTexture(imageNamed: "threeGorges1")
      background2.texture = SKTexture(imageNamed: "threeGorges2")
    case 4:
      labelColors = UIColor.yellowColor()
      background1.texture = SKTexture(imageNamed: "darkClouds1")
      background2.texture = SKTexture(imageNamed: "darkClouds2")
    case 5:
      labelColors = UIColor.whiteColor()
      background1.texture = SKTexture(imageNamed: "oceanNasa2")
      background2.texture = SKTexture(imageNamed: "oceanNasa1")
    case 6:
      labelColors = UIColor.yellowColor()
      background1.texture = SKTexture(imageNamed: "algerianDesert1")
      background2.texture = SKTexture(imageNamed: "algerianDesert2")
    case 7:
      labelColors = UIColor.whiteColor()
      background1.texture = SKTexture(imageNamed: "oceanBackground1")
      background2.texture = SKTexture(imageNamed: "oceanBackground2")
    case 8:
      labelColors = UIColor.blackColor()
      background1.texture = SKTexture(imageNamed: "skyPurple1")
      background2.texture = SKTexture(imageNamed: "skyPurple2")
    case 9:
      labelColors = UIColor.whiteColor()
      background1.texture = SKTexture(imageNamed: "desertErosion1")
      background2.texture = SKTexture(imageNamed: "desertErosion2")
    case 10:
      labelColors = UIColor.blackColor()
      background1.texture = SKTexture(imageNamed: "sheepField1")
      background2.texture = SKTexture(imageNamed: "sheepField2")
    case 11:
      labelColors = UIColor.yellowColor()
      background1.texture = SKTexture(imageNamed: "europa1")
      background2.texture = SKTexture(imageNamed: "europa2")
    default:
      labelColors = UIColor.blackColor()
      background1.texture = SKTexture(imageNamed: "sky")
      background2.texture = SKTexture(imageNamed: "sky2")
    }
    
    levelLabel.fontColor = labelColors
    scoreBoard.fontColor = labelColors
    highScoreBoard.fontColor = labelColors
    monstersKilledBoard.fontColor = labelColors
    totalCoinsBoard.fontColor = labelColors
  
    backgroundNode.size = CGSize(
      width: background1.size.width + background2.size.width,
      height: frame.size.height)
    backgroundWidth = backgroundNode.size.width * CGFloat(totalBackgrounds) / 2
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
    if birthdayMode { coin.texture = SKTexture(imageNamed: "gift") }
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
  
  func addCrossbows() {
    for i in 1...self.levelReached {
      if (i + 2) % 3 == 0 { //Only adds a new crossbow every 3rd level, starting with level 1
        let crossbowEnemy = Boss(imageNamed: "CrossbowFired")
        if birthdayMode { crossbowEnemy.texture = SKTexture(imageNamed: "Zoe0")}
        crossbowEnemy.name = "boss"
        var yPos = Int()
        yPos = i * Int(self.size.height - navigationBox.size.height) / (self.levelReached + 1) + Int(navigationBox.size.height)
        
        if self.levelReached == 2 {
          yPos = 2 * Int(self.size.height - navigationBox.size.height) / (self.levelReached + 1) + Int(navigationBox.size.height)
        }
        
        crossbowEnemy.position = CGPoint(x: backgroundWidth, y: CGFloat(yPos))
        crossbowEnemy.size = CGSize(width: 75.0, height: 75.0)
        crossbowEnemy.zPosition = 2
        backgroundLayer.addChild(crossbowEnemy)
        
        crossbowEnemy.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: crossbowEnemy.size.width, height: crossbowEnemy.size.height))
        crossbowEnemy.physicsBody?.dynamic = true
        crossbowEnemy.physicsBody?.categoryBitMask = PhysicsCategory.Crossbow.rawValue
        crossbowEnemy.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile.rawValue | PhysicsCategory.Laser.rawValue
        crossbowEnemy.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
      }
    }
  }
  
  func addMonsterBlock(speed: Double) {
    self.removeActionForKey("addingMonsters")
//    let pause = SKAction.waitForDuration(2.0)
    self.runAction(SKAction.repeatActionForever(
      SKAction.sequence([
        SKAction.waitForDuration(speed),
        SKAction.runBlock(self.addMonster)
        ])
      ), withKey: "addingMonsters"
    )
  }
  
  func addMonster() {
      var numNodes = 0
      backgroundLayer.enumerateChildNodesWithName("boss") {
      
      nodeTemp, stop in
      let node = nodeTemp as! Boss
      numNodes++
      if self.rightPoint < self.backgroundWidth && node.health > 0 {
        // Create sprite
        let monster = Monster(texture: self.arrowScenes[0])
        monster.size = CGSize(width: 50.0, height: 10.0)
        monster.name = "arrow"
        monster.playerPosition = CGPoint(x: self.player.position.x, y: self.player.position.y)
        monster.leftPoint = self.leftPoint
        
        if self.birthdayMode {
          monster.texture = SKTexture(imageNamed: "CupcakeDes")
          monster.size = CGSize(width: 50.0, height: 50.0)
        }
        
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: monster.size.width, height: monster.size.height))
        //    monster.physicsBody = SKPhysicsBody(circleOfRadius: monster.size.width/2)
        monster.physicsBody?.dynamic = true
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster.rawValue
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile.rawValue | PhysicsCategory.Player.rawValue | PhysicsCategory.Laser.rawValue
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
        
        // Add the monster to the scene
        self.backgroundLayer.addChild(monster)
        
        // Determine speed of the monster
  //      let minimum = max(Double(3 - (coinsCollected)/20), 0.5)
        let minimum = max(Double(2.8 - Double(self.levelReached)/6.0), 0.8)
        let maximum = minimum + 1.5
        var actualDuration = self.random(min: CGFloat(minimum), max: CGFloat(maximum))
        if self.slowmoPurchased {
          monster.moveDuration = actualDuration
          actualDuration += self.slowmoSpeedModifier
        }
        
        // Determine where to spawn the monster along the Y axis
        let actualY = self.random(min: max(node.position.y - node.size.height/3, self.baseSize), max: min(node.position.y + node.size.height/3, self.size.height))
        
//        let bottomLine = node.position.x - self.rightPoint
        
        monster.position = CGPoint(x: self.rightPoint + monster.size.height, y: actualY)
        // Create the actions
        if numNodes % 2 == 0 {
          monster.realDest = CGPoint(x: self.leftPoint - monster.size.width/2, y: self.player.position.y)
          let v = CGVector(dx: monster.position.x - monster.realDest!.x, dy:  monster.position.y - monster.realDest!.y)
          let angle = atan2(v.dy, v.dx)
          monster.zRotation = angle
          
        } else {
          let playerPredictedPosVector = self.convertAngleToVector(Double(self.player.zRotation) + M_PI_2)
          let playerPredictedPosition = CGPoint(x: self.player.position.x + self.shipSpeedX * playerPredictedPosVector.dx, y: self.player.position.y + self.shipSpeedY * playerPredictedPosVector.dy)
          
          let offset = playerPredictedPosition - monster.position
          let direction = offset.normalized()
          let shootAmount = direction * (self.size.width + monster.size.width)
          monster.realDest = shootAmount + monster.position
          
          let v = CGVector(dx: monster.position.x - playerPredictedPosition.x, dy:  monster.position.y - playerPredictedPosition.y)
          let angle = atan2(v.dy, v.dx)
          monster.zRotation = angle
        }
        
//        let vectorToPlayer = CGVector(dx: (monster.position.x - self.player.position.x), dy:  (monster.position.y - self.player.position.y))
//        let actionMove = SKAction.moveTo(monster.realDest!, duration: NSTimeInterval(actualDuration))
        let actionMove = SKAction.moveTo(monster.realDest!, duration: NSTimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        monster.runAction(SKAction.sequence([actionMove, actionMoveDone]), withKey: "moveSequence")

      } else if node.health > 0 {
          let monster = Monster(texture: self.arrowScenes[0])
          monster.size = CGSize(width: 50.0, height: 10.0)
          monster.name = "arrow"
          monster.zPosition = 3
          monster.playerPosition = CGPoint(x: self.player.position.x, y: self.player.position.y)
          monster.leftPoint = self.leftPoint
          
          if self.birthdayMode {
            monster.texture = SKTexture(imageNamed: "CupcakeDes")
            monster.size = CGSize(width: 50.0, height: 50.0)
          }
          
          monster.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: monster.size.width, height: monster.size.height))
          //    monster.physicsBody = SKPhysicsBody(circleOfRadius: monster.size.width/2)
          monster.physicsBody?.dynamic = true
          monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster.rawValue
          monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile.rawValue | PhysicsCategory.Player.rawValue | PhysicsCategory.Laser.rawValue
          monster.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
          
          // Add the monster to the scene
          self.backgroundLayer.addChild(monster)
          
          // Determine speed of the monster
  //        let minimum = max(Double(3 - (self.coinsCollected)/20), 0.5)
          let minimum = max(Double(2.8 - Double(self.levelReached)/6.0), 0.8)
          let maximum = minimum + 1.5
          var actualDuration = self.random(min: CGFloat(minimum), max: CGFloat(maximum))
          if self.slowmoPurchased {
            monster.moveDuration = actualDuration
            actualDuration += self.slowmoSpeedModifier
          }
          
  //        node.zRotation = angle
          
//          var vector = CGVector()
          let offset = self.player.position - node.position
          
    //      if ball.position != base.position {
    //        offset = ball.position - base.position
    //      } else {
    //        offset = mostRecentBallPosition - mostRecentBasePosition
    //      }
          
          let direction = offset.normalized()
          let shootAmount = direction * (self.size.width + monster.size.width)
          monster.realDest = shootAmount + node.position
          
          monster.position = CGPoint(x: self.rightPoint + monster.size.height, y: node.position.y)
          let v = CGVector(dx: monster.position.x - self.player.position.x, dy:  monster.position.y - self.player.position.y)
          let angle = atan2(v.dy, v.dx)
          
          monster.zRotation = angle
          let actionMove = SKAction.moveTo(monster.realDest!, duration: NSTimeInterval(actualDuration))
          
          let actionMoveDone = SKAction.removeFromParent()
          monster.runAction(SKAction.sequence([actionMove, actionMoveDone]), withKey: "moveSequence")

          let shortPause = SKAction.waitForDuration(0.01)
          var fireArrow1 = SKAction.setTexture(SKTexture(imageNamed: "CrossbowStringBack2"))
          var fireArrow2 = SKAction.setTexture(SKTexture(imageNamed: "CrossbowStringBack"))
          var fireArrow3 = SKAction.setTexture(SKTexture(imageNamed: "CrossbowResetting"))
          var fireArrow4 = SKAction.setTexture(SKTexture(imageNamed: "CrossbowFired"))
          let pauseLong = SKAction.waitForDuration(0.4)
          let pause = SKAction.waitForDuration(0.08)
          var resetBow = SKAction.setTexture(SKTexture(imageNamed: "CrossbowResetting"))
          var stringBack = SKAction.setTexture(SKTexture(imageNamed: "CrossbowStringBack"))
          var stringBack2 = SKAction.setTexture(SKTexture(imageNamed: "CrossbowStringBack2"))
          
          if self.birthdayMode {
            fireArrow1 = SKAction.setTexture(SKTexture(imageNamed: "Zoe1"))
            fireArrow2 = SKAction.setTexture(SKTexture(imageNamed: "Zoe1"))
            fireArrow3 = SKAction.setTexture(SKTexture(imageNamed: "Zoe2"))
            fireArrow4 = SKAction.setTexture(SKTexture(imageNamed: "Zoe0"))
            resetBow = SKAction.setTexture(SKTexture(imageNamed: "Zoe2"))
            stringBack = SKAction.setTexture(SKTexture(imageNamed: "Zoe1"))
            stringBack2 = SKAction.setTexture(SKTexture(imageNamed: "Zoe1"))
          }
          
        if node.health == 100 {
          node.runAction(SKAction.sequence([
            fireArrow1, shortPause, fireArrow2, shortPause, fireArrow3, shortPause, fireArrow4, pauseLong,
            resetBow, pause, stringBack, pause, stringBack2]))
        } else if node.health > 0 {
          node.texture = SKTexture(imageNamed: "CrossbowBroken1")
        }
      }
    }
  }
  
  func upgradePurchased(upgrade: SKSpriteNode) {
    switch upgrade {
//    case purchaseFlame:
//      if totalCoins < flameUpgradeCost {return}
//      if flamePurchased == true {return}
//      totalCoins -= flameUpgradeCost
//      totalCoinsBoard.text = "Total Coins: \(totalCoins)"
//      let shrink = SKAction.scaleTo(0, duration: 0.6)
//      purchaseFlame.runAction(SKAction.sequence([shrink, SKAction.removeFromParent()]))
//      flamePurchased = true
    case purchaseShield:
      if totalCoins < shieldUpgradeCost { return AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) }
      if shield.purchased == true {return}
      
      if purchaseShieldExplanationActive {
//        purchaseShieldExplanationActive = false
        purchaseShieldExplanation.removeFromParent()
      }
      
      shield.purchased = true
      shield.texture = SKTexture(imageNamed: "ShieldActive")
      shield.health = 100
      totalCoins -= shieldUpgradeCost
      totalCoinsBoard.text = "Total Coins: \(totalCoins)"
      
      shield.position = player.position
      let shieldSize = player.size.width + 5
      shield.size = CGSize(width: shieldSize, height: shieldSize)
      shield.alpha = 2
      
//      shield.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: shield.size.width, height: shield.size.height))
      shield.physicsBody = SKPhysicsBody(circleOfRadius: shield.size.width/2)
      shield.physicsBody?.dynamic = true
      shield.physicsBody?.categoryBitMask = PhysicsCategory.Shield.rawValue
      shield.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue
      shield.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
      
      backgroundLayer.addChild(shield)
      
      purchaseShield.runAction(SKAction.scaleTo(0.0, duration: 1.0), withKey: "shrinking")
      
      let shieldPurchasedEvent = GAIDictionaryBuilder.createEventWithCategory("UpgradePurchased", action: "shield", label: "shieldPurchased", value: shieldUpgradeCost).build()
      tracker.send(shieldPurchasedEvent as? [NSObject : AnyObject])
      
    case purchaseSlowmo:
      if totalCoins < slowmoUpgradeCost { return AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) }
      if slowmoPurchased == true {return}
      
      if purchaseSlowmoExplanationActive {
        purchaseSlowmoExplanation.removeFromParent()
      }
      
      totalCoins -= slowmoUpgradeCost
      totalCoinsBoard.text = "Total Coins: \(totalCoins)"
      self.slowmoPurchased = true
      
      self.removeActionForKey("addingMonsters")
      self.addMonsterBlock(2.0)
      
      var countDown = 10
      let count = SKLabelNode(fontNamed: "Chalkduster")
      count.position = CGPoint(x: 0, y: 0)
      count.fontColor = UIColor.whiteColor()
      count.text = String(countDown)
      count.fontSize = 30.0
      count.zPosition = 2
      purchaseSlowmo.addChild(count)
      
      //Changes speed of existing arrows
      backgroundLayer.enumerateChildNodesWithName("arrow") {
        node, stop in
        node.removeAllActions()
        
        let monster = node as! Monster
        
        var actionMove = SKAction()
        
        // Create the actions
        if let monsterExistingMoveDuration = monster.moveDuration {
          actionMove = SKAction.moveTo(monster.realDest!, duration: NSTimeInterval(self.slowmoSpeedModifier + monsterExistingMoveDuration))
        } else {
          actionMove = SKAction.moveTo(monster.realDest!, duration: NSTimeInterval(self.slowmoSpeedModifier))
        }
        let actionMoveDone = SKAction.removeFromParent()
        
        monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
      }
      
      let playUpgrade = SKAction.runBlock {
        self.musicController.pauseBackgroundMusic()
        self.musicController.playUpgradeMusic("dubstepMusic.mp3")
      }
      
      let returnToBackgroundMusic = SKAction.runBlock {
        self.musicController.stopUpgradeMusic()
        self.musicController.resumeBackgroundMusic()
      }
      
      let wait = SKAction.waitForDuration(1.0)
      let keepCount = SKAction.runBlock {
        countDown = self.reduceByOne(countDown)
        count.text = String(countDown)
        if (countDown < 2) {
          count.removeFromParent()
        }
      }
    
      let countDownSequence = SKAction.repeatAction(SKAction.sequence([wait, keepCount]), count: 10)
      let shrink = SKAction.scaleTo(0, duration: slowmoDuration)
      let shrinkAndCountGroup = SKAction.group([shrink, countDownSequence])
      let quickPop = SKAction.scaleTo(1.1, duration: 0.1)
      let grow = SKAction.scaleTo(1.0, duration: 0.1)
      
      let returnToNormalSpeed = SKAction.runBlock {
        self.slowmoPurchased = false
//        self.purchaseSlowmoExplanationActive = false
        
        self.removeActionForKey("addingMonsters")
        self.addMonsterBlock(1.0)
        
        self.backgroundLayer.enumerateChildNodesWithName("arrow") {
          node, stop in
          node.removeAllActions()
          
          let monster = node as! Monster
          
          // Create the actions
          let actionMove = SKAction.moveTo(monster.realDest!, duration: NSTimeInterval(monster.moveDuration!))
          let actionMoveDone = SKAction.removeFromParent()
          
          monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        }
      }
      
      self.runAction(SKAction.sequence([playUpgrade, SKAction.waitForDuration(slowmoDuration), returnToBackgroundMusic]))
      purchaseSlowmo.runAction(SKAction.sequence([quickPop, shrinkAndCountGroup, grow, returnToNormalSpeed]))

      
      let slowmoPurchasedEvent = GAIDictionaryBuilder.createEventWithCategory("UpgradePurchased", action: "slowmo", label: "slowmoPurchased", value: self.slowmoUpgradeCost)
      tracker.send(slowmoPurchasedEvent.build() as! [NSObject: AnyObject])
      
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
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    for touch in (touches ) {
      let touchLocation = touch.locationInNode(self)
      let attackExtendedRect = CGRectMake(attackButton.position.x - attackButton.size.width/2, attackButton.position.y - attackButton.size.height/2, attackButton.size.width,  attackButton.size.height * 2)
      if (CGRectContainsPoint(attackExtendedRect, touchLocation)) && playerDead != true {
        attackButtonPushed()
//      } else if (CGRectContainsPoint(purchaseFlame.frame, touchLocation)) && playerDead == false {
//        upgradePurchased(purchaseFlame)
      } else if (CGRectContainsPoint(purchaseShield.frame, touchLocation)) && playerDead != true {
        upgradePurchased(purchaseShield)
      } else if (CGRectContainsPoint(purchaseSlowmo.frame, touchLocation)) && playerDead != true {
        upgradePurchased(purchaseSlowmo)
      } else if (CGRectContainsPoint(pausedButton.frame, touchLocation)) && playerDead != true {
        pausedButtonPushed()
      } else if (CGRectContainsPoint(muteButton.frame, touchLocation)) && playerDead != true {
        muteButtonPushed()
      } else if (CGRectContainsPoint(base.frame, touchLocation)) && playerDead != true {
        mostRecentBasePosition = base.position
        mostRecentBallPosition = ball.position
      }
    }
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if playerDead == false && !paused {
      for touch in (touches) {
        let touchLocation = touch.locationInNode(self)
          
        if (CGRectContainsPoint(attackButton.frame, touchLocation)) {
          return
        }
        
        if leftExplanationActive {
          leftExplanationActive = false
          leftThumbExplanation.removeFromParent()
          
          rightExplanationActive = true
          rightThumbExplanation.size = CGSize(width: 100.0, height: 100.0)
          rightThumbExplanation.position = CGPoint(x: attackButton.position.x - 30, y: navigationBox.position.y + navigationBox.size.height + rightThumbExplanation.size.height/2)
          self.addChild(rightThumbExplanation)
          rightThumbExplanation.runAction(SKAction.repeatActionForever(fadeAlphaSequence))
        }

        if touchLocation.x < size.width / 3 {
          
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
          let multiplier:CGFloat = 0.1
          
          shipSpeedX = max(min(v.dx * multiplier, 2.5), -2.5)
          shipSpeedY = max(min(v.dy * multiplier, 2.5), -2.5)
            
          mostRecentBasePosition = base.position
          mostRecentBallPosition = ball.position
          
          if (CGRectContainsPoint(base.frame, touchLocation)) { ball.position = touchLocation }
          else { ball.position = CGPointMake(base.position.x - xDist, base.position.y + yDist) }
        }
      }
    }
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    for touch in (touches) {
      let touchLocation = touch.locationInNode(self)
      if (!CGRectContainsPoint(self.base.frame, touchLocation)) {
        removeProjectile()
      }
    }
  }
  
  func removeProjectile() {
    switch dragonSelected {
    case 1: flame.removeFromParent()
    case 3: laser.removeFromParent()
    default: break
    }
  }
  
  func returnFromBackground() {
    print("return from background")
    paused = false
    pausedLabel.removeFromParent()

    if slowmoPurchased { musicController.resumeUpgradeMusic() } else { musicController.playBackgroundMusic("epicMusic.mp3") }
    pausedButton.texture = SKTexture(imageNamed: "pause-button")
  }
  
  func goingToBackground() {
    print("going to background")
    paused = true
    pausedLabel.removeFromParent()
    musicController.pauseUpgradeMusic()
    musicController.stopBackgroundMusic()
  }
  
  func pausedButtonPushed() {
    if !paused {
      pausedButton.texture = SKTexture(imageNamed: "paused-pushed")
      paused = true
      pausedLabel.removeFromParent()
      self.addChild(pausedLabel)
      musicController.pauseBackgroundMusic()
      musicController.pauseUpgradeMusic()
    } else if paused {
      pausedButton.texture = SKTexture(imageNamed: "pause-button")
      paused = false
      pausedLabel.removeFromParent()
      musicController.resumeBackgroundMusic()
      musicController.resumeUpgradeMusic()
    }
  }
  
  func muteButtonPushed() {
    if !muted {
      muteButton.texture = SKTexture(imageNamed: "muteSoundIcon")
      muted = true
      musicController.muteAllSound()
      musicController.pauseBackgroundMusic()
      if let upgradeMusic = musicController.upgradeMusicPlayer {
        upgradeMusic.volume = Float(0.0)
      }
    } else if muted {
      muteButton.texture = SKTexture(imageNamed: "soundIcon")
      muted = false
      musicController.unMuteAllSound()
      if !slowmoPurchased { musicController.resumeBackgroundMusic() }
      if let upgradeMusic = musicController.upgradeMusicPlayer {
        upgradeMusic.volume = musicController.upgradeVolume
      }
    }
  }
  
  func attackButtonPushed() {
    if rightExplanationActive && collectCoinsExplanationActive == false && self.levelReached < 2 {
      rightExplanationActive = false
      rightThumbExplanation.removeFromParent()
      
      collectCoinsExplanationActive = true
      collectCoinsExplanation.size = CGSize(width: 100.0, height: 50.0)
      collectCoinsExplanation.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
      self.addChild(collectCoinsExplanation)
      collectCoinsExplanation.runAction(SKAction.sequence([SKAction.waitForDuration(3.0), SKAction.fadeAlphaTo(0.0, duration: 2.0), SKAction.removeFromParent()]))
    }
    
    if dragonSelected == 1 || dragonSelected == 0 {
      let projectile = SKSpriteNode(texture: firstFireballFrame)
      
      let projectilePosVector = convertAngleToVector(Double(player.zRotation) + M_PI_2)
      projectile.position = CGPoint(x: player.position.x + projectilePosVector.dx, y: player.position.y + projectilePosVector.dy) //Makes fireball appear to come from mouth of player rather than from middle of body.
      projectile.size = CGSize(width: 25.0, height: 25.0)
      
      projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
      projectile.physicsBody?.dynamic = true
      projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile.rawValue
      projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue | PhysicsCategory.Crossbow.rawValue
      projectile.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
      projectile.physicsBody?.usesPreciseCollisionDetection = true
      
      var offset = CGPoint()
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
      var shootFireballGroup = SKAction.group([fireballSoundEffect, shootFireball, shrink])
    
      if birthdayMode {
        shootFireballGroup = SKAction.group([fireballSoundEffect, shrink])
        projectile.texture = SKTexture(imageNamed: "windBlowing")
      }
      
      if muted {
        shootFireballGroup = SKAction.group([shootFireball, shrink])
      }

      projectile.runAction(shootFireballGroup)
      projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    if dragonSelected == 1 {
      print("Shot flame")
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
      flame.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue | PhysicsCategory.Crossbow.rawValue
      flame.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
      
      backgroundLayer.addChild(flame)
    }
    
    if dragonSelected == 2 || dragonSelected == 3 {
      print("Shot laserBall")
      let projectile = SKSpriteNode(texture: firstLaserBallFrame)
      
      let projectilePosVector = convertAngleToVector(Double(player.zRotation) + M_PI_2)
      projectile.position = CGPoint(x: player.position.x + projectilePosVector.dx, y: player.position.y + projectilePosVector.dy) //Makes fireball appear to come from mouth of player rather than from middle of body.
      projectile.size = CGSize(width: 30.0, height: 9.0)
      projectile.zRotation = player.zRotation + 1.57079633
      
      projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
      projectile.physicsBody?.dynamic = true
      projectile.physicsBody?.categoryBitMask = PhysicsCategory.Laser.rawValue
//      projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue | PhysicsCategory.Crossbow.rawValue
      projectile.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
      projectile.physicsBody?.usesPreciseCollisionDetection = true
      
      var offset = CGPoint()
      if ball.position != base.position {
        offset = ball.position - base.position
      } else {
        offset = mostRecentBallPosition - mostRecentBasePosition
      }
      
      backgroundLayer.addChild(projectile)
      
      let direction = offset.normalized()
      let shootAmount = direction * (self.size.width)
      let realDest = shootAmount + projectile.position
      
      let actionMove = SKAction.moveTo(realDest, duration: 1.0)
      let actionMoveDone = SKAction.removeFromParent()
      
      let shootLaserBall = SKAction.animateWithTextures(laserBallScenes, timePerFrame: 0.05)
//      let shrink = SKAction.scaleTo(0.2, duration: 2.0)
      var shootLaserBallGroup = SKAction.group([shootLaserBall, laserBallSoundEffect])
      
      if muted {
        shootLaserBallGroup = shootLaserBall
      }
      
      projectile.runAction(shootLaserBallGroup)
      projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    if dragonSelected == 3 {
      print("Shot laser beam")
      laser = SKSpriteNode(texture: laserScenes[0])
      laser.size = CGSize(width: player.size.width*2, height: 9)
      laser.zPosition = 1
      
//      let animateLaser = SKAction.animateWithTextures(laserScenes, timePerFrame: 0.07)
//      let laserStart = SKAction.group([ animateLaser, SKAction.scaleBy(4.0, duration: 0.5) ])
//      let repeatForever = SKAction.repeatActionForever(animateLaser)
//      laser.runAction(repeatForever)
      
      laser.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: laser.size.width, height: laser.size.height))
      laser.physicsBody?.dynamic = true
      laser.physicsBody?.categoryBitMask = PhysicsCategory.Laser.rawValue
//      laser.physicsBody?.contactTestBitMask = PhysicsCategory.Monster.rawValue | PhysicsCategory.Crossbow.rawValue
      laser.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
      
      backgroundLayer.addChild(laser)
    }
  }

  
  func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
    print("Arrow hit by fire")
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
    monstersKilledBoard.text = "Arrows Destroyed: \(monstersDestroyed)"
  }
  
  func laserDidCollideWithMonster(laser:SKSpriteNode, monster:SKSpriteNode) {
    print("Arrow hit by laser")
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
    monstersKilledBoard.text = "Arrows Destroyed: \(monstersDestroyed)"
  }
  
  func playerShotCrossbow(crossbowHit: SKSpriteNode, laser: Bool) {
    if let boss = crossbowHit as? Boss {
      boss.health -= 50
      
      if laser {
        boss.health = 0
      }
      
      if boss.health > 0 {
        crossbowHit.texture = SKTexture(imageNamed: "CrossbowBroken1")
        print("player shot the crossbow!")
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
      let wonLevelLabel = SKLabelNode(fontNamed: "Copperplate")
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
      
      backgroundLayer.enumerateChildNodesWithName("arrow") {
        node, _ in
        node.removeFromParent()
      }
      
      let pause = SKAction.waitForDuration(0.5)
      let fadeAway = SKAction.fadeOutWithDuration(1.0)
      let startNextLevel = SKAction.runBlock() {
        if self.playerDead == false {
          self.musicController.stopBackgroundMusic()
          self.musicController.stopUpgradeMusic()
          let reveal = SKTransition.flipHorizontalWithDuration(0.5)
          let scene = GameScene(size: self.size, level: self.levelReached+1, muted: self.muted, coinsCollected: self.coinsCollected, monstersDestroyed: self.monstersDestroyed, shield: self.shield, dragonType: self.dragonSelected, birthdayMode: self.birthdayMode, birthdayPicture: self.birthdayPicture)
          self.backgroundLayer.removeAllChildren()
          self.backgroundLayer.removeFromParent()
          self.view?.presentScene(scene, transition:reveal)
        }
      }
      
      wonLevelLabel.runAction(SKAction.sequence([pause, fadeAway, startNextLevel]))
    }
  }
  
  func endGame(showAds: Bool) {
    paused = false
    self.musicController.stopBackgroundMusic()
    self.musicController.playSoundEffect("PlayerDeath.wav")
    
    let gameOverTransition = SKAction.runBlock {
      let gameOverScene = GameOverScene(size: self.size, muted: self.muted, won: false, score: self.coinsCollected, monstersDestroyed: self.monstersDestroyed, levelReached: self.levelReached, coinsPerLevelMultiplier: self.coinsPerLevelMultiplier, dragonSelected: self.dragonSelected, birthdayMode: self.birthdayMode, birthdayPicture: self.birthdayPicture, highScoreAchieved: self.highScoreAchieved)
      let reveal = SKTransition.flipHorizontalWithDuration(0.5)
//      self.playerDead = false
      self.view?.presentScene(gameOverScene, transition: reveal)
      if showAds && self.levelReached > 1 {
        NSNotificationCenter.defaultCenter().postNotificationName("showInterstitialAdsID", object: nil)
      }
    }
    
    self.player.removeActionForKey("playerFlappingWings")
    let freezeTexture = SKAction.setTexture(self.playerFlyingScenes[0])
    let spinShrinkDuration = 1.5
    let spinPlayer = SKAction.rotateByAngle(10.0, duration: spinShrinkDuration)
    let shrinkPlayer = SKAction.scaleTo(0.0, duration: spinShrinkDuration)
    
    let spinAndShrinkGroup = SKAction.group([spinPlayer, shrinkPlayer])
    
    self.player.runAction(SKAction.sequence([freezeTexture, spinAndShrinkGroup, gameOverTransition]))
  }
  
  func monsterDidCollideWithPlayer(monster: SKSpriteNode) {
    print("Monster got the player!")

    if playerDead == false {
      
      self.playerDead = true
      self.paused = true

      AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
      
      self.musicController.pauseBackgroundMusic()
      self.musicController.stopUpgradeMusic()

      let coinsToEvadeDeath = 10 + 2 * coinsPerLevelMultiplier * (self.levelReached-1)
//      let coinsToEvadeDeath = 50 * Int((self.levelReached+2)/4)
      
      let gameOverAlert = UIAlertController(title: "Game Over", message: "Spend \(coinsToEvadeDeath) coins to evade death?", preferredStyle: UIAlertControllerStyle.Alert)
      
      gameOverAlert.addAction(UIAlertAction(title: "YES!", style: .Default, handler: { (action: UIAlertAction) in
        monster.removeFromParent()
        self.playerDead = false

        self.paused = false
        self.musicController.resumeBackgroundMusic()
        self.musicController.resumeUpgradeMusic()
        
        self.totalCoins -= (coinsToEvadeDeath - self.shieldUpgradeCost)
        self.upgradePurchased(self.purchaseShield)
        NSUserDefaults.standardUserDefaults().setObject(self.totalCoins,forKey:"TotalCoins")
        self.totalCoinsBoard.text = "Total Coins: \(self.totalCoins)"
      }))
      
      gameOverAlert.addAction(UIAlertAction(title: "No, I'll restart", style: .Default, handler: { (action: UIAlertAction) in
        self.endGame(true)
      }))
      
      let gameOverVideoAlert = UIAlertController(title: "Bonus Life & Coins!", message: "Evade death & win 50 coins by watching a short video?", preferredStyle: UIAlertControllerStyle.Alert)
      
      gameOverVideoAlert.addAction(UIAlertAction(title: "YES!", style: .Default, handler: { (action: UIAlertAction) in
        monster.removeFromParent()
        Chartboost.showRewardedVideo(CBLocationGameScreen)
        //Can move all the below to AppDelegate
//        self.playerDead = false
//        self.totalCoins += self.shieldUpgradeCost + 50 //Used to offset cost of shield purchase below
//        self.upgradePurchased(self.purchaseShield)
//        NSUserDefaults.standardUserDefaults().setObject(self.totalCoins,forKey:"TotalCoins")
//        self.totalCoinsBoard.text = "Total Coins: \(self.totalCoins)"
        //
      }))
      
      gameOverVideoAlert.addAction(UIAlertAction(title: "No, I'll restart", style: .Default, handler: { (action: UIAlertAction) in
        self.endGame(false)
      }))
      
      if Chartboost.hasRewardedVideo(CBLocationGameScreen) && (arc4random_uniform(4) + 1) % 3 == 0 && self.levelReached >= 2  {
        self.musicController.playSoundEffect("PlayerDeath.wav")
        self.view?.window?.rootViewController?.presentViewController(gameOverVideoAlert, animated: true, completion: nil)
      } else if totalCoins >= coinsToEvadeDeath {
        self.musicController.playSoundEffect("PlayerDeath.wav")
        self.view?.window?.rootViewController?.presentViewController(gameOverAlert, animated: true, completion: nil)
      } else {
        self.endGame(true)
      }
    }
  }
  
  @objc private func finishedShowingRewardedVideo(notification: NSNotification){
    print("finished showing rewarded video")
    self.totalCoins += self.shieldUpgradeCost + 50 //Used to offset cost of shield purchase below
    self.upgradePurchased(self.purchaseShield)
    NSUserDefaults.standardUserDefaults().setObject(self.totalCoins,forKey:"TotalCoins")
    self.totalCoinsBoard.text = "Total Coins: \(self.totalCoins)"
  }
  
  @objc private func rewardVideoClosed(notification: NSNotification){
     NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "revivePlayer", userInfo: nil, repeats: false)
  }
  
  func revivePlayer() {
    self.playerDead = false
    self.paused = false
  }
  
  func playerCollectedCoin(player:SKSpriteNode, coin: SKSpriteNode) {
    coin.removeFromParent()
    coinCount--
    
    coinsCollected++
    totalCoins++
    NSUserDefaults.standardUserDefaults().setObject(totalCoins,forKey:"TotalCoins")
    
    scoreBoard.text = "Score: \(coinsCollected)"
    totalCoinsBoard.text = "Total Coins: \(totalCoins)"

    if totalCoins >= slowmoUpgradeCost && slowmoPurchased == false {
      purchaseSlowmo.runAction(SKAction.scaleTo(1.0, duration: 0.3))
      if self.coinsEverCollected + self.coinsCollected <= 30 && purchaseSlowmoExplanationActive == false && purchaseShieldExplanationActive == false {
        collectCoinsExplanation.removeFromParent()
        rightThumbExplanation.removeFromParent()
        purchaseSlowmoExplanationActive = true
        purchaseSlowmoExplanation.size = CGSize(width: 100.0, height: 100.0)
        purchaseSlowmoExplanation.position = CGPoint(x: purchaseSlowmo.position.x - 30, y: navigationBox.position.y + navigationBox.size.height + purchaseSlowmoExplanation.size.height/2)
        self.addChild(purchaseSlowmoExplanation)
//        purchaseSlowmoExplanation.runAction(SKAction.repeatActionForever(fadeAlphaSequence))
        purchaseSlowmoExplanation.runAction(SKAction.sequence([SKAction.waitForDuration(3.0), SKAction.fadeAlphaTo(0.0, duration: 2.0), SKAction.removeFromParent()]))
      }

    }
    
    if totalCoins >= shieldUpgradeCost && shield.purchased == false {
      purchaseShield.runAction(SKAction.scaleTo(1.0, duration: 0.3))
      if self.coinsEverCollected + self.coinsCollected <= 40 && purchaseShieldExplanationActive == false {
        purchaseSlowmoExplanation.removeFromParent()
        collectCoinsExplanation.removeFromParent()
        rightThumbExplanation.removeFromParent()
        purchaseShieldExplanationActive = true
        purchaseShieldExplanation.size = CGSize(width: 100.0, height: 100.0)
        purchaseShieldExplanation.position = CGPoint(x: purchaseShield.position.x - 30, y: navigationBox.position.y + navigationBox.size.height + purchaseShieldExplanation.size.height/2)
        self.addChild(purchaseShieldExplanation)
        purchaseShieldExplanation.runAction(SKAction.sequence([SKAction.waitForDuration(3.0), SKAction.fadeAlphaTo(0.0, duration: 2.0), SKAction.removeFromParent()]))
      }
    }
    
    if self.rightPoint >= self.backgroundWidth && killCrossbowExplanationActive == false {
//      collectCoinsExplanationActive = false
      collectCoinsExplanation.removeFromParent()
      
      killCrossbowExplanationActive = true
      killCrossbowExplanation.size = CGSize(width: 100.0, height: 100.0)
      killCrossbowExplanation.position = CGPoint(x: self.size.width - killCrossbowExplanation.size.width, y: (self.size.height/1.25))
      self.addChild(killCrossbowExplanation)
      killCrossbowExplanation.runAction(SKAction.sequence([SKAction.waitForDuration(3.0), SKAction.fadeAlphaTo(0.0, duration: 2.0), SKAction.removeFromParent()]))
//      killCrossbowExplanation.runAction(SKAction.repeatActionForever(fadeAlphaSequence))
    }
    
    
    if let savedScore: Int = NSUserDefaults.standardUserDefaults().objectForKey("HighestScore") as? Int {
      if coinsCollected > savedScore {
        highScoreAchieved = true
        NSUserDefaults.standardUserDefaults().setObject(coinsCollected,forKey:"HighestScore")
        highScoreBoard.text = "High Score: \(coinsCollected)"
      }
    }
  }
    
  func shieldHitByMonster(monster: SKSpriteNode) {
    monster.removeFromParent()
    monstersDestroyed++
    monstersKilledBoard.text = "Arrows Destroyed: \(monstersDestroyed)"
    shield.health -= 50
    let popShield = SKAction.sequence([SKAction.scaleTo(1.3, duration: 0.1), SKAction.scaleTo(1.0, duration: 0.1)])
    
    if shield.health <= 0 {
      let removeShield = SKAction.removeFromParent()
      let resetShieldTexture = SKAction.setTexture(SKTexture(imageNamed: "ShieldActive"))
      shield.runAction(SKAction.sequence([shieldDestroyedSoundEffect, removeShield, resetShieldTexture]))
      self.shield.purchased = false
      if totalCoins >= shieldUpgradeCost {
        purchaseShield.removeActionForKey("shrinking")
        purchaseShield.runAction(SKAction.scaleTo(1.0, duration: 0.3))
      }
    } else {
      let changeTexture = SKAction.setTexture(SKTexture(imageNamed: "ShieldBroken"))
      shield.runAction(SKAction.sequence([popShield, shieldHitSoundEffect, changeTexture]))
    }
  }
  
  func didBeginContact(contact: SKPhysicsContact) {
    
    // Step 1. Bitiwse OR the bodies' categories to find out what kind of contact we have
    let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
    switch contactMask {
      
    case PhysicsCategory.Monster.rawValue | PhysicsCategory.Projectile.rawValue:
      if let bodyB = contact.bodyB.node as? SKSpriteNode {
        if let bodyA = contact.bodyA.node as? SKSpriteNode {
          if contact.bodyA.categoryBitMask == PhysicsCategory.Monster.rawValue {
            projectileDidCollideWithMonster(bodyB, monster: bodyA)
          } else {
            projectileDidCollideWithMonster(bodyA, monster: bodyB)
          }
        }
      }
      
    case PhysicsCategory.Monster.rawValue | PhysicsCategory.Laser.rawValue:
      if let bodyB = contact.bodyB.node as? SKSpriteNode {
        if let bodyA = contact.bodyA.node as? SKSpriteNode {
          if contact.bodyA.categoryBitMask == PhysicsCategory.Monster.rawValue {
            laserDidCollideWithMonster(bodyB, monster: bodyA)
          } else {
            laserDidCollideWithMonster(bodyA, monster: bodyB)
          }
        }
      }
      
    case PhysicsCategory.Monster.rawValue | PhysicsCategory.Player.rawValue:
      // Here we don't care which body is which, the scene is ending
      if let bodyB = contact.bodyB.node as? SKSpriteNode {
        if let bodyA = contact.bodyA.node as? SKSpriteNode {
          if contact.bodyA.categoryBitMask == PhysicsCategory.Monster.rawValue {
            monsterDidCollideWithPlayer(bodyA)
          } else {
            monsterDidCollideWithPlayer(bodyB)
          }
        }
      }
      
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
            self.playerShotCrossbow(bodyA, laser: false)
          } else {
            self.playerShotCrossbow(bodyB, laser: false)
          }
        }
      }
    
    case PhysicsCategory.Crossbow.rawValue | PhysicsCategory.Laser.rawValue:
      if let bodyB = contact.bodyB.node as? SKSpriteNode {
        if let bodyA = contact.bodyA.node as? SKSpriteNode {
          if contact.bodyA.categoryBitMask == PhysicsCategory.Crossbow.rawValue {
            self.playerShotCrossbow(bodyA, laser: true)
          } else {
            self.playerShotCrossbow(bodyB, laser: true)
          }
        }
      }
      
    case PhysicsCategory.Shield.rawValue | PhysicsCategory.Monster.rawValue:
      if let bodyB = contact.bodyB.node as? SKSpriteNode {
        if let bodyA = contact.bodyA.node as? SKSpriteNode {
          if contact.bodyA.categoryBitMask == PhysicsCategory.Monster.rawValue {
            self.shieldHitByMonster(bodyA)
          } else {
            self.shieldHitByMonster(bodyB)
          }
        }
      }
      
    case PhysicsCategory.Crossbow.rawValue | PhysicsCategory.Coin.rawValue:
      break
    case PhysicsCategory.Crossbow.rawValue | PhysicsCategory.Player.rawValue:
      break
    case PhysicsCategory.Crossbow.rawValue | PhysicsCategory.Monster.rawValue:
      break
      
    case PhysicsCategory.Shield.rawValue | PhysicsCategory.Coin.rawValue:
      break
    case PhysicsCategory.Shield.rawValue | PhysicsCategory.Projectile.rawValue:
      break
    case PhysicsCategory.Shield.rawValue | PhysicsCategory.Player.rawValue:
      break
    case PhysicsCategory.Shield.rawValue | PhysicsCategory.Crossbow.rawValue:
      break
    case PhysicsCategory.Shield.rawValue | PhysicsCategory.Laser.rawValue:
      break

    case PhysicsCategory.Laser.rawValue | PhysicsCategory.Coin.rawValue:
      break
    case PhysicsCategory.Laser.rawValue | PhysicsCategory.Player.rawValue:
      print("laser hitting player")
      break

    case PhysicsCategory.Projectile.rawValue | PhysicsCategory.Player.rawValue:
      break
    case PhysicsCategory.Projectile.rawValue | PhysicsCategory.Coin.rawValue:
      break
   
    case PhysicsCategory.Monster.rawValue | PhysicsCategory.Coin.rawValue:
      break
    case PhysicsCategory.Monster.rawValue | PhysicsCategory.Monster.rawValue:
      break
      
    default:
      print(contact.bodyA.node)
      print(contact.bodyB.node)
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
    if rightPoint >= backgroundWidth {
      backgroundLayer.enumerateChildNodesWithName("boss") {
        node, stop in
          let v = CGVector(dx: node.position.x - self.player.position.x, dy:  node.position.y - self.player.position.y)
          let angle = atan2(v.dy, v.dx)
          node.zRotation = angle
      }
    }
    
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
      
      if dragonSelected == 1 {
        let flamePosVector = convertAngleToVector(Double(player.zRotation) + M_PI_2)
        flame.position = CGPoint(x: player.position.x + flamePosVector.dx, y: player.position.y + flamePosVector.dy)
        flame.zRotation = player.zRotation + 1.57079633
      }
      
      if dragonSelected == 3 {
        let laserPosVector = convertAngleToVector(Double(player.zRotation) + M_PI_2)
        laser.position = CGPoint(x: player.position.x + 4.5 * laserPosVector.dx, y: player.position.y + 4.5 * laserPosVector.dy)
        laser.zRotation = player.zRotation + 1.57079633
      }
      
      if shield.purchased == true {
        shield.position = CGPoint(x: player.position.x, y: player.position.y)
        shield.zRotation = player.zRotation + 1.57079633
      }
    }
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
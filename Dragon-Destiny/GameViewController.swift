//
//  GameViewController.swift
//  SpriteKitSimpleGame
//
//  Created by Main Account on 9/30/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import UIKit
import SpriteKit
import iAd

class GameViewController: UIViewController, UINavigationControllerDelegate {
  
  var dragonType: Int?
  var birthdayMode: Bool!
  var birthdayImage = UIImageView()
  var tracker: GAITracker!
  
  override func viewWillAppear(animated: Bool) {
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    var birthimg = UIImage()
    
    if let image = birthdayImage.image {
      birthimg = image
    }
    
    tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "GameViewController")
    
    let builder = GAIDictionaryBuilder.createScreenView()
    tracker.send(builder.build() as [NSObject : AnyObject])
    
    let dragonSelected = GAIDictionaryBuilder.createEventWithCategory("GameOptionsSelected", action: "dragonSelected", label: "dragonSelected", value: self.dragonType)
    self.tracker.send(dragonSelected.build() as [NSObject: AnyObject])
    
    let scene = GameScene(size: view.bounds.size, level: 1, muted: false, coinsCollected: 0, monstersDestroyed: 0, shield: Shield(), dragonType: dragonType!, birthdayMode: birthdayMode, birthdayPicture: birthimg)
    let skView = view as! SKView
    skView.ignoresSiblingOrder = true
    scene.scaleMode = .ResizeFill
    skView.presentScene(scene)
    
    if let userId = NSUserDefaults.standardUserDefaults().objectForKey("userId") as? String {
      print("User ID exists: \(userId)")
    } else {
      let uuid = NSUUID().UUIDString
      NSUserDefaults.standardUserDefaults().setValue(uuid, forKey: "userId")
      print("Set User ID to \(uuid)")
    }

//    skView.scene!.view!.paused = true
    
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
}

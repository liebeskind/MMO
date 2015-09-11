//
//  StartMenuViewController.swift
//  Dragon-Destiny
//
//  Created by Daniel Liebeskind on 8/24/15.
//  Copyright (c) 2015 Cybenex LLC. All rights reserved.
//

import UIKit
import SpriteKit

class StartMenuViewController: UIViewController {

  @IBOutlet weak var blueButton: UIButton!
  @IBOutlet weak var redButton: UIButton!
  @IBOutlet weak var fireballImage: UIImageView!
  @IBOutlet weak var flameImage: UIImageView!
  @IBOutlet weak var laserBallImage: UIImageView!
  @IBOutlet weak var laserImage: UIImageView!
  
  var dragonSelected = 0
  var previouslySelectedDragon: UIButton?
  
  override func viewWillAppear(animated: Bool) {
    var tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "StartMenuViewController")
    
    var builder = GAIDictionaryBuilder.createScreenView()
    tracker.send(builder.build() as [NSObject : AnyObject])
  }
  
  override func viewDidAppear(animated: Bool) {
    fireballImage.hidden = false
    flameImage.hidden = true
    laserBallImage.hidden = true
    laserImage.hidden = true
  }
  
  @IBAction func dragonSelectionButtonPressed(sender: UIButton) {
    dragonSelected = sender.tag
    sender.highlighted = true
    previouslySelectedDragon?.highlighted = false
    previouslySelectedDragon = sender
    
    switch sender.tag {
    case 0:
      fireballImage.hidden = false
      flameImage.hidden = true
      laserBallImage.hidden = true
      laserImage.hidden = true
    case 1:
      fireballImage.hidden = true
      flameImage.hidden = false
      laserBallImage.hidden = true
      laserImage.hidden = true
    case 2:
      fireballImage.hidden = true
      flameImage.hidden = true
      laserBallImage.hidden = false
      laserImage.hidden = true
    case 3:
      fireballImage.hidden = true
      flameImage.hidden = true
      laserBallImage.hidden = true
      laserImage.hidden = false
    default:
      fireballImage.hidden = false
      flameImage.hidden = true
      laserBallImage.hidden = true
      laserImage.hidden = true
    }
  }
  
  @IBAction func playArcadeButtonPushed(sender: UIButton) {
//    let reveal = SKTransition.flipHorizontalWithDuration(0.5)
//    let scene = GameScene(size: self.view.frame.size)
    
    let gameViewController = self.storyboard!.instantiateViewControllerWithIdentifier("GameViewController") as! GameViewController
    
    gameViewController.dragonType = dragonSelected
      
    self.navigationController!.pushViewController(gameViewController, animated: true)
    
//    self.presentViewController(gameViewController, animated: false, completion: nil)
  }
}

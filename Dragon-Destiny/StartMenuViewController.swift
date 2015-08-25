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

  override func viewWillAppear(animated: Bool) {
    var tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "StartMenuViewController")
    
    var builder = GAIDictionaryBuilder.createScreenView()
    tracker.send(builder.build() as [NSObject : AnyObject])
  }
  
  @IBAction func playArcadeButtonPushed(sender: UIButton) {
//    let reveal = SKTransition.flipHorizontalWithDuration(0.5)
//    let scene = GameScene(size: self.view.frame.size)
    
    let gameViewController = self.storyboard!.instantiateViewControllerWithIdentifier("GameViewController") as! GameViewController
      
//    self.navigationController!.pushViewController(gameViewController, animated: true)
    
    self.presentViewController(gameViewController, animated: false, completion: nil)
  }
}

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

  @IBOutlet weak var totalCoinsLabel: UILabel!
  @IBOutlet weak var dragonDestinyTitle: UILabel!
  
  @IBOutlet weak var blueButton: UIButton!
  @IBOutlet weak var redButton: UIButton!
  @IBOutlet weak var greenButton: UIButton!
  @IBOutlet weak var yellowButton: UIButton!
  
  @IBOutlet weak var fireballImage: UIImageView!
  @IBOutlet weak var flameImage: UIImageView!
  @IBOutlet weak var laserBallImage: UIImageView!
  @IBOutlet weak var laserImage: UIImageView!

  @IBOutlet weak var flameDragonImage: UIImageView!
  @IBOutlet weak var laserBallDragonImage: UIImageView!
  @IBOutlet weak var laserBeamDragonImage: UIImageView!

  @IBOutlet weak var lockFlame: UIImageView!
  @IBOutlet weak var lockLaserBall: UIImageView!
  @IBOutlet weak var lockLaserBeam: UIImageView!
  
  @IBOutlet weak var flameCostLabel: UILabel!
  @IBOutlet weak var laserBallCostLabel: UILabel!
  @IBOutlet weak var laserBeamCostLabel: UILabel!
  
  var birthdayPicker = UIButton()
  var birthdayPickerLabel = UILabel()
  
  var dragonSelected = 0
  var previouslySelectedDragon: UIButton?
  
  var totalCoins: Int?
  var birthdayMode = false
  
  let flameDragonPurchased = NSUserDefaults.standardUserDefaults().objectForKey("flameDragonPurchased") as? Bool
  let laserBallDragonPurchased = NSUserDefaults.standardUserDefaults().objectForKey("laserBallDragonPurchased") as? Bool
  let laserBeamDragonPurchased = NSUserDefaults.standardUserDefaults().objectForKey("laserBeamDragonPurchased") as? Bool
  
  override func viewDidLoad() {
    self.totalCoins = NSUserDefaults.standardUserDefaults().objectForKey("TotalCoins") as? Int
    
    if let hasCoins = self.totalCoins {
      totalCoinsLabel.text = "Total Coins: \(hasCoins)"
    }
    
    if flameDragonPurchased == true {
      println("flame dragon purchased")
      lockFlame.hidden = true
      flameCostLabel.hidden = true
    } else {
//      redButton.userInteractionEnabled = false
    }
    
    if laserBallDragonPurchased == true {
      println("laser ball dragon purchased")
      lockLaserBall.hidden = true
      laserBallCostLabel.hidden = true
    } else {
//      greenButton.userInteractionEnabled = false
    }
    
    if laserBeamDragonPurchased == true {
      println("laser beam dragon purchased")
      lockLaserBeam.hidden = true
      laserBeamCostLabel.hidden = true
    } else {
//      yellowButton.userInteractionEnabled = false
    }
  }
  
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
    
    println(self.view.frame)
    
    birthdayPickerLabel.text = "Change Mode"
    birthdayPickerLabel.font = UIFont(name: "MarkerFelt-Thin", size: 25)
    birthdayPickerLabel.textColor = UIColor.blueColor()
    birthdayPickerLabel.textAlignment = .Center
    birthdayPickerLabel.numberOfLines = 5
    birthdayPickerLabel.frame = CGRectMake(200, 0, self.view.frame.width, 50)
    birthdayPicker.setTitle("", forState: .Normal)
    birthdayPicker.setTitleColor(UIColor.redColor(), forState: .Normal)
    birthdayPicker.frame = CGRectMake(200, 0, self.view.frame.width, 50)
    birthdayPicker.addTarget(self, action: "birthdayPickerPressed:", forControlEvents: .TouchUpInside)
    self.view.addSubview(birthdayPickerLabel)
    self.view.addSubview(birthdayPicker)
  }
  
  func birthdayPickerPressed(sender: UIButton!) {
    if birthdayMode {
      birthdayMode = false
      birthdayPickerLabel.text = "Change Mode"
      dragonDestinyTitle.text = "Dragon Destiny"
    } else {
      birthdayMode = true
      birthdayPickerLabel.text = "Change Mode"
      dragonDestinyTitle.text = "Birthday Destiny"
    }
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
      if flameDragonPurchased == true {
        fireballImage.hidden = true
        flameImage.hidden = false
        laserBallImage.hidden = true
        laserImage.hidden = true
      } else {
        if let enoughCoins = self.totalCoins {
          if enoughCoins >= 200 {
            let purchaseDragonAlert = UIAlertController(title: "Purchase Flame Dragon", message: "Spend 200 coins to unlock flame dragon?", preferredStyle: UIAlertControllerStyle.Alert)
            
            purchaseDragonAlert.addAction(UIAlertAction(title: "YES!", style: .Default, handler: { (action: UIAlertAction!) in
              self.totalCoins! -= 200
              self.totalCoinsLabel.text = "Total Coins: \(self.totalCoins!)"
              NSUserDefaults.standardUserDefaults().setObject(self.totalCoins,forKey:"TotalCoins")
            }))
            
            purchaseDragonAlert.addAction(UIAlertAction(title: "I changed my mind", style: .Default, handler: { (action: UIAlertAction!) in
              println("Handle Cancel Logic here")
            }))
            
            presentViewController(purchaseDragonAlert, animated: true, completion: nil)
          }
        }
      }
    case 2:
      if laserBallDragonPurchased == true {
        fireballImage.hidden = true
        flameImage.hidden = true
        laserBallImage.hidden = false
        laserImage.hidden = true
      } else {
        println("purchase laser ball dragon?")
      }
    case 3:
      if laserBeamDragonPurchased == true {
        fireballImage.hidden = true
        flameImage.hidden = true
        laserBallImage.hidden = true
        laserImage.hidden = false
      } else {
        println("purchase laser beam dragon?")
      }
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
    gameViewController.birthdayMode = self.birthdayMode
      
    self.navigationController!.pushViewController(gameViewController, animated: true)
    
//    self.presentViewController(gameViewController, animated: false, completion: nil)
  }
}

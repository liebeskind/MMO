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
  @IBOutlet weak var dragonDestinyTitle: UILabel!
  
  var birthdayPicker = UIButton()
  var birthdayPickerLabel = UILabel()
  
  var dragonSelected = 0
  var previouslySelectedDragon: UIButton?
  
  var totalCoins: Int?
  var birthdayMode = false
  
  override func viewDidLoad() {
    self.totalCoins = NSUserDefaults.standardUserDefaults().objectForKey("TotalCoins") as? Int
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
    
    birthdayPickerLabel.text = "Birthday Mode"
    birthdayPickerLabel.font = UIFont(name: "MarkerFelt-Thin", size: 25)
    birthdayPickerLabel.textColor = UIColor.blueColor()
    birthdayPickerLabel.textAlignment = .Center
    birthdayPickerLabel.numberOfLines = 5
    birthdayPickerLabel.frame = CGRectMake(200, 0, self.view.frame.width, 50)
    birthdayPicker.setTitle("*", forState: .Normal)
    birthdayPicker.setTitleColor(UIColor.redColor(), forState: .Normal)
    birthdayPicker.frame = CGRectMake(200, 0, self.view.frame.width, 50)
    birthdayPicker.addTarget(self, action: "birthdayPickerPressed:", forControlEvents: .TouchUpInside)
    self.view.addSubview(birthdayPickerLabel)
    self.view.addSubview(birthdayPicker)
  }
  
  func birthdayPickerPressed(sender: UIButton!) {
    if birthdayMode {
      birthdayMode = false
      birthdayPickerLabel.text = "Birthday Mode"
      dragonDestinyTitle.text = "Dragon Destiny"
    } else {
      birthdayMode = true
      birthdayPickerLabel.text = "Dragon Mode"
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
    gameViewController.birthdayMode = self.birthdayMode
      
    self.navigationController!.pushViewController(gameViewController, animated: true)
    
//    self.presentViewController(gameViewController, animated: false, completion: nil)
  }
}

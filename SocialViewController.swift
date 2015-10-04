//
//  SocialViewController.swift
//  Dragon Heroes
//
//  Created by Daniel Liebeskind on 8/12/15.
//  Copyright (c) 2015 Cybenex LLC. All rights reserved.
//

import UIKit
import Social
class SocialViewController: UIViewController {
  
  var score: Int?
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    let serviceType = SLServiceTypeFacebook
//    if SLComposeViewController.isAvailableForServiceType(serviceType) {
//      let controller = SLComposeViewController(forServiceType: serviceType)
//      controller.setInitialText("WhateverMessage!")
//      controller.addImage(UIImage(named: "Facebook"))
//      controller.addURL(NSURL(string: "http://www.facebook.com"))
//      controller.completionHandler = {(result: SLComposeViewControllerResult) in
//        println("Completed")
//      }
//      presentViewController(controller, animated: true, completion: nil)
//    } else{
//      println("The Facebook service is not available")
//    }
    NSNotificationCenter.defaultCenter().addObserver(self, selector:
      "showTweetSheet:", name: "TwitterNotification", object: nil)
  }
  
  @objc private func showTweetSheet(notification: NSNotification){
    print("twitter button pressed")
    let tweetSheet = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
    tweetSheet.completionHandler = {
      result in
      switch result {
      case SLComposeViewControllerResult.Cancelled:
        //Add code to deal with it being cancelled
        break
        
      case SLComposeViewControllerResult.Done:
        //Add code here to deal with it being completed
        //Remember that dimissing the view is done for you, and sending the tweet to social media is automatic too. You could use this to give in game rewards?
        break
      }
    }
    
    tweetSheet.setInitialText("I just scored \(self.score) points in Dragons of Destiny!") //The default text in the tweet
//    tweetSheet.addImage(UIImage(named: "TestImage.png")) //Add an image if you like?
    tweetSheet.addURL(NSURL(string: "http://apple.co/1ORfMrR")) //A url which takes you into safari if tapped on
    
    self.presentViewController(tweetSheet, animated: false, completion: {
      //Optional completion statement
    })
  }
}
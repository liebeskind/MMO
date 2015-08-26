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
import GoogleMobileAds

class GameViewController: UIViewController, GADInterstitialDelegate, UINavigationControllerDelegate {
  
  var interstitial:GADInterstitial?
//  var interstitialAd:ADInterstitialAd! = nil
//  var interstitialAdView: UIView = UIView()
//  var closeButton:UIButton!
  
  override func viewWillAppear(animated: Bool) {
    var tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "GameViewController")
    
    var builder = GAIDictionaryBuilder.createScreenView()
    tracker.send(builder.build() as [NSObject : AnyObject])
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let scene = GameScene(size: view.bounds.size, level: 1, coinsCollected: 0)
    let skView = view as! SKView
    skView.ignoresSiblingOrder = true
    scene.scaleMode = .ResizeFill
    skView.presentScene(scene)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "presentInterstitial:", name:"showInterstitialAdsID", object: nil)
    
    if let userId = NSUserDefaults.standardUserDefaults().objectForKey("userId") as? String {
      println("User ID exists: \(userId)")
    } else {
      var uuid = NSUUID().UUIDString
      NSUserDefaults.standardUserDefaults().setValue(uuid, forKey: "userId")
      println("Set User ID to \(uuid)")
    }
    
    interstitial = createAndLoadInterstitial()
//    UIViewController.prepareInterstitialAds()
//    self.interstitialPresentationPolicy = ADInterstitialPresentationPolicy.Manual
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  @objc private func presentInterstitial(notification: NSNotification){
//    loadInterstitialAd()
    if let isReady = interstitial?.isReady {
      interstitial?.presentFromRootViewController(self)
    }
  }
  
//  //iAd Interstitial
//  func loadInterstitialAd() {
//    interstitialAd = ADInterstitialAd()
//    interstitialAd.delegate = self
//  }
//  
//  func interstitialAdWillLoad(interstitialAd: ADInterstitialAd!) {
//    println("Will Load iAD")
//  }
//  
//  func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
//    println("Did Load iAD")
//    interstitialAdView = UIView()
//    interstitialAdView.frame = self.view.bounds
//    view.addSubview(interstitialAdView)
//    
//    closeButton = UIButton(frame: CGRect(x: 5, y:  10, width: 100, height: 25))
////    closeButton.setBackgroundImage(UIImage(named: "error"), forState: UIControlState.Normal)
//    closeButton.setTitle("CLOSE", forState: UIControlState.Normal)
//    closeButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
//    closeButton.addTarget(self, action: Selector("close"), forControlEvents: UIControlEvents.TouchDown)
//    view.addSubview(closeButton)
//    
//    interstitialAd.presentInView(interstitialAdView)
//    UIViewController.prepareInterstitialAds()
//  }
//  
//  func interstitialAdActionDidFinish(interstitialAd: ADInterstitialAd!) {
//    println("Did Finish iAD")
//    interstitialAdView.removeFromSuperview()
//    closeButton.removeFromSuperview()
//  }
//  
//  func interstitialAdActionShouldBegin(interstitialAd: ADInterstitialAd!, willLeaveApplication willLeave: Bool) -> Bool {
//        println("iAd action should begin iAd")
//    return true
//  }
//  
//  func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
//        println("Failed to receive iAd")
//    if let isReady = interstitial?.isReady {
//      interstitial?.presentFromRootViewController(self)
//    } else {
//      println("AdMob ad wasn't ready, so didn't load")
//    }
//  }
//  
//  func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
//        println("iAd Did unload")
//    interstitialAdView.removeFromSuperview()
//    closeButton.removeFromSuperview()
//  }
//  
//  func close() {
//    interstitialAdView.removeFromSuperview()
//    closeButton.removeFromSuperview()
//    interstitial = nil
//  }
  
  
  //AdMob Interstitial
  func createAndLoadInterstitial()->GADInterstitial {
//    println("adMobCreateAndLoadInterstitial")
    var interstitial = GADInterstitial(adUnitID: "ca-app-pub-1048344523427807/2816356772")
    interstitial.delegate = self
    var request = GADRequest()
    request.testDevices = ["2f78537250ad45ed0f48261919acaeeb"]
    interstitial.loadRequest(request)
    
    return interstitial
  }
  
  func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
//    println("adMobInterstitialDidFailToReceiveAdWithError:\(error.localizedDescription)")
    interstitial = createAndLoadInterstitial()
//    loadInterstitialAd()
  }
  
  func interstitialDidReceiveAd(ad: GADInterstitial!) {
//    println("adMobInterstitialDidReceiveAd")
  }
  
  func interstitialWillDismissScreen(ad: GADInterstitial!) {
//    println("adMobInterstitialWillDismissScreen")
  }
  
  func interstitialDidDismissScreen(ad: GADInterstitial!) {
//    println("adMobInterstitialDidDismissScreen")
    interstitial = createAndLoadInterstitial()
  }
  
  func interstitialWillLeaveApplication(ad: GADInterstitial!) {
//    println("adMobInterstitialWillLeaveApplication")
  }
  
  func interstitialWillPresentScreen(ad: GADInterstitial!) {
//    println("adMobInterstitialWillPresentScreen")
  }
}

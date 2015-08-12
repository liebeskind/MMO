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

class GameViewController: UIViewController, GADInterstitialDelegate {
  
  var interstitial:GADInterstitial?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let scene = GameScene(size: view.bounds.size)
    let skView = view as! SKView
    skView.ignoresSiblingOrder = true
    scene.scaleMode = .ResizeFill
    skView.presentScene(scene)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "presentInterstitial:", name:"showInterstitialAdsID", object: nil)
    
    interstitial = createAndLoadInterstitial()
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  @objc private func presentInterstitial(notification: NSNotification){
    if let isReady = interstitial?.isReady {
      interstitial?.presentFromRootViewController(self)
    }
  }
  
  func createAndLoadInterstitial()->GADInterstitial {
    println("createAndLoadInterstitial")
    var interstitial = GADInterstitial(adUnitID: "ca-app-pub-1048344523427807/2816356772")
    interstitial.delegate = self
    var request = GADRequest()
    request.testDevices = ["2f78537250ad45ed0f48261919acaeeb"]
    interstitial.loadRequest(request)
    
    return interstitial
  }
  
  //Interstitial delegate
  func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
    println("interstitialDidFailToReceiveAdWithError:\(error.localizedDescription)")
//    interstitial = createAndLoadInterstitial()
  }
  
  func interstitialDidReceiveAd(ad: GADInterstitial!) {
    println("interstitialDidReceiveAd")
  }
  
  func interstitialWillDismissScreen(ad: GADInterstitial!) {
    println("interstitialWillDismissScreen")
  }
  
  func interstitialDidDismissScreen(ad: GADInterstitial!) {
    println("interstitialDidDismissScreen")
    interstitial = createAndLoadInterstitial()
  }
  
  func interstitialWillLeaveApplication(ad: GADInterstitial!) {
    println("interstitialWillLeaveApplication")
  }
  
  func interstitialWillPresentScreen(ad: GADInterstitial!) {
    println("interstitialWillPresentScreen")
  }
}

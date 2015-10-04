//
//  AppDelegate.swift
//  SpriteKitSimpleGame
//
//  Created by Main Account on 9/30/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import UIKit
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ChartboostDelegate, GADInterstitialDelegate {

  var window: UIWindow?
  var interstitial:GADInterstitial?
  var eliminateAdsPurchased: Bool?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    
    // Configure tracker from GoogleService-Info.plist.
    var configureError:NSError?
    GGLContext.sharedInstance().configureWithError(&configureError)
    assert(configureError == nil, "Error configuring Google services: \(configureError)")
    
    // Optional: configure GAI options.
    let gai = GAI.sharedInstance()
    gai.trackUncaughtExceptions = true  // report uncaught exceptions
    gai.defaultTracker.allowIDFACollection = true // Enable IDFA collection to collect user demographic information
//    gai.logger.logLevel = GAILogLevel.None  // remove before app release
    
    if UIScreen.mainScreen().brightness < 0.6 {
      UIScreen.mainScreen().brightness = 0.6
    }
    
    eliminateAdsPurchased = NSUserDefaults.standardUserDefaults().boolForKey("eliminateAdsPurchased")
    
    Chartboost.startWithAppId("5601ad2143150f235b341dc1", appSignature: "51eefe0cd45fdc0d3b2979c205fb5f4346e4e7eb", delegate: self)
    Chartboost.setAutoCacheAds(true)
    Chartboost.setShouldPrefetchVideoContent(true)
    Chartboost.cacheRewardedVideo(CBLocationGameScreen)
    Chartboost.setShouldRequestInterstitialsInFirstSession(true)
    
    AdColony.configureWithAppID("app437208845d0c41e39e", zoneIDs: ["vzdda6b3b271824796ad"], delegate: nil, logging: false)
    
    if eliminateAdsPurchased == nil || eliminateAdsPurchased == false {

      Chartboost.cacheInterstitial(CBLocationGameOver)      
      interstitial = createAndLoadInterstitial()
      
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "presentInterstitial:", name:"showInterstitialAdsID", object: nil)
    }
    return true
  }
  
  @objc private func presentInterstitial(notification: NSNotification){
    
    eliminateAdsPurchased = NSUserDefaults.standardUserDefaults().boolForKey("eliminateAdsPurchased")
    if eliminateAdsPurchased == true { return }
    if Chartboost.hasInterstitial(CBLocationGameOver) {
      Chartboost.showInterstitial(CBLocationGameOver)
    } else {
      Chartboost.cacheInterstitial(CBLocationGameOver)
      if let _ = interstitial?.isReady {
        interstitial?.presentFromRootViewController(self.window?.rootViewController)
      } else {
        AdColony.playVideoAdForZone("vzdda6b3b271824796ad", withDelegate: nil)
      }
    }
  }
  
  func createAndLoadInterstitial()->GADInterstitial {
    let interstitial = GADInterstitial(adUnitID: "ca-app-pub-1048344523427807/2816356772")
    interstitial.delegate = self
    let request = GADRequest()
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
    print("adMobInterstitialDidReceiveAd")
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
    print("adMobInterstitialWillPresentScreen")
  }
  
  // Called after an interstitial has been displayed on the screen.
  func didDisplayInterstitial(location: String!){
    print("Chartboost ad displayed")
  }
  
  // Called after an interstitial has been loaded from the Chartboost API
  // servers and cached locally.
  func didCacheInterstitial(location: String!){
    print("Chartboost ad cached")
  }
  
  func didCacheRewardedVideo(location: String!) {
    print("Chartboost Rewarded Video cached")
  }
  
  func didDismissInterstitial(location: String!) {
    print("Chartboost ad dismissed")

  }
  
  // Called after an interstitial has attempted to load from the Chartboost API
  // servers but failed.
  func didFailToLoadInterstitial(location: String!, withError error: CBLoadError) {
    print("Failed to load Chartboost ad")
  }
  
  func didFailToLoadRewardedVideo(location: String!, withError error: CBLoadError) {
    print("Failed to load Chartboost Rewarded Video")
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//    NSNotificationCenter.defaultCenter().postNotificationName("PauseGameScene", object: self)
    NSNotificationCenter.defaultCenter().postNotificationName("GoingToBackground", object: self)
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if UIScreen.mainScreen().brightness < 0.6 {
      UIScreen.mainScreen().brightness = 0.6
    }
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
      NSNotificationCenter.defaultCenter().postNotificationName("BackFromBackground", object: self)
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}


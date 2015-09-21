//
//  StartMenuViewController.swift
//  Dragon-Destiny
//
//  Created by Daniel Liebeskind on 8/24/15.
//  Copyright (c) 2015 Cybenex LLC. All rights reserved.
//

import UIKit
import SpriteKit
import MediaPlayer
import AudioToolbox
//import CameraManager
import GameKit

class StartMenuViewController: UIViewController, GKGameCenterControllerDelegate {

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
  
//  var tracker = GAI.sharedInstance().defaultTracker
  var tracker: GAITracker!
  
//  let birthdayModeContainer = UIView()
  
  var moviePlayer: MPMoviePlayerController!
  
//  let cameraManager = CameraManager.sharedInstance
//  var cameraView = UIView()
//  
//  var cameraButton = UIButton()
//  @IBOutlet weak var flashModeButton: UIButton!
  
//  @IBOutlet weak var askForPermissionsButton: UIButton!
//  @IBOutlet weak var askForPermissionsLabel: UILabel!
  
//  let playerImage = UIImageView()
//  
//  var birthdayPicker = UIButton()
//  var birthdayPickerLabel = UILabel()
  
  var dragonSelected = 0
//  var previouslySelectedDragon: UIButton?
  
  var totalCoins: Int?
  var birthdayMode = false
  
  var flameDragonPurchased = NSUserDefaults.standardUserDefaults().objectForKey("flameDragonPurchased") as? Bool
  var laserBallDragonPurchased = NSUserDefaults.standardUserDefaults().objectForKey("laserBallDragonPurchased") as? Bool
  var laserBeamDragonPurchased = NSUserDefaults.standardUserDefaults().objectForKey("laserBeamDragonPurchased") as? Bool
  
  let flameDragonCost = 200
  let laserBallDragonCost = 600
  let laserBeamDragonCost = 1200
  
  var gcEnabled = Bool() // Stores if the user has Game Center enabled
  var gcDefaultLeaderBoard = String() // Stores the default leaderboardID
  
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
//  override func shouldAutorotate() -> Bool {
//    return false
//  }
//
//  override func supportedInterfaceOrientations() -> Int {
//    return Int(UIInterfaceOrientationMask.All.rawValue)
//  }
  
  func authenticateLocalPlayer() {
    let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
    
    localPlayer.authenticateHandler = {(ViewController, error) -> Void in
      if((ViewController) != nil) {
        // 1 Show login if player is not logged in
        self.presentViewController(ViewController, animated: true, completion: nil)
      } else if (localPlayer.authenticated) {
        // 2 Player is already euthenticated & logged in, load game center
        self.gcEnabled = true
        
        // Get the default leaderboard ID
        localPlayer.loadDefaultLeaderboardIdentifierWithCompletionHandler({ (leaderboardIdentifer: String!, error: NSError!) -> Void in
          if error != nil {
            println(error)
          } else {
            self.gcDefaultLeaderBoard = leaderboardIdentifer
          }
        })
      } else {
        // 3 Game center is not enabled on the users device
        self.gcEnabled = false
        println("Local player could not be authenticated, disabling game center")
        println(error)
      }
    }
  }
  
  func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!) {
    gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func viewDidLoad() {
    self.totalCoins = NSUserDefaults.standardUserDefaults().objectForKey("TotalCoins") as? Int
//    totalCoins = 100000
//    imagePicker.delegate = self
    self.authenticateLocalPlayer()
    
    if let hasCoins = self.totalCoins {
      totalCoinsLabel.text = "Total Coins: \(hasCoins)"
    }
    
    if flameDragonPurchased == true {
      println("flame dragon purchased")
      lockFlame.hidden = true
      flameCostLabel.hidden = true
    } else {
    }
    
    if laserBallDragonPurchased == true {
      lockLaserBall.hidden = true
      laserBallCostLabel.hidden = true
    } else {
    }
    
    if laserBeamDragonPurchased == true {
      lockLaserBeam.hidden = true
      laserBeamCostLabel.hidden = true
    } else {
    }
    
//    self.cameraManager.showAccessPermissionPopupAutomatically = false
    
//    self.askForPermissionsButton.hidden = true
//    self.askForPermissionsLabel.hidden = true
    
//    let currentCameraState = self.cameraManager.currentCameraStatus()
//    
//    if currentCameraState == .NotDetermined {
//      self.askForPermissionsButton.hidden = false
//      self.askForPermissionsLabel.hidden = false
//    } else if (currentCameraState == .Ready) {
//      self.addCameraToView()
//    }
//    if !self.cameraManager.hasFlash {
//      self.flashModeButton.enabled = false
//      self.flashModeButton.setTitle("No flash", forState: UIControlState.Normal)
//    }
//    self.cameraView.frame = CGRect(x: 25, y: 25, width: self.view.frame.width - 50, height: self.view.frame.height - 50)
//    self.cameraButton.frame = CGRect(x: cameraView.frame.width/2 - 50, y: cameraView.frame.height-75, width: 100, height: 50)
//    self.cameraButton.setTitle("Take Picture", forState: .Normal)
//    self.cameraButton.backgroundColor = UIColor.blueColor()
//    let takePicture = UITapGestureRecognizer(target: self, action: "recordButtonTapped")
//    self.cameraButton.addGestureRecognizer(takePicture)
  }
  
  override func viewWillAppear(animated: Bool) {
    tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "StartMenuViewController")
    
    var builder = GAIDictionaryBuilder.createScreenView()
    tracker.send(builder.build() as [NSObject : AnyObject])
  }
  
  override func viewDidAppear(animated: Bool) {
    fireballImage.hidden = false
    flameImage.hidden = true
    laserBallImage.hidden = true
    laserImage.hidden = true
    activityIndicator.hidden = true
    
//    birthdayPickerLabel.text = "Change Mode"
//    birthdayPickerLabel.font = UIFont(name: "MarkerFelt-Thin", size: 25)
//    birthdayPickerLabel.textColor = UIColor.blueColor()
//    birthdayPickerLabel.textAlignment = .Center
//    birthdayPickerLabel.numberOfLines = 5
//    birthdayPickerLabel.frame = CGRectMake(200, 0, self.view.frame.width, 50)
//    birthdayPicker.setTitle("", forState: .Normal)
//    birthdayPicker.setTitleColor(UIColor.redColor(), forState: .Normal)
//    birthdayPicker.frame = CGRectMake(200, 0, self.view.frame.width, 50)
//    birthdayPicker.addTarget(self, action: "birthdayPickerPressed:", forControlEvents: .TouchUpInside)
//    self.view.addSubview(birthdayPickerLabel)
//    self.view.addSubview(birthdayPicker)
  }
  
//  func birthdayPickerPressed(sender: UIButton!) {
//    if birthdayMode {
//      birthdayMode = false
//      birthdayPickerLabel.text = "Change Mode"
//      dragonDestinyTitle.text = "Dragon Destiny"
//      birthdayModeContainer.removeFromSuperview()
//      playerImage.removeFromSuperview()
//    } else {
//      birthdayMode = true
//      birthdayPickerLabel.text = "Change Mode"
//      dragonDestinyTitle.text = "Birthday Destiny"
//
//      birthdayModeContainer.frame = CGRect(x: blueButton.frame.origin.x, y: blueButton.frame.origin.y, width: yellowButton.frame.origin.x + yellowButton.frame.width - blueButton.frame.origin.x, height: blueButton.frame.height)
//      birthdayModeContainer.backgroundColor = UIColor.whiteColor()
//      self.view.addSubview(birthdayModeContainer)
//
//      playerImage.frame = CGRect(x: birthdayModeContainer.frame.width/2 - 35, y: 10, width: 70, height: 70)
//      playerImage.image = UIImage(named: "ShieldActive")
//      
//      playerImage.userInteractionEnabled = true
//      let touchImage = UITapGestureRecognizer(target: self, action: "pickImage")
//      playerImage.addGestureRecognizer(touchImage)
//
//      self.birthdayModeContainer.addSubview(playerImage)
//    }
//  }
  
//  func pickImage() {
//    self.view.addSubview(self.cameraView)
//    self.cameraView.addSubview(self.cameraButton)
//    cameraManager.cameraOutputMode = .StillImage
//    cameraManager.flashMode = .Off
//    cameraManager.writeFilesToPhoneLibrary = true
//    cameraManager.cameraDevice = .Front
//    cameraManager.cameraOutputQuality = .Low
  
//    imagePicker.allowsEditing = false
////    if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
//      imagePicker.sourceType = .Camera
//      imagePicker.cameraCaptureMode = .Photo
////    } else {
////      imagePicker.sourceType = .PhotoLibrary
//      imagePicker.modalPresentationStyle = UIModalPresentationStyle.FormSheet
////      let alertController = UIAlertController(title: "No Camera Available", message:
////        "There is no camera available!", preferredStyle: UIAlertControllerStyle.Alert)
////      alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
////      self.presentViewController(alertController, animated: true, completion: nil)
////    }
//    presentViewController(imagePicker, animated: true, completion: nil)
//  }
  
//    private func addCameraToView() {
//      self.cameraManager.addPreviewLayerToView(self.cameraView, newCameraOutputMode: CameraOutputMode.VideoWithMic)
//      CameraManager.sharedInstance.showErrorBlock = { (erTitle: String, erMessage: String) -> Void in
  
        //            var alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .Alert)
        //            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alertAction) -> Void in
        //                //
        //            }))
        //
        //            let topController = UIApplication.sharedApplication().keyWindow?.rootViewController
        //
        //            if (topController != nil) {
        //                topController?.presentViewController(alertController, animated: true, completion: { () -> Void in
        //                    //
        //                })
        //            }
//      }
//    }
//  
//  @IBAction func changeFlashMode(sender: UIButton)
//  {
  
    
//    switch (self.cameraManager.changeFlashMode()) {
//    case .Off:
//      sender.setTitle("Flash Off", forState: UIControlState.Normal)
//    case .On:
//      sender.setTitle("Flash On", forState: UIControlState.Normal)
//    case .Auto:
//      sender.setTitle("Flash Auto", forState: UIControlState.Normal)
//    }
//  }
//  
//  func recordButtonTapped()
//  {
//    println("tapped record button")
//    switch (self.cameraManager.cameraOutputMode) {
//    case .StillImage:
//      self.cameraManager.capturePictureWithCompletition({ (image, error) -> Void in
//        let vc: ImageViewController? = self.storyboard?.instantiateViewControllerWithIdentifier("ImageVC") as? ImageViewController
//        if let validVC: ImageViewController = vc {
//          if let capturedImage = image {
//            validVC.image = capturedImage
//            println("got here")
//        self.playerImage.image = image
//        self.cameraView.removeFromSuperview()
//            self.navigationController?.pushViewController(validVC, animated: true)
//          }
//        }
//      })
//    case .VideoWithMic, .VideoOnly:
//      sender.selected = !sender.selected
//      sender.setTitle(" ", forState: UIControlState.Selected)
//      sender.backgroundColor = sender.selected ? UIColor.redColor() : UIColor.greenColor()
//      if sender.selected {
//        self.cameraManager.startRecordingVideo()
//      } else {
//        self.cameraManager.stopRecordingVideo({ (videoURL, error) -> Void in
//          if let errorOccured = error {
//            self.cameraManager.showErrorBlock(erTitle: "Error occurred", erMessage: errorOccured.localizedDescription)
//          }
//        })
//      }
//    }
//  }
  
//  @IBAction func outputModeButtonTapped(sender: UIButton)
//  {
//    self.cameraManager.cameraOutputMode = self.cameraManager.cameraOutputMode == CameraOutputMode.VideoWithMic ? CameraOutputMode.StillImage : CameraOutputMode.VideoWithMic
//    switch (self.cameraManager.cameraOutputMode) {
//    case .StillImage:
//      self.cameraButton.selected = false
//      self.cameraButton.backgroundColor = UIColor.greenColor()
//      sender.setTitle("Image", forState: UIControlState.Normal)
//    case .VideoWithMic, .VideoOnly:
//      sender.setTitle("Video", forState: UIControlState.Normal)
//    }
//  }
//  
//  @IBAction func changeCameraDevice(sender: UIButton)
//  {
//    self.cameraManager.cameraDevice = self.cameraManager.cameraDevice == CameraDevice.Front ? CameraDevice.Back : CameraDevice.Front
//    switch (self.cameraManager.cameraDevice) {
//    case .Front:
//      sender.setTitle("Front", forState: UIControlState.Normal)
//    case .Back:
//      sender.setTitle("Back", forState: UIControlState.Normal)
//    }
//  }
//  
//  @IBAction func askForCameraPermissions(sender: UIButton)
//  {
//    self.cameraManager.askUserForCameraPermissions({ permissionGranted in
////      self.askForPermissionsButton.hidden = true
////      self.askForPermissionsLabel.hidden = true
////      self.askForPermissionsButton.alpha = 0
////      self.askForPermissionsLabel.alpha = 0
//      if permissionGranted {
//        self.addCameraToView()
//      }
//    })
//  }
//  
//  @IBAction func changeCameraQuality(sender: UIButton)
//  {
//    switch (self.cameraManager.changeQualityMode()) {
//    case .High:
//      sender.setTitle("High", forState: UIControlState.Normal)
//    case .Low:
//      sender.setTitle("Low", forState: UIControlState.Normal)
//    case .Medium:
//      sender.setTitle("Medium", forState: UIControlState.Normal)
//    }
//  }
//
//
//  
//  // MARK: - UIImagePickerControllerDelegate Methods
//  
//  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
//    if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
//      UIImageWriteToSavedPhotosAlbum(pickedImage, nil, nil, nil) //Saves image to camera roll
//      
//      let imageSize = CGSize(width: 100, height: 100)
//      
////      var imagePicked = Toucan(image: pickedImage).resize(imageSize, fitMode: Toucan.Resize.FitMode.Crop).maskWithRoundedRect(cornerRadius: 5).image
//      
//      playerImage.image = pickedImage
//      playerImage.contentMode = .ScaleAspectFit
//    }
//    
//    dismissViewControllerAnimated(true, completion: nil)
//  }
//  
//  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
//    dismissViewControllerAnimated(true, completion: nil)
//  }

  @IBAction func dragonSelectionButtonPressed(sender: UIButton) {
//    dragonSelected = sender.tag
//    sender.highlighted = true
//    previouslySelectedDragon?.highlighted = false
//    previouslySelectedDragon = sender
    
    switch sender.tag {
    case 0:
      dragonSelected = 0
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
          if enoughCoins < flameDragonCost {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
          } else if enoughCoins >= flameDragonCost {
            let purchaseDragonAlert = UIAlertController(title: "Purchase Flame Dragon", message: "Spend 200 coins to unlock flame dragon?", preferredStyle: UIAlertControllerStyle.Alert)
            
            purchaseDragonAlert.addAction(UIAlertAction(title: "YES!", style: .Default, handler: { (action: UIAlertAction!) in
              self.flameDragonPurchased = true
              self.fireballImage.hidden = true
              self.flameImage.hidden = false
              self.lockFlame.removeFromSuperview()
              self.dragonSelected = 1
              NSUserDefaults.standardUserDefaults().setObject(true,forKey:"flameDragonPurchased")
              
              self.totalCoins! -= self.flameDragonCost
              self.totalCoinsLabel.text = "Total Coins: \(self.totalCoins!)"
              NSUserDefaults.standardUserDefaults().setObject(self.totalCoins,forKey:"TotalCoins")

              let path = NSBundle.mainBundle().pathForResource("flameVideo", ofType:"mov")
              let url = NSURL.fileURLWithPath(path!)
              self.moviePlayer = MPMoviePlayerController(contentURL: url)
              if let player = self.moviePlayer {
                player.view.frame = CGRect(x: self.view.frame.size.width/10, y: self.view.frame.size.height/10, width: self.view.frame.size.width - 2 * self.view.frame.size.width/10, height: self.view.frame.size.height - 2 * self.view.frame.size.height/10)
                player.scalingMode = MPMovieScalingMode.AspectFit
                player.fullscreen = true
                player.controlStyle = MPMovieControlStyle.None
                player.movieSourceType = MPMovieSourceType.File
                player.repeatMode = MPMovieRepeatMode.None
                player.prepareToPlay()
                player.play()
                
                self.view.addSubview(player.view)
                
                var flameDragonPurchasedEvent = GAIDictionaryBuilder.createEventWithCategory("PermanentUpgradePurchased", action: "dragonPurchased", label: "FlameDragonPurchased", value: self.flameDragonCost).build()
                self.tracker.send(flameDragonPurchasedEvent as [NSObject: AnyObject])
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "doneButtonClick:", name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
              }
            }))
            
            purchaseDragonAlert.addAction(UIAlertAction(title: "I changed my mind", style: .Default, handler: { (action: UIAlertAction!) in
              println("Handle Cancel Logic here")
            }))
            
            presentViewController(purchaseDragonAlert, animated: true, completion: nil)
          }
        } else {
          AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
      }
    case 2:
      if laserBallDragonPurchased == true {
        fireballImage.hidden = true
        flameImage.hidden = true
        laserBallImage.hidden = false
        laserImage.hidden = true
      } else {
        if let enoughCoins = self.totalCoins {
          if enoughCoins < laserBallDragonCost {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
          } else if enoughCoins >= laserBallDragonCost {
            let purchaseDragonAlert = UIAlertController(title: "Purchase Laser Dragon", message: "Spend 600 coins to unlock laser dragon?", preferredStyle: UIAlertControllerStyle.Alert)
            
            purchaseDragonAlert.addAction(UIAlertAction(title: "YES!", style: .Default, handler: { (action: UIAlertAction!) in
              self.laserBallDragonPurchased = true
              self.fireballImage.hidden = true
              self.flameImage.hidden = true
              self.laserBallImage.hidden = false
              self.lockLaserBall.removeFromSuperview()
              self.dragonSelected = 2
              NSUserDefaults.standardUserDefaults().setObject(true,forKey:"laserBallDragonPurchased")
              
              self.totalCoins! -= self.laserBallDragonCost
              self.totalCoinsLabel.text = "Total Coins: \(self.totalCoins!)"
              NSUserDefaults.standardUserDefaults().setObject(self.totalCoins,forKey:"TotalCoins")
              
              let path = NSBundle.mainBundle().pathForResource("laserBallVideo", ofType:"mov")
              let url = NSURL.fileURLWithPath(path!)
              self.moviePlayer = MPMoviePlayerController(contentURL: url)
              if let player = self.moviePlayer {
                player.view.frame = CGRect(x: self.view.frame.size.width/10, y: self.view.frame.size.height/10, width: self.view.frame.size.width - 2 * self.view.frame.size.width/10, height: self.view.frame.size.height - 2 * self.view.frame.size.height/10)
                player.scalingMode = MPMovieScalingMode.AspectFit
                player.fullscreen = true
                player.controlStyle = MPMovieControlStyle.None
                player.movieSourceType = MPMovieSourceType.File
                player.repeatMode = MPMovieRepeatMode.None
                player.prepareToPlay()
                player.play()
                
                self.view.addSubview(player.view)
                
                let laserBallDragonPurchasedEvent = GAIDictionaryBuilder.createEventWithCategory("PermanentUpgradePurchased", action: "dragonPurchased", label: "LaserBallDragonPurchased", value: self.laserBallDragonCost)
                self.tracker.send(laserBallDragonPurchasedEvent.build() as [NSObject: AnyObject])
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "doneButtonClick:", name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
              }
            }))
            
            purchaseDragonAlert.addAction(UIAlertAction(title: "I changed my mind", style: .Default, handler: { (action: UIAlertAction!) in
              println("Handle Cancel Logic here")
            }))
            
            presentViewController(purchaseDragonAlert, animated: true, completion: nil)
          }
        }
      }
    case 3:
      if laserBeamDragonPurchased == true {
        fireballImage.hidden = true
        flameImage.hidden = true
        laserBallImage.hidden = true
        laserImage.hidden = false
      } else {
        if let enoughCoins = self.totalCoins {
          if enoughCoins < laserBeamDragonCost {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
          } else if enoughCoins >= laserBeamDragonCost {
            let purchaseDragonAlert = UIAlertController(title: "Purchase Laser Beam Dragon", message: "Spend 1,200 coins to unlock laser beam dragon?", preferredStyle: UIAlertControllerStyle.Alert)
            
            purchaseDragonAlert.addAction(UIAlertAction(title: "YES!", style: .Default, handler: { (action: UIAlertAction!) in
              self.laserBeamDragonPurchased = true
              self.fireballImage.hidden = true
              self.flameImage.hidden = true
              self.laserBallImage.hidden = true
              self.laserImage.hidden = false
              self.lockLaserBeam.removeFromSuperview()
              self.dragonSelected = 3
              NSUserDefaults.standardUserDefaults().setObject(true,forKey:"laserBeamDragonPurchased")
              
              self.totalCoins! -= self.laserBeamDragonCost
              self.totalCoinsLabel.text = "Total Coins: \(self.totalCoins!)"
              NSUserDefaults.standardUserDefaults().setObject(self.totalCoins,forKey:"TotalCoins")
              
              let path = NSBundle.mainBundle().pathForResource("laserBeamVideo", ofType:"mov")
              let url = NSURL.fileURLWithPath(path!)
              self.moviePlayer = MPMoviePlayerController(contentURL: url)
              if let player = self.moviePlayer {
                player.view.frame = CGRect(x: self.view.frame.size.width/10, y: self.view.frame.size.height/10, width: self.view.frame.size.width - 2 * self.view.frame.size.width/10, height: self.view.frame.size.height - 2 * self.view.frame.size.height/10)
                player.scalingMode = MPMovieScalingMode.AspectFit
                player.fullscreen = true
                player.controlStyle = MPMovieControlStyle.None
                player.movieSourceType = MPMovieSourceType.File
                player.repeatMode = MPMovieRepeatMode.None
                player.prepareToPlay()
                player.play()
                
                self.view.addSubview(player.view)
                
                var laserBeamDragonPurchasedEvent = GAIDictionaryBuilder.createEventWithCategory("PermanentUpgradePurchased", action: "dragonPurchased", label: "LaserBeamDragonPurchased", value: self.laserBeamDragonCost)
                self.tracker.send(laserBeamDragonPurchasedEvent.build() as [NSObject: AnyObject])
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "doneButtonClick:", name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
              }
            }))
            
            purchaseDragonAlert.addAction(UIAlertAction(title: "I changed my mind", style: .Default, handler: { (action: UIAlertAction!) in
              println("Handle Cancel Logic here")
            }))
            
            presentViewController(purchaseDragonAlert, animated: true, completion: nil)
          }
        }
      }
    default:
      fireballImage.hidden = false
      flameImage.hidden = true
      laserBallImage.hidden = true
      laserImage.hidden = true
    }
  }
  
  func doneButtonClick(sender:NSNotification?){
    let value = UIInterfaceOrientation.Portrait.rawValue
    UIDevice.currentDevice().setValue(value, forKey: "orientation")
    self.moviePlayer.stop()
    self.moviePlayer.view.removeFromSuperview()
  }
  
  @IBAction func playArcadeButtonPushed(sender: UIButton) {
//    let reveal = SKTransition.flipHorizontalWithDuration(0.5)
//    let scene = GameScene(size: self.view.frame.size)
    
    activityIndicator.hidden = false
    activityIndicator.startAnimating()
    
    let gameViewController = self.storyboard!.instantiateViewControllerWithIdentifier("GameViewController") as! GameViewController
    
    gameViewController.dragonType = dragonSelected
    gameViewController.birthdayMode = self.birthdayMode
//    gameViewController.birthdayImage = self.playerImage
    
    self.navigationController!.pushViewController(gameViewController, animated: true)
    
//    self.presentViewController(gameViewController, animated: false, completion: nil)
  }
}

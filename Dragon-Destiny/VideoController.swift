//
//  VideoController.swift
//  Dragon-Destiny
//
//  Created by Daniel Liebeskind on 9/15/15.
//  Copyright (c) 2015 Cybenex LLC. All rights reserved.
//

import AVFoundation

class VideoController: UIViewController {
  var tutorialVideoPlayer: AVPlayer!
  
  func playTutorialVideo(filename: String) -> AVPlayer {
    let url = NSBundle.mainBundle().URLForResource(
      filename, withExtension: nil)
    if (url == nil) {
      println("Could not find file: \(filename)")
      return AVPlayer()
    }
    
    var error: NSError? = nil
    tutorialVideoPlayer =
      AVPlayer(URL: url)
    if tutorialVideoPlayer == nil {
      println("Could not create audio player: \(error!)")
      return AVPlayer()
    }
    
    tutorialVideoPlayer.volume = 0.8
//    tutorialVideoPlayer.play()
  
    return tutorialVideoPlayer
  }
}

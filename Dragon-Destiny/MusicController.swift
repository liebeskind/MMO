//
//  MusicController.swift
//  Dragon-Destiny
//
//  Created by Daniel Liebeskind on 8/12/15.
//  Copyright (c) 2015 Cybenex LLC. All rights reserved.
//

import AVFoundation

class MusicController: UIViewController {
  var backgroundMusicPlayer: AVAudioPlayer!
  var soundEffectPlayer: AVAudioPlayer!
  var upgradeMusicPlayer: AVAudioPlayer!

  func playBackgroundMusic(filename: String) {
    let url = NSBundle.mainBundle().URLForResource(
      filename, withExtension: nil)
    if (url == nil) {
      println("Could not find file: \(filename)")
      return
    }
    
    var error: NSError? = nil
    backgroundMusicPlayer =
      AVAudioPlayer(contentsOfURL: url, error: &error)
    if backgroundMusicPlayer == nil {
      println("Could not create audio player: \(error!)")
      return
    }
    
    backgroundMusicPlayer.volume = 0.8
    backgroundMusicPlayer.numberOfLoops = -1
    backgroundMusicPlayer.prepareToPlay()
    backgroundMusicPlayer.play()
  }

  @objc func pauseBackgroundMusic() {
    if backgroundMusicPlayer.volume > 0 {
      backgroundMusicPlayer.volume -= 0.05
//      self.performSelector("reduceBackgroundMusicVolume", withObject: nil, afterDelay: 0.1)
      NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("pauseBackgroundMusic"), userInfo: nil, repeats: false)
      
    } else {
      backgroundMusicPlayer.pause()
    }
  }

  func stopBackgroundMusic() {
    backgroundMusicPlayer.pause()
  }

  func resumeBackgroundMusic() {
    backgroundMusicPlayer.volume = 0.8
    backgroundMusicPlayer.play()
  }

  func playUpgradeMusic(filename: String) {
    let url = NSBundle.mainBundle().URLForResource(
      filename, withExtension: nil)
    if (url == nil) {
      println("Could not find file: \(filename)")
      return
    }
    
    var error: NSError? = nil
    upgradeMusicPlayer =
      AVAudioPlayer(contentsOfURL: url, error: &error)
    if upgradeMusicPlayer == nil {
      println("Could not create audio player: \(error!)")
      return
    }
    
    upgradeMusicPlayer.volume = 0.9
    upgradeMusicPlayer.numberOfLoops = 0
    upgradeMusicPlayer.prepareToPlay()
    upgradeMusicPlayer.play()
  }

  func stopUpgradeMusic() {
    if upgradeMusicPlayer != nil {
      upgradeMusicPlayer.stop()
    }
  }

  func playSoundEffect(filename: String) {
    let url = NSBundle.mainBundle().URLForResource(
      filename, withExtension: nil)
    if (url == nil) {
      println("Could not find file: \(filename)")
      return
    }
    
    var error: NSError? = nil
    soundEffectPlayer =
      AVAudioPlayer(contentsOfURL: url, error: &error)
    if soundEffectPlayer == nil {
      println("Could not create audio player: \(error!)")
      return
    }
    
    soundEffectPlayer.volume = 0.5
    soundEffectPlayer.numberOfLoops = 0
    soundEffectPlayer.prepareToPlay()
    soundEffectPlayer.play()
  }
  
  func loadSoundEffect(filename: String) {
    let url = NSBundle.mainBundle().URLForResource(
      filename, withExtension: nil)
    if (url == nil) {
      println("Could not find file: \(filename)")
      return
    }
    
    var error: NSError? = nil
    soundEffectPlayer =
      AVAudioPlayer(contentsOfURL: url, error: &error)
    if soundEffectPlayer == nil {
      println("Could not create audio player: \(error!)")
      return
    }
  }
}
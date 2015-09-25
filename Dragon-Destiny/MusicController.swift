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

  var backgroundVolume = Float(0.8)
  var upgradeVolume = Float(0.9)
  var soundEffectVolume = Float(0.5)

  func muteAllSound() {
    self.backgroundVolume = Float(0.0)
    self.upgradeVolume = Float(0.0)
    self.soundEffectVolume = Float(0.0)
  }
  
  func unMuteAllSound() {
    self.backgroundVolume = Float(0.8)
    self.upgradeVolume = Float(0.9)
    self.soundEffectVolume = Float(0.5)
  }
  
  func playBackgroundMusic(filename: String) {
    backgroundMusicPlayer = nil
    let url = NSBundle.mainBundle().URLForResource(
      filename, withExtension: nil)
    if (url == nil) {
      print("Could not find file: \(filename)")
      return
    }
    
    var error: NSError? = nil
    do {
      backgroundMusicPlayer =
        try AVAudioPlayer(contentsOfURL: url!)
    } catch let error1 as NSError {
      error = error1
      backgroundMusicPlayer = nil
    }
    if backgroundMusicPlayer == nil {
      print("Could not create audio player: \(error!)")
      return
    }
    
    if backgroundMusicPlayer.playing { return }
    
    backgroundMusicPlayer.volume = 0.8
    backgroundMusicPlayer.numberOfLoops = -1
    backgroundMusicPlayer.prepareToPlay()
    backgroundMusicPlayer.play()
  }

  @objc func pauseBackgroundMusic() {
    if backgroundMusicPlayer != nil {
      if backgroundMusicPlayer.volume > 0 {
        backgroundMusicPlayer.volume -= 0.05
  //      self.performSelector("reduceBackgroundMusicVolume", withObject: nil, afterDelay: 0.1)
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("pauseBackgroundMusic"), userInfo: nil, repeats: false)
        
      } else {
        backgroundMusicPlayer.pause()
      }
    }
  }

  func stopBackgroundMusic() {
    if backgroundMusicPlayer != nil {
      backgroundMusicPlayer.pause()
    }
  }

  func resumeBackgroundMusic() {
    if let upgradeMusic = upgradeMusicPlayer {
      if upgradeMusic.playing { return }
    }
    
    if backgroundMusicPlayer.playing { return }
    if backgroundMusicPlayer == nil {
      playBackgroundMusic("epicMusic.mp3")
    } else {
      backgroundMusicPlayer.volume = self.backgroundVolume
      backgroundMusicPlayer.play()
    }
  }

  func playUpgradeMusic(filename: String) {
    let url = NSBundle.mainBundle().URLForResource(
      filename, withExtension: nil)
    if (url == nil) {
      print("Could not find file: \(filename)")
      return
    }
    
    var error: NSError? = nil
    do {
      upgradeMusicPlayer =
        try AVAudioPlayer(contentsOfURL: url!)
    } catch let error1 as NSError {
      error = error1
      upgradeMusicPlayer = nil
    }
    if upgradeMusicPlayer == nil {
      print("Could not create audio player: \(error!)")
      return
    }
    
    if upgradeMusicPlayer.playing { return }
    
    upgradeMusicPlayer.volume = self.upgradeVolume
    upgradeMusicPlayer.numberOfLoops = 0
    upgradeMusicPlayer.prepareToPlay()
    upgradeMusicPlayer.play()
  }

  func pauseUpgradeMusic() {
    if upgradeMusicPlayer != nil {
      upgradeMusicPlayer.pause()
    }
  }
  
  func resumeUpgradeMusic() {
    if let upgradeMusic = upgradeMusicPlayer {
      if upgradeMusic.playing { return }
    }
    
    if upgradeMusicPlayer != nil {
      upgradeMusicPlayer.volume = self.upgradeVolume
      upgradeMusicPlayer.play()
    }
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
      print("Could not find file: \(filename)")
      return
    }
    
    var error: NSError? = nil
    do {
      soundEffectPlayer =
        try AVAudioPlayer(contentsOfURL: url!)
    } catch let error1 as NSError {
      error = error1
      soundEffectPlayer = nil
    }
    if soundEffectPlayer == nil {
      print("Could not create audio player: \(error!)")
      return
    }
    
    soundEffectPlayer.volume = self.soundEffectVolume
    soundEffectPlayer.numberOfLoops = 0
    soundEffectPlayer.prepareToPlay()
    soundEffectPlayer.play()
  }
  
  func loadSoundEffect(filename: String) {
    let url = NSBundle.mainBundle().URLForResource(
      filename, withExtension: nil)
    if (url == nil) {
      print("Could not find file: \(filename)")
      return
    }
    
    var error: NSError? = nil
    do {
      soundEffectPlayer =
        try AVAudioPlayer(contentsOfURL: url!)
    } catch let error1 as NSError {
      error = error1
      soundEffectPlayer = nil
    }
    if soundEffectPlayer == nil {
      print("Could not create audio player: \(error!)")
      return
    }
  }
}
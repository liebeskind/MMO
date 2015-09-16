//
//  ImageViewController.swift
//  Dragon-Destiny
//
//  Created by Daniel Liebeskind on 9/16/15.
//  Copyright (c) 2015 Cybenex LLC. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
  
  var image: UIImage?
  @IBOutlet weak var imageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.hidden = false
    
    if let validImage = self.image {
      self.imageView.image = validImage
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}

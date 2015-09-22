//
//  InAppPurchaseViewController.swift
//  Dragon Heroes
//
//  Created by Daniel Liebeskind on 8/12/15.
//  Copyright (c) 2015 Cybenex LLC. All rights reserved.
//

import StoreKit

class InAppPurchaseViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
  let defaults = NSUserDefaults.standardUserDefaults()
  
  var product_id: NSString?;
  
  override func viewDidLoad() {
    super.viewDidLoad()
    product_id = "eliminateAds";
    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    
    //Check if product is purchased
    if (defaults.boolForKey("eliminateAdsPurchased")){
      // Hide a view or show content depends on your requirement
//      overlayView.hidden = true
    }
    else if (!defaults.boolForKey("stonerPurchased")){
      println("false")
    }
  }
  
  @IBAction func unlockAction(sender: AnyObject) {
    println("About to fetch the products")
    
    if (SKPaymentQueue.canMakePayments())
    {
      var productID:NSSet = NSSet(object: self.product_id!);
      var productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as Set<NSObject>)
      productsRequest.delegate = self;
      productsRequest.start();
      println("Fetching Products");
    }else{
      println("can't make purchases");
    }
  }
  
  func buyProduct(product: SKProduct){
    println("Sending the Payment Request to Apple");
    var payment = SKPayment(product: product)
    SKPaymentQueue.defaultQueue().addPayment(payment);
    
  }
  
  func productsRequest (request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
    
    var count : Int = response.products.count
    if (count>0) {
      var validProducts = response.products
      var validProduct: SKProduct = response.products[0] as! SKProduct
      if (validProduct.productIdentifier == self.product_id) {
        println(validProduct.localizedTitle)
        println(validProduct.localizedDescription)
        println(validProduct.price)
        buyProduct(validProduct);
      } else {
        println(validProduct.productIdentifier)
      }
    } else {
      println("nothing")
    }
  }
  
  //IAP Delegates
  func request(request: SKRequest!, didFailWithError error: NSError!) {
    println("Error Fetching product information");
  }
  
  func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!)    {
    println("Received Payment Transaction Response from Apple");
    
    for transaction:AnyObject in transactions {
      if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
        switch trans.transactionState {
        case .Purchased:
          println("Product Purchased");
          SKPaymentQueue.defaultQueue().finishTransaction(transaction as? SKPaymentTransaction)
          defaults.setBool(true , forKey: "eliminateAdsPurchased")
//          overlayView.hidden = true
          break;
        case .Failed:
          println("Purchased Failed");
          SKPaymentQueue.defaultQueue().finishTransaction(transaction as? SKPaymentTransaction)
          break;
        case .Restored:
          println("Already Purchased");
          SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        default: break
        }
      }
    }
  }
}



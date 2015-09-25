//
//  InAppPurchaseViewController.swift
//  Dragon Heroes
//
//  Created by Daniel Liebeskind on 8/12/15.
//  Copyright (c) 2015 Cybenex LLC. All rights reserved.
//

import StoreKit

//class InAppPurchaseViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
//  let defaults = NSUserDefaults.standardUserDefaults()
//  
//  var product_id = "eliminateAds"
//  
//  override func viewDidLoad() {
//    super.viewDidLoad()
//    product_id = "eliminateAds";
//    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
//    
//    //Check if product is purchased
//    if (defaults.boolForKey("eliminateAdsPurchased")){
//      // Hide a view or show content depends on your requirement
////      overlayView.hidden = true
//    }
//    else if (!defaults.boolForKey("stonerPurchased")){
//      print("false")
//    }
//  }
//  
//  func eliminateAdsPurchase() {
//    print("About to fetch the products")
//    
//    if (SKPaymentQueue.canMakePayments())
//    {
//      let productID:NSSet = NSSet(object: self.product_id);
//      let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as Set<NSObject>)
//      productsRequest.delegate = self;
//      productsRequest.start();
//      print("Fetching Products");
//    }else{
//      print("can't make purchases");
//    }
//  }
//  
//  func buyProduct(product: SKProduct){
//    print("Sending the Payment Request to Apple");
//    let payment = SKPayment(product: product)
//    SKPaymentQueue.defaultQueue().addPayment(payment);
//    
//  }
//  
//  func productsRequest (request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
//    
//    let count : Int = response.products.count
//    if (count>0) {
////      let validProducts = response.products
//      let validProduct: SKProduct = response.products[0]
//      if (validProduct.productIdentifier == self.product_id) {
//        print(validProduct.localizedTitle)
//        print(validProduct.localizedDescription)
//        print(validProduct.price)
//        buyProduct(validProduct);
//      } else {
//        print(validProduct.productIdentifier)
//      }
//    } else {
//      print("nothing")
//    }
//  }
//  
//  //IAP Delegates
//  func request(request: SKRequest, didFailWithError error: NSError) {
//    print("Error Fetching product information");
//  }
//  
//  func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])    {
//    print("Received Payment Transaction Response from Apple");
//    
//    for transaction:AnyObject in transactions {
//      if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
//        switch trans.transactionState {
//        case .Purchased:
//          print("Product Purchased");
//          SKPaymentQueue.defaultQueue().finishTransaction(transaction as SKPaymentTransaction)
//          defaults.setBool(true , forKey: "eliminateAdsPurchased")
////          overlayView.hidden = true
//          break;
//        case .Failed:
//          print("Purchased Failed");
//          SKPaymentQueue.defaultQueue().finishTransaction(transaction as SKPaymentTransaction)
//          break;
//        case .Restored:
//          print("Already Purchased");
//          SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
//        default: break
//        }
//      }
//    }
//  }
//}



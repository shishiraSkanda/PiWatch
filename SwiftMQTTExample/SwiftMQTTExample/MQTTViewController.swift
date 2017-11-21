//
//  ViewController.swift
//  PiWatch
//
//  Created by Priyanka Gopakumar on 15/11/2016.
//  Copyright © 2016 Priyanka. All rights reserved.
//

/*
 The controller is used to connect to the host, using the IP address and port number of the raspberry pi.
 The view controller represents the MQTT client on PiWatch application. It subscribes to a particular
 channel. It receives the MQTT push message from the server when a intrusion is detected. On receiveing the 
 message the user is informed using alert or notification. The user is provided with an option to capture a 
 still image during an alert. 
 A log of events are maintained in CoreData.
 Author: Adolfo Martinelli
 Retrieved on: 13/11/2016
 Source: https://github.com/aciidb0mb3r/SwiftMQTT
 */

import UIKit
import SwiftMQTT
import CoreData
import AVFoundation

class MQTTViewController: UIViewController, MQTTSessionDelegate{

    //An instance of MQTTSession
    var mqttSession: MQTTSession!
    
    //The method is used connect to the server and subscribe to the channel
    func callAll()
    {
        self.viewDidLoad()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Establish connection methos is called
        self.establishConnection()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "hideKeyboard")
        self.view.addGestureRecognizer(tapGesture)
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo! as NSDictionary
        let kbHeight = userInfo.objectForKey(UIKeyboardFrameBeginUserInfoKey)?.CGRectValue.size.height
        //self.bottomConstraint.constant = kbHeight!
    }
    
    func keyboardWillHide(notification: NSNotification) {
       // self.bottomConstraint.constant = 0
    }
    
    /*
     This is SwiftMQTT function used to establish an MQTT session with a host. This is done using an MQTTSession function and specifying
     the host IP address, the port number to listen to. Once the connection is established, the user is subscribed to a channel or a topic.
     */
    
    func establishConnection() {
        
        //NSNotificationCenter.defaultCenter().postNotificationName("start", object: nil)
        let host = "118.139.52.237"
        let port:UInt16 = 1883
        let clientID = self.clientID()
        
        mqttSession = MQTTSession(host: host, port: port, clientID: clientID, cleanSession: true, keepAlive: 15, useSSL: false)
        mqttSession.delegate = self
        
        self.appendStringToTextView("Trying to connect to \(host) on port \(port) for clientID \(clientID)")
        mqttSession.connect {
            if !$0 {
                self.appendStringToTextView("Error Occurred During connection \($1)")
                self.notifyUser("Server Error", message: "Failed to connect to server")
               // NSNotificationCenter.defaultCenter().postNotificationName("stop", object: nil)
                return
            }
            self.appendStringToTextView("Connected.")
            self.subscribeToChannel()
        }
    }
    
    /*
     The user is subscribed to a topic using this SwiftMQTT function called subscribe. Here, we have subscribed to a channel
     called testTopic which is the name specified in the server code.
    */
    func subscribeToChannel() {
        let subChannel = "testTopic"
        mqttSession.subscribe(subChannel, qos: MQTTQoS.AtLeastOnce) {
            if !$0 {
                self.appendStringToTextView("Error Occurred During subscription \($1)")
                self.notifyUser("Server Error", message: "Failed to switch on notification")
                return
            }
            self.appendStringToTextView("Subscribed to \(subChannel)")
        }
        
       // NSNotificationCenter.defaultCenter().postNotificationName("stop", object: nil)
    }
    
    /*
     Should the user choose to not receive notifications from the server, the user can unsubsribe to the channel. To unsubscribe,
     this function is called.
    */
    func unSubscribeToChannel() {
        //let subChannel = "/#"
        let subChannel = "testTopic"
        mqttSession.unSubscribe(subChannel){
            if !$0 {
                self.appendStringToTextView("Error Occurred During unsubscription \($1)")
                self.notifyUser("Server Error", message: "Failed to switch off notification")
                return
            }
            self.appendStringToTextView("Unsubscribed to \(subChannel)")
        }
   }
    
    func appendStringToTextView(string: String) {
      //  self.textView.text = "\(self.textView.text)\n\(string)"
    }
    
    
    /*
     This function is automatically invoked when the user receives a push notification or message from the server on a given topic.
     We use this function to determine is an intrusion has occured which has caused the push message to be received. 
     The notifyUser() method is called to pop an alert or a notification regarding the intrusion.
    */
    func mqttSession(session: MQTTSession, didReceiveMessage message: NSData, onTopic topic: String) {
        let stringData = NSString(data: message, encoding: NSUTF8StringEncoding) as! String
        self.appendStringToTextView("data received on topic \(topic) message \(stringData)")
        print("Printing message \(stringData)")
        notifyUser("Alert", message: "Intrusion detected. View disturbance in live stream.")
    }
    
    /*
     User-defined function that is invoked when a message is received from the MQTT server. The user is presented with an option 
     to take a snapshot when the alert is presented to him/her. In case the application is inactive, the user is given a notification 
     regarding the intrusion.
    */
    func notifyUser(title: String, message: String)
    {
        if UIApplication.sharedApplication().applicationState == .Active {
            
            // App is active, show an alert
            
            let intruderAlert = UIAlertController(title: "Intrusion Detected", message: "Would you like to take a snapshot?", preferredStyle: UIAlertControllerStyle.Alert)
            
            intruderAlert.addAction(UIAlertAction(title: "Confirm", style: .Default, handler: { (action: UIAlertAction!) in
                
                let popVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("captureImageView") as! NewEventDetailsViewController
        
                /*
                  The following 4 lines of code ensure that no matter which screen the user is on, the user is presented with 
                 a pop-up showing the image or snapshot captured at the location if the user chooses to take a snapshot
                 when the instrusion alert is presented to him/her.
                 */
                
            UIApplication.sharedApplication().keyWindow?.rootViewController?.addChildViewController(popVC)
                //self.addChildViewController(popVC)
                popVC.view.frame = (UIApplication.sharedApplication().keyWindow?.rootViewController!.view.frame)!
                UIApplication.sharedApplication().keyWindow?.rootViewController?.view.addSubview(popVC.view)
                popVC.didMoveToParentViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
                //popVC.didMoveToParentViewController(self)

                // go to details view
                // self.performSegueWithIdentifier("showNewEventDetails", sender: self)
                
            }))
            
            intruderAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
                print("Capture cancelled")
                self.addToHistory()
            }))
            
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(intruderAlert, animated: true, completion: nil)
            //presentViewController(intruderAlert, animated: true, completion: nil)

        }
        else
        {
            // App is inactive, show a notification
            let notification = UILocalNotification()
            if #available(iOS 8.2, *) {
                notification.alertTitle = title
            } else {
                // Fallback on earlier versions
            }
            notification.alertBody = message
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }
    
    func socketErrorOccurred(session: MQTTSession) {
        self.appendStringToTextView("Socket Error")
    }
    
    func didDisconnectSession(session: MQTTSession) {
        self.appendStringToTextView("Session Disconnected.")
    }
    
    /*
     Generates a random client ID using which the connection to the server is established.
    */
    func clientID() -> String {

        let userDefaults = NSUserDefaults.standardUserDefaults()
        let clientIDPersistenceKey = "clientID"
        
        var clientID = ""
        
        if let savedClientID = userDefaults.objectForKey(clientIDPersistenceKey) as? String {
            clientID = savedClientID
        } else {
            clientID = self.randomStringWithLength(5)
            userDefaults.setObject(clientID, forKey: clientIDPersistenceKey)
            userDefaults.synchronize()
        }
        
        return clientID
    }
    
    /*
    SOURCE: http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
    */
    func randomStringWithLength(len: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString : NSMutableString = NSMutableString(capacity: len)
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        return String(randomString)
    }
    
    /*
     For every notification that is received from the server, the event details are added to the Core Data.
     The entity Event is assigned a data, time and an optional image path.
    */
    func addToHistory()
    {
        let newEvent: Event = (NSEntityDescription.insertNewObjectForEntityForName("Event",
            inManagedObjectContext: LiveFeedViewController.managedObjectContext!) as? Event)!
        print("adding to history")
        newEvent.date = NSDate()
        newEvent.imagePath = LiveFeedViewController.imagePath

        do
        {
            try LiveFeedViewController.managedObjectContext!.save()
            NSNotificationCenter.defaultCenter().postNotificationName("load", object: nil)
        }
        catch let error
        {
            print("Could not add to table \(error)")
        }
        LiveFeedViewController.imagePath = "nil"
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showNewEventDetails")
        {
            let destinationVC = segue.destinationViewController as! NewEventDetailsViewController
        }

    }
}

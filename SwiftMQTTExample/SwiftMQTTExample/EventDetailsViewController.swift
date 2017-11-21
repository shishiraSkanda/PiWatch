//
//  EventDetailsViewController.swift
//  PiWatch
//
//  Created by Priyanka Gopakumar on 15/11/2016.
//  Copyright © 2016 Priyanka. All rights reserved.
//

/*
 The application allows the user to click on an event from the History table and view an image and date and time
 associated with the event. If no image was captured, a default image is shown.
*/
import UIKit

class EventDetailsViewController: UIViewController {

    var currentEvent: Event?
    
    // UI components
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var dateTimeLabel: UILabel!
    
    // creating a view to display a progress spinner while data is being loaded from the server
    var progressView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // setting up the progress view
        setProgressView()
        
        if Reachability.isConnectedToNetwork() == true      // if data network exists then download the JSON article
        {
            print("Internet connection OK")
            print("Current event image path \(self.currentEvent!.imagePath)")
            
            // if an image path exists then load the image from the server
            if (self.currentEvent?.imagePath != "nil")
            {
                self.view.addSubview(self.progressView) // start showing the progress view
                downloadImageFromLink()                
            }
            
        }
        else        // if data network isn't available show an alert
        {
            print("Internet connection FAILED")
            let alert = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet to download the image.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        self.dateTimeLabel.text = formatter.stringFromDate(currentEvent!.date!)

    }

    /*
     If an image path is available for the event, the image is downloaded and shown on the image view.
    */
    func downloadImageFromLink()
    {
        let completeImagePath: String = "http://118.139.52.237\(self.currentEvent!.imagePath!)"
        print("Complete image path: \(completeImagePath)")
        let url = NSURL(string: completeImagePath)
        
        let data = NSData(contentsOfURL:url!)
        if (data != nil)    // if image was found on the server
        {
            self.eventImage.image = UIImage(data:data!)
        }
        else    // if image was not found
        {
            displayAlertMessage("Alert", message: "Unable to locate image resource")
        }
        self.stopProgressView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     Setting up the progress view that displays a spinner while the serer data is being downloaded.
     The view uses an activity indicator (a spinner) and a simple text to convey the information.
     Source: YouTube
     Tutorial: Swift - How to Create Loading Bar (Spinners)
     Author: Melih Şimşek
     URL: https://www.youtube.com/watch?v=iPTuhyU5HkI
     */
    func setProgressView()
    {
        // setting the UI specifications
        self.progressView = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 50))
        self.progressView.backgroundColor = UIColor.lightGrayColor()
        self.progressView.layer.cornerRadius = 10
        let wait = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        wait.color = UIColor(red: 254/255, green: 218/255, blue: 2/255, alpha: 1)
        wait.hidesWhenStopped = false
        wait.startAnimating()
        
        let message = UILabel(frame: CGRect(x: 60, y: 0, width: 200, height: 50))
        message.text = "Loading image..."
        message.textColor = UIColor(red: 254/255, green: 218/255, blue: 2/255, alpha: 1)
        
        self.progressView.addSubview(wait)
        self.progressView.addSubview(message)
        self.progressView.center = self.view.center
        self.progressView.tag = 1000
        
    }
    
    /*
     This method is invoked to remove the progress spinner from the view.
     Source: YouTube
     Tutorial: Swift - How to Create Loading Bar (Spinners)
     Author: Melih Şimşek
     URL: https://www.youtube.com/watch?v=iPTuhyU5HkI
     */
    func stopProgressView()
    {
        let subviews = self.view.subviews
        for subview in subviews
        {
            if subview.tag == 1000
            {
                subview.removeFromSuperview()
            }
        }
    }

    /*
     A custom function to display an alert on the screen based on the title and message passed
     */
    func displayAlertMessage(title: String, message: String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(alertAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }


}

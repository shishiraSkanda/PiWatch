//
//  EventDetailsViewController.swift
//  PiWatch
//
//  Created by Priyanka Gopakumar on 15/11/2016.
//  Copyright © 2016 Priyanka. All rights reserved.
//

/*
 The application provides the user with a feature to view a snapshot of the location when an instrusion is detected. This
 screen provides a image and a date-time text to the user as a pop-up no matter which screen he/she is on.
 */
 
import UIKit
import CoreData

class NewEventDetailsViewController: UIViewController {

    // UI components
    @IBOutlet weak var snapshot: UIImageView!
    @IBOutlet weak var dateTimeLabel: UILabel!
    
    
    required init?(coder aDecoder: NSCoder) {
        //img_path = nil
        super.init(coder: aDecoder)
    }
    
    // creating a view to display a progress spinner while data is being loaded from the server
    var progressView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setting up the progress view
        setProgressView()

        if Reachability.isConnectedToNetwork() == true      // if data network exists then download the JSON article
        {
            print("Internet connection OK")
            downloadImageLink()
            self.view.addSubview(self.progressView) // start showing the progress view

        }
        else        // if data network isn't available show an alert
        {
            print("Internet connection FAILED")
            let alert = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }

    }

    /*
     This method makes an HTTP GET request to the Raspberry Pi to take a snapshot and retrieve the path of the snapshot
     from the server. The URL for the request is specified and the response is in JSON format with the image path in a tag
     called "img_path".
    */
    func downloadImageLink()
    {
        var url: NSURL
        
        // N value in the URL refers to the number of records to be downloaded from the server. Since we require only one (the latest) record, we have given N = 1
        url = NSURL(string: "http://118.139.52.237:3000/captureImage")!
        
        //print(url)
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url){
            (data, response, error) in
            if (error != nil)
            {
                print("Error \(error)")
                self.displayAlertMessage("Connection Failed", message: "Failed to retrieve image from the server")
                self.stopProgressView()     // stop the progress spinner view if connection fails
            }
            else
            {
                self.parseJSON(data!)
                
            }
            //self.syncCompleted = true
        }
        task.resume()
    }
    
    
    /*
     This function is invoked after the JSON data is downloaded from the server. The key-value method is used
     to extract all the necessary data. The image path is retrieved from parsing the JSON data.
     */
    func parseJSON(linkJSON:NSData){
        do{
            
            let result = try NSJSONSerialization.JSONObjectWithData(linkJSON, options: NSJSONReadingOptions.MutableContainers)
            
            print("Result : \(result)")
            
            
           LiveFeedViewController.imagePath = result.objectForKey("img_path")! as! String
            print("Image path is \(LiveFeedViewController.imagePath!)")
            
            dispatch_async(dispatch_get_main_queue()) {
                self.downloadImageFromLink()
            }
        }

        catch
        {
            print("JSON Serialization error")
        }
    }

    
    /*
     The image is loaded on the image view from the link sent by the server. The event is then added to history.
    */
    func downloadImageFromLink()
    {
        if (LiveFeedViewController.imagePath != nil || LiveFeedViewController.imagePath != "nil")
        {
            let completeImagePath: String = "http://118.139.52.237\(LiveFeedViewController.imagePath!)"
            let url = NSURL(string: completeImagePath)
            
            let data = NSData(contentsOfURL:url!)
            self.snapshot.image = UIImage(data:data!)
            self.stopProgressView()
        }
        self.addToHistory()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     A function to allow custom alerts to be created by passing a title and a message
     */
    func displayAlertMessage(title: String, message: String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(alertAction)
        self.presentViewController(alertController, animated: true, completion: nil)
        self.stopProgressView()
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

    // pop-up removed from super view when the Done button is clicked
    @IBAction func doneButton(sender: AnyObject) {
        
        self.view.removeFromSuperview()
    }
    
    /*
     This method is used to add the new event to Core Data along with the valid image path.
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


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

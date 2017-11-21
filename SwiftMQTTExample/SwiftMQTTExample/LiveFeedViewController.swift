//
//  LiveFeedViewController.swift
//  PiWatch
//
//  Created by Priyanka Gopakumar on 28/10/2016.
//  Copyright © 2016 Priyanka Gopakumar. All rights reserved.
//

/*
 The application provides a functionality to receive live feeds from the Raspberry Pi camera using an HTTP request.
 The screen provides a web view where the video can be viewed. The user may choose to stop streaming, pause streaming
 or start streaming again. The request is made to the IP address of the Raspberry Pi.
 This is the first screen to be loaded on the application and hence user defined settings are checked first on this screen.
 */
import UIKit
import CoreData

class LiveFeedViewController: UIViewController {
    
    // declaring the attributes
    var liveFeedURL: String = "http://118.139.52.237"
    static var managedObjectContext: NSManagedObjectContext?
    var settingsList: NSMutableArray
    static var settings: Settings?
    static var controller = MQTTViewController()
    static var imagePath: String? = "nil"
    
    // UI elements
    @IBOutlet weak var liveFeedView: UIWebView!
    
    // setting up the progress view
    var progressView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        print("finished load")
        
        // checking settings to determine if notifications must be sent
        checkSettings()
        
        if(LiveFeedViewController.settings?.notification == true)
        {
            
            //controller = MQTTViewController()
            LiveFeedViewController.controller.callAll()
            
        }
        // setting up the progress view
        setProgressView()
        self.view.addSubview(self.progressView)
        
        dispatch_async(dispatch_get_main_queue()) {
            if(LiveFeedViewController.settings != nil)
            {
                self.stopProgressView()
            }
        }

        
    }
 
    
    func stopProgress(notification: NSNotification){
        
        print("called stop progress view notification function")
        //stopping progress view after connecting to MQTT server
        self.stopProgressView()
    }
    
    func startProgress(notification: NSNotification){
        
        print("called start progress view notification function")
        // setting up the progress view
        setProgressView()
        self.view.addSubview(self.progressView)

    }
    
    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        LiveFeedViewController.managedObjectContext = appDelegate.managedObjectContext
        self.settingsList = NSMutableArray()
        super.init(coder: aDecoder)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     Invoked when the user clicks on the play button on the screen. The data is loaded and placed on the webview
    */
    @IBAction func startLiveFeed(sender: AnyObject) {
        
        self.loadWebView(self.liveFeedURL)
        
    }
    
    /*
     Invoked when the user clicks on pause. New data is not loaded on the webview.
    */
    @IBAction func pauseLiveFeed(sender: AnyObject) {
         liveFeedView.stopLoading()
        
    }
    
    /*
     Invoked when the user clicks on stop. A blank screen is loaded.
    */
    @IBAction func stopLiveFeed(sender: AnyObject) {
       self.loadWebView("about:blank")

        //liveFeedView.stopLoading()
        
    }
    
    /*
     Checks if internet connection is available, if so, an NSURLConnection is made to receive a response from the
     HTTP server on the Raspberry Pi that is streaming the live feed. The URL to load from is sent as a parameter
     to the function. If no internet connection is available, the user is presented with an alert.
    */
    func loadWebView(liveFeedURL: String )
    {
        // checking if network is available (Reachability class is defined in another file)
        
        if Reachability.isConnectedToNetwork() == true      // if data network exists then start the live feed
        {
            print("Internet connection OK")
            
            // setting up the progress view
            setProgressView()
            self.view.addSubview(self.progressView)
            
            // taking the string liveFeedURL and converting it to a URL
            let url = NSURL (string: liveFeedURL)
            
            // creating a URL request
            let requestObj = NSURLRequest(URL: url!);
            var responseObj : NSURLResponse?
            
            do{
                let data = try NSURLConnection.sendSynchronousRequest(requestObj, returningResponse: &responseObj) as NSData?
                if let httpResponse = responseObj as? NSHTTPURLResponse
                {
                    print("http response is \(httpResponse.statusCode)")
                }
                
                
                print(requestObj)
            }
            catch
            {
                // stopping the progress view
                self.stopProgressView()
                displayAlertMessage("Server Error", message: "Unable to connect to the server for live feed")
            }
            
            
            
            // loading the web page in the web view
            liveFeedView.loadRequest(requestObj)
            
            // stopping the progress view
            self.stopProgressView()
            
            
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
     A custom function to display an alert on the screen based on the title and message passed
     */
    func displayAlertMessage(title: String, message: String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(alertAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationVC: SettingViewController = segue.destinationViewController as! SettingViewController
        destinationVC.managedObjectContext = LiveFeedViewController.managedObjectContext!
    }
    
    /*
     This method is called to check the latest settings from the Core Data entity Settings.
    */
    func checkSettings()
    {
        print("checking settings")
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Settings", inManagedObjectContext:
            LiveFeedViewController.managedObjectContext!)
        fetchRequest.entity = entityDescription
        var result = []
        print("Outside do")
        do
        {
            result = try LiveFeedViewController
                .managedObjectContext!.executeFetchRequest(fetchRequest)
            self.settingsList.addObjectsFromArray(result as Array)
            print("Count = \(self.settingsList.count)")
            if (self.settingsList.count == 0)
            {
                let newSettings: Settings = (NSEntityDescription.insertNewObjectForEntityForName("Settings",
                    inManagedObjectContext: LiveFeedViewController.managedObjectContext!) as? Settings)!
                print("inside if")
                newSettings.frequency = "Monthly"
                newSettings.deleteMethod = "Automatic"
                newSettings.notification = true
                self.settingsList.addObject(newSettings)
                LiveFeedViewController.settings = newSettings
                saveSettings()
            }
            
            LiveFeedViewController.settings = self.settingsList.objectAtIndex(0) as! Settings
            
            print("Inside do")
        }
            
        catch
        {
            let fetchError = error as NSError
            print(fetchError)
            print("fetch error")
        }
        
    }
    
    /*
     Invoked to save the settings in Core Data
    */
    func saveSettings()
    {
        self.settingsList.removeAllObjects();
        self.settingsList.addObject(LiveFeedViewController.settings!)
        
        do
        {
            try LiveFeedViewController.managedObjectContext!.save()
        }
        catch let error
        {
            print("Could not add to table \(error)")
        }
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
        self.progressView = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 50))
        self.progressView.backgroundColor = UIColor.lightGrayColor()
        self.progressView.layer.cornerRadius = 10
        let wait = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        wait.color = UIColor(red: 254/255, green: 218/255, blue: 2/255, alpha: 1)
        wait.hidesWhenStopped = false
        wait.startAnimating()
        
        let message = UILabel(frame: CGRect(x: 60, y: 0, width: 200, height: 50))
        message.text = "Connecting to server..."
        message.textColor = UIColor(red: 254/255, green: 218/255, blue: 2/255, alpha: 1)
        
        self.progressView.addSubview(wait)
        self.progressView.addSubview(message)
        self.progressView.center = self.view.center
        self.progressView.tag = 1000
        
        print("called the set progress view function")
        
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
        print("called the stop progress view method")
    }
    
}

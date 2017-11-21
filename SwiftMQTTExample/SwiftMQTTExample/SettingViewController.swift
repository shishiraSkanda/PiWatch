//
//  SettingViewController.swift
//  PiWatch
//
//  Created by Priyanka Gopakumar on 13/11/2016.
//  Copyright © 2016 Priyanka. All rights reserved.
//

/*
 The application provides some basic settings for the user to choose such as notification on or off,
 a method to delete previous events from history (either manually or automatically), and if automatic,
 the provides the frequency with which the delete of history should happen (either weekly, monthly, fortnightly,
 or yearly).
 The screen makes use of a switch, a segmented control and a picker view to implement these functionalities.
 The settings are dynamically saved in a Core Data entity as the user sets them. Default settings are used
 in case of first instance of using the application.
 */
import UIKit
import CoreData

class SettingViewController: UIViewController,UIPickerViewDelegate, UIPickerViewDataSource {

    // declaring the UI elements
    @IBOutlet weak var notificationsSwitch: UISwitch!
    @IBOutlet weak var frequencyView: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var frequencyPicker: UIPickerView!
    
    // declaring the attributes
    var managedObjectContext: NSManagedObjectContext
    var pickerData: [String] = [String]()
    var settingsList: NSMutableArray
    var settings: Settings?
    
    required init?(coder aDecoder: NSCoder)
    {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        self.managedObjectContext = appDelegate.managedObjectContext
        settingsList = NSMutableArray()
        //settings = Settings()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setting some custom colours for the switch
        let yellowColor = UIColor(red: 254/255, green: 218/255, blue: 2/255, alpha: 1)
        self.notificationsSwitch.onTintColor = yellowColor
        self.notificationsSwitch.tintColor = yellowColor
 

        // Connect data to the picker view
        self.frequencyPicker.delegate = self
        self.frequencyPicker.dataSource = self
        
        // setting a listener for the notification switch
        self.notificationsSwitch.addTarget(self, action: "switchChanged:", forControlEvents: UIControlEvents.ValueChanged)
        
        // Input data into picker
        pickerData = ["Daily", "Weekly", "Fortnightly", "Monthly"]
        
        // fetching the data from core data for Category entity and putting it in the settings list. The first entry in the list is taken to be the final setting
        
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Settings", inManagedObjectContext:
            self.managedObjectContext)
        fetchRequest.entity = entityDescription
        var result = []
        print("Outside do")
        do
        {
            result = try self.managedObjectContext.executeFetchRequest(fetchRequest)
            self.settingsList.addObjectsFromArray(result as Array)
            print("Count = \(self.settingsList.count)")
            if (self.settingsList.count == 0)
            {
                let newSettings: Settings = (NSEntityDescription.insertNewObjectForEntityForName("Settings",
                    inManagedObjectContext: self.managedObjectContext) as? Settings)!
                print("inside if")
                newSettings.frequency = "Monthly"
                newSettings.deleteMethod = "Automatic"
                newSettings.notification = true
                self.settingsList.addObject(newSettings)
                //self.settings = newSettings
                saveSettings()
            }
            
            self.settings = self.settingsList.objectAtIndex(0) as! Settings
            
            print("Inside do")
        }
            
        catch
        {
            let fetchError = error as NSError
            print(fetchError)
            print("fetch error")
        }
        
        // setting the switch to the previous value
        self.notificationsSwitch.on = self.settings!.notification == 1 ? true:false
        
        // setting the picker view to the previous value
        setPickerToPreviousValue()
        
        // setting the segmented control to previous value
        setDeleteMethodToPreviousValue()
        
    }
    

    func saveSettings()
    {
        self.settingsList.removeAllObjects();
       self.settingsList.addObject(self.settings!)
        
        do
        {
            try self.managedObjectContext.save()
        }
        catch let error
        {
            print("Could not add to table \(error)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     This function is invoked when the user changes the setting on the segmented control.
     The two options given for delete are automatic and manual. If automatic is chosen then additional
     options are displayed to the user by making the frequencyView view visible.
     If manual, then the frequencyView is hidden.
    */
    
    @IBAction func segmentedContolChange(sender: AnyObject) {
        
        if (self.segmentedControl.selectedSegmentIndex == 0)
        {
            self.frequencyView.hidden = false
            self.settings!.deleteMethod = "Automatic"
        }
        else
        {
            self.frequencyView.hidden = true
            self.settings!.deleteMethod = "Manual"
        }
        self.saveSettings()
    }

    // configuring the picker view
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int{
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return pickerData.count
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let yellowColor = UIColor(red: 254/255, green: 218/255, blue: 2/255, alpha: 1)
        //let color = (row == pickerView.selectedRowInComponent(component)) ? yellowColor : yellowColor
        return NSAttributedString(string: pickerData[row], attributes: [NSForegroundColorAttributeName: yellowColor])
    }
    
    /*
     This function is invoked when the user selects a row from the picker. The options are as shown below.
     The option corresponding to the row that is picked is saved in the core data by calling the saveSettings() method.
    */
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        switch(row)
        {
            case 0: self.settings!.frequency = "Daily"
            case 1: self.settings!.frequency = "Weekly"
            case 2: self.settings!.frequency = "Fortnightly"
            case 3: self.settings!.frequency = "Monthly"
            default: self.settings!.frequency = "Monthly"
        }
        self.view.endEditing(true)
        self.saveSettings()
    }

    /*
     Function that is called while loading the view to set the picker to the last saved setting.
    */
    func setPickerToPreviousValue()
    {
        var frequency: String
        frequency = settings!.frequency!
        print("Frequency is \(frequency)")
        switch (frequency)
        {
            case "Daily": frequencyPicker.selectRow(0, inComponent: 0, animated: true)
            case "Weekly": frequencyPicker.selectRow(1, inComponent: 0, animated: true)
            case "Fortnightly": frequencyPicker.selectRow(2, inComponent: 0, animated: true)
            case "Monthly": frequencyPicker.selectRow(3, inComponent: 0, animated: true)
            default: frequencyPicker.selectRow(3, inComponent: 0, animated: true)
        }
    }
    
    /*
     Function that is called while loading the view to set the segemented control to the last saved setting.
     */
    func setDeleteMethodToPreviousValue()
    {
        let method: String
        method = settings!.deleteMethod!
        switch (method)
        {
            case "Automatic": segmentedControl.selectedSegmentIndex = 0
            case "Manual":  segmentedControl.selectedSegmentIndex = 1
                            self.frequencyView.hidden = true
            default: segmentedControl.selectedSegmentIndex = 0
            
        }
        
        
    }

    /*
     An action listener function that is invoked when the user changes the switch settings. As and when the setting is changed, the core
     data entity Settings is updated as well by calling the saveSettings() method.
     If notifications is turned off, the unsubscribe method for MQTT server is called to stop receiving push notification.
     If notifications is turned on, the user is again subscribed to the channel.
    */
    func switchChanged(mySwitch: UISwitch) {
        self.settings!.notification = self.notificationsSwitch.on
        //let mqttViewController = MQTTViewController()
        if (notificationsSwitch.on)
        {
            LiveFeedViewController.controller.callAll()
        }
        else
        {
            LiveFeedViewController.controller.unSubscribeToChannel()
        }
        saveSettings()
    }

}

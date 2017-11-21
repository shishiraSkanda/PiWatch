//
//  HistoryTableViewController.swift
//  PiWatch
//
//  Created by Priyanka Gopakumar on 13/11/2016.
//  Copyright © 2016 Priyanka. All rights reserved.
//

/*
 The application provides the user with a history of events or intrusions that have occurred. The list is provided
 in a table view. The list is also filtered to ensure that the delete functionality set by the user is implemented before
 presenting the events to the user. An NSCalendar method is used to compare dates of the events to the current date
 for deleting them. 
 The NSDate extension methods were retrieved from Stack Overflow.
 Source: http://stackoverflow.com/questions/27182023/getting-the-difference-between-two-nsdates-in-months-days-hours-minutes-seconds
 Retrieved on 13/11/2016
*/

import UIKit
import CoreData

extension NSDate {
    
    func daysFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: self, options: []).day
    }
}

class HistoryTableViewController: UITableViewController {

    // UI components
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var deleteAllButton: UIBarButtonItem!
    @IBOutlet weak var emptyLabel: UILabel!
    
    // attributes
    var managedObjectContext: NSManagedObjectContext
    var eventList: NSMutableArray
    var selectedEvents: NSMutableArray
    var currentEvent: Event?
    var selectedPosition: Int?
    
    
    override func viewDidLoad() {
        
        // loaded the history from Core Data using the managed object context
        self.tableView.allowsMultipleSelection = true
        super.viewDidLoad()
        emptyLabel.text = ""
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Event", inManagedObjectContext:
            self.managedObjectContext)
        fetchRequest.entity = entityDescription
        var result = []
        do
        {
            self.eventList.removeAllObjects()
            result = try self.managedObjectContext.executeFetchRequest(fetchRequest)
            self.eventList.addObjectsFromArray(result as Array)
            if (self.eventList.count == 0)
            {
                self.emptyLabel.text = "No Events"
            }
        }
            
        catch
        {
            let fetchError = error as NSError
            print(fetchError)
        }
        
        self.sortHistoryByDateTime()
        self.tableView.reloadData()
        self.deselectAllRows()
        self.automaticDeleteHistory()
        //self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        // to dynamically update the table when a notification is received, this method is implemented which calls the function loadList when an alert notification for intrusion is received
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadList:",name:"load", object: nil)
    }
    
    func loadList(notification: NSNotification){
       
        self.viewDidLoad()
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.viewDidLoad()
    }

    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        self.managedObjectContext = appDelegate.managedObjectContext
        self.eventList = NSMutableArray()
        self.selectedEvents = NSMutableArray()
        super.init(coder: aDecoder)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.eventList.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("eventCell", forIndexPath: indexPath) as! EventTableViewCell
        let event: Event = self.eventList.objectAtIndex(indexPath.row) as! Event
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        cell.dateLabel.text = formatter.stringFromDate(event.date!)
        
        formatter.dateFormat = "HH:mm:ss"
        cell.timeLabel.text = formatter.stringFromDate(event.date!)
       
        cell.selectionStyle = .None
        return cell
        
    }
    


    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // segue to move control to view the details of a selected reminder in another view controller
        if (segue.identifier == "showEventDetailsSegue")
        {
            //self.selectedPosition = tableView.indexPathForSelectedRow!.row
            self.currentEvent = self.eventList[selectedPosition!] as? Event
            let destinationVC: EventDetailsViewController = segue.destinationViewController as! EventDetailsViewController
            destinationVC.currentEvent = self.currentEvent
        }
    }
    
    /*
     This function is being used to add a button to each row of the table view.
     This button is to view the details of an event
     The button can be accessed by swiping left on a row in the table
     */
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        // button to view the details of the category
        let viewEvent = UITableViewRowAction(style: .Normal, title: "View")
        {action, indexPath in
            self.selectedPosition = indexPath.row
            // if this is pressed them the prepareForSegue method is called for the DisplayCategorySegue
            self.performSegueWithIdentifier("showEventDetailsSegue", sender: self)
        }
        
                // setting custom colours for each of the row buttons
        viewEvent.backgroundColor = UIColor.orangeColor()
        return [viewEvent]
    }
    
    
    /*
     This method is invoked when the Delete button is clicked the user is asked to confirm if the selected events must be deleted.
     If not events are available or no events are selected, an alert is shown to the user.
     The delete of events is updated on Core Data as well.
     */
    
    @IBAction func deleteSelected(sender: AnyObject)
    {
        if(self.selectedEvents.count == 0)
        {
            if(self.eventList.count == 0)
            {
                notifyUser("Alert", message: "No events to delete")
            }
            else
            {
                notifyUser("Alert", message: "No events selected to delete")
        
            }
        }
        else
        {
            let deleteAlert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete the selected events?", preferredStyle: UIAlertControllerStyle.Alert)
            
            deleteAlert.addAction(UIAlertAction(title: "Confirm", style: .Default, handler: { (action: UIAlertAction!) in
                for currentEvent in self.selectedEvents
                {
                    self.eventList.removeObject(currentEvent)
                    
                    // Delete the row from the data source
                    self.managedObjectContext.deleteObject(currentEvent as! NSManagedObject)
                }
                
                self.saveHistory()
                self.deselectAllRows()
                self.selectedEvents.removeAllObjects()
            }))
            
            deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
                print("Delete cancelled")
            }))
            
            presentViewController(deleteAlert, animated: true, completion: nil)
            
        }
    }
    
    /*
     Invoked when the Delete All button is clicked. The user is asked to confirm the delete of all the events.
     If no events are available then the user is sent an alert.
     The delete operation is reflected in the Core Data as well.
    */
    @IBAction func deleteAllEvents(sender: AnyObject) {
        
         if(self.eventList.count == 0)
        {
           notifyUser("Alert", message: "No events to delete")
         
        }
        else
        {
            let deleteAlert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete all events?", preferredStyle: UIAlertControllerStyle.Alert)
        
            deleteAlert.addAction(UIAlertAction(title: "Confirm", style: .Default, handler: { (action: UIAlertAction!) in
            self.eventList.removeAllObjects()
            let fetchRequest = NSFetchRequest(entityName: "Event")
            if #available(iOS 9.0, *) {
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do
                {
                    try self.managedObjectContext.executeRequest(deleteRequest)
                } catch let error as NSError
                {
                    print("error occured in deleting all objects from core data : \(error)")
                }
                
            } else {
                // Fallback on earlier versions
            }
            self.saveHistory()
            }))
        
            deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
            print("Delete cancelled")
        }))
        
        presentViewController(deleteAlert, animated: true, completion: nil)
        
        }
    }
    
    // to allow select of row for delete
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
        self.selectedEvents.addObject(self.eventList.objectAtIndex(indexPath.row))
    }
    
    // to allow deselect of row initially chosen for delete
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
        self.selectedEvents.removeObject(self.eventList.objectAtIndex(indexPath.row))
    }
    
    // save the core data model
    func saveHistory()
    {
       // self.settingsList.removeAllObjects();
        //self.settingsList.addObject(self.settings!)
        
        do
        {
            try self.managedObjectContext.save()
        }
        catch let error
        {
            print("Could not add to table \(error)")
        }
        if (self.eventList.count == 0)
        {
            self.emptyLabel.text = "No Events"
        }
        self.tableView.reloadData()
    }
    
    
    /*
     This function is used to sort the events list by comparing the dates of the events
     Adapted from a code retrieved from http://stackoverflow.com/questions/25769107/sort-nsarray-with-sortedarrayusingcomparator
     Author: Mike S and Miro
     Date: 13/11/2016
     */
    func sortHistoryByDateTime()
    {
        var eventList: NSMutableArray
        eventList = self.eventList
        let sortedList = eventList.sortedArrayUsingComparator{
            (object1, object2) -> NSComparisonResult in
            let event1 = object1 as! Event
            let event2 = object2 as! Event
            let result = event2.date!.compare(event1.date!)
            return result
        }
        self.eventList.setArray(sortedList)
    }
    
    // to remove the select ticks from all the rows in the table
    func deselectAllRows()
    {
        for index in 0 ..< self.eventList.count
        {
            
            let indexPath: NSIndexPath = NSIndexPath(forRow: index, inSection: 0)
            tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
        }
        
    }
    
    /*
     This method is invoked during load of the screen to ensure the older or unwanted events are deleted from the
     list before presenting it to the user. The automatic delete function invokes the necesssary function in case
     the user has chosen the automatic delete option in the settings.
    */
    func automaticDeleteHistory()
    {
        var settingsList = NSMutableArray()
        var settings: Settings
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Settings", inManagedObjectContext:
            self.managedObjectContext)
        fetchRequest.entity = entityDescription
        var result = []
        do
        {
            result = try self
                .managedObjectContext.executeFetchRequest(fetchRequest)
            settingsList.addObjectsFromArray(result as Array)
            settings = settingsList.objectAtIndex(0) as! Settings
            if settings.deleteMethod == "Automatic"
            {
                switch(settings.frequency!)
                {
                case "Daily": self.deleteDailyHistory()
                case "Weekly": self.deleteWeeklyHistory()
                case "Fortnightly": self.deleteFortnightlyHistory()
                case "Monthly": self.deleteMonthlyHistory()
                default: self.deleteMonthlyHistory()
                }
            }
        }
            
        catch
        {
            let fetchError = error as NSError
            print(fetchError)
        }
      
    }
    
    // method to delete all events more than a day old
    func deleteDailyHistory()
    {
        let today = NSDate()
        for event in self.eventList
        {
            //Checks if date is older than yesterday
            if today.daysFrom(event.date) >= 1
            {
                self.eventList.removeObject(event)
               
                // Delete the row from the data source
                managedObjectContext.deleteObject(event as! NSManagedObject)
            }
    
        }
        self.saveHistory()
        
    }
    
    // method to delete all events more than a week old
    func deleteWeeklyHistory()
    {
        let today = NSDate()
        for event in self.eventList
        {
            //Checks if date is older than yesterday
            if today.daysFrom(event.date) >= 7
            {
                self.eventList.removeObject(event)
                
                // Delete the row from the data source
                managedObjectContext.deleteObject(event as! NSManagedObject)
            }
            
        }
        self.saveHistory()
        
    }
    
    // method to delete all events more than a fortnight old
    func deleteFortnightlyHistory()
    {
        let today = NSDate()
        for event in self.eventList
        {
            //Checks if date is older than yesterday
            if today.daysFrom(event.date) >= 14
            {
                self.eventList.removeObject(event)
                
                // Delete the row from the data source
                managedObjectContext.deleteObject(event as! NSManagedObject)
            }
            
        }
        self.saveHistory()
        
    }
    
    // method to delete all events more than a month old
    func deleteMonthlyHistory()
    {
        let today = NSDate()
        for event in self.eventList
        {
            //Checks if date is older than yesterday
            if today.daysFrom(event.date) >= 30
            {
                self.eventList.removeObject(event)
                
                // Delete the row from the data source
                managedObjectContext.deleteObject(event as! NSManagedObject)
            }
            
        }
        self.saveHistory()
        
    }
    
    // a method to present the user with a custom alert
    func notifyUser(title: String, message: String)
    {
        if UIApplication.sharedApplication().applicationState == .Active {
            // App is active, show an alert
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(alertAction)
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
            
            //self.presentViewController(alertController, animated: true, completion: nil)
        } else {
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

}

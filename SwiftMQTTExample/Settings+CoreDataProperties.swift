//
//  Settings+CoreDataProperties.swift
//  PiWatch
//
//  Created by Priyanka Gopakumar on 15/11/2016.
//  Copyright © 2016 Priyanka. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Settings {

    @NSManaged var deleteMethod: String?
    @NSManaged var frequency: String?
    @NSManaged var notification: NSNumber?

}

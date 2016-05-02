//
//  Files+CoreDataProperties.swift
//  Infoto
//
//  Created by Scott Bridgman on 2/21/16.
//  Copyright © 2016 Tohism. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Files {

    @NSManaged var create_date: NSTimeInterval
    @NSManaged var desc: String?
    @NSManaged var edit_date: NSTimeInterval
    @NSManaged var fileName: String?
    @NSManaged var fileType: String?
    @NSManaged var title: String?
    @NSManaged var whichFolder: Folders?

}

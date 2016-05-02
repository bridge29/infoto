//
//  Folders+CoreDataProperties.swift
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

extension Folders {

    @NSManaged var daysTilDelete: Int16
    @NSManaged var isLocked: Bool
    @NSManaged var name: String?
    @NSManaged var orderPosition: Int16
    @NSManaged var sortBy: Int16
    @NSManaged var files: NSSet?

}

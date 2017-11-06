//
//  EPConstants.swift
//  EPContactPicker
//
//  Created by Prabaharan Elangovan on 16/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit

//Declare all the static constants here
struct EPGlobalConstants {
    
//MARK: String Constants
    struct Strings {
        static let birdtdayDateFormat = "MMM d"
        static let contactsTitle = "Contacts"
        static let phoneNumberNotAvaialable = "No phone numbers available"
        static let emailNotAvaialable = "No emails available"
        static let bundleIdentifier = "EPContactsPicker"
        static let cellNibIdentifier = "EPContactCell"
    }

//MARK: Color Constants
    struct Colors {
      static let grey = UIColor(red: 243 / 255.0, green: 243 / 255.0, blue: 243 / 255.0, alpha: 1.0)
      static let lightGrey = UIColor(red: 203 / 255.0, green: 203 / 255.0, blue: 203 / 255.0, alpha: 1.0)
      static let nxYellow = UIColor(red: 251 / 255.0, green: 176 / 255.0, blue: 64 / 255.0, alpha: 1.0)
    }
    
    
//MARK: Array Constants
    struct Arrays {
        static let alphabets = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","#"] //# indicates the names with numbers and blank spaces
    }
    
}

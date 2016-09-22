//
//  EPContact.swift
//  EPContacts
//
//  Created by Prabaharan Elangovan on 13/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit
import Contacts

open class EPContact: NSObject {
    
    open var firstName: NSString!
    open var lastName: NSString!
    open var company: NSString!
    open var thumbnailProfileImage: UIImage?
    open var profileImage: UIImage?
    open var birthday: Date?
    open var birthdayString: String?
    open var contactId: String?
    open var phoneNumbers = [(phoneNumber: String, phoneLabel: String)]()
    open var emails = [(email: String, emailLabel: String )]()
    
    override init() {
        super.init()
    }
    
    public init (contact: CNContact)
    {
        super.init()
        
        //VERY IMPORTANT: Make sure you have all the keys accessed below in the fetch request
        firstName = contact.givenName as NSString!
        lastName = contact.familyName as NSString!
        company = contact.organizationName as NSString!
        contactId = contact.identifier
        
        if let thumbnailImageData = contact.thumbnailImageData {
            thumbnailProfileImage = UIImage(data:thumbnailImageData)
        }
        
        if let imageData = contact.imageData {
            profileImage = UIImage(data:imageData)
        }
        
        if let birthdayDate = contact.birthday {
            
            birthday = Calendar(identifier: Calendar.Identifier.gregorian).date(from: birthdayDate)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = EPGlobalConstants.Strings.birdtdayDateFormat
            //Example Date Formats:  Oct 4, Sep 18, Mar 9
            birthdayString = dateFormatter.string(from: birthday!)
        }
        
        for phoneNumber in contact.phoneNumbers {
            let phone = phoneNumber.value 
            phoneNumbers.append((phone.stringValue,phoneNumber.label!))
        }

        for emailAddress in contact.emailAddresses {
            let email = emailAddress.value as String
            emails.append((email,emailAddress.label!))
        }
    }
    
    open func displayName() -> String {
        return "\(firstName) \(lastName)"
    }
    
    open func contactInitials() -> String {
        var initials = String()
        if firstName.length > 0 {
            initials.append(firstName.substring(to: 1))
        }
        if lastName.length > 0 {
            initials.append(lastName.substring(to: 1))
        }
        return initials
    }
    
}

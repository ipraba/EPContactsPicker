//
//  EPContact.swift
//  EPContacts
//
//  Created by Prabaharan Elangovan on 13/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit
import Contacts

public class EPContact: NSObject {
    
    public var firstName: NSString!
    public var lastName: NSString!
    public var company: NSString!
    public var thumbnailProfileImage: UIImage?
    public var profileImage: UIImage?
    public var birthday: NSDate?
    public var birthdayString: String?
    public var contactId: String?
    public var phoneNumbers = [(phoneNumber: String, phoneLabel: String)]()
    public var emails = [(email: String, emailLabel: String )]()
    
    override init() {
        super.init()
    }
    
    public init (contact: CNContact)
    {
        super.init()
        
        //VERY IMPORTANT: Make sure you have all the keys accessed below in the fetch request
        firstName = contact.givenName
        lastName = contact.familyName
        company = contact.organizationName
        contactId = contact.identifier
        
        if let thumbnailImageData = contact.thumbnailImageData {
            thumbnailProfileImage = UIImage(data:thumbnailImageData)
        }
        
        if let imageData = contact.imageData {
            profileImage = UIImage(data:imageData)
        }
        
        if let birthdayDate = contact.birthday {
            
            birthday = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)?.dateFromComponents(birthdayDate)
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = EPGlobalConstants.Strings.birdtdayDateFormat
            //Example Date Formats:  Oct 4, Sep 18, Mar 9
            birthdayString = dateFormatter.stringFromDate(birthday!)
        }
        
        for phoneNumber in contact.phoneNumbers {
            let phone = phoneNumber.value as! CNPhoneNumber
            phoneNumbers.append((phone.stringValue,phoneNumber.label))
        }

        for emailAddress in contact.emailAddresses {
            let email = emailAddress.value as! String
            emails.append((email,emailAddress.label))
        }
    }
    
    public func displayName() -> String {
        return "\(firstName) \(lastName)"
    }
    
    public func contactInitials() -> String {
        var initials = String()
        if firstName.length > 0 {
            initials.appendContentsOf(firstName.substringToIndex(1))
        }
        if lastName.length > 0 {
            initials.appendContentsOf(lastName.substringToIndex(1))
        }
        return initials
    }
    
}

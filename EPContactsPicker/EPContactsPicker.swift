//
//  EPContactsPicker.swift
//  EPContacts
//
//  Created by Prabaharan Elangovan on 12/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit
import Contacts


@objc protocol EPPickerDelegate{
    
optional    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error : NSError)
optional    func epContactPicker(_: EPContactsPicker, didCancel error : NSError)
optional    func epContactPicker(_: EPContactsPicker, didSelectContact contact : EPContact)
optional    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts : [EPContact])

}

typealias ContactsHandler = (contacts : [CNContact] , error : NSError?)  -> Void

enum SubtitleCellValue{
    case PhoneNumber
    case Email
    case Birthday
    case Organization
    
}

class EPContactsPicker: UITableViewController {
    
// MARK: - Properties
    var contactDelegate : EPPickerDelegate?
    var contactsStore : CNContactStore?
    var arrContacts = [CNContact]()
    var contactSearchBar = UISearchBar()
    var orderedContacts = [String:[CNContact]]() //Contacts ordered in dicitonary alphabetically
    
    var sortedContactKeys = [String]()
    var multiSelectEnabled : Bool = false //Default is single selection contact
    var selectedContacts = [EPContact]()
    
    var subtitleCellValue = SubtitleCellValue.PhoneNumber
    
// MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = EPGlobalConstants.Strings.contactsTitle
        let nib = UINib(nibName: "EPContactCell", bundle: NSBundle.mainBundle())
        tableView.registerNib(nib, forCellReuseIdentifier: "Cell")
        
        inititlizeBarButtons()
        initializeSearchBar()
        reloadContacts()
    }
    
    func initializeSearchBar(){

        contactSearchBar = UISearchBar(frame: CGRectMake(0, 0, 320, 44))
        contactSearchBar.sizeToFit()
        contactSearchBar.setShowsCancelButton(false, animated: true)
        
        self.tableView.tableHeaderView? = contactSearchBar
    }
    
    func inititlizeBarButtons(){
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "onTouchCancelButton")
        self.navigationItem.leftBarButtonItem = cancelButton
        
        if multiSelectEnabled {
            let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "onTouchDoneButton")
            self.navigationItem.rightBarButtonItem = doneButton
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  
    convenience init(delegate: EPPickerDelegate? )  {
        self.init(delegate: delegate , multiSelection: false)
    }
    
    convenience init(delegate: EPPickerDelegate? , multiSelection : Bool ){
        self.init(style: .Plain)
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
    }

    convenience init(delegate: EPPickerDelegate? , multiSelection : Bool , subtitleCellType : SubtitleCellValue){
        self.init(style: .Plain)
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
        subtitleCellValue = subtitleCellType
    }
    
    
// MARK: - Contact Operations
  
  func reloadContacts(){
    getContacts({ (contacts, error) in
        if (error == nil)
        {
            self.arrContacts = contacts
            dispatch_async(dispatch_get_main_queue(), {
                // code here
                self.tableView.reloadData()
            })

        }
        
    })
  }
  
  func getContacts (completion :  ContactsHandler){
    if contactsStore == nil {
        //ContactStore is control for accessing the Contacts
        contactsStore = CNContactStore()
    }
        let error = NSError(domain: "EPContactPickerErrorDomain", code: 1, userInfo: [ NSLocalizedDescriptionKey: "No Contacts Access"])
        
        switch CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        {
            case CNAuthorizationStatus.Denied,CNAuthorizationStatus.Restricted :
                //User has denied the current app to access the contacts.
                
                let productName = NSBundle.mainBundle().infoDictionary!["CFBundleName"]!
                
                let alert = UIAlertController(title: "Unable to access contacts", message: "\(productName) does not have access to contacts. Kindly enable it in privacy settings ", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: {  action in
                    self.contactDelegate?.epContactPicker!(self, didContactFetchFailed: error)
                    completion(contacts: [],error:error)
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
                
            break
            
            case CNAuthorizationStatus.NotDetermined :
                //This case means the user is prompted for the first time for allowing contacts
                contactsStore?.requestAccessForEntityType(CNEntityType.Contacts, completionHandler: { (granted, error) -> Void in
                    //At this point an alert is provided to the user to provide access to contacts. This will get invoked if a user responds to the alert
                    if  (!granted ){
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion(contacts: [],error:error!)
                        })
                    }
                    else{
                        self.getContacts(completion)
                    }
                })
            break
            
            case  CNAuthorizationStatus.Authorized :
                //Authorization granted by user for this app.
                var contactsArray = [CNContact]()
                
                let contactFetchRequest = CNContactFetchRequest(keysToFetch: allowedContactKeys())
                
                do {
                    try contactsStore?.enumerateContactsWithFetchRequest(contactFetchRequest, usingBlock: { (contact, stop) -> Void in
                        //Ordering contacts based on alphabets in firstname
                        contactsArray.append(contact)
                        var key : String = "#"
                        //If ordering has to be happening via family name change it here.
                        if let firstLetter = contact.givenName[0..<1] where ( firstLetter.containsAlphabets()) {
                            key = firstLetter.uppercaseString
                        }
                        var contacts = [CNContact]()
                        
                        if let segregatedContact = self.orderedContacts[key]
                        {
                            contacts = segregatedContact

                        }
                        contacts.append(contact)
                        self.orderedContacts[key] = contacts

                    })
                    self.sortedContactKeys = Array(self.orderedContacts.keys).sort(<)
                    if self.sortedContactKeys.first == "#"
                    {
                        self.sortedContactKeys.removeFirst()
                        self.sortedContactKeys.append("#")
                    }
                    completion(contacts: contactsArray,error: nil)
                }
                //Catching exception as enumerateContactsWithFetchRequest can throw errors
                catch let error as NSError {
                    print(error.localizedDescription)
                }
            break
            
        }
    
    
  }
    
    
    func allowedContactKeys() -> [CNKeyDescriptor]{
        //We have to provide only the keys which we have to access. We should avoid unnecessary keys when fetching the contact. Reducing the keys means faster the access.
        return [CNContactNamePrefixKey,
            CNContactGivenNameKey,
          //  CNContactMiddleNameKey,
            CNContactFamilyNameKey,
          //  CNContactNameSuffixKey,
          //  CNContactNicknameKey,
          //  CNContactPhoneticGivenNameKey,
          //  CNContactPhoneticMiddleNameKey,
          //  CNContactPhoneticFamilyNameKey,
            CNContactOrganizationNameKey,
          //  CNContactDepartmentNameKey,
          //  CNContactJobTitleKey,
            CNContactBirthdayKey,
          //  CNContactNonGregorianBirthdayKey,
          //  CNContactNoteKey,
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey,
            CNContactImageDataAvailableKey,
          //  CNContactTypeKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
          //  CNContactPostalAddressesKey,
          //  CNContactDatesKey,
          //  CNContactUrlAddressesKey,
          //  CNContactRelationsKey,
          //  CNContactSocialProfilesKey,
          //  CNContactInstantMessageAddressesKey
        ]
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sortedContactKeys.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let contactsForSection = orderedContacts[sortedContactKeys[section]]
        {
            return contactsForSection.count
        }
        return 0
    }

    // MARK: - Table view delegates

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EPContactCell
        cell.accessoryType = UITableViewCellAccessoryType.None
        //Convert CNContact to EPContact
        if let contactsForSection = orderedContacts[sortedContactKeys[indexPath.section]]
        {
            let contact =  EPContact(contact: contactsForSection[indexPath.row])
            if multiSelectEnabled  && selectedContacts.contains({ $0.contactId == contact.contactId }) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
            
            cell.updateContactsinUI(contact, indexPath: indexPath, subtitleType: subtitleCellValue)
            return cell
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Convert CNContact to EPContact        
        if let contactsForSection = orderedContacts[sortedContactKeys[indexPath.section]]
        {
            let contact =  EPContact(contact: contactsForSection[indexPath.row])
            if multiSelectEnabled {
                let cell = tableView.cellForRowAtIndexPath(indexPath)
                //Keeps track of enable=ing and disabling contacts
                if cell?.accessoryType == UITableViewCellAccessoryType.Checkmark
                {
                    cell?.accessoryType = UITableViewCellAccessoryType.None
                    selectedContacts = selectedContacts.filter(){
                        return contact.contactId != $0.contactId
                    }
                }
                else{
                    cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
                    selectedContacts.append(contact)
                }
            }
            else{
                //Single selection code
                contactDelegate?.epContactPicker!(self, didSelectContact: contact)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }

    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: index), atScrollPosition: UITableViewScrollPosition.Top , animated: false)        
        return EPGlobalConstants.Arrays.alphabets.indexOf(title)!
    }
    
    override  func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return sortedContactKeys
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedContactKeys[section]
    }
    
//MARK: Button Actions
    func onTouchCancelButton() {
        contactDelegate?.epContactPicker!(self, didCancel: NSError(domain: "EPContactPickerErrorDomain", code: 2, userInfo: [ NSLocalizedDescriptionKey: "User Canceled Selection"]))
        dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func onTouchDoneButton() {
        contactDelegate?.epContactPicker!(self, didSelectMultipleContacts: selectedContacts)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

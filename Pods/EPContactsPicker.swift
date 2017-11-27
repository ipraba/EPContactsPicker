//
//  EPContactsPicker.swift
//  EPContacts
//
//  Created by Prabaharan Elangovan on 12/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit
import Contacts


public protocol EPPickerDelegate: class {
    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError)
    func epContactPicker(_: EPContactsPicker, didCancel error: NSError)
    func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact)
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact])
  
    func updateSendButton(enabled: Bool, selectedContacts: [EPContact])
    func presentContactPermissionAlert()
}

public extension EPPickerDelegate {
    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError) { }
    func epContactPicker(_: EPContactsPicker, didCancel error: NSError) { }
    func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact) { }
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact]) { }
  
    func updateSendButton(enabled: Bool, selectedContacts: [EPContact]) { }
    func presentContactPermissionAlert() { }
}

typealias ContactsHandler = (_ contacts : [CNContact] , _ error : NSError?) -> Void

public enum SubtitleCellValue{
    case phoneNumber
    case email
    case birthday
    case organization
}

open class EPContactsPicker: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    // MARK: - Properties
    
    open weak var contactDelegate: EPPickerDelegate? 
    var contactsStore: CNContactStore?
    var resultSearchController = UISearchController()
    var orderedContacts = [String: [CNContact]]() //Contacts ordered in dicitonary alphabetically
    var sortedContactKeys = [String]()
    
    var selectedContacts = [EPContact]()
    var filteredContacts = [CNContact]()
    var multiSelectContactLimit : UInt = 0
    
    var subtitleCellValue = SubtitleCellValue.phoneNumber
    var multiSelectEnabled: Bool = false //Default is single selection contact
    
    // MARK: - Lifecycle Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = EPGlobalConstants.Strings.contactsTitle
        self.view.backgroundColor = UIColor.clear
        let bgView = UIView()
        bgView.backgroundColor = UIColor.clear
        self.tableView.backgroundView = bgView
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.sectionIndexColor = UIColor.white
        self.tableView.sectionIndexBackgroundColor = UIColor.clear
        registerContactCell()
        inititlizeBarButtons()
        initializeSearchBar()
        reloadContacts()
    }
    
    func initializeSearchBar() {
        self.resultSearchController = ( {
            let controller = UISearchController(searchResultsController: nil)
            controller.searchBar.barStyle = UIBarStyle.black
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.delegate = self
            self.tableView.tableHeaderView = controller.searchBar
          
            return controller
        })()
    }
    
    func inititlizeBarButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(onTouchCancelButton))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        if multiSelectEnabled {
            let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(onTouchDoneButton))
            self.navigationItem.rightBarButtonItem = doneButton
            
        }
    }
    
    fileprivate func registerContactCell() {
        
        let podBundle = Bundle(for: self.classForCoder)
        if let bundleURL = podBundle.url(forResource: EPGlobalConstants.Strings.bundleIdentifier, withExtension: "bundle") {
            
            if let bundle = Bundle(url: bundleURL) {
                
                let cellNib = UINib(nibName: EPGlobalConstants.Strings.cellNibIdentifier, bundle: bundle)
                tableView.register(cellNib, forCellReuseIdentifier: "Cell")
            }
            else {
                assertionFailure("Could not load bundle")
            }
        }
        else {
            
            let cellNib = UINib(nibName: EPGlobalConstants.Strings.cellNibIdentifier, bundle: nil)
            tableView.register(cellNib, forCellReuseIdentifier: "Cell")
        }
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Initializers
  
    convenience public init(delegate: EPPickerDelegate?) {
        self.init(delegate: delegate, multiSelection: false)
    }
    
    convenience public init(delegate: EPPickerDelegate?, multiSelection : Bool) {
        self.init(style: .plain)
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
    }

    convenience public init(delegate: EPPickerDelegate?, multiSelection : Bool, subtitleCellType: SubtitleCellValue) {
        self.init(style: .plain)
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
        subtitleCellValue = subtitleCellType
    }
  
  convenience public init(delegate: EPPickerDelegate?, multiSelection: Bool, subtitleCellType: SubtitleCellValue, multiSelectContactLimit: UInt) {
    self.init(delegate: delegate, multiSelection: multiSelection, subtitleCellType: subtitleCellType)
    self.multiSelectContactLimit = multiSelectContactLimit
  }
  
  convenience public init(delegate: EPPickerDelegate?, multiSelection: Bool, multiSelectionContactLimit: UInt) {
    self.init(delegate: delegate, multiSelection: multiSelection)
    self.multiSelectContactLimit = multiSelectionContactLimit
  }
    
    
    // MARK: - Contact Operations
  
      open func reloadContacts() {
        getContacts( {(contacts, error) in
            if (error == nil) {
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }
        })
      }
  
    func getContacts(_ completion:  @escaping ContactsHandler) {
        if contactsStore == nil {
            //ContactStore is control for accessing the Contacts
            contactsStore = CNContactStore()
        }
        let error = NSError(domain: "EPContactPickerErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "No Contacts Access"])
        
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
            case CNAuthorizationStatus.denied, CNAuthorizationStatus.restricted:
                //User has denied the current app to access the contacts.
                self.contactDelegate?.presentContactPermissionAlert()
            case CNAuthorizationStatus.notDetermined:
                //This case means the user is prompted for the first time for allowing contacts
                contactsStore?.requestAccess(for: CNEntityType.contacts, completionHandler: { (granted, error) -> Void in
                    //At this point an alert is provided to the user to provide access to contacts. This will get invoked if a user responds to the alert
                    if  (!granted ){
                        DispatchQueue.main.async(execute: { () -> Void in
                            completion([], error! as NSError?)
                        })
                    }
                    else{
                        self.getContacts(completion)
                    }
                })
            
            case  CNAuthorizationStatus.authorized:
                //Authorization granted by user for this app.
                var contactsArray = [CNContact]()
                let addContact = CNMutableContact()
                addContact.givenName = "+ Add phone number"
                contactsArray.insert(addContact, at: 0)
                
                
                let contactFetchRequest = CNContactFetchRequest(keysToFetch: allowedContactKeys())
                
                do {
                    try contactsStore?.enumerateContacts(with: contactFetchRequest, usingBlock: { (contact, stop) -> Void in
                        //Ordering contacts based on alphabets in firstname
                        contactsArray.append(contact)
                        var key: String = "#"
                        //If ordering has to be happening via family name change it here.
                        if let firstLetter = contact.givenName[0..<1] , firstLetter.containsAlphabets() {
                            key = firstLetter.uppercased()
                        }
                        var contacts = [CNContact]()
                        
                        if let segregatedContact = self.orderedContacts[key] {
                            contacts = segregatedContact
                        }
                        contacts.append(contact)
                        self.orderedContacts[key] = contacts

                    })
                    self.sortedContactKeys = Array(self.orderedContacts.keys).sorted(by: <)
                    if self.sortedContactKeys.first == "#" {
                        self.sortedContactKeys.removeFirst()
                        self.sortedContactKeys.append("#")
                    }
                  
                  let key = self.sortedContactKeys.first ?? "#"
                  var firstContacts = self.orderedContacts[key] ?? []
                  firstContacts.insert(addContact, at: 0)
                  self.orderedContacts[key] = firstContacts
                  
                    completion(contactsArray, nil)
                }
                //Catching exception as enumerateContactsWithFetchRequest can throw errors
                catch let error as NSError {
                    print(error.localizedDescription)
                }
            
        }
    }
    
    func allowedContactKeys() -> [CNKeyDescriptor]{
        //We have to provide only the keys which we have to access. We should avoid unnecessary keys when fetching the contact. Reducing the keys means faster the access.
        return [CNContactNamePrefixKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
        ]
    }
  
  fileprivate func design(textField: UITextField, placeholderText: String) {
    textField.attributedPlaceholder = NSAttributedString(string: placeholderText,
                                                         attributes: [NSForegroundColorAttributeName: UIColor.black])
    textField.font = UIFont(name: "HelveticaNeue", size: 14.0)!
    let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal,
                                              toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25)
    textField.addConstraint(heightConstraint)
  }
  
  fileprivate func addContactAction(_ alertController: UIAlertController) {
    guard let nameField = (alertController.textFields![0] as UITextField).text,
          let phoneField = (alertController.textFields![1] as UITextField).text else {
        return
    }
    
    if nameField != "" && phoneField != "" {
      // create a new contact
      let contact = CNMutableContact()
      contact.givenName = nameField
      let phoneNumber = CNLabeledValue(label: CNLabelPhoneNumberiPhone,
                                       value: CNPhoneNumber(stringValue: phoneField))
      contact.phoneNumbers.append(phoneNumber)
      
      let key = self.sortedContactKeys.first ?? "#"
      var keysContacts = self.orderedContacts[key] ?? []
      keysContacts.insert(contact, at: 1)
      self.orderedContacts[key] = keysContacts
      
      self.tableView.reloadData()
      let indexPath = IndexPath(item: 1, section: 0)
      self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
      self.tableView.delegate?.tableView!(self.tableView, didSelectRowAt: indexPath)
    } else {
      let errorAlert = UIAlertController(title: "Error", message: "Please input name and phone number", preferredStyle: .alert)
      errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { alert -> Void in
        self.present(alertController, animated: true, completion: nil)
      }))
      self.present(errorAlert, animated: true, completion: nil)
    }
  }
  
  func presenetNewContactScreen() {
    let alertController = UIAlertController(title: "Add Contact", message: "", preferredStyle: .alert)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { _ in
      alertController.dismiss(animated: true, completion: nil)
    })
    
    alertController.addAction(cancelAction)
    
    let action = UIAlertAction(title: "OK", style: .default, handler: { alert -> Void in
      self.addContactAction(alertController)
    })
    
    alertController.addAction(action)
    
    alertController.addTextField(configurationHandler: { (textField) -> Void in
      textField.autocapitalizationType = .words
      self.design(textField: textField, placeholderText: "Name")
    })
    
    alertController.addTextField(configurationHandler: { (textField) -> Void in
      textField.keyboardType = .decimalPad
      self.design(textField: textField, placeholderText: "Number")
    })
    
    // Background color
    let backView = alertController.view.subviews.last?.subviews.last
    backView?.layer.cornerRadius = 6.0
    backView?.backgroundColor = EPGlobalConstants.Colors.grey
    
    self.present(alertController, animated: true, completion: nil)
  }
    
    // MARK: - Table View DataSource
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        if resultSearchController.isActive { return 1 }
        return sortedContactKeys.count
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if resultSearchController.isActive { return filteredContacts.count }
        if let contactsForSection = orderedContacts[sortedContactKeys[section]] {
            return contactsForSection.count
        }
        return 0
    }
  
    // MARK: - Table View Delegates

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! EPContactCell
        cell.accessoryType = UITableViewCellAccessoryType.none
        //Convert CNContact to EPContact
		let contact: EPContact
        
        if resultSearchController.isActive {
            contact = EPContact(contact: filteredContacts[(indexPath as NSIndexPath).row])
        } else {
			guard let contactsForSection = orderedContacts[sortedContactKeys[(indexPath as NSIndexPath).section]] else {
				assertionFailure()
				return UITableViewCell()
			}

			contact = EPContact(contact: contactsForSection[(indexPath as NSIndexPath).row])
        }
		
        if multiSelectEnabled  && selectedContacts.contains(where: { $0.contactId == contact.contactId }) {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
            cell.tintColor = EPGlobalConstants.Colors.nxYellow
        }
		
        cell.updateContactsinUI(contact, indexPath: indexPath, subtitleType: subtitleCellValue)
      if indexPath.row == 0 && indexPath.section == 0 {
        cell.contactDetailTextLabel.text = ""
      }
      
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! EPContactCell
        let selectedContact =  cell.contact!
        if selectedContact.firstName == "+ Add phone number" {
          // add new contact
          presenetNewContactScreen()
          return
      }
      
        if multiSelectEnabled {
            //Keeps track of enable=ing and disabling contacts
            if cell.accessoryType == UITableViewCellAccessoryType.checkmark {
                cell.accessoryType = UITableViewCellAccessoryType.none
                selectedContacts = selectedContacts.filter(){
                    return selectedContact.contactId != $0.contactId
                }
            }
            else if (self.multiSelectContactLimit == 0 || self.selectedContacts.count < Int(self.multiSelectContactLimit)) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
                cell.tintColor = EPGlobalConstants.Colors.nxYellow
                selectedContacts.append(selectedContact)
            }
          let enabled = self.multiSelectContactLimit == 0
                        || self.selectedContacts.count == self.multiSelectContactLimit
          self.contactDelegate?.updateSendButton(enabled: enabled, selectedContacts: self.selectedContacts)
        }
        else {
            //Single selection code
			resultSearchController.isActive = false
			self.dismiss(animated: true, completion: {
				DispatchQueue.main.async {
					self.contactDelegate?.epContactPicker(self, didSelectContact: selectedContact)
				}
			})
        }
      self.resultSearchController.dismiss(animated: true, completion: nil)
    }
    
    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if resultSearchController.isActive { return 0 }
        tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: UITableViewScrollPosition.top , animated: false)        
        return sortedContactKeys.index(of: title)!
    }
    
    override  open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if resultSearchController.isActive { return nil }
        return sortedContactKeys
    }
  
    // MARK: - Button Actions
    
    func onTouchCancelButton() {
        dismiss(animated: true, completion: {
            self.contactDelegate?.epContactPicker(self, didCancel: NSError(domain: "EPContactPickerErrorDomain", code: 2, userInfo: [ NSLocalizedDescriptionKey: "User Canceled Selection"]))
        })
    }
    
    func onTouchDoneButton() {
        dismiss(animated: true, completion: {
            self.contactDelegate?.epContactPicker(self, didSelectMultipleContacts: self.selectedContacts)
        })
    }
    
    // MARK: - Search Actions
    
    open func updateSearchResults(for searchController: UISearchController)
    {
        if let searchText = resultSearchController.searchBar.text , searchController.isActive {
            
            let predicate: NSPredicate
            if searchText.characters.count > 0 {
                predicate = CNContact.predicateForContacts(matchingName: searchText)
            } else {
                predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactsStore!.defaultContainerIdentifier())
            }
            
            let store = CNContactStore()
            do {
                filteredContacts = try store.unifiedContacts(matching: predicate,
                    keysToFetch: allowedContactKeys())
                //print("\(filteredContacts.count) count")
                
                self.tableView.reloadData()
                
            }
            catch {
                print("Error!")
            }
        }
    }
    
    open func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
}

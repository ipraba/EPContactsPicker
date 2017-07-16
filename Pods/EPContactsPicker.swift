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
}

public extension EPPickerDelegate {
	func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError) { }
	func epContactPicker(_: EPContactsPicker, didCancel error: NSError) { }
	func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact) { }
	func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact]) { }
}

typealias ContactsHandler = (_ contacts : [CNContact] , _ error : NSError?) -> Void

public enum SubtitleCellValue{
    case phoneNumber
    case email
    case birthday
    case organization
}

open class EPContactsPicker: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    open weak var contactDelegate: EPPickerDelegate?
    var contactsStore: CNContactStore?
    var resultSearchController = UISearchController()
    var orderedContacts = [String: [CNContact]]() //Contacts ordered in dicitonary alphabetically
    var sortedContactKeys = [String]()
    
    var selectedContacts = [EPContact](){
        didSet {
            if sendInvitesButton != nil {
                updateSendInvitesButtonTitle()
                updateContactSelectionButton()
            }
        }
    }

    var filteredContacts = [CNContact]()
    
    var subtitleCellValue = SubtitleCellValue.phoneNumber
    var multiSelectEnabled: Bool = false //Default is single selection contact
    //Hides navigation bar when search bar is active.
    var isPresentingSearch: Bool = false{
        didSet{
            navigationController!.isNavigationBarHidden = isPresentingSearch
        }
    }
    
    var shouldSelectAllContactsOnLoad = false //If we need all contacts selected on controller load select true
    var tableView = UITableView()
    var sendInvitesButton: UIBarButtonItem?
    var totalNumberOfLoadedContacts = 0
    
    // MARK: - Lifecycle Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = EPGlobalConstants.Strings.contactsTitle
        initializeTableView()
        inititlizeBarButtons()
        initializeSearchBar()
        reloadContacts()
    }
    
    func initializeSearchBar() {
        self.resultSearchController = ( {
            let controller = UISearchController(searchResultsController: nil)
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
            let selectAllContactsButton = UIBarButtonItem(title: EPGlobalConstants.SelectAllContactsButton.selectAllContactString, style: UIBarButtonItemStyle.plain, target: self, action: #selector(onTouchSelectionButton))
            self.navigationItem.rightBarButtonItem = selectAllContactsButton
//            self.navigationItem.
           
        }
    }
    
    func initializeTableView(){
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        registerContactCell()
        view.addSubview(tableView)
    }
    
    func initializeToolBarWithButton(){
        let toolBar = UIToolbar(frame: CGRect(x: 0,
                                              y: view.frame.height - EPGlobalConstants.SendInvitesButton.height,
                                              width: view.frame.width,
                                              height: EPGlobalConstants.SendInvitesButton.height))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        sendInvitesButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(onTouchSendInvitesButton))
        updateSendInvitesButtonTitle()
        let attributes = [NSFontAttributeName:EPGlobalConstants.SendInvitesButton.titleFont!]
        sendInvitesButton!.setTitleTextAttributes(attributes, for: [])
        toolBar.items = [space, sendInvitesButton!, space]
        toolBar.backgroundColor = UIColor.white
        tableView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.frame.height - toolBar.frame.height)
        view.addSubview(toolBar)
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
        self.init()
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
    }

    convenience public init(delegate: EPPickerDelegate?, multiSelection : Bool, subtitleCellType: SubtitleCellValue) {
        self.init()
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
        subtitleCellValue = subtitleCellType
    }
    
    convenience public init(delegate: EPPickerDelegate?, multiSelection : Bool, subtitleCellType: SubtitleCellValue, selectAllContactsOnLoad: Bool, sendInvitesButtonEnabled: Bool) {
        self.init()
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
        subtitleCellValue = subtitleCellType
        if selectAllContactsOnLoad {
            shouldSelectAllContactsOnLoad = true
        }
        if sendInvitesButtonEnabled {
            initializeToolBarWithButton()
        }
    }
    
    // MARK: - Contact Operations
  
      open func reloadContacts() {
        getContacts( {(contacts, error) in
            if (error == nil) {
                DispatchQueue.main.async(execute: {
                    if self.shouldSelectAllContactsOnLoad {
                        self.selectAllContacts()
                    }
                    self.tableView.reloadData()
                })
            }
            self.totalNumberOfLoadedContacts = contacts.count
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
                
                let productName = Bundle.main.infoDictionary!["CFBundleName"]!
                
                let alert = UIAlertController(title: "Unable to access contacts", message: "\(productName) does not have access to contacts. Kindly enable it in privacy settings ", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {  action in
                    completion([], error)
                    self.dismiss(animated: true, completion: {
                        self.contactDelegate?.epContactPicker(self, didContactFetchFailed: error)
                    })
                })
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            
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
                
                let contactFetchRequest = CNContactFetchRequest(keysToFetch: allowedContactKeys())
                
                do {
                    try contactsStore?.enumerateContacts(with: contactFetchRequest, usingBlock: { (contact, stop) -> Void in
                        switch self.subtitleCellValue {
                        case .email:
                            if !contact.emailAddresses.isEmpty {
                                self.insert(contact: contact, to: &contactsArray)
                            }
                        case .phoneNumber:
                            if !contact.phoneNumbers.isEmpty {
                                self.insert(contact: contact, to: &contactsArray)
                            }
                        default:
                            self.insert(contact: contact, to: &contactsArray)
                        }                    })
                    self.sortedContactKeys = Array(self.orderedContacts.keys).sorted(by: <)
                    if self.sortedContactKeys.first == "#" {
                        self.sortedContactKeys.removeFirst()
                        self.sortedContactKeys.append("#")
                    }
                    completion(contactsArray, nil)
                }
                //Catching exception as enumerateContactsWithFetchRequest can throw errors
                catch let error as NSError {
                    print(error.localizedDescription)
                }
            
        }
    }
    
    func insert(contact: CNContact, to contactsArray: inout [CNContact]){
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
    
    func selectAllContacts(){
        let array = Array(orderedContacts.values)
        selectedContacts.removeAll()
        for contactArray in array{
            for contact in contactArray {
                let ePContact = EPContact(contact: contact)
                selectedContacts.append(ePContact)
            }
        }
        tableView.reloadData()
    }
    
    func deselectAllContacts() {
        selectedContacts.removeAll()
        tableView.reloadData()
    }
    
    // MARK: - Table View DataSource
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        if resultSearchController.isActive { return 1 }
        return sortedContactKeys.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if resultSearchController.isActive { return filteredContacts.count }
        if let contactsForSection = orderedContacts[sortedContactKeys[section]] {
            return contactsForSection.count
        }
        return 0
    }

    // MARK: - Table View Delegates

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! EPContactCell
        cell.contactSelected = false
        //Convert CNContact to EPContact
		let contact: EPContact
        
        if resultSearchController.isActive {
            contact = EPContact(contact: filteredContacts[(indexPath as NSIndexPath).row])
        } else {
			guard let contactsForSection = orderedContacts[sortedContactKeys[(indexPath as NSIndexPath).section]] else {
				assertionFailure()
				return UITableViewCell()
			}
			contact = EPContact(contact: contactsForSection[(indexPath as NSIndexPath).row])  //
        }
		
        if multiSelectEnabled  && selectedContacts.contains(where: { $0.contactId == contact.contactId }) {
            cell.contactSelected = true
        }
		
        cell.updateContactsinUI(contact, indexPath: indexPath, subtitleType: subtitleCellValue)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! EPContactCell
        let selectedContact =  cell.contact!
        if multiSelectEnabled {
            //Keeps track of enable=ing and disabling contacts
            if cell.contactSelected == true {
                cell.contactSelected = false
                selectedContacts = selectedContacts.filter(){
                    return selectedContact.contactId != $0.contactId
                }
            }
            else {
                cell.contactSelected = true
                selectedContacts.append(selectedContact)
            }
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
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if resultSearchController.isActive { return 0 }
        tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: UITableViewScrollPosition.top , animated: false)        
        return sortedContactKeys.index(of: title)!
    }
    
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if resultSearchController.isActive { return nil }
        return sortedContactKeys
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if resultSearchController.isActive { return nil }
        return sortedContactKeys[section]
    }
    
    // MARK: - Button Actions
    
    func onTouchCancelButton() {
        dismiss(animated: true, completion: {
            self.contactDelegate?.epContactPicker(self, didCancel: NSError(domain: "EPContactPickerErrorDomain", code: 2, userInfo: [ NSLocalizedDescriptionKey: "User Canceled Selection"]))
        })
    }
    
    func onTouchSendInvitesButton() {
        dismiss(animated: true, completion: {
           /* if self.isPresentingSearch {
                self.isPresentingSearch = false
            } else { */
                self.contactDelegate?.epContactPicker(self, didSelectMultipleContacts: self.selectedContacts)
            //}
        })
    }
    
    func onTouchSelectionButton() {
        if totalNumberOfLoadedContacts > selectedContacts.count {
            selectAllContacts()
        }else{
            deselectAllContacts()
        }
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
                switch self.subtitleCellValue {
                case .email:
                    filteredContacts = filteredContacts.filter{!$0.emailAddresses.isEmpty}
                default:
                    break
                }
                self.tableView.reloadData()
                
            }
            catch {
                print("Error!")
            }
        }
    }
    
    open func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isPresentingSearch = false
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    open func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isPresentingSearch = true
    }
    
    //MARK: - Update Appearance Of Send Invites Button
    
    func updateSendInvitesButtonTitle() {
        let numberOfInvites = selectedContacts.count
        var title = ""
        if numberOfInvites > 0 {
            title = "Send \(numberOfInvites) \(numberOfInvites == 1 ? "Invite" : "Invites")"
            sendInvitesButton!.isEnabled = true
        }else{
            title = "Select Contacts"
            sendInvitesButton!.isEnabled = false
        }
        sendInvitesButton!.title = title
    }
    
    func updateContactSelectionButton(){
        let contactSelectionButton = self.navigationItem.rightBarButtonItem
        if totalNumberOfLoadedContacts > selectedContacts.count {
            contactSelectionButton?.title = EPGlobalConstants.SelectAllContactsButton.selectAllContactString
        }else{
            contactSelectionButton?.title = EPGlobalConstants.SelectAllContactsButton.deselectAllContactsString
        }
    }
    
}

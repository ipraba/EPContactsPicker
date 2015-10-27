EPContactsPicker
===========
A contacts picker component for iOS. Created in swift using the new contacts framework by apple. 

![Single Selection](https://raw.githubusercontent.com/ipraba/EPContactsPicker/master/Screenshots/Screen2.png)

![Multi Selection](https://raw.githubusercontent.com/ipraba/EPContactsPicker/master/Screenshots/Screen3.png)


Requirements
------------
Requires **iOS 9,** the `ContactsUI.framework` and `Contacts.framework`.

Features
--------

EPContacts Picker provides lot of features which lets you customize the picker

1. Single selection and multiselection option
2. Making the secondary data to show as requested(Phonenumbers, Emails, Birtday and Organisation)
3. Section Indexes to easily navigate throught the contacts
4. Showing initials when image is not available
5. EPContact object to get the properties of the contacts

Delegates
--------
EPContactsPicker provides you four delegates for getting the callbacks on the picker

```swift
optional    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error : NSError)
optional    func epContactPicker(_: EPContactsPicker, didCancel error : NSError)
optional    func epContactPicker(_: EPContactsPicker, didSelectContact contact : EPContact)
optional    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts : [EPContact])
```

EPContact Object
----------------

EPContact object provides you the properties of a contact. This contains properties like displayname, initials, firstname, lastname, organisation, birthdayString etc


Suggestions and feedbacks are welcome 
-------------------------------------



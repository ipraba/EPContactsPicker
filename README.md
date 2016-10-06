<p align="center" >
  <img src="EPContactsPickerLogo.jpg" alt="EPContactsPicker" title="EPContactsPicker" width="196">
</p>

EPContactsPicker
===========
Contacts picker component using new contacts framework by apple


[![Platform](https://img.shields.io/cocoapods/p/EPContactsPicker.svg?style=flat)](http://cocoapods.org/pods/EPContactsPicker)
[![Swift 3](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/EPContactsPicker.svg?style=flat)](http://cocoadocs.org/docsets/EPContactsPicker)
[![CI Status](https://travis-ci.org/ipraba/EPContactsPicker.svg?branch=master)](https://travis-ci.org/ipraba/EPContactsPicker)
[![License](https://img.shields.io/cocoapods/l/Ouroboros.svg?style=flat)](https://github.com/ipraba/EPContactsPicker/blob/master/LICENSE)
[![Twitter: @HaveYouMetPrabu](https://img.shields.io/badge/contact-@HaveYouMetPrabu-blue.svg?style=flat)](https://twitter.com/HaveYouMetPrabu)

Preview
-------
![Single Selection](https://raw.githubusercontent.com/ipraba/EPContactsPicker/master/Screenshots/Screen2.png)    ![Multi Selection](https://raw.githubusercontent.com/ipraba/EPContactsPicker/master/Screenshots/Screen3.png)

# Installation #

## CocoaPods ##
EPContactsPicker is available on CocoaPods. Just add the following to your project Podfile:

`pod 'EPContactsPicker'`

## Manual Installation ##

Just drag and drop the `EPContactsPicker` folder into your project

# Requirements #

* iOS9+
* Swift 3.0
* ARC

For manual installation you might have to add these frameworks in your Build Phases
`ContactsUI.framework` and `Contacts.framework`.

# Features #

EPContacts Picker provides lot of features which lets you customize the picker

1. Single selection and multiselection option
2. Search Contacts
3. Making the secondary data to show as requested(Phonenumbers, Emails, Birthday and Organisation)
4. Section Indexes to easily navigate throught the contacts
5. Showing initials when image is not available
6. EPContact object to get the properties of the contacts

# Initialization #

Init the picker by passing delegate, multiselection option and the secondary data(Phone number, Email, brithday and Organisation) to be displayed

    let contactPickerScene = EPContactsPicker(delegate: self, multiSelection:false, subtitleCellType: SubtitleCellValue.Email)
    let navigationController = UINavigationController(rootViewController: contactPickerScene)
    self.presentViewController(navigationController, animated: true, completion: nil)

# Delegates #

EPContactsPicker provides you four delegates for getting the callbacks on the picker

```swift
func epContactPicker(_: EPContactsPicker, didContactFetchFailed error : NSError)
func epContactPicker(_: EPContactsPicker, didCancel error : NSError)
func epContactPicker(_: EPContactsPicker, didSelectContact contact : EPContact)
func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts : [EPContact])
```

# EPContact Object #

EPContact object provides you the properties of a contact. This contains properties like displayname, initials, firstname, lastname, organisation, birthdayString etc

## License ##

EPContactsPicker is available under the MIT license. See the [LICENSE](https://github.com/ipraba/EPContactsPicker/blob/master/LICENSE) file for more info.

## Contributors ##

[@ipraba](https://github.com/ipraba)
[@Sorix](https://github.com/Sorix)


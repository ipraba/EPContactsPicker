Pod::Spec.new do |s|
  s.name             = "EPContactsPickerFilterable"
  s.version          = "1.0.4a"
  s.summary          = "A contacts picker component for iOS written in swift using new contacts framwork"
  s.description      = <<-DESC
Features
1. Single selection and multiselection option
2. Making the secondary data to show as requested(Phonenumbers, Emails, Birthday and Organisation)
3. Section Indexes to easily navigate throught the contacts
4. Showing initials when image is not available
5. EPContact object to get the properties of the contacts
DESC

  s.license          = 'MIT'
  s.author           = { "Prabaharan" => "mailprabaharan.e@gmail.com" }
  s.source           = { :git => "https://github.com/jackorapollo/EPContactsPicker.git", :tag => s.version.to_s }
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.source_files = 'EPContactsPicker'
  s.frameworks = 'Contacts', 'ContactsUI'
  s.resources        = ["EPContactsPicker/EPContactCell.xib"]

end

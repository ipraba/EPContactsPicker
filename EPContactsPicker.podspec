Pod::Spec.new do |s|
  s.name             = "EPContactsPicker"
  s.version          = "2.0.2"
  s.summary          = "A contacts picker component for iOS written in swift using new contacts framwork"
  s.description      = <<-DESC
Features
1. Single selection and multiselection option
2. Making the secondary data to show as requested(Phonenumbers, Emails, Birthday and Organisation)
3. Section Indexes to easily navigate throught the contacts
4. Showing initials when image is not available
5. EPContact object to get the properties of the contacts
DESC

  s.homepage         = "https://github.com/ipraba/EPContactsPicker"
  s.license          = 'MIT'
  s.author           = { "Prabaharan" => "mailprabaharan.e@gmail.com" }
  s.source           = { :git => "https://github.com/ipraba/EPContactsPicker.git", :tag => s.version.to_s }
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.source_files = 'Pods'
  s.frameworks = 'Contacts', 'ContactsUI'
  s.resources        = ["Pods/EPContactCell.xib"]
  s.resource_bundles = {
    'EPContactsPicker' => ['Pods/**/*.xib']
    }

end

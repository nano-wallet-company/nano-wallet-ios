source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
inhibit_all_warnings!
use_frameworks!

workspace 'Raiblocks'

target 'Raiblocks' do
  pod 'SwiftWebSocket'
  pod 'ReactiveSwift'
  pod 'ReactiveCocoa'
  pod 'Cartography'
  pod 'EFQRCode'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'RealmSwift'
  pod 'M13Checkbox'
end

post_install do |installer|
  installer.pods_project.targets.each  do |target|
      target.build_configurations.each  do |config|
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
      end
   end
end

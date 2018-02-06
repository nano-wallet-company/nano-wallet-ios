source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
inhibit_all_warnings!
use_frameworks!

workspace 'Raiblocks'

target 'Raiblocks' do
  pod 'SwiftWebSocket'
  pod 'ReactiveSwift', '~> 3.0'
  pod 'ReactiveCocoa', '~> 7.0.1'
  pod 'Cartography', '~> 2.1.0'
  pod "EFQRCode", '~> 4.1.0'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'RealmSwift'
end

post_install do |installer|
  installer.pods_project.targets.each  do |target|
      target.build_configurations.each  do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
      end
   end
end

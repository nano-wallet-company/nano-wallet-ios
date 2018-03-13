# Nano Wallet for iOS

## Setup

* Clone the repo
* Make sure [CocoaPods](https://cocoapods.org) is installed and run `pod install` in the `Raiblocks` directory
* Open the `Raiblocks.xcworkspace` file
* You must build and run on your device due to the `RaiCoreBase` library's support for arm64 architecture.
* You should be good to go!

_Note: Nano Wallet for iOS supports devices with iOS 11+_


### Contributing

* Fork the codebase
* Make changes
* Submit a pull request for review

### How to update RaiCoreBase if a new `.dylib` file is provided:

`RaiCoreBase` is an internal framework that handles Wallet Seed creation, private/public key creation, work signing and more. It can be found in the `RaiCoreBase` directory in the project.

It currently supports `arm64` devices which means it does not support devices that don't support iOS 11.

0) Note: This setup relies on Cocoapods as a dependency and won't work without it.

1) Drag in the updated .dylib file and the interface.h files from Downloads into Xcode (not into the folder in Finder). Make sure `Copy items if needed` is checked.

2) In terminal, in the project root directory, run `install_name_tool -id @rpath/RaiCoreBase.framework/RaiCoreBase ./RaiCoreBase/RaiCoreBase.dylib`

3) Next in the Xcode folder structure, remove the `.dylib` file extension from the .dylib file so the icon becomes a little Terminal and the file name reads RaiCoreBase

4) Go to Build Phases for the Framework and create a Copy Files job (if one doesn't exist, Destination: resources. Copy only when installing: no, Code sign on copy: yes). The item being copied is the little terminal icon with file name `RaiCoreBase`.

5) Go to Build Phases for the main project target and create a Copy Files job (if one doesn't exist) where the item referenced is RaiCoreBase.framework (copy only when installing: no, code sign on copy: yes. Destintation: Frameworks

6) In `RaiCoreBase`, make sure that the interface.h file is public to the Framework; Make sure `RaiCoreBase` is public (and required) to the Framework and the main project target

7) Make sure that the `.framework` is included in the main target's Embedded Binaries

8) Make sure that your `RaiCoreBase.h` file has `#import <RaiCoreBase/interface.h>` at the top

Troubleshooting:

* Build and run to make everything link and load up to make sure the code and framework is loaded together correctly.

* Also make sure you're importing `RaiCoreBase` into the wrapper library's `.h` file, that should give you access to all functions in the the `.m` file

### Have a question?

If you need any help, please visit our [GitHub Issues](https://github.com/nanocurrency/raiblocks-ios-wallet/issues) or the [Nano #support channel](https://chat.nano.org). Feel free to file an issue if you aren't able to find a solution.

### License

(to come)

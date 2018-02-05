# Nano iOS Wallet

## Setup

* Clone the repo
* Make sure [CocoaPods](https://cocoapods.org) is installed and run `pod install` in the `Raiblocks` directory
* Open the `Raiblocks.xcworkspace` file
* Build and run on your device and you should be good to go!


### Contributing

* Fork the codebase
* Make changes
* Submit a pull request for review


### How to set up RaiCore (if needed)

This should already be set up for you by cloning the repo but if you need to update or install `librai_lib.dylib`, here's how you do it:

* Get the `librai_lib.dylib` file as well as the `interface.h` file, the `.dsym file` is optional but is including for good measure.
* Drag the files into the RaiCore directory in the project directory (via Mac's Finder)
* In Xcode, add a Copy File job in Build Phases that references the `.dylib` file and loads it as a framework
	* Build Settings -> Other Linker Flags should include `-lrai_lib` on the end of the string (remove the tick marks around the string)
* Build Settings -> Library Search Paths should include `/Raiblocks/Raiblocks/RaiCore/` as a path to search for additional frameworks (i.e. ours)
* Build and run on your device

* **NOTE:** Any time you replace `librai_lib.dylib` in the `RaiCoreBase` folder, you have to run `install_name_tool -id @rpath/RaiCoreBase.framework/RaiCoreBase ./RaiCoreBase/RaiCoreBase.dylib` from the root directory of the project. Please note the _lack_ of `.dylib` from the first instance. The file tree in Xcode should have the `.dylib` extension in the file.


### Have a question?

If you need any help, please visit our [GitHub Issues](https://github.com/nanocurrency/raiblocks-ios-wallet/issues) or the [Nano #support channel](https://chat.nano.org). Feel free to file an issue if you do not manage to find any solution.

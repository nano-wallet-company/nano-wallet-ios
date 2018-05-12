# Nano Wallet for iOS

## Setup

* Clone the repo
* Make sure [CocoaPods](https://cocoapods.org) is installed and run `pod install` in the `Raiblocks` directory
* Open the `Raiblocks.xcworkspace` file
* You must build and run on your device due to the `RaiCoreBase` library's support for arm64 architecture.
* You should be good to go!

_Note: Nano Wallet for iOS supports devices with iOS 11+_


### Contributing

All Nano Wallet development happens on GitHub. Contributions make for good karma and
we welcome new contributors. We take contributors seriously, and thus have a
contributor [code of conduct](CODE_OF_CONDUCT.md).

* Fork the codebase
* See [Issues](https://github.com/nano-wallet-company/nano-wallet-ios/issues) for open bugs or feature requests
* Make changes in your local branch
* Submit a pull request for review, discussion and possible merge

### Links

| Link | Description |
| :----- | :------ |
[NanoWalletCompany.com](https://nanowalletco.com/) | Nano Wallet Company Homepage
[Nano.org](https://nano.org/) | Nano Homepage
[@NanoWalletCo](https://twitter.com/nanowalletco) | Follow Nano on Twitter to stay up to date.
[Releases](https://github.com/nano-wallet-company/nano-wallet-ios/releases) | Check out the releases and their changelogs.
[Code of Conduct](CODE_OF_CONDUCT.md) | Find out the standards we hold ourselves to.


### How to update RaiCoreBase if a new `.dylib` file is provided:

`RaiCoreBase` is an internal framework that handles Wallet Seed creation, private/public key creation, work signing and more. It can be found in the `RaiCoreBase` directory in the project.

It currently supports `arm64` devices which means it does not support devices that don't support iOS 11.

0) Note: This setup relies on Cocoapods as a dependency and won't work without it.

1) In terminal, starting in the wallet's base directory, copy the `.dylib` file into the `RaiCoreBase` directory. Example: `cp ../../Downloads/librai_lib.dylib RaiCoreBase/RaiCoreBase.dylib`

2) In terminal, in the project root directory, run `install_name_tool -id @rpath/RaiCoreBase.framework/RaiCoreBase ./RaiCoreBase/RaiCoreBase.dylib`

3) Remove the file extension: `mv RaiCoreBase/RaiCoreBase.dylib RaiCoreBase/RaiCoreBase`

4) Make sure that `Architectures` says "arm64." ![](https://dzwonsemrish7.cloudfront.net/items/1X1G2p3R2M0d28320x0C/Screen%20Shot%202018-05-02%20at%206.59.46%20PM.png?v=2f49e9b4)

(That's it! You should be good to go.)

Troubleshooting:

* Build and run to make everything link and load up to make sure the code and framework is loaded together correctly.

* Also make sure you're importing `RaiCoreBase` into the wrapper library's `.h` file, that should give you access to all functions in the the `.m` file

* Go to Build Phases for the Framework and create a Copy Files job (if one doesn't exist, Destination: resources. Copy only when installing: no, Code sign on copy: yes). The item being copied has the file name `RaiCoreBase`.

* Go to Build Phases for the main project target and create a Copy Files job (if one doesn't exist) where the item referenced is RaiCoreBase.framework (copy only when installing: no, code sign on copy: yes. Destination: Frameworks

* In `RaiCoreBase`, make sure that the interface.h file is public to the Framework; Make sure `RaiCoreBase` is public (and required) to the Framework and the main project target

* Make sure that the `.framework` is included in the main target's Embedded Binaries

* Make sure that your `RaiCoreBase.h` file has `#import <RaiCoreBase/interface.h>` at the top


### Have a question?

If you need any help, please visit our [GitHub Issues](https://github.com/nano-wallet-company/nano-wallet-ios/issues) or the [Nano #support channel](https://chat.nano.org). Feel free to file an issue if you aren't able to find a solution.

### License

Nano Wallet is released under the [BSD-2 License](https://github.com/nano-wallet-company/nano-ios-wallet/blob/master/LICENSE)

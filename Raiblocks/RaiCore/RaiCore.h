//
//  RaiCore.h
//  Raiblocks
//
//  Created by Zack Shapiro on 12/5/17.
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

@import Foundation;

@import RaiCoreBase;


@interface RaiCore: NSObject

- (BOOL)walletAddressIsValid:(NSString *)string;

- (NSData *)createSeed;

- (NSData *)createPrivateKey:(NSData *)seed atIndex:(UInt8)index;
- (NSData *)privateKeyForSeed:(NSString *)seed atIndex:(UInt8)index;

- (NSData *)createPublicKey:(NSData *)privateKey;

- (NSString *)createAddressFromPublicKey:(NSData *)publicKey;
- (NSString *)createAddressFromPublicKeyString:(NSString *)publicKey;

- (NSString *)seedOrKeyToString:(NSData *)data;
- (NSString *)signatureToString:(NSData *)data;

- (NSString *)signTransaction:(NSString *)transaction withPrivateKey:(NSData *)privateKey;

@end


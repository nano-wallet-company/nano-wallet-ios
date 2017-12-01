//
//  RaiCore.m
//  Raiblocks
//
//  Created by Zack Shapiro on 12/5/17.
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Raiblocks-Swift.h"

#import "RaiCore.h"

// TODO: name the functions better
@implementation RaiCore

// MARK: - Address validation

- (BOOL)walletAddressIsValid:(NSString *)string;
{
    const char *str = [string UTF8String];

    return xrb_valid_address((char *)str) == 0;
}


// MARK: - Create Seed

- (NSData *)createSeed;
{
    void *mem = malloc(32);
    NSData *data = [[NSData alloc] initWithBytes:mem length:32];
    unsigned char *bytePair = (unsigned char *)[data bytes];

    xrb_generate_random(bytePair);

    free(mem);
    return data;
}


// MARK: - Crate Private Keys

- (NSData *)createPrivateKey:(NSData *)seed atIndex:(UInt8)index;
{
    unsigned char *seedBytePair = (unsigned char *)[seed bytes];

    void *priv = malloc(32);
    NSData *privateKeyData = [[NSData alloc] initWithBytes:priv length:32];
    unsigned char *privateKeyBytePair = (unsigned char *)[privateKeyData bytes];

    xrb_seed_key(seedBytePair, index, privateKeyBytePair);

    free(priv);
    return privateKeyData;
}

- (NSData *)privateKeyForSeed:(NSString *)seed atIndex:(UInt8)index;
{
    const char *str = [seed UTF8String];

    void *mem = malloc(32);
    NSData *data = [[NSData alloc] initWithBytes:mem length:32];
    unsigned char *bytePair = (unsigned char *)[data bytes];

    xrb_uint256_from_string((char *)str, bytePair);

    free(mem);
    return [self createPrivateKey:data atIndex:index];
}


// MARK: - Create Public Key

- (NSData *)createPublicKey:(NSData *)privateKey;
{
    unsigned char *privateKeyBytePair = (unsigned char *)[privateKey bytes];

    void *public = malloc(32);
    NSData *publicKeyData = [[NSData alloc] initWithBytes:public length:32];
    unsigned char *publicKeyBytePair = (unsigned char *)[publicKeyData bytes];

    xrb_key_account(privateKeyBytePair, publicKeyBytePair);

    free(public);
    return publicKeyData;
}


// MARK: - Create Addresses

- (NSString *)createAddressFromPublicKey:(NSData *)publicKey;
{
    char string[128] = {0};
    unsigned char *publicKeyBytes = (unsigned char *)[publicKey bytes];

    xrb_uint256_to_address(publicKeyBytes, string);

    NSString *address = [NSString stringWithFormat:@"%s", string];

    if (![self walletAddressIsValid:address]) {
        return nil;
    }

    return address;
}

- (NSString *)createAddressFromPublicKeyString:(NSString *)publicKey;
{
    const char *str = [publicKey UTF8String];

    void *mem = malloc(32);
    NSData *data = [[NSData alloc] initWithBytes:mem length:32];
    unsigned char *bytePair = (unsigned char *)[data bytes];

    xrb_uint256_from_string((char *)str, bytePair);

    char string[128] = {0};
    xrb_uint256_to_address(bytePair, string);

    NSString *address = [NSString stringWithFormat:@"%s", string];

    if (![self walletAddressIsValid:address]) {
        return nil;
    }

    free(mem);
    return address;
}


// MARK: - String Converstion

- (NSString *)seedOrKeyToString:(NSData *)data;
{
    unsigned char *bytes = (unsigned char *)[data bytes];
    char string[128] = {0}; // NOTE: this really only needs to be 65 bits

    xrb_uint256_to_string(bytes, string);

    return [NSString stringWithFormat:@"%s", string];
}


- (NSString *)signatureToString:(NSData *)data;
{
    unsigned char *bytes = (unsigned char *)[data bytes];
    char string[256] = {0}; // NOTE: this really only needs to be 129 bits

    xrb_uint512_to_string(bytes, string);

    return [NSString stringWithFormat:@"%s", string];
}

- (NSString *)signTransaction:(NSString *)transaction withPrivateKey:(NSData *)privateKey;
{
    const char *txn = [transaction UTF8String];
    unsigned char *privateKeyBytePair = (unsigned char *)[privateKey bytes];

    const char *signedTransaction = xrb_sign_transaction((char *)txn, privateKeyBytePair);

    return [NSString stringWithFormat:@"%s", signedTransaction];
}

@end





//
//  Loadable.h
//  AutoSynth
//
//  Created by Dustin Dettmer on 4/6/14.
//  Copyright (c) 2014 DustyTech. All rights reserved.
//

#import <Foundation/Foundation.h>

/* LoadableArray should be used as part of the property declaration for arrays
 *
 *  Example usage:
 *    @property (strong) LoadableArray(MyCustomClass, children);
 *
 *    MyCustomClass should be a sublcass of Loadable
 *
 */
#define LoadableArray(type, name) \
    NSArray *name; \
    @property (assign) type *__##name##ElementType

@interface Loadable : NSObject

+ (id)withJsonString:(NSString*)string;
+ (id)withJsonData:(NSData*)data;
+ (id)withDictionary:(NSDictionary*)dictionary;

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

// This methods add underscores in front of reserved keywords.
// Subclasses can override these methods to provide more renaming.
- (NSString*)propertyNameFromDictionaryKey:(NSString*)dictionaryKey;

@end

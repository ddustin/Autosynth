//
//  Loadable.m
//  AutoSynth
//
//  Created by Dustin Dettmer on 4/6/14.
//  Copyright (c) 2014 DustyTech. All rights reserved.
//

#import "Loadable.h"
#import <objc/runtime.h>
#import <objc/message.h>

static SEL getSetter(NSString *key);
static NSString *getType(Class cls, NSString *key);
static BOOL typeIsValid(NSString *type);
static BOOL isType(Class cls, Class superCls);
static NSString *getIdType(NSString *type);
static NSString *arrayElementType(Class cls, NSString *key);
static NSArray *reservedKeywords();

@implementation Loadable

+ (id)withJsonString:(NSString *)string
{
    return [[self class] withJsonData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (id)withJsonData:(NSData *)data
{
    NSError *error = nil;
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    NSAssert(dictionary != nil, @"Json parsing failed: %@", [error userInfo][@"NSDebugDescription"] ?: error);
    
    return [[self class] withDictionary:dictionary];
}

+ (id)withDictionary:(NSDictionary *)dictionary
{
    Loadable *loadable = [[self class] alloc];
    
    return [loadable initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if((self = [super init]))
    {
        if(![dictionary isKindOfClass:[NSDictionary class]]) {
            
            NSAssert(NO, @"Loadable initWithDictionary called with a non-dictionary object: %@", [dictionary class]);
            return self;
        }
        
        NSMutableArray *missingProperties = nil;
        
        for(NSString *key in dictionary) {
            
            NSString *propertyName = [self propertyNameFromDictionaryKey:key];
            
            SEL setter = getSetter(propertyName);
            
            id value = [dictionary objectForKey:key];
            
            if([self respondsToSelector:setter]) {
                
                NSString *type = getType([self class], propertyName);
                NSString *idType = getIdType(type);
                
                if(idType) {
                    
                    Class propClass = NSClassFromString(idType);
                    
                    if(!propClass) {
                        
                        NSAssert(NO, @"Failed to find class %@ for property %@ on class %@", propClass, propertyName, [self class]);
                        continue;
                    }
                    
                    void (*function)(id, SEL, id) = (void*)objc_msgSend;
                    
                    if(isType(propClass, [Loadable class])) {
                        
                        if([value isKindOfClass:[NSNull class]]) {
                            
                            function(self, setter, nil);
                            continue;
                        }
                        
                        if(![value isKindOfClass:[NSDictionary class]]) {
                            
                            NSAssert(NO, @"Got a non dictionary type [%@] for property %@ on class %@", [value class], propertyName, [self class]);
                            continue;
                        }
                        
                        Loadable *loadable = [propClass alloc];
                        
                        loadable = [loadable initWithDictionary:value];
                        
                        function(self, setter, loadable);
                    }
                    else if(isType(propClass, [NSArray class])) {
                        
                        if([value isKindOfClass:[NSNull class]]) {
                            
                            function(self, setter, nil);
                            continue;
                        }
                        
                        if(![value isKindOfClass:[NSArray class]]) {
                            
                            NSAssert(NO, @"Got a non array type [%@] for property %@ on class %@", [value class], propertyName, [self class]);
                            continue;
                        }
                        
                        NSString *elementType = arrayElementType([self class], propertyName);
                        
                        elementType = getIdType(elementType);
                        
                        if(elementType) {
                            
                            Class elementClass = NSClassFromString(elementType);
                            
                            if(!elementClass) {
                                
                                NSAssert(NO, @"Failed to find class %@ for array %@'s element type on class %@", propClass, propertyName, [self class]);
                                continue;
                            }
                            
                            NSMutableArray *array = [NSMutableArray array];
                            
                            if(isType(elementClass, [Loadable class])) {
                                
                                for(id object in value) {
                                    
                                    if(![object isKindOfClass:[NSDictionary class]]) {
                                        
                                        NSAssert(NO, @"Got a non dictionary type [%@] for array element on property %@ on class %@", [object class], propertyName, [self class]);
                                        continue;
                                    }
                                    
                                    Loadable *loadable = [elementClass alloc];
                                    
                                    [array addObject:[loadable initWithDictionary:object]];
                                }
                            }
                            else {
                                
                                for(id element in value)
                                    [array addObject:[element copy]];
                            }
                            
                            function(self, setter, array);
                        }
                        else {
                            
                            function(self, setter, value);
                        }
                    }
                    else if(isType(propClass, [NSDate class])) {
                        
                        if([value isKindOfClass:[NSNull class]]) {
                            
                            function(self, setter, nil);
                            continue;
                        }
                        
                        if(![value isKindOfClass:[NSNumber class]]) {
                            
                            NSAssert(NO, @"Got the wrong type [%@] for property %@ on class %@, it should be %@", [value class], propertyName, [self class], [NSNumber class]);
                            continue;
                        }
                        
                        NSNumber *number = value;
                        
                        function(self, setter, [NSDate dateWithTimeIntervalSince1970:number.doubleValue]);
                    }
                    else {
                        
                        NSAssert([value isKindOfClass:propClass], @"Got the wrong type [%@] for property %@ on class %@, it should be %@", [value class], propertyName, [self class], propClass);
                        
                        function(self, setter, [value copy]);
                    }
                }
                else {
                    
                    if(!typeIsValid(type)) {
                        
                        NSAssert(NO, @"Type %@ on property %@ on class %@ is not supported", type, propertyName, [self class]);
                        continue;
                    }
                    
                    if([value isKindOfClass:[NSNull class]])
                        value = @(0);
                    
                    if(![value isKindOfClass:[NSNumber class]]) {
                        
                        NSAssert(NO, @"Got the wrong type [%@] for property %@ on class %@, it should be %@", [value class], propertyName, [self class], [NSNumber class]);
                        continue;
                    }
                    
                    NSNumber *number = value;
                    
#define TYPE_MATCH(type, typeCandidate) \
    (strcmp(type, @encode(typeCandidate)) == 0)

#define CALL_SETTER(self, setter, type, value) \
    { \
        void (*function)(id, SEL, type) = (void*)objc_msgSend; \
        function(self, setter, value); \
    }
                    
                    if(TYPE_MATCH(type.UTF8String, char)) {
                        
                        CALL_SETTER(self, setter, char, number.charValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, BOOL)) {
                        
                        CALL_SETTER(self, setter, BOOL, number.boolValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, int)) {
                        
                        CALL_SETTER(self, setter, int, number.intValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, short)) {
                        
                        CALL_SETTER(self, setter, short, number.shortValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, long)) {
                        
                        CALL_SETTER(self, setter, long, number.longValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, long long)) {
                        
                        CALL_SETTER(self, setter, long long, number.longLongValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, unsigned char)) {
                        
                        CALL_SETTER(self, setter, unsigned char, number.unsignedCharValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, unsigned int)) {
                        
                        CALL_SETTER(self, setter, unsigned int, number.unsignedIntValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, unsigned short)) {
                        
                        CALL_SETTER(self, setter, unsigned short, number.unsignedShortValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, unsigned long)) {
                        
                        CALL_SETTER(self, setter, unsigned long, number.unsignedLongValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, unsigned long long)) {
                        
                        CALL_SETTER(self, setter, unsigned long long, number.unsignedLongValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, float)) {
                        
                        CALL_SETTER(self, setter, float, number.floatValue);
                    }
                    else if(TYPE_MATCH(type.UTF8String, double)) {
                        
                        CALL_SETTER(self, setter, double, number.doubleValue);
                    }
                    else {
                        
                        NSAssert(NO, @"Unrecognized objCType '%s' for property %@ on class %@", [number objCType], propertyName, [self class]);
                    }
                }
            }
            else {
                
                missingProperties = missingProperties ?: [NSMutableArray array];
                
                [missingProperties addObject:[NSString stringWithFormat:@"@property (strong) %@ *%@;", [value class], propertyName]];
            }
        }
        
        NSAssert(missingProperties == nil, @"Class %@ is missing these properties:\n%@", [self class], [missingProperties componentsJoinedByString:@"\n"]);
    }
    
    return self;
}

- (NSString *)propertyNameFromDictionaryKey:(NSString *)dictionaryKey
{
    if([reservedKeywords() containsObject:dictionaryKey])
        return [@"_" stringByAppendingString:dictionaryKey];
    
    return dictionaryKey;
}

@end

static SEL getSetter(NSString *key)
{
    NSCAssert(key.length, @"Setter key must have length");
    
    NSString *letter = [key substringToIndex:1];
    NSString *remainder = [key substringFromIndex:1];
    
    NSString *result = [letter.uppercaseString stringByAppendingString:remainder];
    
    return NSSelectorFromString([NSString stringWithFormat:@"set%@:", result]);
}

static NSString *getType(Class cls, NSString *key)
{
    NSString *result = nil;
    
    objc_property_t property = class_getProperty(cls, key.UTF8String);
    
    char *type = property_copyAttributeValue(property, "T");
    
    if(type)
        result = [NSString stringWithUTF8String:type];
    
    free(type);
    
    return result;
}

static BOOL typeIsValid(NSString *type)
{
    static NSArray *validTypes;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        validTypes = @[@"c", @"i", @"s", @"l", @"q", @"f", @"C", @"I", @"S", @"L", @"Q", @"f", @"d", @"B"];
    });
    
    return [validTypes containsObject:type];
}

static BOOL isType(Class cls, Class superCls)
{
    for(; cls && cls != [NSObject class]; cls = class_getSuperclass(cls))
        if(cls == superCls)
            return YES;
    
    return NO;
}

static NSString *getIdType(NSString *type)
{
    if([type hasPrefix:@"@\""]) {
        
        if([type length] < 3) {
            
            NSCAssert(NO, @"Type %@ is too short", type);
            return nil;
        }
        
        type = [type substringFromIndex:2];
        type = [type substringToIndex:type.length - 1];
        
        return type;
    }
    
    return nil;
}

static NSString *arrayElementType(Class cls, NSString *key)
{
    key = [NSString stringWithFormat:@"__%@ElementType", key];
    
    return getType(cls, key);
}

static NSArray *reservedKeywords()
{
    static NSArray *array;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        array =
        @[
          @"auto",
          @"BOOL",
          @"break",
          @"Class",
          @"case",
          @"bycopy",
          @"char",
          @"byref",
          @"const",
          @"id",
          @"continue",
          @"IMP",
          @"default",
          @"in",
          @"do",
          @"inout",
          @"double",
          @"nil",
          @"else",
          @"NO",
          @"enum",
          @"NULL",
          @"extern",
          @"oneway",
          @"float",
          @"out",
          @"for",
          @"Protocol",
          @"goto",
          @"SEL",
          @"if",
          @"self",
          @"inline",
          @"super",
          @"int",
          @"YES",
          @"long",
          @"register",
          @"restrict",
          @"return",
          @"short",
          @"signed",
          @"sizeof",
          @"static",
          @"struct",
          @"switch",
          @"typedef",
          @"union",
          @"unsigned",
          @"void",
          @"volatile",
          @"while",
          @"_Bool",
          @"atomic",
          @"_Complex",
          @"nonatomic",
          @"_Imaginery",
          @"retain",
          ];
    });
    
    return array;
}

//
//  AutoSynthTests.m
//  AutoSynthTests
//
//  Created by Dustin Dettmer on 4/6/14.
//  Copyright (c) 2014 DustyTech. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Loadable.h"

@interface PrimativesModel : Loadable

@property (assign) BOOL a;
@property (assign) char b;
@property (assign) int c;
@property (assign) short d;
@property (assign) long e;
@property (assign) long long f;
@property (assign) unsigned char g;
@property (assign) unsigned int h;
@property (assign) unsigned short i;
@property (assign) unsigned long j;
@property (assign) unsigned long long k;
@property (assign) float l;
@property (assign) double m;

@end

@implementation PrimativesModel
@end

@interface DateModel : Loadable

@property (strong) NSDate *date;

@end

@implementation DateModel
@end

@interface InceptionModel : Loadable

@property (strong) InceptionModel *inception;
@property (strong) DateModel *model;
@property (strong) LoadableArray(PrimativesModel, primatives);
@property (strong) NSArray *numbers;
@property (strong) NSDictionary *dictionary;

@end

@implementation InceptionModel
@end

@interface KeywordsModel : Loadable

@property (assign) int _void;
@property (assign) int _char;
@property (assign) int _short;
@property (assign) int _int;
@property (assign) int _long;
@property (assign) int _float;
@property (assign) int _double;
@property (assign) int _signed;
@property (assign) int _unsigned;
@property (assign) int _id;
@property (assign) int _const;
@property (assign) int _volatile;
@property (assign) int _in;
@property (assign) int _out;
@property (assign) int _inout;
@property (assign) int _bycopy;
@property (assign) int _byref;
@property (assign) int _oneway;
@property (assign) int _self;
@property (assign) int _super;
@property (assign) int _default;

@end

@implementation KeywordsModel
@end

@interface AutoSynthTests : XCTestCase

@end

@implementation AutoSynthTests

- (NSDictionary*)primatives
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    for(int i = 1, letter = 'a'; letter <= 'm'; i++, letter++) {
        
        [dictionary setObject:@(i) forKey:[NSString stringWithFormat:@"%c", letter]];
    }
    
    return dictionary;
}

- (void)assertPrimative:(PrimativesModel*)model
{
    XCTAssertEqual(model.a, 1, @"");
    XCTAssertEqual(model.b, 2, @"");
    XCTAssertEqual(model.c, 3, @"");
    XCTAssertEqual(model.d, 4, @"");
    XCTAssertEqual(model.e, 5, @"");
    XCTAssertEqual(model.f, 6, @"");
    XCTAssertEqual(model.g, 7, @"");
    XCTAssertEqual(model.h, 8, @"");
    XCTAssertEqual(model.i, 9, @"");
    XCTAssertEqual(model.j, 10, @"");
    XCTAssertEqual(model.k, 11, @"");
    XCTAssertEqual(model.l, 12, @"");
    XCTAssertEqual(model.m, 13, @"");
}

- (void)testPrimitives
{
    PrimativesModel *model = [PrimativesModel withDictionary:[self primatives]];
    
    [self assertPrimative:model];
}

- (void)testDate
{
    NSDate *date = [NSDate date];
    
    DateModel *model = [DateModel withDictionary:@{@"date": @(date.timeIntervalSince1970)}];
    
    XCTAssertEqual(model.date.timeIntervalSince1970, date.timeIntervalSince1970, @"");
}

- (void)testInception
{
    NSDate *date = [NSDate date];
    
    id dictionary =
    @{
      @"model": @{@"date": @(date.timeIntervalSince1970)},
      @"inception":
          @{
              @"model": @{@"date": @(date.timeIntervalSince1970)},
              @"inception":
                  @{
                      @"model": @{@"date": @(date.timeIntervalSince1970)},
                      @"primatives":
                          @[[self primatives], [self primatives], [self primatives]],
                      @"numbers": @[ @(1), @(2), @(3), ],
                      @"dictionary": @{@"a": @(1)},
                      },
              },
      };
    
    InceptionModel *model = [InceptionModel withDictionary:dictionary];
    
    XCTAssertEqual(model.model.date.timeIntervalSince1970, date.timeIntervalSince1970, @"");
    XCTAssertEqual(model.inception.model.date.timeIntervalSince1970, date.timeIntervalSince1970, @"");
    XCTAssertEqual(model.inception.inception.model.date.timeIntervalSince1970, date.timeIntervalSince1970, @"");
    
    XCTAssertEqual(model.inception.inception.primatives.count, 3, @"");
    
    XCTAssertEqual(model.inception.inception.numbers.count, 3, @"");
    XCTAssertEqualObjects(model.inception.inception.numbers[0], @(1), @"");
    XCTAssertEqualObjects(model.inception.inception.numbers[1], @(2), @"");
    XCTAssertEqualObjects(model.inception.inception.numbers[2], @(3), @"");
    
    XCTAssertEqual(model.inception.inception.dictionary.count, 1, @"");
    XCTAssertEqualObjects(model.inception.inception.dictionary.allKeys.firstObject, @"a", @"");
    XCTAssertEqualObjects(model.inception.inception.dictionary.allValues.firstObject, @(1), @"");
    
    for(PrimativesModel *element in model.inception.inception.primatives)
        [self assertPrimative:element];
}

- (void)testKeywords
{
    id dictionary =
    @{
      @"void": @(7),
      @"char": @(7),
      @"short": @(7),
      @"int": @(7),
      @"long": @(7),
      @"float": @(7),
      @"double": @(7),
      @"signed": @(7),
      @"unsigned": @(7),
      @"id": @(7),
      @"const": @(7),
      @"volatile": @(7),
      @"in": @(7),
      @"out": @(7),
      @"inout": @(7),
      @"bycopy": @(7),
      @"byref": @(7),
      @"oneway": @(7),
      @"self": @(7),
      @"super": @(7),
      @"default": @(7),
      };
    
    KeywordsModel *model = [KeywordsModel withDictionary:dictionary];
    
    XCTAssertEqual(model._void, 7, @"");
    XCTAssertEqual(model._char, 7, @"");
    XCTAssertEqual(model._short, 7, @"");
    XCTAssertEqual(model._int, 7, @"");
    XCTAssertEqual(model._long, 7, @"");
    XCTAssertEqual(model._float, 7, @"");
    XCTAssertEqual(model._double, 7, @"");
    XCTAssertEqual(model._signed, 7, @"");
    XCTAssertEqual(model._unsigned, 7, @"");
    XCTAssertEqual(model._id, 7, @"");
    XCTAssertEqual(model._const, 7, @"");
    XCTAssertEqual(model._volatile, 7, @"");
    XCTAssertEqual(model._in, 7, @"");
    XCTAssertEqual(model._out, 7, @"");
    XCTAssertEqual(model._inout, 7, @"");
    XCTAssertEqual(model._bycopy, 7, @"");
    XCTAssertEqual(model._byref, 7, @"");
    XCTAssertEqual(model._oneway, 7, @"");
    XCTAssertEqual(model._self, 7, @"");
    XCTAssertEqual(model._super, 7, @"");
    XCTAssertEqual(model._default, 7, @"");
}

@end

//
//  AnimalInfo.m
//  CKToolbox
//
//  Created by Jonathan Crooke on 17/01/2016.
//  Copyright (c) 2016 Jonathan Crooke. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "AnimalInfo.h"

static NSDictionary <NSString *, NSString *> *mapping() {
  static NSDictionary *mapping = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    mapping = @{
                @"common"     : @"commonName",
                @"binomial"   : @"binomialName",
                @"population"	: @"population",
                @"image"      : @"imageName",
                @"info"       : @"info",
                @"url"        : @"URLString"
                };
  });
  return mapping;
}

@interface NSMutableArray (Shuffled)
- (void)_shuffle;
@end

@interface AnimalInfo ()
@property (copy, nonatomic, readwrite) NSString *commonName;
@property (copy, nonatomic, readwrite) NSString *binomialName;
@property (copy, nonatomic, readwrite) NSString *imageName;
@property (copy, nonatomic, readwrite) NSString *population;
@property (strong) NSString *URLString;
@property (copy, nonatomic, readwrite) NSString *info;
@end

@implementation AnimalInfo

+ (NSArray <AnimalInfo *> *)allAnimals
{
  NSURL *URL = [[NSBundle mainBundle] URLForResource:@"Animals" withExtension:@"plist"];
  NSArray *values = [NSArray arrayWithContentsOfURL:URL];
  NSMutableArray *animals = [NSMutableArray array];
  for (NSDictionary *value in values) {
    [animals addObject:[[AnimalInfo alloc] initWithDictionary:value]];
  }
  [animals _shuffle];
  return animals.copy;
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary
{
  if ((self = [super init])) {
    [mapping() enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                                   NSString * _Nonnull value,
                                                   BOOL * _Nonnull stop)
    {
      [self setValue:dictionary[key] forKey:value];
    }];
  }
  return self;
}

- (UIImage *)image {
  return [UIImage imageNamed:[self.imageName stringByAppendingPathExtension:@"jpg"]];
}

- (NSURL *)URL {
  return [NSURL URLWithString:self.URLString];
}

@end

@implementation NSMutableArray (Shuffled)

- (void)_shuffle {
  for (NSUInteger i = 0; i < self.count - 2; ++i) {
    [self exchangeObjectAtIndex:i withObjectAtIndex:i + (arc4random() % self.count - i)];
  }
}

@end

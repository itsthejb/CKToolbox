//
//  CKVisualEffectComponentSpecs.m
//  CKToolbox
//
//  Created by Jonathan Crooke on 07/02/2016.
//  Copyright © 2016 Jonathan Crooke. All rights reserved.
//

#import <ComponentSnapshotTestCase/CKComponentSnapshotTestCase.h>
#import <ComponentKit/ComponentKit.h>
#import <CKToolbox/CKVisualEffectComponent.h>

@interface CKVisualEffectComponentSpecs : CKComponentSnapshotTestCase
@property CKComponent *component;
@property CKComponent *imageComponent;
@end

@implementation CKVisualEffectComponentSpecs

- (void)testItShouldHaveExpectedAppearForBlurView
{
  self.component =
  [CKOverlayLayoutComponent
   newWithComponent:self.imageComponent
   overlay:
   [CKVisualEffectComponent
    newWithVisualEffect:[UIBlurEffect new]
    component:nil]];
}

- (void)setUp {
  [super setUp];

  UIImage *image = [[UIImage alloc]
                    initWithContentsOfFile:[[NSBundle bundleForClass:[self class]]
                                            pathForResource:@"Sumatran-Tiger-Hero"
                                            ofType:@"jpg"]];

  self.imageComponent =
  [CKRatioLayoutComponent
   newWithRatio:image.size.height / image.size.width
   size:{}
   component:
   [CKComponent
    newWithView:{
      [UIImageView class], {
        {@selector(setImage:), image},
        {@selector(setContentMode:), @(UIViewContentModeScaleAspectFill)}
      }
    }
    size:{}]];
}

- (void)tearDown {
  self.recordMode = YES;
  CKSizeRange sizeRange = {{320, 0}, {320, INFINITY}};
  CKSnapshotVerifyComponent(self.component, sizeRange, nil);
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

@end

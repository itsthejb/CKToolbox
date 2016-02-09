//
//  AnimalComponent.m
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

#import "AnimalComponent.h"
#import "AnimalOverlayComponent.h"
#import "AnimalInfo.h"
#import "AnimalComponentResponder.h"
#import <ComponentKit/ComponentKit.h>
#import <ComponentKit/CKOptimisticViewMutations.h>
#import <ComponentKit/CKComponentSubclass.h>

static UIViewContentMode kImageContentMode = UIViewContentModeScaleAspectFill;

@interface AnimalComponent ()
@property (nonatomic, strong, readwrite) AnimalInfo *model;
@property (nonatomic, strong, readwrite) AnimalOverlayComponent *overlay;
@end

NS_INLINE CKComponent *imageComponent(UIImage *image)
{
  return
  [CKRatioLayoutComponent
   newWithRatio:image.size.height / image.size.width
   size:{}
   component:
   [CKComponent newWithView:{
    [UIImageView class],
    {
      {@selector(setUserInteractionEnabled:), @YES},
      {@selector(setImage:), image},
      {@selector(setClipsToBounds:), @YES},
      {@selector(setContentMode:), @(kImageContentMode)},
      CKComponentTapGestureAttribute(CKComponentAction(@selector(didTap:)))
    }
  } size:{}]];
}

@implementation AnimalComponent

+ (id)initialState {
  return @(AnimalComponentOverlayShowNo);
}

+ (instancetype)newWithAnimal:(AnimalInfo*)animal
{
  CKComponentScope scope(self, animal.binomialName);
  AnimalComponent *component = nil;

  BOOL showOverlay = [scope.state() boolValue];
  if (showOverlay) {
    AnimalOverlayComponent *overlay = [AnimalOverlayComponent newWithAnimal:animal];
    component =
    [self
     newWithComponent:
     [CKBackgroundLayoutComponent
      newWithComponent:overlay
      background:imageComponent(animal.image)]];
    component.overlay = overlay;
  } else {
    component = [self newWithComponent:imageComponent(animal.image)];
  }

  component.model = animal;
  return component;
}

#pragma mark Animations

- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(AnimalComponent *)previousComponent
{
  return {CKComponentAnimationHooks({
    .willRemount = ^NSArray <UIView *> *{
      UIView *blurView = [AnimalOverlayComponent blurView];
      UIImageView *imageView = [[UIImageView alloc] initWithImage:self.model.image];
      imageView.frame = blurView.frame = previousComponent.viewContext.frame;
      imageView.contentMode = kImageContentMode;
      imageView.clipsToBounds = YES;
      return @[imageView, blurView];
    },
    .didRemount = ^id (NSArray <UIView *> *overlays) {
      UIView *imageView = overlays.firstObject;
      UIView *blurView = overlays.lastObject;

      self.viewContext.view.alpha =
      // UIVisualEffectView
      blurView.alpha =
      previousComponent.overlay.textComponent.viewContext.view.alpha = !self.overlay;

      [self.viewContext.view.superview insertSubview:imageView belowSubview:self.viewContext.view];
      [self.viewContext.view.superview insertSubview:blurView aboveSubview:imageView];
      self.viewContext.view.alpha = 0.0;

      [UIView animateWithDuration:0.3 animations:^{
        imageView.frame = blurView.frame = self.viewContext.frame;
        blurView.alpha = !!self.overlay;
      } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
          self.viewContext.view.alpha = 1.0;
        } completion:^(BOOL finished) {
          [overlays makeObjectsPerformSelector:@selector(removeFromSuperview)];
        }];
      }];
      return nil;
    },
  })};
}

@end

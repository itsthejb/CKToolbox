//
//  AnimalOverlayComponent.m
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

#import "AnimalOverlayComponent.h"
#import "AnimalInfo.h"
#import <ComponentKit/CKComponentSubclass.h>

UIView *blurFactory() {
  return [AnimalOverlayComponent blurView];
}

static CKComponent *label(NSString *text, UIFont *font, NSTextAlignment alignment = NSTextAlignmentLeft) {
  return [CKLabelComponent newWithLabelAttributes:{
    .string = text,
    .font = font,
    .color = [UIColor lightGrayColor],
    .alignment = alignment
  } viewAttributes:{
    {@selector(setBackgroundColor:), [UIColor clearColor]},
    {@selector(setOpaque:), @NO}
  } size:{}];
}

static CKComponent *textComponent(AnimalInfo *info)
{
  std::vector<std::vector<CKStackLayoutComponentChild>> columns = {
    std::vector<CKStackLayoutComponentChild>(),
    std::vector<CKStackLayoutComponentChild>()
  };

  auto it = columns.begin();
  NSArray *sections = [info.info componentsSeparatedByString:@"\n\n"];
  [sections enumerateObjectsUsingBlock:^(NSString * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop)
  {
    NSArray *components = [section componentsSeparatedByString:@"\n"];
    NSCAssert(components.count == 2, components.description);

    auto column = &(*(it + (idx % columns.size())));
    column->insert(column->end(), {
      {
        .spacingBefore = 10,
        .component = label(components[0], [UIFont boldSystemFontOfSize:12])
      },
      { .component = label(components[1], [UIFont systemFontOfSize:12]), }
    });
  }];

  return
  [CKStackLayoutComponent
   newWithView:{
     [UIView class],
     {
       {@selector(setBackgroundColor:), [UIColor clearColor]},
       {@selector(setOpaque:), @NO}
     }
   }
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .alignItems = CKStackLayoutAlignItemsStretch
   }
   children:{
     {
       .component = label(info.commonName, [UIFont boldSystemFontOfSize:16], NSTextAlignmentCenter)
     },
     {
       .component = label(info.binomialName, [UIFont italicSystemFontOfSize:12], NSTextAlignmentCenter)
     },
     {
       .spacingBefore = 10,
       .component = label(@"Population", [UIFont boldSystemFontOfSize:16], NSTextAlignmentCenter),
     },
     {
       .component = label(info.population, [UIFont systemFontOfSize:12], NSTextAlignmentCenter)
     },
     {
       .spacingBefore = 10,
       .component = [CKComponent newWithView:{
         [UIView class],
         {
           {@selector(setBackgroundColor:), [UIColor lightGrayColor]}
         }
       } size:{
         .height = 1.0 / [UIScreen mainScreen].scale,
         .width = CKRelativeDimension::Percent(1.0)
       }]
     },
     {
       .component =
       [CKStackLayoutComponent
        newWithView:{}
        size:{}
        style:{
          .direction = CKStackLayoutDirectionHorizontal,
          .spacing = 10
        }
        children:{
          {
            .component = [CKStackLayoutComponent
                          newWithView:{}
                          size:{
                            .width = CKRelativeDimension::Percent(sections.count == 1 ? 1.0 : 0.5)
                          }
                          style:{}
                          children:columns[0]]
          },
          {
            .component = [CKStackLayoutComponent
                          newWithView:{}
                          size:{
                            .width = CKRelativeDimension::Percent(sections.count == 1 ? 0.0 : 0.5)
                          }
                          style:{}
                          children:columns[1]]
          }
        }]
     }}];
}

@interface AnimalOverlayComponent ()
@property (nonatomic, strong, readwrite) CKComponent *textComponent;
@end

@implementation AnimalOverlayComponent

+ (instancetype)newWithAnimal:(AnimalInfo*)animal {
  CKComponent *text = textComponent(animal);
  AnimalOverlayComponent *component =
  [self
   newWithView:{ blurFactory }
   component:
   [CKInsetComponent
    newWithInsets:UIEdgeInsetsMake(20, 20, 20, 20)
    component:
    [CKInsetComponent
     newWithInsets:UIEdgeInsetsMake(10, 10, 10, 10)
     component:
     [CKCenterLayoutComponent
      newWithCenteringOptions:CKCenterLayoutComponentCenteringY
      sizingOptions:CKCenterLayoutComponentSizingOptionDefault
      child:text
      size:{}]]]];
  component.textComponent = text;
  return component;
}

+ (UIView*)blurView
{
  // UIVisualEffectView will complain if we try to manipulate its alpha
  // (although it seems to look fine)
  // avoid this by putting it in a container view
  UIView *container = [UIView new];
  container.userInteractionEnabled = NO;
  [container addSubview:^{
    UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:
                                [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    return view;
  }()];
  return container;
}

@end

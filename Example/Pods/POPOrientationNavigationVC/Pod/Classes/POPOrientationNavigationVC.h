//
//  POPOrientationNavigationVC.h
//  CommonLib
//
//  Created by popeveryday on 7/3/14.
//  Copyright (c) 2014 Lapsky. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GTScrollNavigationBar;

@interface POPOrientationNavigationVC : UINavigationController

@end


typedef enum {
    GTScrollNavigationBarNone,
    GTScrollNavigationBarScrollingDown,
    GTScrollNavigationBarScrollingUp
} GTScrollNavigationBarState;

@interface GTScrollNavigationBar : UINavigationBar

@property (strong, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) GTScrollNavigationBarState scrollState;

- (void)resetToDefaultPositionWithAnimation:(BOOL)animated;

@end

//PUT THESE LINES IN YOUR VIEWCONTROLLER TO HANDLE ORIENTATION
//#pragma manage orientation
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    // Return YES for supported orientations
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
//}
//
//- (BOOL)shouldAutorotate  // iOS 6 autorotation fix
//{
//    return YES;
//}
//
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations // iOS 6 autorotation fix
//{
//    return UIInterfaceOrientationMaskPortrait;
//}
//
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation // iOS 6 autorotation fix
//{
//    return UIInterfaceOrientationPortrait;
//}
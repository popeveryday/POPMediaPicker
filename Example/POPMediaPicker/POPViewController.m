//
//  POPViewController.m
//  POPMediaPicker
//
//  Created by popeveryday on 02/11/2016.
//  Copyright (c) 2016 popeveryday. All rights reserved.
//

#import "POPViewController.h"
#import <POPMediaPicker/POPMediaPicker.h>
#import <POPLib/POPLib.h>

@interface POPViewController ()<POPMediaPickerDelegate>

@end

@implementation POPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Add Media" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(addMedia:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, 140, 40);
    button.center = self.view.center;
    [self.view addSubview:button];
    
    LocalizedDefaultLanguageCode(@"vi");
}

-(void) addMedia:(id)sender{
    POPMediaPickerVC* picker = [[POPMediaPickerVC alloc] initWithSourceAlbum:POPMediaPickerAlbumCameraRollOnly mediaType:POPMediaPickerFileTypeAll];
//    picker.returnOnSelectSingleItem = YES;
    picker.itemOrderDescending = YES;
    picker.showCaptureButton = YES;
    picker.popMediaPickerDelegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma POPMediaPicker delegate functions

//implement to show Image Capture Button (showCaptureButton = YES)
-(void)popMediaPickerDidSaveCaptureImage:(UIImage *)image picker:(POPMediaPickerVC *)picker{
    
}

//implement to show Video Record Button (showCaptureButton = YES)
-(void)popMediaPickerDidSaveRecordVideoToTempFolder:(NSString *)file picker:(POPMediaPickerVC *)picker{
    
}

//implement to handle saved files to temp folder
-(void)popMediaPickerDidSaveFilesToTempFolder:(NSMutableArray *)savedFiles picker:(POPMediaPickerVC *)picker
{
    
}

//OR implement to handle saved files to temp folder
//-(void)popMediaPickerDidSaveOneFileToTempFolder:(NSString *)file picker:(POPMediaPickerVC *)picker{}

//OR implement to handle after files selected and before save files to temp folder
//-(void)popMediaPickerDidSelectedImageAssets:(NSMutableArray *)imageAssets picker:(POPMediaPickerVC *)picker{}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

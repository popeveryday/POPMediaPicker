//
//  POPMediaPickerVC.h
//  DemoMultiImagePicker
//
//  Created by popeveryday on 5/14/14.
//  Copyright (c) 2014 Lapsky. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AssetsLibrary;
#import <POPLib/POPLib.h>
#import <POPOrientationNavigationVC/POPOrientationNavigationVC.h>
#import <MBProgressHUD/MBProgressHUD.h>

enum POPMediaPickerFileType
{
    POPMediaPickerFileTypeAll,
    POPMediaPickerFileTypeImageOnly,
    POPMediaPickerFileTypeVideoOnly,
};

enum POPMediaPickerAlbum
{
    POPMediaPickerAlbumAll,
    POPMediaPickerAlbumLocalOnly,
    POPMediaPickerAlbumShareOnly,
    POPMediaPickerAlbumCameraRollOnly,
};



@class POPMediaPicker_AlbumVC;
@class POPMediaPickerVC;

@protocol POPMediaPickerCustomCameraDelegate <NSObject>

@optional
-(void) POPMediaPickerCustomCameraDoneWithImage:(UIImage*)image;
-(void) POPMediaPickerCustomCameraDoneVideoPath:(NSString*)videoPath;
-(void) POPMediaPickerCustomCameraDidCancelWith:(UIViewController*) cameraController;


@end


@protocol POPMediaPickerDelegate <NSObject>

@optional
-(void) popMediaPickerDidSelectedImageAssets:(NSMutableArray*)imageAssets picker:(POPMediaPickerVC*)picker;
-(void) popMediaPickerDidCancel:(POPMediaPickerVC*)picker;

-(void) popMediaPickerDidSaveFilesToTempFolder:(NSMutableArray*)savedFiles picker:(POPMediaPickerVC*)picker;
-(void) popMediaPickerDidSaveOneFileToTempFolder:(NSString*)file picker:(POPMediaPickerVC*)picker;

-(void) popMediaPickerDidSaveCaptureImage:(UIImage*)image picker:(POPMediaPickerVC*)picker;
-(void) popMediaPickerDidSaveRecordVideoToTempFolder:(NSString*)file picker:(POPMediaPickerVC*)picker;

//call custom camera photo/video after close picker
-(void) popMediaPickerProcessCustomCaptureImage:(POPMediaPickerVC*)picker;
-(void) popMediaPickerProcessCustomRecordVideo:(POPMediaPickerVC*)picker;

//return controller that process capture/record and have to implement POPMediaPickerCustomCameraDelegate
-(UIViewController*) popMediaPickerReturnCustomCaptureImageController:(id<POPMediaPickerCustomCameraDelegate>)delegate picker:(POPMediaPickerVC*)picker;
-(UIViewController*) popMediaPickerReturnCustomRecordVideoController:(id<POPMediaPickerCustomCameraDelegate>)delegate picker:(POPMediaPickerVC*)picker;

-(void) popMediaPickerDidDisappear:(POPMediaPickerVC*)advPicker;


@end




@interface POPMediaPickerVC : POPOrientationNavigationVC
@property (nonatomic) id<POPMediaPickerDelegate> popMediaPickerDelegate;
@property (nonatomic) UIPopoverController* popoverContainer;
@property (nonatomic, readonly) BOOL isViewAsPopoverController;

@property (nonatomic) enum POPMediaPickerAlbum sourceAlbum;
@property (nonatomic) enum POPMediaPickerFileType mediaType;
@property (nonatomic) BOOL returnOnSelectSingleItem;
@property (nonatomic) BOOL itemOrderDescending;
@property (nonatomic) BOOL showCaptureButton;

-(id) initWithSourceAlbum:(enum POPMediaPickerAlbum) sourceAlbum mediaType:(enum POPMediaPickerFileType) mediaType;

-(void) cancelAction:(id)sender;
-(void) doneActionWithAssetImage:(NSMutableArray*)assetImages;
-(void) SetNavigationBarColor:(UIColor*)color;
-(void) SetNavigationBarColorHex:(NSString*)colorhex;

-(void) closeView;

@end


@interface POPMediaPicker_AlbumVC : UITableViewController
@property (nonatomic) ALAssetsLibrary *assetsLibrary;
@property (nonatomic) NSMutableArray *groups;
@property (nonatomic) POPMediaPickerVC* rootController;
@end

@interface POPMediaPicker_AlbumDetailVC : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, POPMediaPickerCustomCameraDelegate>

@property (nonatomic) UICollectionView* collectionView;

@property (nonatomic) NSMutableArray *assets;
@property (nonatomic) ALAssetsGroup *assetsGroup;

@property (nonatomic) POPMediaPickerVC* rootController;

@end

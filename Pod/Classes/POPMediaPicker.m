//
//  POPMediaPickerVC.m
//  DemoMultiImagePicker
//
//  Created by popeveryday on 5/14/14.
//  Copyright (c) 2014 Lapsky. All rights reserved.
//

#import "POPMediaPicker.h"
#import <MobileCoreServices/UTCoreTypes.h>

@interface POPMediaPickerVC ()

@end

@implementation POPMediaPickerVC{
    MBProgressHUD* loading;
    BOOL isExistAndExecuteDelegate;
    BOOL isExecutePhotoDelegate;
}


-(id) initWithSourceAlbum:(enum POPMediaPickerAlbum) sourceAlbum mediaType:(enum POPMediaPickerFileType) mediaType
{
    
    if (sourceAlbum == POPMediaPickerAlbumCameraRollOnly)
    {
        POPMediaPicker_AlbumDetailVC* rootView = [[POPMediaPicker_AlbumDetailVC alloc] init];
        rootView.rootController = self;
        self = [super initWithRootViewController:rootView];
    }else{
        POPMediaPicker_AlbumVC* rootView = [[POPMediaPicker_AlbumVC alloc] initWithStyle:UITableViewStylePlain];
        rootView.rootController = self;
        self = [super initWithRootViewController:rootView];
    }
    
    if (self) {
        self.mediaType = mediaType;
        self.sourceAlbum = sourceAlbum;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void) viewDidDisappear:(BOOL)animated{
    [self popToRootViewControllerAnimated:YES];
    
    if(isExistAndExecuteDelegate){
        if (isExecutePhotoDelegate && [_popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerProcessCustomCaptureImage:)])
        {
            [_popMediaPickerDelegate popMediaPickerProcessCustomCaptureImage:self];
        }
        else if (isExecutePhotoDelegate == NO && [_popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerProcessCustomRecordVideo:)])
        {
            [_popMediaPickerDelegate popMediaPickerProcessCustomRecordVideo:self];
        }
    }
    
    if (_popMediaPickerDelegate && [_popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidDisappear:)]) {
        [_popMediaPickerDelegate popMediaPickerDidDisappear:self];
    }
}


-(void) closeView
{
    self.delegate = nil;
    
    if (GC_Device_IsIpad && _isViewAsPopoverController)
    {
        [_popoverContainer dismissPopoverAnimated:YES];
        [_popoverContainer.delegate popoverControllerDidDismissPopover:_popoverContainer];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void) closeViewAndExecuteCustomCapture:(BOOL)isPhoto
{
    isExistAndExecuteDelegate = YES;
    isExecutePhotoDelegate = isPhoto;
    [self closeView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) cancelAction:(id)sender
{
    if ([_popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidCancel:)]) {
        [_popMediaPickerDelegate popMediaPickerDidCancel:self];
    }
    [self closeView];
}

-(void) doneActionWithAssetImage:(NSMutableArray*)assetImages{
    if ([self.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSelectedImageAssets:picker:)]) {
        [self.popMediaPickerDelegate popMediaPickerDidSelectedImageAssets:assetImages picker:self];
    }
    
    if ([_popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveFilesToTempFolder:picker:)]
        || [_popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveOneFileToTempFolder:picker:)])
    {
        [self saveImageToTempFolder:assetImages];
    }else{
        [self closeView];
    }
    
    
}



-(void)saveImageToTempFolder:(NSMutableArray*) assets
{
    loading = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:loading];
    loading.labelText = @"Saving Images";
    loading.detailsLabelText = @"please wait";
    loading.square = YES;
    [loading show:YES];
    
    //remove all file
    NSString* path = [FileLib GetTempPath:@"POPMediaPickerVC"];
    [FileLib RemoveFileOrDirectory:path];
    [FileLib CreateDirectory:path];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveImage:assets index:0 savedFiles:[[NSMutableArray alloc] init]];
    });
}

-(void)saveImage:(NSMutableArray*) assets index:(NSInteger) index savedFiles:(NSMutableArray*)savedFiles{
    
    if (index >= assets.count){
        if ([_popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveFilesToTempFolder:picker:)]) {
            [_popMediaPickerDelegate popMediaPickerDidSaveFilesToTempFolder:savedFiles picker:self];
        }
        
        [loading hide:YES];
        
        [self closeView];
        
        return;
    }
    
    loading.detailsLabelText = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)index+1, (unsigned long)assets.count];
    
    @autoreleasepool
    {
        NSString* originalFileName = [[assets[index] defaultRepresentation] filename];
        
        
        NSString* saveFile = [FileLib GetTempPath:@"POPMediaPickerVC" autoCreateDir:YES];//[FileLib GetNewName:@"image_" suffix: @".jpg"];
        
        saveFile = [saveFile stringByAppendingPathComponent:originalFileName];
        
        if ([self exportDataToURL:saveFile error:nil andAsset:assets[index]]) {
            if ([FileLib GetFileSizeWithPath:saveFile] > 0) {
                [savedFiles addObject:saveFile];
                
                if ([_popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveOneFileToTempFolder:picker:)]) {
                    [_popMediaPickerDelegate popMediaPickerDidSaveOneFileToTempFolder:saveFile picker:self];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveImage:assets index:index+1 savedFiles:savedFiles];
        });
    }
}

- (BOOL) exportDataToURL: (NSString*) filePath error: (NSError**) error andAsset:(ALAsset*)asset
{
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!handle) {
        return NO;
    }
    
    static const NSUInteger BufferSize = 1024*1024;
    
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
    NSUInteger offset = 0, bytesRead = 0;
    
    do {
        @try {
            bytesRead = [rep getBytes:buffer fromOffset:offset length:BufferSize error:error];
            [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
            offset += bytesRead;
        } @catch (NSException *exception) {
            free(buffer);
            
            return NO;
        }
    } while (bytesRead > 0);
    
    free(buffer);
    return YES;
}

-(void) setPopoverContainer:(UIPopoverController *)popoverContainer{
    _popoverContainer = popoverContainer;
    _isViewAsPopoverController = YES;
}

-(void) SetNavigationBarColor:(UIColor*)color
{
    [ViewLib setNavigationBarColor:color viewController:self.viewControllers.firstObject];
}

-(void) SetNavigationBarColorHex:(NSString*)colorhex
{
    [ViewLib setNavigationBarColorHex:colorhex viewController:self.viewControllers.firstObject];
}


@end


//======================================================================================================================

@interface POPMediaPicker_AlbumVC ()

@end

@implementation POPMediaPicker_AlbumVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Photo Library";
    
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.rootController action:@selector(cancelAction:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    

    _assetsLibrary = [[ALAssetsLibrary alloc] init];
    _groups = [[NSMutableArray alloc] init];
    
    // setup our failure view controller in case enumerateGroupsWithTypes fails
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error)
    {
        NSString *errorMessage = nil;
        switch ([error code]) {
            case ALAssetsLibraryAccessUserDeniedError:
            case ALAssetsLibraryAccessGloballyDeniedError:
                errorMessage = @"The user has declined access to it.";
                break;
            default:
                errorMessage = @"Reason unknown.";
                break;
        }
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Load Photo Library Failure!" message:@"Photo Library isn't accessable.\nPlease enable it form the iOS Settings app > Privacy > Photo > Turn on" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
    };
    
    // emumerate through our groups and only add groups that contain photos
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop)
    {
        if (self.rootController.mediaType == POPMediaPickerFileTypeImageOnly) {
            [group setAssetsFilter: [ALAssetsFilter allPhotos]];
        }else if (self.rootController.mediaType == POPMediaPickerFileTypeVideoOnly) {
            [group setAssetsFilter: [ALAssetsFilter allVideos]];
        }else{
            [group setAssetsFilter: [ALAssetsFilter allAssets]];
        }
        
        if ([group numberOfAssets] > 0)
        {
            [self.groups addObject:group];
        }
        else
        {
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        }
    };
    
    // enumerate photo
    NSUInteger groupTypes = ALAssetsGroupAll;
    if( self.rootController.sourceAlbum == POPMediaPickerAlbumLocalOnly )
        groupTypes = ALAssetsGroupLibrary | ALAssetsGroupSavedPhotos | ALAssetsGroupAlbum;
    if( self.rootController.sourceAlbum == POPMediaPickerAlbumCameraRollOnly )
        groupTypes = ALAssetsGroupSavedPhotos;
    if( self.rootController.sourceAlbum == POPMediaPickerAlbumShareOnly )
        groupTypes = ALAssetsGroupPhotoStream;
    
    [self.assetsLibrary enumerateGroupsWithTypes:groupTypes usingBlock:listGroupBlock
                                    failureBlock:failureBlock];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.groups.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
    
    ALAssetsGroup *groupForCell = self.groups[indexPath.row];
    CGImageRef posterImageRef = [groupForCell posterImage];
    UIImage *posterImage = [UIImage imageWithCGImage:posterImageRef];
    cell.imageView.image = posterImage;
    cell.textLabel.text = [groupForCell valueForProperty:ALAssetsGroupPropertyName];
    cell.detailTextLabel.text = [@(groupForCell.numberOfAssets) stringValue];
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    POPMediaPicker_AlbumDetailVC* view = [[POPMediaPicker_AlbumDetailVC alloc] init];
    view.assetsGroup = self.groups[[self.tableView indexPathForSelectedRow].row];
    view.rootController = self.rootController;
    [self.navigationController pushViewController:view animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}


@end



//======================================================================================================================
//======================================================================================================================



#define imgNameCapture @"POPMediaPickerCapture"
#define imgNameRecord @"POPMediaPickerRecord"

@interface POPMediaPicker_AlbumDetailVC ()

@end

@implementation POPMediaPicker_AlbumDetailVC{
    UILabel* labelToolbar;
    UIBarButtonItem* doneButton;
    CGSize cellSize;
    ALAssetsLibrary *assetsLibrary;
    BOOL isInitAsset;
}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    cellSize = self.rootController.isViewAsPopoverController ? CollectionViewItem_Size(NO) : GC_CollectionViewItem_Size;
    
    
    //collectionview
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    [flow setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flow setItemSize: cellSize];
    [flow setMinimumInteritemSpacing:0];
    [flow setMinimumLineSpacing:4];
    [flow setSectionInset:UIEdgeInsetsMake(4, 4, 4, 4)];
    
    
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:flow];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.allowsMultipleSelection = YES;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview: _collectionView];
    
    //toolbar
    if (self.rootController.returnOnSelectSingleItem == NO) {
        UIBarButtonItem* selectButton = [[UIBarButtonItem alloc] initWithTitle:@"Select All" style:UIBarButtonItemStylePlain target:self action:@selector(selectAllAction:)];
        UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self.rootController action:@selector(cancelAction:)];
        
        labelToolbar = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
        labelToolbar.textAlignment = NSTextAlignmentCenter;
        UIBarItem* titleItem = [[UIBarButtonItem alloc] initWithCustomView:labelToolbar];
        
        UIBarItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        [self.navigationController setToolbarHidden:NO animated:NO];
        [self setToolbarItems:@[selectButton, space, titleItem, space, cancelButton]];
        
        //done button
        doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }else{
        [self.navigationController setToolbarHidden:YES animated:NO];
        //cancel button
        doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.rootController action:@selector(cancelAction:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    
    //if quick select form camera roll -> get camera roll library
    if (self.assetsGroup == nil) {
        // setup our failure view controller in case enumerateGroupsWithTypes fails
        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error)
        {
            NSString *errorMessage = nil;
            switch ([error code]) {
                case ALAssetsLibraryAccessUserDeniedError:
                case ALAssetsLibraryAccessGloballyDeniedError:
                    errorMessage = @"The user has declined access to it.";
                    break;
                default:
                    errorMessage = @"Reason unknown.";
                    break;
            }
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Load Photo Library Failure!" message:@"Photo Library isn't accessable.\nPlease enable it form the iOS Settings app > Privacy > Photo > Turn on" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            
        };
        
        // emumerate through our groups and only add groups that contain photos
        ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop)
        {
            if (self.rootController.mediaType == POPMediaPickerFileTypeImageOnly) {
                [group setAssetsFilter: [ALAssetsFilter allPhotos]];
            }else if (self.rootController.mediaType == POPMediaPickerFileTypeVideoOnly) {
                [group setAssetsFilter: [ALAssetsFilter allVideos]];
            }else{
                [group setAssetsFilter: [ALAssetsFilter allAssets]];
            }
            
            if ([group numberOfAssets] > 0 && self.assetsGroup == nil)
            {
                self.assetsGroup = group;
            }
            
            [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
        };

        assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:listGroupBlock
                                        failureBlock:failureBlock];
        
    }else [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
    
    
    //validate delegate
    if (self.rootController.showCaptureButton
        && ![self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveCaptureImage:picker:)]
        && ![self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveRecordVideoToTempFolder:picker:)]
        && ![self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerProcessCustomCaptureImage:)]
        && ![self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerProcessCustomRecordVideo:)]
        )
    {
        [[[UIAlertView alloc] initWithTitle:@"Delegate Invalidate" message:@"showCaptureButton = true\nRequire one of following delegates:\n - popMediaPickerDidSaveCaptureImage\n - popMediaPickerDidSaveRecordVideoToTempFolder\n - popMediaPickerProcessCustomCaptureImage\n - popMediaPickerProcessCustomRecordVideo"
                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
    
    if (![self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveFilesToTempFolder:picker:)]
        && ![self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveOneFileToTempFolder:picker:)]
        && ![self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSelectedImageAssets:picker:)]
        )
    {
        [[[UIAlertView alloc] initWithTitle:@"Delegate Invalidate" message:@"Done button require one of following delegates:\n - popMediaPickerDidSaveFilesToTempFolder\n - popMediaPickerDidSaveOneFileToTempFolder\n - popMediaPickerDidSelectedImageAssets"
                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}


-(void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:NO];
}


- (void)preparePhotos
{
    if (isInitAsset) return;
    isInitAsset = YES;
    
    @autoreleasepool {
        
        if (!self.assets) {
            _assets = [[NSMutableArray alloc] init];
        } else {
            [self.assets removeAllObjects];
        }
        
        ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop)
        {
            if (result) {
                if (self.rootController.itemOrderDescending) {
                    [self.assets insertObject:result atIndex:0];
                }else{
                    [self.assets addObject:result];
                }
            }
        };
        [self.assetsGroup enumerateAssetsUsingBlock:assetsEnumerationBlock];
        
        //insert custom buttons to assets
        if([self isSuitableDisplayButton:NO]){
            if (self.rootController.itemOrderDescending) [self.assets insertObject:imgNameRecord atIndex:0];
            else [self.assets addObject:imgNameRecord];
        }
        
        if([self isSuitableDisplayButton:YES]){
            if (self.rootController.itemOrderDescending) [self.assets insertObject:imgNameCapture atIndex:0];
            else [self.assets addObject:imgNameRecord];
        }
        

        dispatch_sync(dispatch_get_main_queue(), ^{
            [_collectionView reloadData];
            // scroll to bottom if show ascending items
            if (!self.rootController.itemOrderDescending) {
                NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:_assets.count-1 inSection:0];
                [_collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            }
            
            self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
            [self updateTitle];
        });
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma action functions
-(void) doneAction:(id)sender{
    

    NSMutableArray* result = [[NSMutableArray alloc] init];
    for(NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems)
    {
        [result addObject: _assets[ indexPath.row ] ];
    }
    
    [self.rootController doneActionWithAssetImage:result];
}

-(void) selectAllAction:(id)sender{
    if ( [((UIBarButtonItem*)sender).title isEqualToString:@"Select All"] ) {
        
        for (int i = 0; i < _assets.count; i++) {
            [_collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        }
        
        
        [((UIBarButtonItem*)sender) setTitle:@"Deselect All"];
    }else{
        
        for(NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        
        [((UIBarButtonItem*)sender) setTitle:@"Select All"];
    }
    
    [self updateTitle];
}

-(BOOL) isSuitableDisplayButton:(BOOL) isPhotoButton{
    if (!self.rootController.showCaptureButton) return NO;
    
    if( isPhotoButton
       && (self.rootController.mediaType == POPMediaPickerFileTypeAll || self.rootController.mediaType == POPMediaPickerFileTypeImageOnly)
       && (
           [self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveCaptureImage:picker:)]
           || [self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerProcessCustomCaptureImage:)]
    || [self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerReturnCustomCaptureImageController:picker:)]
           ) )
    {
        return YES;
    }
    
    if( isPhotoButton == NO
       && (self.rootController.mediaType == POPMediaPickerFileTypeAll || self.rootController.mediaType == POPMediaPickerFileTypeVideoOnly)
       && (
        [self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveRecordVideoToTempFolder:picker:)]
           || [self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerProcessCustomRecordVideo:)]
           || [self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerReturnCustomRecordVideoController:picker:)]
           )
       
       )
    {
        return YES;
    }
    
    return NO;
}



#pragma collectionView functions
-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    UIImage *thumbnail;
    UIImageView* videoIcon;
    UILabel* videoTime;
    
    if ([cell viewWithTag:100] == nil) {
        videoIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"POPMediaPickerVideo"]];
        videoIcon.tag = 100;
        videoIcon.frame = CGRectMake(0, 0, 60, 60);
        [cell addSubview:videoIcon];
        
        
        videoTime = [[UILabel alloc] initWithFrame:CGRectMake(cellSize.width - 62, cellSize.height - 20, 58, 20)];
        videoTime.tag = 101;
        videoTime.shadowColor = [UIColor grayColor];
        videoTime.textAlignment = NSTextAlignmentRight;
        [videoTime setFont:[UIFont fontWithName:videoTime.font.fontName size:10]];
        [videoTime setTextColor:[UIColor whiteColor]];
        [cell addSubview:videoTime];
    }else{
        videoIcon = (UIImageView*)[cell viewWithTag:100];
        videoTime = (UILabel*)[cell viewWithTag:101];
    }
    
    if (!self.rootController.returnOnSelectSingleItem) {
        cell.selectedBackgroundView = ImageViewWithImagename(!self.rootController.isViewAsPopoverController && GC_Device_IsIpad ? @"POPMediaPickerSelectedIpad" : @"POPMediaPickerSelected");
    }
    
    videoIcon.hidden = YES;
    videoTime.hidden = YES;
    
    //display detail of cell here...
    id obj = self.assets[indexPath.row];
    if ( [obj class] == [ALAsset class] ) {
        ALAsset *asset = obj;
        CGImageRef thumbnailImageRef = [asset thumbnail];
        thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
        
        videoIcon.hidden = [asset valueForProperty:ALAssetPropertyType] != ALAssetTypeVideo;
        videoTime.hidden = [asset valueForProperty:ALAssetPropertyType] != ALAssetTypeVideo;
        if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
            float duration = [[asset valueForProperty:ALAssetPropertyDuration] floatValue];
            int minutes = duration/60;
            int seconds = duration - (minutes*60);
            videoTime.text = [NSString stringWithFormat:@"%d.%@%d",minutes,seconds>9?@"":@"0",seconds ];
        }
    }else{
        thumbnail =  [UIImage imageNamed: obj ];
        cell.selectedBackgroundView = nil;
    }
    
    cell.backgroundView = [[UIImageView alloc] initWithImage:thumbnail];
    
    
    return cell;
}

-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id obj = self.assets[indexPath.row];
    
    if ( [obj class] != [ALAsset class] ) {
        if ( [obj isEqualToString:imgNameCapture] ) {
            
            if ([self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerProcessCustomCaptureImage:)])
            {
                [self.rootController closeViewAndExecuteCustomCapture:YES];
            }
            else if ([self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerReturnCustomCaptureImageController:picker:)])
            {
                UIViewController* capture = [self.rootController.popMediaPickerDelegate popMediaPickerReturnCustomCaptureImageController:self picker:self.rootController];
                [self addCustomController:capture];
            }
            else
            {
                [self startCamera:YES];
            }
            
        }else{
            if ([self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerProcessCustomRecordVideo:)])
            {
                [self.rootController closeViewAndExecuteCustomCapture:NO];
            }
            else if ([self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerReturnCustomRecordVideoController:picker:)])
            {
                UIViewController* record = [self.rootController.popMediaPickerDelegate popMediaPickerReturnCustomRecordVideoController:self picker:self.rootController];
                [self addCustomController:record];
            }
            else
            {
                [self startCamera:NO];
            }
        }
        return;
    }
        
    
    if (self.rootController.returnOnSelectSingleItem)
    {
        [self doneAction:doneButton];
        return;
    }
    
    [self updateTitle];
}

-(void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self updateTitle];
}

-(void) updateTitle{
    if (self.rootController.returnOnSelectSingleItem) return;
    
    labelToolbar.text = _collectionView.indexPathsForSelectedItems.count == 0 ? @"No Item Selected" : [NSString stringWithFormat:@"%@ Items Selected", [StringLib FormatDouble:_collectionView.indexPathsForSelectedItems.count decimalLength:0]];
    
    [doneButton setEnabled: _collectionView.indexPathsForSelectedItems.count > 0];
}

- (BOOL) startCamera:(BOOL)photoOnly
{
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] == NO)
        return NO;
    
    @try {
        UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if (photoOnly) {
            cameraUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
            cameraUI.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        }else{
            cameraUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
            cameraUI.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        }
        
        // Hides the controls for moving & scaling pictures, or for
        // trimming movies. To instead show the controls, use YES.
        cameraUI.allowsEditing = NO;
        cameraUI.delegate = self;
        
        [self addCustomController:cameraUI];
    }
    @catch (NSException *exception) {
        NSLog(@"bug: %@", exception);
    }
    @finally {
        
    }
    
    
    
    return YES;
}

-(void) addCustomController:(UIViewController*)controller
{
    //move camera to adv image picker
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
    controller.view.frame = self.view.frame;
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:controller.view];
    
    //hide navigation bar and toolbar
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setToolbarHidden:YES animated:NO];
}

#pragma UIImagePickerController delegate functions

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if(picker.cameraCaptureMode == UIImagePickerControllerCameraCaptureModePhoto){
        if ([self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveCaptureImage:picker:)])
        {
            UIImage *newImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            
            //fix orientation
            newImage = [ImageLib fixOrientation:newImage];
            
            [ViewLib showLoading:picker.view];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.rootController.popMediaPickerDelegate popMediaPickerDidSaveCaptureImage:newImage picker:self.rootController];
                [ViewLib hideLoading:picker.view];
            });
            
        }
    }else{
        if ([self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveRecordVideoToTempFolder:picker:)]) {
            
            NSURL *recordedVideoURL = [info objectForKey:UIImagePickerControllerMediaURL];
            [self.rootController.popMediaPickerDelegate popMediaPickerDidSaveRecordVideoToTempFolder:recordedVideoURL.path picker:self.rootController];
        }
    }
    [self.rootController closeView];
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.view removeFromSuperview] ;
    [picker removeFromParentViewController];
    picker = nil;
    
    [self.rootController cancelAction:nil];
}

#pragma POPMediaPickerCustomCamera delegate functions

-(void) POPMediaPickerCustomCameraDoneWithImage:(UIImage*)image
{
    if ([self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveCaptureImage:picker:)]) {
        [self.rootController.popMediaPickerDelegate popMediaPickerDidSaveCaptureImage:image picker:self.rootController];
    }
    [self.rootController closeView];
}


-(void) POPMediaPickerCustomCameraDoneVideoPath:(NSString *)videoPath
{
    if ([self.rootController.popMediaPickerDelegate respondsToSelector:@selector(popMediaPickerDidSaveRecordVideoToTempFolder:picker:)]) {
        [self.rootController.popMediaPickerDelegate popMediaPickerDidSaveRecordVideoToTempFolder:videoPath picker:self.rootController];
    }
    [self.rootController closeView];
}

-(void) POPMediaPickerCustomCameraDidCancelWith:(UIViewController*) cameraController
{
    [self.rootController closeView];
}

#pragma manage orientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate  // iOS 6 autorotation fix
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations // iOS 6 autorotation fix
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation // iOS 6 autorotation fix
{
    return UIInterfaceOrientationPortrait;
}

@end



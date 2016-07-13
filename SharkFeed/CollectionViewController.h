//
//  CollectionViewController.h
//  SharkFeed
//
//  Created by Jeremy Bringetto on 7/11/16.
//  Copyright © 2016 Jeremy Bringetto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTTPCall.h"

@interface CollectionViewController : UICollectionViewController <HTTPCallDelegate, UICollectionViewDataSource, UICollectionViewDelegate>


@property (nonatomic) NSInteger pagesLoaded;
@property (nonatomic) NSInteger pageVisible;
@property (nonatomic) NSMutableArray *allPhotos;
@property (nonatomic) NSMutableArray *thumbnailURLs;
@property (nonatomic) NSMutableDictionary *thumbnailImages;
@property (nonatomic) NSMutableDictionary *selectedPhotoDetails;
@property (nonatomic) NSOperationQueue *q;
@property (nonatomic) UIImage *sharkImage;
@property (nonatomic) BOOL loadAnotherPage;




@end

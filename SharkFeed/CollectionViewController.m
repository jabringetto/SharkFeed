//
//  CollectionViewController.m
//  SharkFeed
//
//  Created by Jeremy Bringetto on 7/11/16.
//  Copyright © 2016 Jeremy Bringetto. All rights reserved.
//

#import "CollectionViewController.h"
#import "CollectionViewCell.h"
#import "LightboxVC.h"

@interface CollectionViewController ()

@end

@implementation CollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad
{
    [super viewDidLoad];
    _sharkImage =  [UIImage imageNamed:@"sharkIcon.png"];
    _loadAnotherPage = YES;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    UIRefreshControl  *refreshControl = [[UIRefreshControl alloc]init];
    [self.collectionView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    
    [self.collectionView registerClass:[CollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    NSInteger pageToBeLoaded = _pagesLoaded + 1;
    [self sharkDataAPICall:pageToBeLoaded];
    [self.navigationItem setTitle:@"SHARK FEED"];
    
    
   
    NSLog(@"viewDidLoad");

}
-(void)viewWillAppear:(BOOL)animated
{
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"<BACK"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(backBtnClicked:)];
    self.navigationItem.leftBarButtonItem = backButton;
}
-(void)refresh:(UIRefreshControl*)refreshCntrl
{

    _allPhotos = [[NSMutableArray alloc]init];
    [refreshCntrl endRefreshing];
    _pagesLoaded = 0;
     [self sharkDataAPICall:1];
    
}
-(void)backBtnClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)sharkDataAPICall:(NSInteger)pageNum
{
    NSString *pageToLoad = [NSString stringWithFormat:@"%ld",(long)pageNum];
    
    NSString *urlPrefix = @"https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=949e98778755d1982f537d56236bbb42&text=shark&format=json&nojsoncallback=1&page=";
    NSString *urlParameter = pageToLoad;
    NSString *urlSuffix = @"&extras=url_t,url_c,url_l,url_o";
    
    NSString *sharksURL = [NSString stringWithFormat:@"%@%@%@",urlPrefix,urlParameter,urlSuffix];

    HTTPCall *sharksCallPageOne = [[HTTPCall alloc]initWithSessionAndURL:sharksURL method:@"GET" body:nil];
    sharksCallPageOne.delegate = self;
}

-(void)httpCallResponse:(NSDictionary*)httpResponse
{
    
    NSData *data = httpResponse[@"data"];
    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    if(d && [d isKindOfClass:[NSDictionary class]])
    {
        [self parseAPIResponse:d];
    }
    
}
-(void)parseAPIResponse:(NSDictionary*)d
{
    if(!_allPhotos)
    {
        _allPhotos = [[NSMutableArray alloc]init];
    }
    if(!_thumbnailURLs)
    {
        _thumbnailURLs = [[NSMutableArray alloc]init];
    }
    
    NSNumber *page = d[@"photos"][@"page"];
    if(_pagesLoaded < [page integerValue])
    {
        _pagesLoaded = [page integerValue];
    }
     NSLog(@"PAGE: %@",page);
   
    NSArray *pagePhotos = d[@"photos"][@"photo"];
    
    for (NSDictionary *aPhoto in pagePhotos)
    {
        NSMutableDictionary *photoDetails = [[NSMutableDictionary alloc]init];
        NSString *idNum =  aPhoto[@"id"];
        NSString *imgURL_t =  [self limitedSanitize:aPhoto[@"url_t"]];
        NSString *imgURL_c= [self limitedSanitize:aPhoto[@"url_c"]];
        NSString *imgURL_l= [self limitedSanitize:aPhoto[@"url_l"]];
        NSString *imgURL_o =  [self limitedSanitize:aPhoto[@"url_o"]];
    
        
        [photoDetails setObject:idNum forKey:@"id"];
        [photoDetails setObject:imgURL_t  forKey:@"url_t"];
        [photoDetails setObject:imgURL_c forKey:@"url_c"];
        [photoDetails setObject:imgURL_o  forKey:@"url_o"];
        [photoDetails setObject:imgURL_l forKey:@"url_l"];
        
        [_allPhotos addObject:photoDetails];
        [_thumbnailURLs addObject:imgURL_t];
        
        
    }

     NSLog(@"ALL PHOTOS: %@",_allPhotos);
    
    
      NSLog(@"NUM PHOTOS: %lu",(unsigned long)[_allPhotos count]);
    
   
    [self loadThumbnailImages];
    
    
}

-(void)loadThumbnailImages
{
    _q = [[NSOperationQueue alloc]init];
    _q.maxConcurrentOperationCount = 5;
    if(!_thumbnailImages)
    {
        _thumbnailImages = [[NSMutableDictionary alloc]init];
    }
    for (NSString *url in _thumbnailURLs)
    {
        BOOL thumbnailAlreadyLoaded = [[_thumbnailImages allKeys]containsObject:url];
        BOOL urlNotEmpty = ![url isEqualToString:@""];
        
        if(!thumbnailAlreadyLoaded && urlNotEmpty)
        {
            NSOperation *op = [self taskWithData:url];
            [_q addOperation:op];
        }
        
    }
    if(_pagesLoaded < 3)
    {
         [self sharkDataAPICall:_pagesLoaded+1];
    }
    else
    {
        _loadAnotherPage = YES;
    }
}
- (NSOperation*)taskWithData:(NSString*)url
{
    
    NSInvocationOperation* getImage = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(fetchAndResizeImage:) object:url];
    
    return getImage;
}


- (void)fetchAndResizeImage:(NSString*)urlString
{
    if(urlString && [urlString isKindOfClass:[NSString class]])
    {
        NSURL *url = [NSURL URLWithString:urlString];
        NSData *imgData = [NSData dataWithContentsOfURL:url];
        UIImage *rawImage = [UIImage imageWithData:imgData];
        CGSize newSize = CGSizeMake(50.0, 50.0);
        UIGraphicsBeginImageContext(newSize);
        [rawImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
      
        UIGraphicsEndImageContext();
        
        
        if(newImage)
        {
             [_thumbnailImages setObject:newImage forKey:urlString];
        }
        else
        {
            [_thumbnailImages setObject:_sharkImage forKey:urlString];
             NSLog(@"NEW IMAGE IS NULL");
        }
        
       
        NSInteger numImages = [[_thumbnailImages allKeys]count];
        __weak __typeof__(self) weakSelf = self;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if(numImages % 10 == 0)
            {
                [weakSelf.collectionView reloadData];
            }
            
        }];
    }
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{

    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger n = 1;
    if(_allPhotos.count > 1)
    {
        n = _allPhotos.count;
    }
    
    return n;
}

- (CollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

    //cell.backgroundColor = [UIColor redColor];
    //UIImageView *imgview = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0,cell.frame.size.width,cell.frame.size.height)];
    
    NSString *url_t = [_thumbnailURLs objectAtIndex:indexPath.row];
    
    UIImage *cellImage = [[UIImage alloc]init];
    UIImageView *imgview = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0,cell.frame.size.width,cell.frame.size.height)];
    
    if(url_t && ![url_t isEqualToString:@""])
    {
        cellImage = [_thumbnailImages objectForKey:url_t];
    }
    UIImage *img = [[UIImage alloc]init];
    //BOOL notNSNull = [cellImage isKindOfClass:[NSNull class]];
    if(cellImage)
    {
        img = cellImage;
    }
    else
    {
        img = _sharkImage;
    }
    
    imgview.image = img;
    
    cell.backgroundView = imgview;
    //[cell.contentView addSubview:imgview];
    // Configure the cell
    
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedPhotoDetails = _allPhotos[indexPath.row];
    [self performSegueWithIdentifier:@"lightboxSegue" sender:self];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    LightboxVC *lvc = (LightboxVC *)segue.destinationViewController;
    lvc.photoDetails = _selectedPhotoDetails;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

#pragma mark <UIScrollViewDelegate>

-(void)scrollViewDidScroll:(UIScrollView *)scrollView;
{
 
    CollectionViewCell *cell = (CollectionViewCell*)  [[self.collectionView visibleCells]lastObject];
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    

    NSInteger trigger = (_pagesLoaded-1)*100-1;
    if(trigger < 199)
    {
        trigger = 199;
    }
    if(indexPath.row > trigger && _loadAnotherPage)
    {
        NSLog(@"Making the call");
        _loadAnotherPage = NO;
        [self sharkDataAPICall:_pagesLoaded+1];
    }

}


-(NSString*)limitedSanitize:(NSString*)inputString
{
    NSString *outputString = @"";
    
    BOOL notNSNull = ![inputString isKindOfClass:[NSNull class]];
    BOOL isAString = [inputString isKindOfClass:[NSString class]];
    BOOL isANumber = [inputString isKindOfClass:[NSNumber class]];
    
    if(inputString && isAString && notNSNull)
    {
        outputString = inputString;
    }
    if(isANumber)
    {
        NSNumber *n = (NSNumber*)inputString;
        outputString = [n stringValue];
    }
    return outputString;
}

@end

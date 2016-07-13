//
//  LightboxVC.m
//  SharkFeed
//
//  Created by Jeremy Bringetto on 7/12/16.
//  Copyright © 2016 Jeremy Bringetto. All rights reserved.
//

#import "LightboxVC.h"


@interface LightboxVC ()

@end

@implementation LightboxVC

-(void)viewDidLoad
{
    [super viewDidLoad];
    _lightboxImage.userInteractionEnabled = YES;
    UIPinchGestureRecognizer *pgr = [[UIPinchGestureRecognizer alloc]
                                     initWithTarget:self action:@selector(handlePinch:)];
    pgr.delegate = self;
    [_lightboxImage addGestureRecognizer:pgr];
    // Do any additional setup after loading the view.
}
-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"PHOTO DETAILS: %@",_photoDetails);
    
    NSString *photoID = _photoDetails[@"id"];
    NSString *url_l = _photoDetails[@"url_l"];
    NSString *url_o = _photoDetails[@"url_o"];
    
    NSString *url = @"";
    if(url_l && ![url_l isEqualToString:@""])
    {
        url = url_l;
    }
    else if(url_o && ![url_o isEqualToString:@""])
    {
        url = url_o;
    }
    HTTPCall *bigPhotoCall = [[HTTPCall alloc]initWithSessionAndURL:url method:@"GET" body:nil];
    bigPhotoCall.delegate = self;
    
    NSString *photoInfoPrefix = @"https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=949e98778755d1982f537d56236bbb42&photo_id=";
    NSString *photoInfoParameter = photoID;
    NSString *photoInfoSuffix =  @"&format=json&nojsoncallback=1";
    NSString *photoInfoURL = [NSString stringWithFormat:@"%@%@%@",photoInfoPrefix,photoInfoParameter,photoInfoSuffix];
    
    HTTPCall *infoCall = [[HTTPCall alloc]initWithSessionAndURL:photoInfoURL method:@"GET" body:nil];
    infoCall.delegate = self;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
}
-(void)httpCallResponse:(NSDictionary *)httpResponse
{
    NSURLResponse *response = httpResponse[@"response"];
    NSData *data = httpResponse[@"data"];
    
    
    if([response.URL.absoluteString containsString:@".jpg"])
    {
        if(data)
        {
            _rawImage = [UIImage imageWithData:data];
            _lightboxImage.image = _rawImage;
        }
    }
     if([response.URL.absoluteString containsString:@"getInfo"])
     {
          NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
         if(photoInfo)
         {
             NSLog(@"PHOTO INFO: %@",photoInfo);
             [self parsePhotoInfo:photoInfo];
         }
     }
  

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}
-(void)parsePhotoInfo:(NSDictionary *)photoInfo
{
    NSString *description = photoInfo[@"photo"][@"description"][@"_content"];
    description = [self limitedSanitize:description];
    description = [self decodeHTML:description];
    _descriptionLabel.text = [NSString stringWithFormat:@"Description: %@",description];
    
    NSArray *urlArray = photoInfo[@"photo"][@"urls"][@"url"];
    NSDictionary *firstURL = [urlArray objectAtIndex:0];
    _flikrPageURL =  [self limitedSanitize:firstURL[@"_content"]];

    NSLog(@"DESCRIPTION: %@",description);
    NSLog(@"PAGE URL: %@",_flikrPageURL);
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

- (IBAction)openInFlikr:(id)sender
{
    NSLog(@"Attempting to open page on flikr.com");
    
    BOOL pageURLNotEmpty = ![_flikrPageURL isEqualToString:@""];
    
    if(pageURLNotEmpty)
    {
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_flikrPageURL]];
    }
}

- (IBAction)downloadImage:(id)sender
{
    UIImageWriteToSavedPhotosAlbum(_rawImage, nil, nil, nil);
    [self showAlert:@"PHOTO SAVED":@"This photo has been successfully saved to your device."];
}
-(void)showAlert:(NSString*)title :(NSString*)msg
{
    UIAlertController *errorMess = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        
        [self dismissViewControllerAnimated:NO completion:^(){}];
         
         }];
        
        [errorMess addAction:ok];
        
        [self presentViewController:errorMess animated:YES completion:nil];
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
-(NSString *)decodeHTML:(NSString*)htmlString
{
    NSData* stringData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* options = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
    NSAttributedString* decodedAttributedString;
    decodedAttributedString = [[NSAttributedString alloc] initWithData:stringData options:options documentAttributes:NULL                                                   error:NULL];
    NSString* decodedString = [decodedAttributedString string];
    
    return decodedString;
}
-(void)handlePinch:(UIPinchGestureRecognizer*)recognizer{
    if ([recognizer state] == UIGestureRecognizerStateEnded) {
        NSLog(@"======== Scale Applied ===========");
        if ([recognizer scale]<1.0f) {
            [recognizer setScale:1.0f];
        }
        CGAffineTransform transform = CGAffineTransformMakeScale([recognizer scale],  [recognizer scale]);
        _lightboxImage.transform = transform;
    }
}



@end

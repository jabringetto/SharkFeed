//
//  LightboxVC.h
//  SharkFeed
//
//  Created by Jeremy Bringetto on 7/12/16.
//  Copyright © 2016 Jeremy Bringetto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTTPCall.h"

@interface LightboxVC : UIViewController <HTTPCallDelegate>

@property (nonatomic) UIImage *rawImage;

@property (nonatomic) NSDictionary *photoDetails;

@property (nonatomic) NSString *flikrPageURL;

@property (weak, nonatomic) IBOutlet UIImageView *lightboxImage;

@property (weak, nonatomic) IBOutlet UIButton *downloadButton;

@property (weak, nonatomic) IBOutlet UIButton *flikrButton;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

- (IBAction)openInFlikr:(id)sender;


- (IBAction)downloadImage:(id)sender;

@end

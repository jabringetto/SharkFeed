//
//  HTTPCall.h
//
//
//  Created by Jeremy Bringetto
//

#import <Foundation/Foundation.h>


@protocol HTTPCallDelegate <NSObject>

-(void)httpCallResponse:(NSDictionary*)httpResponse;

@end

@interface HTTPCall : NSObject <NSURLSessionDelegate>

@property (nonatomic, weak) id <HTTPCallDelegate> delegate;

-(instancetype)initWithSessionAndURL:(NSString*)urlString method:(NSString*)httpMethod body:(NSDictionary*)postBody;

@end
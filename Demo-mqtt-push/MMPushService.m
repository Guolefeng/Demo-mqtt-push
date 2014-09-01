//
//  MMPushService.m
//  yuxi-manager
//
//  Created by Guo Yu on 14-8-27.
//  Copyright (c) 2014年 ylink. All rights reserved.
//

#import "MMPushService.h"

#import "MQTTKit/MQTTKit.h"

#define kMQTTServerHost @"iot.eclipse.org"
#define kTopic @"MQTTExample/testcnpush"

@interface MMPushService()

@property (nonatomic, strong) MQTTClient *client;


@end

@implementation MMPushService

+ (MMPushService *)sharedService {
	static dispatch_once_t predicate = 0;
	static MMPushService *object = nil;
    
	dispatch_once(&predicate, ^{ object = [[self class] new]; });
    
	return object;
}


- (void)reconnect {
    UIApplication *application = [UIApplication sharedApplication];
    
    if (self.client) {
        [self sendNotification:@"do reconnect..."];
        self.client = nil;
    }
    
    NSString *clientID = [[[UIDevice currentDevice]identifierForVendor]UUIDString];
    self.client = [[MQTTClient alloc] initWithClientId:clientID];
    self.client.keepAlive = 600;
    
    __weak MMPushService *weakSelf = self;
    [self.client setMessageHandler:^(MQTTMessage *message) {
        [weakSelf sendNotification:[NSString stringWithFormat:@"received:%@", message.payload]];
        NSLog(@"trigged :%@", message.payload);
    }];
    
    // connect the MQTT client
    [self.client connectToHost:kMQTTServerHost completionHandler:^(MQTTConnectionReturnCode code) {
        if (code == ConnectionAccepted) {
            [self sendNotification:@"did connect..."];
            // The client is connected when this completion handler is called
            NSLog(@"client is connected with id %@", clientID);
            // Subscribe to the topic
            [self.client subscribe:kTopic withCompletionHandler:^(NSArray *grantedQos) {
                // The client is effectively subscribed to the topic when this completion handler is called
                NSLog(@"subscribed to topic %@", kTopic);
                BOOL res = [self.client enableBackgrounding];
                
                if (!res) {
                    NSLog(@"Failed to enable background socket...");
                }
            }];
        } else {
            NSLog(@"Failed to connect to server...");
        }
    }];
    
    [application setKeepAliveTimeout:600 handler:^{
        [self sendNotification:@"timeout handler activited..."];
        [self reconnect];
    }];
    
}

- (void)sendNotification:(NSString*)message {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    
    UIApplication *application = [UIApplication sharedApplication];
    
    UILocalNotification *notification = [UILocalNotification new];
    notification.repeatInterval = 0;
    [notification setAlertBody:[NSString stringWithFormat:@"%@: %@", dateString, message]];
    [notification setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    [notification setTimeZone:[NSTimeZone defaultTimeZone]];
    [notification setSoundName:UILocalNotificationDefaultSoundName];
    
    [application scheduleLocalNotification:notification];
}

@end

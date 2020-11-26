//
//  LTViewController.m
//  LThen
//
//  Created by vgop@outlook.com on 11/25/2020.
//  Copyright (c) 2020 vgop@outlook.com. All rights reserved.
//

#import "LTViewController.h"
#import "LThen/LTAsyncListEnumerator.h"

#define  __DATASTRING__ [[[NSDate date] description] UTF8String]
#define LTLog(message, ...)     NSLog(@"%s line:%d %s\n", __FUNCTION__,__LINE__,[[NSString stringWithFormat:message, ## __VA_ARGS__] UTF8String])

@interface LTViewController ()
@end

@implementation LTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [LTAsyncListEnumerator createAyncChain]
    .then(^id(id r) {
        
        LTLog(@"%@",r);
        return @"1";
    })
    .then(^id(id r) {
        
        LTLog(@"%@",r);
        return [LTAsyncListEnumerator promise:^(LTPromiseFun resolve, LTPromiseFun reject) {
            
            if (arc4random_uniform(2)) {
                LTLog(@"random reject");
                reject(@"reject");
            }
            else{
                LTLog(@"random resolve");
                resolve(@"resolve");
            }
        }]
        .then(^id(id r) {
            return [LTAsyncListEnumerator promise:^(LTPromiseFun resolve, LTPromiseFun reject) {
                
                if (arc4random_uniform(2)) {
                    LTLog(@"random2 reject");
                    reject(@"reject");
                }
                else{
                    LTLog(@"random2 resolve");
                    resolve(@"resolve");
                }
            }];
        })
        .then(^id(id r) {
            LTLog(@"%@",r);
            return r;
            
        });
        
    })
    .then(^id(id r) {
        LTLog(@"%@",r);
        return @"3";
    })
    .catchFunction(^id(id r) {
        LTLog(@"catch %@",r);
        return @"3";
    })
    .then(^id(id r) {
        LTLog(@"%@",r);
        return [LTAsyncListEnumerator reject:@"reject directly"];
    })
    .then(^id(id r) {
        LTLog(@"Never show");
        return @"3";
    })
    .catchFunction(^id(id r) {
        LTLog(@"catch %@",r);
        return @"3";
    })
    .startTask();
    
	// Do any additional setup after loading the view, typically from a nib.
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

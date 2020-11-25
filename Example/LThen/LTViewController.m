//
//  LTViewController.m
//  LThen
//
//  Created by vgop@outlook.com on 11/25/2020.
//  Copyright (c) 2020 vgop@outlook.com. All rights reserved.
//

#import "LTViewController.h"
#import "LThen/LTAsyncListEnumerator.h"
@interface LTViewController ()

@end

@implementation LTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [LTAsyncListEnumerator createAyncChain]
    .then(^id(id r) {
        
        NSLog(@"%@",r);
        return @"1";
    })
    .then(^id(id r) {
        NSLog(@"%@",r);
        return @"3";
    }).then(^id(id r) {
        NSLog(@"%@",r);
        return nil;
    }).startTask();
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

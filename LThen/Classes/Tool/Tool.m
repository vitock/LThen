//
//  Tool.m
//  LThen
//
//  Created by wei li on 2020/11/25.
//

#import "Tool.h"
 

@implementation NSMutableArray (LTStack)

 
- (void)lt_push:(NSObject *)anObject {
    if(anObject){
        [self addObject:anObject];
    }
    
}

- (NSObject *)lt_pop {
    if ( self.count > 0 ) {
        NSObject *anObject = [self lastObject];
        [self removeLastObject];
        return anObject;
    }
    return nil;
}

 

@end

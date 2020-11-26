//
//  Tool.h
//  LThen
//
//  Created by wei li on 2020/11/25.
//

#import <Foundation/Foundation.h>
#ifdef DEBUG
#define  __DATASTRING__ [[[NSDate date] description] UTF8String]

#define LTLog(message, ...)     printf("%s %s line:%d %s\n",__DATASTRING__, __FUNCTION__,__LINE__,[[NSString stringWithFormat:message, ## __VA_ARGS__] UTF8String]) //  NSLog(@"(Gtgj) %s\n" message "\n\n", __PRETTY_FUNCTION__, ##__VA_ARGS__)
#else
#define LTLog( ...)

#endif





@interface NSMutableArray (LTStack)
- (void)lt_push:(id) obj;

- (id )lt_pop ;

@end

//
//  LTAsyncListEnumerator.h
//
//  Created by liw003 on 2019/1/8.
//  Copyright © 2019年 . All rights reserved.
//

#import <Foundation/Foundation.h>

@class LTAsyncListEnumerator;
@class LTThenable;

typedef id (^LTPromiseFun)(id r);
typedef LTThenable *(^LTPromiseChain)(LTPromiseFun r);

typedef void(^LTAsyncEnumertorAction)(id item , LTAsyncListEnumerator *obj);
@interface LTPromiseFuncHolder : NSObject
@property (nonatomic, copy)LTPromiseFun fun;
/// 1  then 2:catch
@property (nonatomic, assign)int nFuncType;

@property (nonatomic, assign)int isRunned;
@end

@implementation LTPromiseFuncHolder
@end




@interface LTAsyncListEnumerator:NSObject
@end



@interface LTThenable:NSObject
@property (nonatomic,readonly)LTPromiseChain then;
@property (nonatomic,readonly)LTPromiseChain catchFunction;
@property (nonatomic,readonly)LTThenable *(^startTask)(void);

- (LTPromiseChain )catchFunction;
- (LTPromiseChain )then;
/**
 * then最后显式调用,不要先start 后 then,
 * 否则一些同步的立即返回的回调可能会丢失
 * 如果第一个 then 是异步的,那就没问题
 */
- (LTThenable *(^)())startTask;

/// 中断
- (void)reject;
@end



@interface LTAsyncListEnumerator(){
    int tagFinish ;
    int isReject ;
    
    int iSyncCount;
}

@property (nonatomic,copy)dispatch_block_t nxt;
@property (nonatomic,copy)LTAsyncEnumertorAction action;
@property (nonatomic,copy)dispatch_block_t finish;
@property (nonatomic,assign)int currentIndex;
@property (nonatomic,retain)NSArray *arr;
@property (nonatomic,copy)dispatch_block_t clear;

@property (nonatomic,copy)void (^rejectAction)(id err);
- (void)begin;
/// 继续
- (void)next;
/// 异常中断
- (void)reject:(id )err ;

/// 异步队列事务,dealAction:任务,finish:任务结束回调,reject:任务中断回调
+ (LTAsyncListEnumerator *)enumeratorList:(NSArray *)arr  action:(LTAsyncEnumertorAction) dealAction finish:(dispatch_block_t)finish reject:(void (^)(id err)) rejectAction;

@end



@interface LTAsyncListEnumerator(ltpromisze)

+ (LTThenable *)createAyncChain;


/// 中间用于返回的状态 开始第一个调用时,使用 [GTAsyncListEnumerator createAyncChain].then
+ (LTThenable *)promise:(void (^)(LTPromiseFun resolve , LTPromiseFun reject))func;

+ (LTThenable *)resolve:(id) r;
+ (LTThenable *)reject:(id) r;

+ (LTThenable *)wait:(CGFloat) time;


/// 并行执行,执行结束就 结果是一个数组,如果一个抛错误,那么全部错误,
/// 需要最后 startTask
+ (LTThenable *)parallel:(NSArray<LTThenable *> *)tasks  max :(int) maxTaskSameTime;

@end

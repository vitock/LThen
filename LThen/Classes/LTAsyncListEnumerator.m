//
//  LTAsyncListEnumerator.m
//
//  Created by liw003 on 2019/1/8.
//  Copyright © 2019年 . All rights reserved.
//

#import "LTAsyncListEnumerator.h"
#import "RACEXTScope.h"
#import "Tool.h"
@class LTPromiseFuncHolder;
id LT_arrGetObject(NSArray *arr, NSUInteger index, Class aClass) {
    NSDictionary *result = nil;
    if (index < arr.count) {
        result = [arr objectAtIndex:index];
        if (result && [result isKindOfClass:aClass]) {
            return result;
        }
    }
    return nil;
}

@interface LTThenable(){
}
@property (nonatomic, assign)BOOL isBegin;


@property (nonatomic, strong)NSMutableArray *arrFunctions;

@property (nonatomic, strong)id currentValue;
@property (nonatomic, copy)void (^func)(LTPromiseFun resolve , LTPromiseFun reject);

/// 0 pendging  1 resolve 2 reject
@property (nonatomic, assign)int nPState;

@property (nonatomic,strong)LTAsyncListEnumerator *enumerator;
@property (nonatomic,assign)BOOL isTaskBeginedOnce;
@end

@implementation LTThenable

+ (LTThenable *)promise:(void (^)(LTPromiseFun resolve , LTPromiseFun reject))func{
    LTThenable *t = [LTThenable new];
    t.func =  func;
    return  t;
}

- (NSMutableArray *)arrFunctions{
    if (_arrFunctions == nil ) {
        _arrFunctions = [NSMutableArray arrayWithCapacity:30];
    }
    return _arrFunctions;
}

- (LTPromiseChain )then{
    @weakify(self);
    return ^(LTPromiseFun f){
        @strongify(self);
        LTPromiseFuncHolder *h = [LTPromiseFuncHolder new];
        h.fun = f;
        h.nFuncType = 1;
        [self.arrFunctions addObject:h];
        return self;
    };
    
}

- (LTStartBlock)startTask{
    self.isTaskBeginedOnce = YES;
    [self begin];
    @weakify(self);
    return ^(){
        /// 什么都不做,只是返回self 方便链式写法
        @strongify(self);
        return self;
    };
}

- (LTPromiseChain )catchFunction{
    @weakify(self);
    return ^(LTPromiseFun f){
        @strongify(self);
        LTPromiseFuncHolder *h = [LTPromiseFuncHolder new];
        h.fun = f;
        h.nFuncType = 2;
        [self.arrFunctions addObject:h];

        return self;
    };
    
}

- (void)begin{
    if (_isBegin) {
        return;
    }
    _isBegin = YES;
    @weakify(self);
    if (self.func) {
        self.nPState = 0;
        /**
         * 有些操作是异步的,避免被release,先retain
         */
        CFRetain((__bridge CFTypeRef)self);
        __block int NRetain = 1;
        self.func(^id(id r) {
            @strongify(self);
            if(self.nPState == 0){
                self.nPState = 1;
                self.currentValue = r;
                [self callThen];
            }
            if (NRetain) {
                NRetain = 0;
                CFRelease((__bridge CFTypeRef)self);
            }
            
            return nil;
        }, ^id(id r) {
            @strongify(self);
            if (self.nPState == 0 ) {
                self.nPState = 2;
                self.currentValue = r;
                [self callThen];
            }
            if (NRetain) {
                NRetain = 0;
                CFRelease((__bridge CFTypeRef)self);
            }
            return nil;
        });
    }else{
        self.nPState = 1;
        [self callThen];
    }
    
}
- (void)reject{
    [self.enumerator reject:nil];
}

- (void)callThen{
    @weakify(self);
    CFRetain((__bridge CFTypeRef)self);
    self.enumerator = [LTAsyncListEnumerator enumeratorList:self.arrFunctions action:^(id item, LTAsyncListEnumerator *obj) {
        @strongify(self);
        if(!self){
            [obj reject:nil];
        }
        
        LTPromiseFuncHolder *f = item;
        /// 区分 catch 和 then
        if (self.nPState  != f.nFuncType ) {
            [obj next];
            return ;
        }
        self.nPState = 1;
        if(f.isRunned == 1){
            LTLog(@"function fired before,  skip");
            [obj next];
            return ;
        }
        
        self.currentValue =  f.fun(self.currentValue);
        f.isRunned = 1;
        
        if ([self.currentValue isKindOfClass:[LTThenable class]]) {
            self.nPState = 0;
            LTThenable *t = self.currentValue;
            t.then(^id(id r) {
                @strongify(self);
                self.nPState = 1;
                self.currentValue = r;
                [obj next];
                return r;
            })
            .catchFunction(^id(id r) {
                @strongify(self);
                self.nPState = 2;
                self.currentValue = r;
                [obj next];
                return r;
            });
            
            [t begin];
            
            
        }
        else{
            [obj next];
        }
        
        
        
    } finish:^(){
        @strongify(self);
        self.isBegin = NO;
        CFRelease((__bridge CFTypeRef)self);
        
    }reject:^(id r ){
        
        LTLog(@"中断异步调用");
        @strongify(self);
        self.isBegin = NO;
        CFRelease((__bridge CFTypeRef)self);
    }];
}


- (void)dealloc{
    LTLog(@"---");
}
@end





@implementation LTAsyncListEnumerator
- (void)reject:(id )err{
    isReject = YES;
    if(self.rejectAction){
        self.rejectAction(err);
        self.rejectAction = nil;
    }
    [self callEndAction];
}

- (void)next{
    
    if (self.nxt == nil) {
        @weakify(self)
        self.nxt = ^(){
            @strongify(self);
            [self _realBegin];
        };
    }
    
    if (self.nxt) {
        ++_currentIndex;
        
        /// 防止同步的调用太多,造成递归爆栈;
        ++iSyncCount;
        if(iSyncCount > 20){
            iSyncCount = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.nxt) {
                    self.nxt();
                }
            });
        }
        else{
            self.nxt();
        }
        
    }
}

- (void)dealloc{
    self.nxt = nil;
    self.action = nil;
    self.finish = nil;
    self.arr = nil;
    self.clear = nil;
}

- (void)callEndAction{
    
    if (tagFinish == 1) {
        return;
    }
    tagFinish = 1;

    if (!isReject) {
        if (_finish) {
            _finish();
            self.finish = nil;
        }
    }
     
    
    if (self.clear) {
        self.clear();
        self.clear = nil;
    }
    
    self.action = nil;
    self.nxt = nil;
    if (self.clear) {
        self.clear();
    }
    
//    
    CFRelease((__bridge CFTypeRef)self);
}

- (void)begin{
    
    CFRetain((__bridge CFTypeRef)self);
    if (_currentIndex >= self.arr.count || _currentIndex < 0 ) {
        [self callEndAction];
        return;
    }
    else{
        [self _realBegin];
    }
    
    
}

- (void)_realBegin{
    if ( _currentIndex >= self.arr.count || _currentIndex < 0 || self.action == nil) {
        [self callEndAction];
        return;
    }
    
    
    
    if (self.action) {
        NSObject *obj =  LT_arrGetObject(self.arr, _currentIndex, [NSObject class]);
        if (obj == nil ) {
            [self callEndAction];
        }
        else{
            self.action(obj, self);
        }
    }
    
    
}



+ (LTAsyncListEnumerator *)enumeratorList:(NSArray *)arr  action:(LTAsyncEnumertorAction) dealAction finish:(dispatch_block_t)finish reject:(void (^)(id err)) rejectAction{
    LTAsyncListEnumerator *obj = [[LTAsyncListEnumerator alloc] init];
    obj.arr = arr;
    obj.action = dealAction;
    obj.finish = finish;
    obj.rejectAction = rejectAction;
    obj.currentIndex = 0;
    [obj begin];
    return obj;
}
@end








@interface LTThenResult : NSObject
@property (nonatomic, assign)NSInteger tag;
@property (nonatomic, strong)id result;
@end

@implementation LTThenResult

@end

@implementation LTAsyncListEnumerator(ltpromisze)

+ (LTThenable *)createAyncChain{
    LTThenable *t = [LTThenable new];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if(t.isTaskBeginedOnce == NO){
//            t.isTaskBeginedOnce = YES;
//            [t begin];
//        }
//    });
    return t;
}
+ (LTThenable *)promise:(void (^)(LTPromiseFun resolve , LTPromiseFun reject))func{
    LTThenable *t = [LTThenable new];
    
    /// resolve reject 只允许 回调一次;
    t.func = ^(LTPromiseFun resolve0, LTPromiseFun reject0) {
        __block int T = 0 ;
        LTPromiseFun resolve1 = (id) ^(id r){
            if (T == 0 ) {
                id r0 = resolve0(r);
                T = 1;
                return r0;
            }
            LTLog(@" ❌❌ ---- 不能Resolve:[%@] 只能回调一次,上次是:%@",r, T == 1 ? @"Resolve":@"Reject");
            return (id) nil;
            
        };
        LTPromiseFun reject1 = (id) ^(id r){
            
            if (T == 0 ) {
                id r0 = reject0(r);
                T = 2;
                return r0;
            }
            LTLog(@" ❌❌---- 不能Reject:[%@] 只能回调一次,上次是:%@", r,T == 1 ? @"Resolve":@"Reject");
            return (id) nil;
        };
        func(resolve1,reject1);
    };
//    t.func =  func;
    return  t;
}
+ (LTThenable *)resolve:(id) r{
    return [self promise:^(LTPromiseFun resolve, LTPromiseFun reject) {
        resolve(r);
    }];
}
+ (LTThenable *)reject:(id) r{
    return [self promise:^(LTPromiseFun resolve, LTPromiseFun reject) {
        reject(r);
    }];
}
+ (LTThenable *)wait:(CGFloat) time{
    return [self promise:^(LTPromiseFun resolve, LTPromiseFun reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            resolve(nil);
        });
    }];
}


+ (LTThenable *)_generator:(LTThenable *)t0 remainTask:(NSMutableArray *)arrTask arrResut:(NSMutableArray *)arrResut originTaskAarray:(NSArray *)tasks {
    return  t0.then(^id(id r) {
        LTThenResult *re0 =  [LTThenResult new];
        re0.tag = [tasks indexOfObject:t0];
        re0.result = r;
        [arrResut addObject:re0];
        
        if (arrTask.count) {
            LTThenable *t1 = (LTThenable *) [arrTask lt_pop];
            
            t0.then(^id(id r) {
                return [self _generator:t1 remainTask:arrTask arrResut:arrResut originTaskAarray:tasks];
            });
//            generater(t1);
        }
        else {
            if(arrResut.count == tasks.count){
//                resolve(nil);
                
                return nil;
            }
        }
        return nil;
    }).startTask();
    

}

+ (LTThenable *)parallel:(NSArray<LTThenable *> *)tasks  max :(int) maxTaskSameTime{
    NSMutableArray *arrResut = [NSMutableArray arrayWithCapacity:tasks.count ? tasks.count : 4];
    
    
    NSMutableArray *arrTask = [NSMutableArray arrayWithCapacity:50];
    for (int i = (int )tasks.count - 1; i >=0 ; -- i ) {
        LTThenable *then = LT_arrGetObject(tasks, i , [LTThenable class]);
        if (then) {
            [arrTask addObject:then];
        }
    
    }
    
   
    LTThenable *t = [LTAsyncListEnumerator createAyncChain];
    t = t.then(^id(id r) {
        return [LTAsyncListEnumerator promise:^(LTPromiseFun resolve, LTPromiseFun reject) {
            
            void(^ __block generater)(LTThenable *) = ^(LTThenable *t0){
                if(!t0){
                    LTLog(@"3333");
                    return ;
                }
                   t0.then(^id(id r) {
                       LTThenResult *re0 =  [LTThenResult new];
                       re0.tag = [tasks indexOfObject:t0];
                       re0.result = r;
                       [arrResut addObject:re0];
                       
                       if (arrTask.count) {
                           LTThenable *t1 = (LTThenable *) [arrTask lt_pop];
                           if(generater && t1){
                               generater(t1);
                           }
                       }
                       else {
                           if(arrResut.count == tasks.count){
                               resolve(nil);
                               generater = nil;
                           }
                       }
                       return nil;
                   })
                .catchFunction(^id(id r) {
                    generater = nil;
                    reject(r);
                    return nil;
                })
                .startTask();
            };
   
            
             
            for (int i = 0 ; i < maxTaskSameTime &&  i < tasks.count; ++ i ) {
                LTThenable *t0 = (LTThenable *) [arrTask lt_pop];
                if (generater && t0) {
                    generater(t0);
                }
            }
        }];
    })
    .then(^id(id r) {
        [arrResut sortUsingComparator:^NSComparisonResult(LTThenResult* obj1, LTThenResult* obj2) {
            return obj1.tag - obj2.tag;
        }];
        
        NSMutableArray *arr2 = [NSMutableArray new];
        for (int i = 0 ; i < arrResut.count; ++ i ) {
            LTThenResult *r2 = LT_arrGetObject(arrResut, i, [LTThenResult class]);
            if(r2.result){
                [arr2 addObject:r2.result];
            }
            
        }
        return arr2;
    });
    /**
     * 有可能 第一个 就直接同步的reject 了,这样后面的catch 或者 then没有机会执行...
     */
    return t;// t.startTask();
}
@end

# LThen

[![CI Status](https://img.shields.io/travis/vitock/LThen.svg?style=flat)](https://travis-ci.org/vitock/LThen)
[![Version](https://img.shields.io/cocoapods/v/LThen.svg?style=flat)](https://cocoapods.org/pods/LThen)
[![License](https://img.shields.io/cocoapods/l/LThen.svg?style=flat)](https://cocoapods.org/pods/LThen)
[![Platform](https://img.shields.io/cocoapods/p/LThen.svg?style=flat)](https://cocoapods.org/pods/LThen)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

LThen is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'LThen'
```

## how to use

### add snippet 
for better experience, please add snippet first
xcode tool bar  editor-> create code snippet
```
catchFunction
catchFunction(^id(id r) {
    <#code#>
    return nil;
})
```

```
then
catchFunction(^id(id r) {
    <#code#>
    return nil;
})


```

```objc
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
```


## Author

vgop@outlook.com, liw

## License

LThen is available under the MIT license. See the LICENSE file for more info.

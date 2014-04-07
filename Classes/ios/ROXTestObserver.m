//
//  ROXTestObserver.m
//  Coyote
//
//  Created by François Vessaz on 18.03.14.
//  Copyright (c) 2014 Lotaris. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <YAML-Framework/YAMLSerialization.h>
#import "ROXTest.h"

@interface ROXTestObserver : XCTestObserver

@property NSString *appVersion;
@property NSString *roxProjectApiId;
@property NSString *roxServerId;
@property NSDictionary* roxServerConfig;
@property NSMutableArray* testsResults;
@property NSString* message;
@property NSTimeInterval duration;
@property NSData* jsonPayload;
@property dispatch_semaphore_t semaphore;

-(NSString*)toHumanName:(NSString*)camelCase;
-(void)generatePayload;
-(void)getRequest;
-(void)postRequestWithURL:(NSURL*)url andType:(NSString*)type;

@end

@implementation ROXTestObserver

+ (void)load {
    [[NSUserDefaults standardUserDefaults] setObject:@"ROXTestObserver,XCTestLog" forKey:@"XCTestObserverClass"];
}

- (void) startObserving {
    [super startObserving];
    
    _appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    _roxProjectApiId = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"roxProjectApiId"];
    _roxServerId = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"roxServerId"];
    _testsResults = [NSMutableArray array];
}

- (void) stopObserving {
    [super stopObserving];
    
    NSString* path = [NSString stringWithFormat:@"/Users/%@/.rox/config.yml",NSUserName()];
    NSInputStream *stream = [[NSInputStream alloc] initWithFileAtPath:path];
    NSError* err = nil;
    NSMutableArray* yaml = [YAMLSerialization objectsWithYAMLStream:stream options:kYAMLReadOptionStringScalars error:&err];
    if (err != nil){
        NSLog(@"ROXTest ERROR: Unable to read ROX YAML config at %@",path);
        return;
    }
    _roxServerConfig = [[[yaml firstObject] valueForKey:@"servers"] valueForKey:_roxServerId];
    [self generatePayload];
}

- (void) testSuiteDidStart:(XCTestRun *) testRun {
}

- (void) testSuiteDidStop:(XCTestRun *) testRun {
    _duration = [testRun testDuration];
}

- (void) testCaseDidStart:(XCTestRun *) testRun {
    _message = nil;
}

- (void) testCaseDidStop:(XCTestRun *) testRun {
    if (![[testRun test] respondsToSelector:@selector(roxKey)]){
        NSLog(@"ROXTest WARNING: skipping test %@ (Cause: test class is not a subclass of ROXTest.)",[[testRun test] name]);
        return;
    }
    XCTestCase* test = (XCTestCase*)[testRun test];
    if (test.roxKey == nil){
        NSLog(@"ROXTest WARNING: skipping test %@ (Cause: test has no ROX key set.)",[[testRun test] name]);
        return;
    }
    int duration = [testRun testDuration] * 1000;
    NSMutableDictionary* testResults = [@{@"k":test.roxKey,
                                          @"n":[self toHumanName:[test name]],
                                          @"p":@([testRun hasSucceeded]),
                                          @"d":@(duration),
                                          @"c":@"XCTest",
                                          @"g":test.roxTags,
                                          @"t":test.roxTickets,
                                          @"a":@{@"objc.method":[test name]}} mutableCopy];
    if (_message != nil){
        [testResults setValue:_message forKey:@"m"];
    }
    [_testsResults addObject:testResults];
}

- (void) testCaseDidFail:(XCTestRun *) testRun withDescription:(NSString *)description inFile:(NSString *) filePath atLine:(NSUInteger) lineNumber {
    _message = [NSString stringWithFormat:@"%@ FAIL: %@ in %@ at line %lu",[[testRun test] name],description,filePath,(unsigned long)lineNumber];
}

-(NSString*)toHumanName:(NSString*)camelCase {
    NSString* str = [camelCase componentsSeparatedByString:@" "][1];
    str = [str stringByReplacingOccurrencesOfString:@"]" withString:@""];
    NSMutableString *str2 = [NSMutableString string];
    for (NSInteger i=0; i<str.length; i++){
        NSString *ch = [str substringWithRange:NSMakeRange(i, 1)];
        if ([ch rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location != NSNotFound) {
            [str2 appendString:@" "];
        }
        [str2 appendString:ch];
    }
    return str2.capitalizedString;
}

-(void)generatePayload {
    NSMutableDictionary* resultsPayload = [NSMutableDictionary dictionary];
    [resultsPayload setValue:_roxProjectApiId forKey:@"j"];
    [resultsPayload setValue:_appVersion forKey:@"v"];
    [resultsPayload setValue:_testsResults forKey:@"t"];
    int duration = _duration * 1000;
    NSDictionary* payload = @{@"d":@(duration),@"r":@[resultsPayload]};
    
    if (![NSJSONSerialization isValidJSONObject:payload]){
        NSLog(@"ROXTest ERROR: invalid JSON (Cause: %@)",[payload description]);
        NSLog(@"ROX server not contacted...");
        return;
    }
    NSError* err = nil;
    _jsonPayload = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&err];
    if (_jsonPayload == nil){
        NSLog(@"ROXTest ERROR: during JSON serialization (Cause: %@).",[err localizedDescription]);
        NSLog(@"ROX server not contacted...");
        return;
    }
    
    [self getRequest];
}

-(void)getRequest {
    NSURL* url = [NSURL URLWithString:[_roxServerConfig valueForKey:@"apiUrl"]];
    NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url];
    NSString* auth = [NSString stringWithFormat:@"RoxApiKey id=\"%@\" secret=\"%@\"",[_roxServerConfig valueForKey:@"apiKeyId"],[_roxServerConfig valueForKey:@"apiKeySecret"]];
    [urlRequest addValue:auth forHTTPHeaderField:@"Authorization"];
    _semaphore = dispatch_semaphore_create(0);
    NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error != nil){
            NSLog(@"ROXTest ERROR with URL session (Cause: %@)",[error localizedDescription]);
            dispatch_semaphore_signal(_semaphore);
            return;
        }
        NSError* err;
        NSDictionary* jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
        if (jsonResponse == nil){
            NSLog(@"ROXTest ERROR during JSON deserialization (Cause: %@).",[err localizedDescription]);
            dispatch_semaphore_signal(_semaphore);
            return;
        }
        NSLog(@"Connected to ROX Center API at %@",[url absoluteString]);
        
        NSURL* postUrl = [NSURL URLWithString:[[[jsonResponse valueForKey:@"_links"] valueForKey:@"v1:test-payloads"] valueForKey:@"href"]];
        NSString* mediaType = [[[jsonResponse valueForKey:@"_links"] valueForKey:@"v1:test-payloads"] valueForKey:@"type"];
        
        [self postRequestWithURL:postUrl andType:mediaType];
    }];
    
    [task resume];
    
    while (dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
}

-(void)postRequestWithURL:(NSURL*)url andType:(NSString*)type {
    NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url];
    NSString* auth = [NSString stringWithFormat:@"RoxApiKey id=\"%@\" secret=\"%@\"",[_roxServerConfig valueForKey:@"apiKeyId"],[_roxServerConfig valueForKey:@"apiKeySecret"]];
    [urlRequest addValue:auth forHTTPHeaderField:@"Authorization"];
    [urlRequest addValue:type forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:_jsonPayload];
    NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error != nil){
            NSLog(@"ROXTest ERROR with URL session (Cause: %@)",[error localizedDescription]);
            dispatch_semaphore_signal(_semaphore);
            return;
        }
        
        if ([(NSHTTPURLResponse*)response statusCode] == 202){
            NSLog(@"The payload was successfully sent to ROX Center.");
        } else {
            NSLog(@"ROXTest ERROR: HTTP %ld error code:\n",[(NSHTTPURLResponse*)response statusCode]);
            if (data != nil){
                NSError* err;
                id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers | NSJSONWritingPrettyPrinted error:&err];
                if (jsonResponse == nil){
                    NSLog(@"ROXTest ERROR during JSON deserialization (Cause: %@).",[err localizedDescription]);
                    dispatch_semaphore_signal(_semaphore);
                    return;
                }
                NSLog(@"ROX server message: %@",[jsonResponse description]);
            }
        }
        
        dispatch_semaphore_signal(_semaphore);
    }];
    
    [task resume];
}

@end

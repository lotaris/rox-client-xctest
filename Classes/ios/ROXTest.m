//
//  ROXTest.m
//  Coyote
//
//  Created by François Vessaz on 19.03.14.
//  Copyright (c) 2014 Lotaris. All rights reserved.
//

#import "ROXTest.h"

static NSArray* roxGlobalTags = nil;
static NSArray* roxGlobalTickets = nil;

@implementation XCTestCase (ROXTest)

NSString* _roxKey;
NSArray* _roxTags;
NSArray* _roxTickets;

+(void)setGlobalTags:(NSArray*)globalTags {
    roxGlobalTags = globalTags;
}

+(void)setGlobalTickets:(NSArray*)globalTickets {
    roxGlobalTickets = globalTickets;
}

-(NSArray*)roxGlobalTags {
    return roxGlobalTags;
}

-(NSArray*)roxGlobalTickets {
    return roxGlobalTickets;
}

- (void)setUp {
    [super setUp];
    
    self.roxKey = nil;
    self.roxTags = nil;
    self.roxTickets = nil;
}

- (void)tearDown {
    [super tearDown];
    
    NSMutableArray* allTags = [@[] mutableCopy];
    if (roxGlobalTags != nil){
        [allTags addObjectsFromArray:roxGlobalTags];
    }
    if (self.roxTags != nil){
        [allTags addObjectsFromArray:self.roxTags];
    }
    self.roxTags = allTags;
    
    NSMutableArray* allTickets = [@[] mutableCopy];
    if (roxGlobalTickets != nil){
        [allTickets addObjectsFromArray:roxGlobalTickets];
    }
    if (self.roxTickets != nil){
        [allTickets addObjectsFromArray:self.roxTickets];
    }
    self.roxTickets = allTickets;
}

-(NSString*)roxKey {
    return _roxKey;
}

-(void)setRoxKey:(NSString *)roxKey {
    _roxKey = roxKey;
}

-(NSArray*)roxTags {
    return _roxTags;
}

-(void)setRoxTags:(NSArray *)roxTags {
    _roxTags = roxTags;
}

-(NSArray*)roxTickets {
    return _roxTickets;
}

-(void)setRoxTickets:(NSArray *)roxTickets {
    _roxTickets = roxTickets;
}

@end

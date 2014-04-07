//
//  ROXTest.h
//  Coyote
//
//  Created by François Vessaz on 19.03.14.
//  Copyright (c) 2014 Lotaris. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface XCTestCase (ROXTest)

@property NSString* roxKey;
@property NSArray* roxTags;
@property NSArray* roxTickets;

+(void)setGlobalTags:(NSArray*)globalTags;
+(void)setGlobalTickets:(NSArray*)globalTickets;

-(NSArray*)roxGlobalTags;
-(NSArray*)roxGlobalTickets;

@end

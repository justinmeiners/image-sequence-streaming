/*
 By: Justin Meiners
 
 Copyright (c) 2015 Justin Meiners
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 */

#import <Foundation/Foundation.h>

@interface ISSequence : NSObject

+ (ISSequence*)sequenceNamed:(NSString*)name;
+ (ISSequence*)sequenceFromFilepath:(NSString*)filepath;

- (id)initWithFilepath:(NSString*)filepath;

- (void)getBytes:(char*)buffer atFrame:(int)frame;

- (int)width;
- (int)height;
- (int)frameCount;
- (NSRange)range;
- (BOOL)validFrame:(int)frame;

@end

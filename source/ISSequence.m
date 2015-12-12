/*
 By: Justin Meiners
 
 Copyright (c) 2015 Justin Meiners
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 */

#import "ISSequence.h"
#import "ISSequenceStream.h"

@interface ISSequence ()
{
    ISSequenceStreamRef _handle;
}

@end

@implementation ISSequence

+ (ISSequence*)sequenceNamed:(NSString*)name
{
    return [[self alloc] initWithFilepath:[[NSBundle mainBundle] pathForResource:name ofType:nil]];
}

+ (ISSequence*)sequenceFromFilepath:(NSString*)filepath
{
    return [[self alloc] initWithFileAtPath:filepath];
}

- (id)initWithFilepath:(NSString*)filepath
{
    if ((self = [super init]))
    {
        if (!filepath)
        {
            return nil;
        }
        
        _handle = ISSequenceStreamCreate([filepath cStringUsingEncoding:NSUTF8StringEncoding]);
        
        if (!_handle)
        {
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    ISSequenceStreamDestroy(_handle);
}

- (void)getBytes:(char*)buffer atFrame:(int)frame
{
    ISSequenceStreamCopyFrame(_handle, frame, buffer);
}

- (int)width
{
    return ISSequenceStreamWidth(_handle);
}

- (int)height
{
    return ISSequenceStreamHeight(_handle);
}

- (int)frameCount
{
    return ISSequenceStreamFrameCount(_handle);
}

- (NSRange)range
{
    return NSMakeRange(0, [self frameCount]);
}

- (BOOL)validFrame:(int)frame
{
    return (frame >= 0 && frame < [self frameCount]);
}

@end

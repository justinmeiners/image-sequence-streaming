/*
 By: Justin Meiners
 
 Copyright (c) 2013 Inline Studios
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
    return [[[self alloc] initWithFilepath:[[NSBundle mainBundle] pathForResource:name ofType:nil]] autorelease];
}

+ (ISSequence*)sequenceFromFilepath:(NSString*)filepath
{
    return [[[self alloc] initWithFileAtPath:filepath] autorelease];
}

- (id)initWithFilepath:(NSString*)filepath
{
    if ((self = [super init]))
    {
        _handle = ISSequenceStreamCreate([filepath cStringUsingEncoding:NSUTF8StringEncoding]);
        
        if (!_handle)
        {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    ISSequenceStreamDestroy(_handle);
    [super dealloc];
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

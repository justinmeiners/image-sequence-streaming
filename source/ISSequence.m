/* Create By: Justin Meiners */

#import "ISSequence.h"
#include <ImageIO/ImageIO.h>

@interface ISPrefixSequence : ISSequence
{
    NSInteger _startFrame;
    NSInteger _frameCount;
    
    NSInteger _width;
    NSInteger _height;
    
    CFDictionaryRef _imageSourceOptions;
}

@property(nonatomic, copy)NSString* prefix;
@property(nonatomic, copy)NSString* suffix;
@property(nonatomic, copy)NSString* numberFormat;

- (NSURL*)frameUrl:(NSInteger)frame;

@end

@implementation ISPrefixSequence

- (id)initWithPrefix:(NSString*)prefix
        numberFormat:(NSString*)numberFormat
              suffix:(NSString*)suffix
          startFrame:(NSInteger)startFrame
          frameCount:(NSInteger)count
{
    if ((self = [super init]))
    {
        self.prefix = prefix;
        self.suffix = suffix;
        self.numberFormat = numberFormat;
        _startFrame = startFrame;
        _frameCount = count;
        
        NSURL* url = [self frameUrl:0];
        
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)url, nil);
        if (!imageSource) return nil;
        
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
        if (!image) return nil;
        
        if (CGImageGetBitsPerPixel(image) != 32)
        {
            CGImageRelease(image);
            CFRelease(imageSource);
            return nil;
        }

        _width = CGImageGetWidth(image);
        _height = CGImageGetHeight(image);
        
        CGImageRelease(image);
        CFRelease(imageSource);
        
        const void* keys[] = { kCGImageSourceShouldCache };
        const void* values[] = { kCFBooleanFalse };
        
        _imageSourceOptions = CFDictionaryCreate(nil, keys, values, 1, nil, nil);
    }
    return self;
}

- (void)dealloc
{
    CFRelease(_imageSourceOptions);
}

- (NSURL*)frameUrl:(NSInteger)frame
{
    NSString* format = [NSString stringWithFormat:@"%@/%@%@%@", [[NSBundle mainBundle] resourcePath], _prefix, _numberFormat, _suffix];
    NSString* path = [NSString stringWithFormat:format, _startFrame + frame];
    
    return [NSURL fileURLWithPath:path];
}

- (void)getBytes:(char*)buffer atFrame:(NSInteger)frame
{
    NSURL* url = [self frameUrl:frame];
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)url, nil);
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
    assert(CGImageGetWidth(image) == _width);
    assert(CGImageGetHeight(image) == _height);

    CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(image));
    CFDataGetBytes(rawData, CFRangeMake(0, CFDataGetLength(rawData)), (UInt8*)buffer);
    
    CGImageRelease(image);
    CFRelease(rawData);
    CFRelease(imageSource);
}

- (NSInteger)width
{
    return _width;
}

- (NSInteger)height
{
    return _height;
}

- (NSInteger)frameCount
{
    return _frameCount;
}

@end


@interface ISStreamSequence : ISSequence
{
    FILE* _filePtr;
    ISSequenceHeader_t _header;
    ISSequenceFrameInfo_t* _frameInfos;
    
    CFDictionaryRef _imageSourceOptions;

}

- (id)initWithFilepath:(NSString*)filepath;

@end

@implementation ISStreamSequence

- (id)initWithFilepath:(NSString*)filePath
{
    if ((self = [super init]))
    {
        if (!filePath)
        {
            return nil;
        }
        
        _filePtr = fopen([filePath cStringUsingEncoding:NSUTF8StringEncoding], "rb");
        
        if (!_filePtr)
        {
            return nil;
        }
        
        fread(&_header, sizeof(ISSequenceHeader_t), 1, _filePtr);
        
        if (_header.signature != IS_SEQUENCE_SIGNATURE)
        {
            fclose(_filePtr);
            return nil;
        }
        
        _frameInfos = malloc(sizeof(ISSequenceFrameInfo_t) * _header.frameCount);
        
        if (!_frameInfos)
        {
            fclose(_filePtr);
            return nil;
        }
        
        fread(_frameInfos, sizeof(ISSequenceFrameInfo_t), _header.frameCount, _filePtr);
        
        const void* keys[] = { kCGImageSourceShouldCache };
        const void* values[] = { kCFBooleanFalse };
        
        _imageSourceOptions = CFDictionaryCreate(nil, keys, values, 1, nil, nil);

    }
    return self;
}

- (void)dealloc
{
    CFRelease(_imageSourceOptions);
    fclose(_filePtr);
    free(_frameInfos);
}

- (void)getBytes:(char*)buffer atFrame:(NSInteger)frame
{
    assert(frame >= 0 && frame < _header.frameCount);
    
    uint32_t offset = _frameInfos[frame].position;
    uint32_t length = _frameInfos[frame].length;
    
    fseek(_filePtr, offset, SEEK_SET);
    fread(buffer, length, 1, _filePtr);
    
    CFDataRef dataRef = CFDataCreateWithBytesNoCopy(nil, (UInt8*)buffer, length, nil);
    CGImageSourceRef imageSource = CGImageSourceCreateWithData(dataRef, _imageSourceOptions);
    
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
    assert(CGImageGetBitsPerPixel(image) == 32);
    
    CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(image));
    CFDataGetBytes(rawData, CFRangeMake(0, CFDataGetLength(rawData)), (UInt8*)buffer);
    
    CGImageRelease(image);
    CFRelease(rawData);
    CFRelease(imageSource);
}

- (NSInteger)width
{
    return (NSInteger)_header.width;
}

- (NSInteger)height
{
    return (NSInteger)_header.height;
}

- (NSInteger)frameCount
{
    return (NSInteger)_header.frameCount;
}

@end


@implementation ISSequence

+ (ISSequence*)sequenceNamed:(NSString*)name
{
    return [[ISStreamSequence alloc] initWithFilepath:[[NSBundle mainBundle] pathForResource:name ofType:nil]];
}

+ (ISSequence*)sequenceFromFilepath:(NSString*)filepath
{
    return [[ISStreamSequence alloc] initWithFilepath:filepath];
}

+ (ISSequence*)sequenceFromPrefix:(NSString*)prefix
                     numberFormat:(NSString*)numberFormat
                           suffix:(NSString*)suffix
                       startFrame:(NSInteger)startFrame
                       frameCount:(NSInteger)count
{
    return [[ISPrefixSequence alloc] initWithPrefix:prefix
                                       numberFormat:numberFormat
                                             suffix:suffix
                                         startFrame:startFrame
                                         frameCount:count];
}

- (void)getBytes:(char*)buffer atFrame:(NSInteger)frame {}

- (NSInteger)width { return 0; }
- (NSInteger)height { return 0; }
- (NSInteger)frameCount { return 0; }

- (NSRange)range
{
    return NSMakeRange(0, [self frameCount]);
}

- (BOOL)validFrame:(NSInteger)frame
{
    return (frame >= 0 && frame < [self frameCount]);
}

@end

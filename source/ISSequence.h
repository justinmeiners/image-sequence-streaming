/* Create By: Justin Meiners */

#import <Foundation/Foundation.h>

#define IS_SEQUENCE_VERSION 2
#define IS_SEQUENCE_SIGNATURE 0x320

#define IS_SEQUENCE_FORMAT_JPG 2

/* both of these structures should be tightly packed with no alignment padding */
typedef struct
{
    uint32_t signature;
    uint32_t version;
    uint32_t format;
    uint32_t frameCount;
    uint16_t width;
    uint16_t height;
} ISSequenceHeader_t;

typedef struct
{
    uint32_t position;
    uint32_t length;
} ISSequenceFrameInfo_t;

@interface ISSequence : NSObject

// for sequences compiled into a single file
+ (ISSequence*)sequenceNamed:(NSString*)name;
+ (ISSequence*)sequenceFromFilepath:(NSString*)filepath;

// for a list of files which are in the resources bundle
+ (ISSequence*)sequenceFromPrefix:(NSString*)prefix
                     numberFormat:(NSString*)numberFormat
                           suffix:(NSString*)sufix
                       startFrame:(NSInteger)startFrame
                       frameCount:(NSInteger)count;

- (void)getBytes:(char*)buffer atFrame:(NSInteger)frame;

- (NSInteger)width;
- (NSInteger)height;
- (NSInteger)frameCount;
- (NSRange)range;
- (BOOL)validFrame:(NSInteger)frame;

@end

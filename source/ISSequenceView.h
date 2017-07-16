/* Create By: Justin Meiners */

#import <UIKit/UIKit.h>
#import "ISSequence.h"

#pragma mark -
#pragma mark ISSequenceView
#pragma mark -


/* the view will refresh drawing once every screen refresh */
#define kISSequnceViewRefreshIntervalDefault 2

/* if you see any artifacts try double or triple buffering */
#define kISSequnceViewBufferCount 2


/* 
 use this view to create your own custom sequence interaction/playback objects.
 Simply call jumpToFrame
 */
 
@interface ISSequenceView : UIView
{
    ISSequence* _sequence;
    NSInteger _refreshInterval;
    NSInteger _currentFrame;
    BOOL _useTextureCache;
}

/* texture caching involves using a CVOpenGLESTextureCache to take advantage of optimal texture
 upload speeds. It currently is not available on the simulator and will force to false. */


- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(NSInteger)interval
       useTextureCache:(bool)textureCache;

- (id)initWithSequence:(ISSequence*)sequence;

- (void)jumpToFrame:(NSInteger)frame;

- (NSInteger)currentFrame;
- (NSInteger)refreshInterval;
- (ISSequence*)sequence;

@end

#pragma mark -
#pragma mark ISSequencePlaybackView
#pragma mark -

@class ISSequencePlaybackView;

typedef enum
{
    kISSequencePlaybackDirectionForward = 1,
    kISSequencePlaybackDirectionBackward = -1
    
} ISSequencePlaybackDirection;

@protocol ISSequencePlaybackViewDelegate <NSObject>
@optional
- (void)sequencePlaybackViewFinishedPlayback:(ISSequencePlaybackView*)view;

@end

/* basic linear playback (a movie) */
@interface ISSequencePlaybackView : ISSequenceView
{
    BOOL _paused;
}

@property(nonatomic, assign)id <ISSequencePlaybackViewDelegate> delegate;
@property(nonatomic, assign)BOOL loops;
@property(nonatomic, assign)NSRange range;
@property(nonatomic, assign)ISSequencePlaybackDirection playbackDirection;
@property(nonatomic, assign)int animationInterval;

- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(NSInteger)interval
       useTextureCache:(BOOL)textureCache
                 loops:(BOOL)loops
                 range:(NSRange)range
     playbackDirection:(ISSequencePlaybackDirection)direction
              delegate:(id<ISSequencePlaybackViewDelegate>)delegate;

- (id)initWithSequence:(ISSequence*)sequence
                 loops:(BOOL)loops
                 range:(NSRange)range
     playbackDirection:(ISSequencePlaybackDirection)direction
              delegate:(id<ISSequencePlaybackViewDelegate>)delegate;



- (void)pause;
- (void)resume;
- (BOOL)paused;

@end

#pragma mark -
#pragma mark ISSequenceDragView
#pragma mark -

typedef enum
{
    kISSequnceDragDirectionHorizontal = 0,
    kISSequnceDragDirectionVertical,
} ISSequenceDragDirection;

@class ISSequenceDragView;

@protocol ISSequenceDragViewDelegate <NSObject>
@optional
- (void)sequenceViewDragStarted:(ISSequenceDragView*)view;
- (void)sequenceViewDragFinished:(ISSequenceDragView*)view;

@end

/* basic draw playback - i am thinking about adding intertia */
@interface ISSequenceDragView : ISSequenceView

@property(nonatomic, assign)BOOL loops;
@property(nonatomic, assign)NSRange range;
@property(nonatomic, assign)CGFloat dragSensitivity;
@property(nonatomic, assign)ISSequenceDragDirection dragDirection;
@property(nonatomic, assign)BOOL reverseDragDirection;
@property(nonatomic, assign)id <ISSequenceDragViewDelegate> delegate;
@property(nonatomic, readonly)BOOL dragging;

- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(NSInteger)interval
       useTextureCache:(BOOL)textureCache
                 loops:(BOOL)loops
                 range:(NSRange)range
         dragDirection:(ISSequenceDragDirection)dragDirection
       dragSensitivity:(CGFloat)dragSensitivity /* 1.0 = a finger drags across the width view plays through the entire sequence. 2.0 half drag etc */
              delegate:(id)delegate;

- (id)initWithSequence:(ISSequence*)sequence
                 loops:(BOOL)loops
                 range:(NSRange)range
         dragDirection:(ISSequenceDragDirection)dragDirection
       dragSensitivity:(CGFloat)dragSensitivity /* 1.0 = a finger drags across the width view plays through the entire sequence. 2.0 half drag etc */
              delegate:(id)delegate;


@end

#pragma mark -
#pragma mark ISSequenceGridView
#pragma mark -

@interface ISSequenceGridView : ISSequenceView
{
    NSInteger _row;
    NSInteger _column;
    NSInteger _rowCount;
    NSInteger _columnCount;
}
@property(nonatomic, assign)BOOL touchEnabled;
@property(nonatomic, assign)NSRange range;

- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(NSInteger)interval
       useTextureCache:(BOOL)textureCache
                 range:(NSRange)range
          framesPerRow:(NSInteger)rowCount
          touchEnabled:(NSInteger)touchEnabled;

- (id)initWithSequence:(ISSequence*)sequence
                 range:(NSRange)range
          framesPerRow:(NSInteger)rowCount
          touchEnabled:(NSInteger)touchEnabled;

- (void)jumpToFrameAtRow:(NSInteger)row
                  column:(NSInteger)column;


// x coordinate
- (NSInteger)row;

// y coordinate
- (NSInteger)column;

- (NSInteger)rowCount;
- (NSInteger)columnCount;

@end

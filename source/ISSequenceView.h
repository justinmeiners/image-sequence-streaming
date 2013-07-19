/*
 By: Justin Meiners
 
 Copyright (c) 2013 Inline Studios
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 */

#import <UIKit/UIKit.h>
#import "ISSequence.h"

#pragma mark -
#pragma mark ISSequenceView
#pragma mark -


/* the view will refresh drawing once every screen refresh */
#define kISSequnceViewRefreshIntervalDefault 1

/* if you see any artifacts try double or triple buffering */
#define kISSequnceViewBuffersDefault 1


@interface ISSequenceView : UIView
{
    ISSequence* _sequence;
    int _refreshInterval;
    int _currentFrame;
    BOOL _useTextureCache;
}

/* texture caching involves using a CVOpenGLESTextureCache to take advantage of optimal texture
 upload speeds. It currently is not available on the simulator and will force to false. */

- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(int)interval
       useTextureCache:(bool)textureCache;

- (void)jumpToFrame:(int)frame;

- (int)currentFrame;
- (int)refreshInterval;
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
       refreshInterval:(int)interval
       useTextureCache:(bool)textureCache
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

@interface ISSequenceDragView : ISSequenceView

@property(nonatomic, assign)BOOL loops;
@property(nonatomic, assign)NSRange range;
@property(nonatomic, assign)float dragSensitivity;
@property(nonatomic, assign)ISSequenceDragDirection dragDirection;
@property(nonatomic, assign)BOOL reverseDragDirection;
@property(nonatomic, assign)id <ISSequenceDragViewDelegate> delegate;
@property(nonatomic, readonly)BOOL dragging;

- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(int)interval
       useTextureCache:(bool)textureCache
                 loops:(BOOL)loops
                 range:(NSRange)range
         dragDirection:(ISSequenceDragDirection)dragDirection
       dragSensitivity:(float)dragSensitivity
              delegate:(id)delegate;

@end

#pragma mark -
#pragma mark ISSequenceGridView
#pragma mark -

@interface ISSequenceGridView : ISSequenceView
{
    int _row;
    int _column;
    int _rowCount;
    int _columnCount;
}
@property(nonatomic, assign)BOOL touchEnabled;
@property(nonatomic, assign)NSRange range;

- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(int)interval
       useTextureCache:(bool)textureCache
                 range:(NSRange)range
          framesPerRow:(int)rowCount
          touchEnabled:(int)touchEnabled;

- (void)jumpToFrameAtRow:(int)row
                  column:(int)column;


// x coordinate
- (int)row;

// y coordinate
- (int)column;

- (int)rowCount;
- (int)columnCount;

@end

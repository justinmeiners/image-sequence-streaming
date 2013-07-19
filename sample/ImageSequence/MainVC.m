//
//  MainVC.m
//  ImageSequence
//
//  Created by Justin Meiners on 7/19/13.
//  Copyright (c) 2013 Inline Studios. All rights reserved.
//

#import "MainVC.h"
#import "ISSequenceView.h"

@interface MainVC ()
{
    ISSequenceDragView* sequenceView;
}
@end

@implementation MainVC


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.frame = CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    
    
    ISSequence* sequence = [ISSequence sequenceNamed:@"car.seq"];
    
    
    sequenceView = [[ISSequenceDragView alloc] initWithSequence:sequence
                                        refreshInterval:1
                                        useTextureCache:YES
                                                  loops:true
                                                  range:[sequence range]
                                          dragDirection:kISSequnceDragDirectionHorizontal
                                        dragSensitivity:2.0
                                               delegate:NULL];
    
    sequenceView.reverseDragDirection = false;
    [self.view addSubview:sequenceView];
    
    sequenceView.frame = self.view.bounds;
    
    
    /*
     ISSequencePlaybackView* view = [[ISSequencePlaybackView alloc]
     initWithSequence:sequence
     refreshInterval:1
     useTextureCache:YES
     loops:YES
     range:[sequence range]
     playbackDirection:kISSequencePlaybackDirectionForward
     delegate:nil];
     */
    
    
    /*
     ISSequence* sequence = [ISSequence sequenceNamed:@"grid.seq"];
     
     ISSequenceGridView* view = [[ISSequenceGridView alloc] initWithSequence:sequence
     refreshInterval:1
     useTextureCache:YES
     range:[sequence range]
     rowCount:21
     touchEnabled:YES];
     */
    
    
    
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
}

@end

/*
 By: Justin Meiners
 
 Copyright (c) 2015 Justin Meiners
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 */
#import "ViewController.h"
#import "ISSequenceView.h"

@interface ViewController ()
{
    ISSequenceDragView* _sequenceView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ISSequence* sequence = [ISSequence sequenceNamed:@"car.seq"];
    
    
    _sequenceView = [[ISSequenceDragView alloc] initWithSequence:sequence
                                                refreshInterval:1
                                                useTextureCache:YES
                                                          loops:true
                                                          range:[sequence range]
                                                  dragDirection:kISSequnceDragDirectionHorizontal
                                                dragSensitivity:2.0
                                                       delegate:nil];
    
    _sequenceView.reverseDragDirection = false;
    [self.view addSubview:_sequenceView];
    
    _sequenceView.frame = self.view.bounds;
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillLayoutSubviews
{
    float aspect;
    float width;
    float height;
    
    if (self.view.bounds.size.width < self.view.bounds.size.height)
    {
        aspect = _sequenceView.sequence.height / (float)_sequenceView.sequence.width;
        
        width = self.view.bounds.size.width;
        height = self.view.bounds.size.width * aspect;
    }
    else
    {
        aspect = _sequenceView.sequence.width / (float)_sequenceView.sequence.height;
        
        width = self.view.bounds.size.height * aspect;
        height = self.view.bounds.size.height;
    }

    _sequenceView.frame = CGRectMake(self.view.bounds.size.width / 2.0 - width / 2.0, self.view.bounds.size.height / 2.0 - height / 2.0, width, height);

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

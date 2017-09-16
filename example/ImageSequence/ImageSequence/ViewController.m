/* Create By: Justin Meiners */

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
    
    
    // ISSequence* sequence = [ISSequence sequenceNamed:@"car.seq"];
    
    
    ISSequence* sequence = [ISSequence sequenceWithNameFormat:@"source/car_%04li.jpg"
                                                   startFrame:1
                                                   frameCount:155];
    
    
    _sequenceView = [[ISSequenceDragView alloc] initWithSequence:sequence
                                                          loops:true
                                                          range:[sequence range]
                                                  dragDirection:kISSequnceDragDirectionHorizontal
                                                dragSensitivity:2.0
                                                       delegate:nil];
    
    _sequenceView.reverseDragDirection = false;
    [self.view addSubview:_sequenceView];
    
    
    /*
    _sequenceView = [[ISSequencePlaybackView alloc] initWithSequence:sequence
                                                               loops:YES
                                                               range:[sequence range]
                                                   playbackDirection:kISSequencePlaybackDirectionForward
                                                            delegate:nil];
    [self.view addSubview:_sequenceView];
     */
    
    
    _sequenceView.frame = self.view.bounds;
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillLayoutSubviews
{
    CGFloat aspect;
    CGFloat width;
    CGFloat height;
    
    if (self.view.bounds.size.width < self.view.bounds.size.height)
    {
        aspect = _sequenceView.sequence.height / (CGFloat)_sequenceView.sequence.width;
        
        width = self.view.bounds.size.width;
        height = self.view.bounds.size.width * aspect;
    }
    else
    {
        aspect = _sequenceView.sequence.width / (CGFloat)_sequenceView.sequence.height;
        
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

image-sequence-streaming
========================

### What are image sequences? ###

Image sequences are animations composed from many individual images (frames). They are very similar to video files, but are designed to be played back non-linearly, meaning frames can be accessed in any order and animations can be played back in any direction.


On mobile devices image sequences are a powerful tool for creating interactive content with outstanding visual quality.


### What is sequence streaming? ###


Unfortunately, most iOS image sequence approaches out there (using UIImageView or custom CGImage code) require the entire animation, or many frames, to be loaded into memory at once. This method has several difficult drawbacks:
- Long load times.
- Large memory footprint.
- Limitations on animation length
- Slow playback speeds

This project aims to overcome these limitations by loading individual frames as needed, into memory from an optimized file format. This approach has several advantageous:
- Essentially no load times. (As fast as playback speed)
- Constant small memory footprint (a few frames at most) regardless of sequence length.  
- Nearly unlimited sequence length.
- Lossless image compression.
- Smooth framerates (Often 30-60 FPS which is faster than conventional video playback)
- Scaling playback - lower resolution animations can be displayed in a larger view improve performance and reduce data size.

The main tradeoff for using approach is that filesize for is often significantly larger than the original images and sequences must be precompiled using a command line tool.


### Credits: ###
 **[LZ4](http://fastcompression.blogspot.com/p/lz4.html)** is one of the  most efficient realtime decompression algorithms out there and a fundamental piece of this project. Without it, realtime playback would not have been acceptable.

 Also thanks to my friend **Steve Glauser** for creating and rendering the sample image sequence.

### Components: ###
- A MacOS X command line tool for compiling a collection of PNG frames into an optimized sequence file. (sequencebuild)
- A C module for working with sequence files. (ISSequenceStream)
- An Objective-C class for working with sequence files. (ISSequence)
- OpenGL ES and Core Video powered UIView class for displaying interactive sequences.
- Interactive UIView classes for linear playback, horizontal and vertical drag control, and grid cell control, (ISSequenceView...)
- An example project and sample animation sequence.


### Usage: ###


```Objective-C
/* loading a sequence */
ISSequence* sequence = [ISSequence sequenceNamed:@"sequence.seq"];

```

```Objective-C
/* creating a drag control view */
ISSequenceDragView* view = [[ISSequenceDragView alloc] initWithSequence:sequence
                                                        refreshInterval:1 /* refresh rate */
                                                        useTextureCache:YES /* texture cache is an optional core video optimization */
                                                                  loops:YES
                                                                  range:[sequence range]
                                                          dragDirection:kISSequnceDragDirectionHorizontal
                                                        dragSensitivity:2.0
                                                               delegate:nil];

[self addSubview:view];

```

```Objective-C
/* creating a grid control view */

/*
 when touch is enabled for grid view touches cause the view to load the grid cell nearest to the touch
 */

ISSequenceGridView* view = [[ISSequenceGridView alloc] initWithSequence:sequence
                                                        refreshInterval:1
                                                        useTextureCache:YES
                                                                  range:[sequence range]
                                                           framesPerRow:21
                                                           touchEnabled:YES];


[self addSubview:view];

```

**Note:** Simulator performance is not a good indicator of device performance in general, and especially in this project. Always be sure to test on device.

### Sequence Files ###

Animations must be compiled using the included sequencebuild tool before they can be loaded into an app. Use the following terminal command (after building the tool).

```
sequencebuild path/to/image_folder path/to/save_file

```

An optional **-nocompress** flag can be applied. This greatly increases filesize, but my result in faster playback for smaller sequences. Profile to determine best performance.

### Example: ###

Due to Github's limit of 100mb per file, the quality of the sample animation included in this project has been limited. The original resolution was reduced from 1024x768 to 960x720 and every other frame was removed. In your own apps you can safely expect to display higher quality animations.

![car1](https://raw.github.com/narpas/image-sequence-streaming/master/screenshots/screen1.png)
![car2](https://raw.github.com/narpas/image-sequence-streaming/master/screenshots/screen2.png)
![car3](https://raw.github.com/narpas/image-sequence-streaming/master/screenshots/screen3.png)

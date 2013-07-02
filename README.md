image-sequence-streaming
========================

Image sequences are a powerful tool for creating interactive content in iOS applications. Unfortuantly, conventional image sequences (using UIImageView or homebrew) have several severe drawbacks as they require all or many frames to be loaded into memory at once.
- Long load times.
- Huge memory footpring.
- Hard limit on the number of frames due to memory.
- Slow framerates due to core graphics/UIKit limitations.

This project aims to overcome these limitations by streaming individual frames, as fast as possible, from an optimized sequence file. This unique approach offers many benefits over traditional methods:
- No load times.
- Constant small memory footprint (a few frames at most) regardless of frame count.  
- Nearly unlimted sequence length.
- Silky smooth framerates that often reach 30-60 FPS which is faster than conventional video playback.
- Sequence stretching - a sequence can be made at a smaller resolution than displayed to improve performance and reduce data size.

The only tradeoffs for this approach is that filesize for a sequence is often significantly larger than the original images and sequences must be precompiled.

Included in this project:
- A command line tool for building a collection of PNGs into a single optimized sequence file. (sequencebuild)
- A C module for loading sequences and random frame access. (ISSequenceHandle)
- An Objective-C wrapper for the C module (ISSequence)
- OpenGL ES and Core Video powered Objective-C view classes for displaying interactive sequences. These include a base renderer, linear playback, horizontal and vertical drag control, and grid cell control, (ISSequenceView, etc)


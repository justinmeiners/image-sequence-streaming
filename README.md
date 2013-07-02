image-sequence-streaming
========================

Image sequences are a powerful tool for creating interactive content in iOS applications. Unfortuantly, conventional image sequences have several severe drawbacks as they require all or many frames to be loaded at once.
- Long load times.
- Huge memory usage.
- Hard limit on the number of frames.
- Slow rendering due to core graphics/UIKit limitations.

This project aims to overcome these limitations by streaming individual frames, as fast as possible, from an optimzied sequence file.

Included in this project:
- A command line tool for building a collection of PNGs into a single optimized sequence file. (sequencebuild)
- A C module for loading sequences and random frame access. (ISSequenceHandle)
- An Objective-C wrapper for the C module (ISSequence)
- OpenGL ES powered Objective-C view classes for displaying interactive sequences. These include a base renderer, linear playback, horizontal and vertical drag control, and grid cell control, (ISSequenceView, etc)


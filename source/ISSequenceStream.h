/*
 By: Justin Meiners
 
 Copyright (c) 2015 Justin Meiners
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 */

#ifndef IS_SEQUENCE_H
#define IS_SEQUENCE_H

#include "ISSequenceInfo.h"
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ISSequenceStream* ISSequenceStreamRef;
    
extern ISSequenceStreamRef ISSequenceStreamCreate (const char* filePath);
extern void ISSequenceStreamDestroy (ISSequenceStreamRef sequence);

extern void ISSequenceStreamCopyFrame (ISSequenceStreamRef sequence, int frameNumber, char* buffer);

extern uint32_t ISSequenceStreamFrameCount (ISSequenceStreamRef sequence);
extern uint32_t ISSequenceStreamWidth (ISSequenceStreamRef sequence);
extern uint32_t ISSequenceStreamHeight (ISSequenceStreamRef sequence);
extern size_t ISSequenceStreamFrameSize (ISSequenceStreamRef sequence);

#ifdef __cplusplus
}
#endif

#endif

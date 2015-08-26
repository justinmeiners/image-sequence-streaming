/*
 By: Justin Meiners
 
 Copyright (c) 2015 Justin Meiners
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 */

#ifndef IS_SEQUENCE_INFO_H
#define IS_SEQUENCE_INFO_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
    
#define IS_SEQUENCE_SIGNATURE 0x320
    
#define IS_SEQUENCE_COMPRESSION 1
#define IS_SEQUENCE_NO_COMPRESSION 0
    
    /* both of these structures should be tightly packed with no alignment padding */
    typedef struct
    {
        int32_t _signature;
        uint32_t _compression;
        uint32_t _frameCount;
        uint16_t _width;
        uint16_t _height;
        uint32_t _bytesPerRow;
        
    } ISSequenceInfo_t;
    
    typedef struct
    {
        uint32_t _position;
        uint32_t _length;
        
    } ISSequenceFrameInfo_t;
    
    
#ifdef __cplusplus
}
#endif

#endif

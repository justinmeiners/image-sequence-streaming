/* Create By: Justin Meiners */

#ifndef IS_SEQUENCE_INFO_H
#define IS_SEQUENCE_INFO_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
    
#define IS_SEQUENCE_VERSION 2
#define IS_SEQUENCE_SIGNATURE 0x320
    
#define IS_SEQUENCE_FORMAT_JPG 2
    
    /* both of these structures should be tightly packed with no alignment padding */
    typedef struct
    {
        uint32_t signature;
        uint32_t version;
        uint32_t format;
        uint32_t frameCount;
        uint16_t width;
        uint16_t height;
    } ISSequenceHeader_t;
    
    typedef struct
    {
        uint32_t position;
        uint32_t length;
    } ISSequenceFrameInfo_t;
    
    
#ifdef __cplusplus
}
#endif

#endif

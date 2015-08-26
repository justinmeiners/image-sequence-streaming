/*
 By: Justin Meiners
 
 Copyright (c) 2015 Justin Meiners
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 */

#include "ISSequenceStream.h"
#include <stdlib.h>
#include <memory.h>
#include <assert.h>
#include "lz4.h"

struct ISSequenceStream
{
    ISSequenceInfo_t _info;
    ISSequenceFrameInfo_t* _frameInfos;
    char* _readBuffer;
    uint32_t _position;
    
    FILE* _filePtr;
    size_t _frameSize;
};


ISSequenceStreamRef ISSequenceStreamCreate (const char* filePath)
{
    assert(filePath);
    
    ISSequenceStreamRef sequence = malloc(sizeof(struct ISSequenceStream));
    
    if (!sequence)
    {
        return NULL;
    }
    
    memset(sequence, 0x0, sizeof(struct ISSequenceStream));
         
    FILE* file = fopen(filePath, "rb");
    
    if (!file)
    {
        free(sequence);
        return NULL;
    }
    
    fread(&sequence->_info, sizeof(ISSequenceInfo_t), 1, file);
    
    if (sequence->_info._signature != IS_SEQUENCE_SIGNATURE)
    {
        free(sequence);
        fclose(file);
        return NULL;
    }
    
    sequence->_frameInfos = malloc(sizeof(ISSequenceFrameInfo_t) * sequence->_info._frameCount);
    
    if (!sequence->_frameInfos)
    {
        free(sequence);
        fclose(file);
        return NULL;
    }
    
    fread(sequence->_frameInfos, sizeof(ISSequenceFrameInfo_t), sequence->_info._frameCount, file);
    
    sequence->_frameSize = sequence->_info._height * sequence->_info._bytesPerRow;
    
    sequence->_filePtr = file;
    
    if (sequence->_info._compression == IS_SEQUENCE_COMPRESSION)
    {
        sequence->_readBuffer = malloc(sequence->_frameSize);
        
        if (!sequence->_readBuffer)
        {
            free(sequence);
            fclose(file);
            return NULL;
        }
    }
    
    sequence->_position = 0;

    return sequence;
}

void ISSequenceStreamDestroy (ISSequenceStreamRef sequence)
{
    if (sequence)
    {
        if (sequence->_filePtr)
        {
            fclose(sequence->_filePtr);
            sequence->_filePtr = NULL;
        }
        
        if (sequence->_readBuffer)
        {
            free(sequence->_readBuffer);
            sequence->_readBuffer = NULL;
        }
        
        if (sequence->_frameInfos)
        {
            free(sequence->_frameInfos);
            sequence->_frameInfos = NULL;
        }
        
        free(sequence);
    }
}

void ISSequenceStreamCopyFrame (ISSequenceStreamRef sequence, int frameNumber, char* buffer)
{
    assert(sequence);
    assert(frameNumber >= 0 && frameNumber < sequence->_info._frameCount);
    
    fseek(sequence->_filePtr, sequence->_frameInfos[frameNumber]._position, SEEK_SET);
    
    if (sequence->_info._compression == IS_SEQUENCE_COMPRESSION)
    {
        fread(sequence->_readBuffer, sequence->_frameInfos[frameNumber]._length, 1, sequence->_filePtr);
        unsigned int outlength = (unsigned int)sequence->_frameSize;
        LZ4_uncompress(sequence->_readBuffer, buffer, outlength);
    }
    else
    {
        fread(buffer, sequence->_frameInfos[frameNumber]._length, 1, sequence->_filePtr);
    }
}

uint32_t ISSequenceStreamFrameCount (ISSequenceStreamRef sequence)
{
    assert(sequence);
    return sequence->_info._frameCount;
}

uint32_t ISSequenceStreamWidth (ISSequenceStreamRef sequence)
{
    assert(sequence);
    return sequence->_info._width;
}

uint32_t ISSequenceStreamHeight (ISSequenceStreamRef sequence)
{
    assert(sequence);
    return sequence->_info._height;
}

size_t ISSequenceStreamFrameSize (ISSequenceStreamRef sequence)
{
    assert(sequence);
    return sequence->_frameSize;
}


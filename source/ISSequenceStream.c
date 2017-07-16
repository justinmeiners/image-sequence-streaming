/* Create By: Justin Meiners */

#include "ISSequenceStream.h"
#include <stdlib.h>
#include <memory.h>
#include <assert.h>
#include <ImageIO/ImageIO.h>

struct ISSequenceStream
{
    ISSequenceHeader_t header;
    ISSequenceFrameInfo_t* frameInfos;
    uint32_t position;
    FILE* filePtr;
    CFDictionaryRef imageSourceDict;
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
    
    fread(&sequence->header, sizeof(ISSequenceHeader_t), 1, file);
    
    if (sequence->header.signature != IS_SEQUENCE_SIGNATURE)
    {
        free(sequence);
        fclose(file);
        return NULL;
    }
    
    sequence->frameInfos = malloc(sizeof(ISSequenceFrameInfo_t) * sequence->header.frameCount);
    
    if (!sequence->frameInfos)
    {
        free(sequence);
        fclose(file);
        return NULL;
    }
    
    fread(sequence->frameInfos, sizeof(ISSequenceFrameInfo_t), sequence->header.frameCount, file);
    
    sequence->filePtr = file;
    sequence->position = 0;
    
    const void* keys[] = { kCGImageSourceShouldCache };
    const void* values[] = { kCFBooleanFalse };
    
    sequence->imageSourceDict = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);

    return sequence;
}

void ISSequenceStreamDestroy (ISSequenceStreamRef sequence)
{
    if (sequence)
    {
        if (sequence->filePtr)
        {
            fclose(sequence->filePtr);
            sequence->filePtr = NULL;
        }
        
        if (sequence->frameInfos)
        {
            free(sequence->frameInfos);
            sequence->frameInfos = NULL;
        }
        
        CFRelease(sequence->imageSourceDict);
        
        free(sequence);
    }
}

void ISSequenceStreamCopyFrame (ISSequenceStreamRef sequence, int frameNumber, char* buffer)
{
    assert(sequence);
    assert(frameNumber >= 0 && frameNumber < sequence->header.frameCount);
    
    int offset = sequence->frameInfos[frameNumber].position;
    int length = sequence->frameInfos[frameNumber].length;
    
    fseek(sequence->filePtr, offset, SEEK_SET);
    fread(buffer, length, 1, sequence->filePtr);
        
    CFDataRef dataRef = CFDataCreateWithBytesNoCopy(NULL, (UInt8*)buffer, length, NULL);
    CGImageSourceRef imageSource = CGImageSourceCreateWithData(dataRef, sequence->imageSourceDict);
    
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    
    CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(image));
    CFDataGetBytes(rawData, CFRangeMake(0, CFDataGetLength(rawData)), (UInt8*)buffer);
    
    CGImageRelease(image);
    CFRelease(rawData);
    CFRelease(imageSource);
}

uint32_t ISSequenceStreamFrameCount (ISSequenceStreamRef sequence)
{
    assert(sequence);
    return sequence->header.frameCount;
}

uint32_t ISSequenceStreamWidth (ISSequenceStreamRef sequence)
{
    assert(sequence);
    return sequence->header.width;
}

uint32_t ISSequenceStreamHeight (ISSequenceStreamRef sequence)
{
    assert(sequence);
    return sequence->header.height;
}



/*
 Copyright (c) 2015 Justin Meiners
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ISSequenceInfo.h"
#import "lz4.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        
        if (argc < 3)
        {
            printf("sequencebuild (-nocompress) [input_dir] [output_file]\n");
            return EXIT_FAILURE;
        }
        
        BOOL compressData = YES;
        
        int i;
        for (i = 1; i < argc - 2; i++)
        {
            if (strcmp(argv[i], "-nocompress") == 0)
            {
                compressData = NO;
            }
        }
        
        NSString* inputPath = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
        NSString* outputPath = [NSString stringWithCString:argv[i + 1] encoding:NSUTF8StringEncoding];
        
        if (!inputPath || !outputPath)
        {
            printf("bad paths\n");
            return EXIT_FAILURE;
        }
        
        FILE* outputFile = fopen([outputPath UTF8String], "wb");
        
        if (!outputFile)
        {
            printf("failed to open output file: %s\n", [outputPath UTF8String]);
            return EXIT_FAILURE;
        }
        
        
        NSError* error = NULL;
        NSArray* inputs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inputPath error:&error];
        
        if (error)
        {
            NSLog(@"%@", error);
            return EXIT_FAILURE;
        }
        
        
        NSMutableArray* sequenceInputs = [NSMutableArray array];
        
        for (NSString* input in inputs)
        {
            if ([[[input pathExtension] lowercaseString] isEqualToString:@"png"])
            {
                [sequenceInputs addObject:input];
            }
        }
        
        int frameCount = (int)[sequenceInputs count];
        
        ISSequenceFrameInfo_t* frameInfos = malloc(sizeof(ISSequenceFrameInfo_t) * frameCount);
        
        ISSequenceInfo_t info;
        info._signature = IS_SEQUENCE_SIGNATURE;
        info._frameCount = (uint32_t)frameCount;
        
        if (compressData)
        {
            info._compression = IS_SEQUENCE_COMPRESSION;
        }
        else
        {
            info._compression = IS_SEQUENCE_NO_COMPRESSION;
        }
        
        unsigned long infoFilePosition = 0;
        
        BOOL infoSelected = NO;
        
        for (i = 0; i < frameCount; i ++)
        {
            printf("processing: %s\n", [[sequenceInputs objectAtIndex:i] UTF8String]);
            
            NSString* fullInputPath = [inputPath stringByAppendingPathComponent:[sequenceInputs objectAtIndex:i]];
            
            CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((CFDataRef)[NSData dataWithContentsOfFile:fullInputPath]);
            CGImageRef image = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, YES, kCGRenderingIntentDefault);
            
            NSUInteger imageWidth = CGImageGetWidth(image);
            NSUInteger imageHeight = CGImageGetHeight(image);
            
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            
            size_t buffSize = imageHeight * imageWidth * 4 * sizeof(char);
            
            char* rawData = (char*)malloc(buffSize);
            memset(rawData, 0x0, buffSize);
            char* outbuffer = (char*)malloc(buffSize);
            
            NSUInteger bytesPerPixel = 4;
            NSUInteger bytesPerRow = bytesPerPixel * imageWidth;
            NSUInteger bitsPerComponent = 8;
            CGContextRef context = CGBitmapContextCreate(rawData,
                                                         imageWidth,
                                                         imageHeight,
                                                         bitsPerComponent, bytesPerRow, colorSpace,
                                                         kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            
            CGColorSpaceRelease(colorSpace);
            CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image);
            CGContextRelease(context);
            CGImageRelease(image);
            CGDataProviderRelease(imgDataProvider);
            
            if (!infoSelected)
            {
                info._width = (uint16_t)imageWidth;
                info._height = (uint16_t)imageHeight;
                info._bytesPerRow = (uint32_t)bytesPerRow;
                
                printf("width: %i\n", (int)imageWidth);
                printf("height: %i\n", (int)imageHeight);
                printf("bytes per row: %i\n", (int)bytesPerRow);
                
                /* write file header */
                fwrite(&info, sizeof(ISSequenceInfo_t), 1, outputFile);
                
                infoFilePosition = ftell(outputFile);
                
                /* write frame info which we will overwrite later */
                fwrite(frameInfos, sizeof(ISSequenceFrameInfo_t), frameCount, outputFile);
                
                infoSelected = YES;
            }
            else
            {
                if (imageWidth != info._width ||
                    imageHeight != info._height)
                {
                    printf("images do not match in size\n");
                    return EXIT_FAILURE;
                }
            }
            
            size_t outlength = buffSize;
            
            if (compressData)
            {
                outlength = LZ4_compress(rawData, outbuffer, (int)buffSize);
                printf("%f%% of raw size\n", outlength / (float)buffSize);
            }
            else
            {
                memcpy(outbuffer, rawData, buffSize);
            }
            
            frameInfos[i]._position = (uint32_t)ftell(outputFile);
            frameInfos[i]._length = (uint32_t)outlength;
            
            fwrite(outbuffer, outlength, 1, outputFile);
            
            free(rawData);
            free(outbuffer);
        }
        
        /* seek back to the beginning, write file info */
        fseek(outputFile, infoFilePosition, SEEK_SET);
        fwrite(frameInfos, sizeof(ISSequenceFrameInfo_t), frameCount, outputFile);
        fclose(outputFile);
        
        printf("done\n");
    }
    
    return 0;
}


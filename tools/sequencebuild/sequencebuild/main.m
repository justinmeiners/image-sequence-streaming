/* Create By: Justin Meiners */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ISSequence.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        
        if (argc < 3)
        {
            printf("sequencebuild [input_dir] [output_file]\n");
            return EXIT_FAILURE;
        }
        
        NSString* inputPath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSString* outputPath = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
        
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
            if ([[[input pathExtension] lowercaseString] isEqualToString:@"jpg"])
            {
                [sequenceInputs addObject:input];
            }
        }
        [sequenceInputs sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        
        int frameCount = (int)[sequenceInputs count];
        
        ISSequenceFrameInfo_t* frameInfos = malloc(sizeof(ISSequenceFrameInfo_t) * frameCount);
        
        ISSequenceHeader_t header;
        header.signature = IS_SEQUENCE_SIGNATURE;
        header.version = IS_SEQUENCE_VERSION;
        header.frameCount = (uint32_t)frameCount;
        header.format = IS_SEQUENCE_FORMAT_JPG;
        
        unsigned long infoFilePosition = 0;
        
        BOOL infoSelected = NO;
        
        for (int i = 0; i < frameCount; i ++)
        {
            printf("%s\n", [[sequenceInputs objectAtIndex:i] UTF8String]);
            
            NSString* fullInputPath = [inputPath stringByAppendingPathComponent:[sequenceInputs objectAtIndex:i]];
            
            NSData* rawImageData = [NSData dataWithContentsOfFile:fullInputPath];
            
            CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((CFDataRef)rawImageData);
            CGImageRef image = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, YES, kCGRenderingIntentDefault);
            
            if (CGImageGetBitsPerPixel(image) != 32)
            {
                printf("image format is incorrect\n");
                return EXIT_FAILURE;
            }
            
            NSUInteger imageWidth = CGImageGetWidth(image);
            NSUInteger imageHeight = CGImageGetHeight(image);
            
            printf("  w: %lu h: %lu\n", imageWidth, imageHeight);

            
            CGImageRelease(image);
            
            if (!infoSelected)
            {
                header.width = (uint16_t)imageWidth;
                header.height = (uint16_t)imageHeight;
                

                /* write file header */
                fwrite(&header, sizeof(ISSequenceHeader_t), 1, outputFile);
                
                infoFilePosition = ftell(outputFile);
                
                /* write incomplete frame info which we will overwrite later */
                fwrite(frameInfos, sizeof(ISSequenceFrameInfo_t), frameCount, outputFile);
                
                infoSelected = YES;
            }
            else
            {
                if (imageWidth != header.width ||
                    imageHeight != header.height)
                {
                    printf("images do not match in size\n");
                    return EXIT_FAILURE;
                }
            }

            size_t imageLength = [rawImageData length];
            
            frameInfos[i].position = (uint32_t)ftell(outputFile);
            frameInfos[i].length = (uint32_t)imageLength;
            
            printf("  offest: %i, size %i\n", frameInfos[i].position, frameInfos[i].length);
            
            fwrite([rawImageData bytes], imageLength, 1, outputFile);
            
            [rawImageData release];
        }
        
        /* seek back to the beginning, write file info */
        fseek(outputFile, infoFilePosition, SEEK_SET);
        fwrite(frameInfos, sizeof(ISSequenceFrameInfo_t), frameCount, outputFile);
        fclose(outputFile);
        
        printf("done\n");
    }
    
    return 0;
}


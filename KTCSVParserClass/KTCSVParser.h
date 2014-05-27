//
//  KTCSVParser.h
//
// Copyright (c) 2013-2014 Karthikeya Udupa KM
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import <Foundation/Foundation.h>

/**
 `KTCSVParserErrorCode` provides error code to handle errors.
 */
enum {
    KTCSVParserErrorCodeInvalidFilePath = 1,
    KTCSVParserErrorCodeInvalidContent = 2,
    KTCSVParserErrorCodeInvalidAccessMode = 3,
    KTCSVParserErrorCodeFileExists = 4
};
typedef NSUInteger KTCSVParserErrorCode;


/**
 `KTCSVParserMode` provides the mode in which the parser is being used.
 */
enum {
    KTCSVParserModeNotSet = 0,
    KTCSVParserModeRead = 1,
    KTCSVParserModeWrite = 2
};
typedef NSUInteger KTCSVParserMode;


#pragma mark Block Typedefs
typedef void (^SuccessReadCompleteBlock)(id responseObject);
typedef void (^FailureBlock)(NSError *errorObject);
typedef void (^SuccessWriteCompleteBlock)(void);
#pragma mark -

@class KTCSVParser;

/**
 `KTCSVParserDelegate` helps in passing the values of the rows/columns to be
 passed to the delegate.
 */
@protocol KTCSVParserDelegate <NSObject>

@optional

/**
 The delegate for parsing/writing the CSV file.
 */
- (void)parserDidBeginDocument:(KTCSVParser *)parser;
- (void)parserDidEndDocument:(KTCSVParser *)parser;

- (void)parser:(KTCSVParser *)parser didBeginRow:(NSUInteger)rowNumber;
- (void)parser:(KTCSVParser *)parser didEndRow:(NSUInteger)rowNumber;
- (void)parser:(KTCSVParser *)parser
  didReadValue:(NSString *)value
      atColumn:(NSUInteger)columnNumber
         atRow:(NSUInteger)rowNumber;
- (void)parser:(KTCSVParser *)parser didFailWithError:(NSError *)error;
- (void)parser:(KTCSVParser *)parser wroteRowAtIndex:(NSUInteger)rowNumber;

@end

/**
 `KTCSVParser` helps parse CSV files and handle CSV content to write to a file.
 */
@interface KTCSVParser : NSObject

@property(assign) id<KTCSVParserDelegate> delegate;

///---------------------------
/// @name Initialisation for `KTCSVParser` class.
///---------------------------

/**
 Initialise the object with the CSV file at the filepath and associates with the
 delegates.
 
 @param filePath  String representing the path of the file.
 @param delimiter String used as a separator between columns.
 @param Delegate  `KTCSVParserDelegate` type object for callbacks.
 */
- (KTCSVParser *)initWithCSVFileReadPath:(NSString *)filePath
                          usingDelimiter:(NSString *)delimiter
                            withDelegate:(id<KTCSVParserDelegate>)delegate;

///---------------------------
/// @name Methods for CSV file reading (Object Methods)
///---------------------------

/**
 Begins parsing the file set in the filepath, the values are provided through
 `KTCSVParserDelegate` provided in the init function in an asynchronous manner.
 */
- (void)parseFile;

/**
 Begins parsing the file set in the filepath, the values are provided through
 `KTCSVParserDelegate` provided in the init function in an syncronous manner
 manner. Should not be used as it would block the main thread.
 */
- (void)parseFile:(BOOL)asyncMode;

///---------------------------
/// @name Methods for CSV file reading (Class Methods) in the form of an blocks
/// as an abstraction to delegation process.
///---------------------------

/**
 Reads the CSV file at the filepath and returns back as an object (Array).
 
 @param filePath String representing the path of the file.
 @param delimiter String used as a separator between columns.
 @param successCallback Callback returning the successful result on completion.
 @param errorCallback Callback returning the failure message on failure.
 */
+ (void)parseCSVFilePath:(NSString *)filePath
          usingDelimiter:(NSString *)delimiter
               onSuccess:(SuccessReadCompleteBlock)successCallback
                 onError:(FailureBlock)failureCallback;

///---------------------------
/// @name Methods for CSV file writing from an array of string array.
///---------------------------

/**
 Write the object as a csv file at the provided filepath with the encoding and
 the delimiter provided.
 
 @param filePath String representing the path of the file.
 @param delimiter String used as a separator between columns.
 @param encoding  Encoding format for the content.
 @param Delegate  `KTCSVParserDelegate` type object for callbacks.
 */
- (KTCSVParser *)initWithCSVFileWritePath:(NSString *)filePath
                             withEncoding:(NSStringEncoding)encoding
                           usingDelimiter:(NSString *)delimiter
                             withDelegate:(id<KTCSVParserDelegate>)delegate;

/**
 Begins writing the content to the file and provide results through the
 `KTCSVParserDelegate` provided in the init function in async non blocking mode.
 */
- (void)writeContent:(NSArray *)content;

/**
 Begins writing the content to the file and provide results through the
 `KTCSVParserDelegate` provided in the init function in syncronous manner,
 should not be used provided for backward compatilbity.
 */
- (void)writeContent:(NSArray *)content
         inAsyncMode:(BOOL)asyncMode
           withError:(NSError **)err;

///---------------------------
/// @name Methods for CSV file writing from an array of string array using
/// blocks as an abstraction to delegation process.
///---------------------------

/**
 Write the object as a csv file at the provided filepath with the encoding and
 the delimiter provided and when complete use the callback  to provide
 information.
 
 @param filePath String representing the path of the file.
 @param delimiter String used as a separator between columns.
 @param encoding  Encoding format for the content.
 @param successCallback Callback called after completing of  file writing.
 @param errorCallback Callback returning the failure message on failure.
 */
+ (void)writeCSVFilePath:(NSString *)filePath
             withContent:(NSArray *)content
          usingDelimiter:(NSString *)delimiter
            withEncoding:(NSStringEncoding)encoding
               onSuccess:(SuccessWriteCompleteBlock)successCallback
                 onError:(FailureBlock)failureCallback;

@end

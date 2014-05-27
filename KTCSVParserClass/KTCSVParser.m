//
//  KTCSVParser.m
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

#import "KTCSVParser.h"

@interface KTCSVParser () {
    
    NSString *_filePath;
    NSString *_delimiter;
    NSStringEncoding _stringEncoding;
    KTCSVParserMode _currentOperationMode;
    
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
    NSMutableArray *_parsedItems;
    
    NSUInteger _totalRowCount;
    NSError *_error;
    
    SuccessReadCompleteBlock _successReadBlock;
    SuccessWriteCompleteBlock _successWriteBlock;
    FailureBlock _failureBlock;
}

@end

@implementation KTCSVParser
static NSString *kErrorDomain = @"com.parser.KTCSVParser";

#pragma mark Reading CSV [Object Methods]

- (KTCSVParser *)initWithCSVFileReadPath:(NSString *)filePath
                          usingDelimiter:(NSString *)delimiter
                            withDelegate:(id<KTCSVParserDelegate>)delegate {
    
    self.delegate = delegate;
    _filePath = filePath;
    _delimiter = delimiter;
    _currentOperationMode = KTCSVParserModeRead;
    
    return self;
}

- (void)parseFile {
    [self parseFile:YES];
}

- (void)parseFile:(BOOL)asyncMode {
    
    if (_currentOperationMode == KTCSVParserModeRead) {
        if (asyncMode == YES) {
            dispatch_queue_t currentQueue =
            dispatch_queue_create("com.kt.csvparser.queue", NULL);
            dispatch_async(currentQueue, ^{ [self processContent]; });
        } else {
            [self processContent];
        }
    } else {
        NSError *er =
        [NSError errorWithDomain:kErrorDomain
                            code:KTCSVParserErrorCodeInvalidAccessMode
                        userInfo:@{
                                   @"error_message" :
                                       @"KTCSVParser not set to parse files."
                                   }];
        
        if ([self.delegate
             respondsToSelector:@selector(parser:didFailWithError:)]) {
            [self.delegate parser:self didFailWithError:er];
        }
    }
}

- (void)processContent {
    
    NSError *fileCheckError =
    [self validateFile:_filePath andDelimiter:_delimiter];
    if (fileCheckError == nil) {
        
        _inputStream = [NSInputStream inputStreamWithFileAtPath:_filePath];
        [_inputStream open];
        
        if ([self.delegate respondsToSelector:@selector(parserDidBeginDocument:)]) {
            [self.delegate parserDidBeginDocument:self];
        }
        
        _parsedItems = [[NSMutableArray alloc] init];
        
        while (1) {
            @try {
                
                @autoreleasepool {
                    
                    NSString *newLine = [self readNewLine];
                    if (newLine.length > 0) {
                        
                        _totalRowCount++;
                        
                        if ([self.delegate
                             respondsToSelector:@selector(parser:didBeginRow:)]) {
                            [self.delegate parser:self didBeginRow:_totalRowCount];
                        }
                        
                        NSUInteger rowIndex = 0;
                        
                        NSArray *rowElements =
                        [newLine componentsSeparatedByString:_delimiter];
                        [_parsedItems addObject:rowElements];
                        
                        for (NSString *value in rowElements) {
                            
                            if ([self.delegate respondsToSelector:@selector(parser:
                                                                            didReadValue:
                                                                            atColumn:
                                                                            atRow:)]) {
                                
                                [self.delegate parser:self
                                         didReadValue:value
                                             atColumn:rowIndex
                                                atRow:_totalRowCount];
                            }
                            
                            rowIndex++;
                        }
                        
                        if ([self.delegate
                             respondsToSelector:@selector(parser:didEndRow:)]) {
                            [self.delegate parser:self didEndRow:_totalRowCount];
                        }
                        
                    } else {
                        
                        if ([self.delegate
                             respondsToSelector:@selector(parserDidEndDocument:)]) {
                            [self.delegate parserDidEndDocument:self];
                        }
                        
                        [self propogateReadSuccess];
                        [self cleanCurrentInstance];
                        return;
                    }
                }
            }
            @catch (NSException *exception) {
                NSError *er = [NSError
                               errorWithDomain:kErrorDomain
                               code:KTCSVParserErrorCodeInvalidContent
                               userInfo:@{@"error_message" : exception.description}];
                
                if ([self.delegate
                     respondsToSelector:@selector(parser:didFailWithError:)]) {
                    [self.delegate parser:self didFailWithError:er];
                }
                
                [self propagateFailure:er];
                [self cleanCurrentInstance];
                return;
            }
            @finally {
            }
        }
        
    } else {
        if ([self.delegate
             respondsToSelector:@selector(parser:didFailWithError:)]) {
            [self.delegate parser:self didFailWithError:fileCheckError];
        }
        [self propagateFailure:fileCheckError];
        [self cleanCurrentInstance];
    }
}

#pragma mark Reading CSV [Class Methods (Abstraction)]

+ (void)parseCSVFilePath:(NSString *)filePath
          usingDelimiter:(NSString *)delimiter
               onSuccess:(SuccessReadCompleteBlock)successCallback
                 onError:(FailureBlock)failureCallback {
    
    KTCSVParser *parserObject =
    [[KTCSVParser alloc] initWithCSVFileReadPath:filePath
                                  usingDelimiter:delimiter
                                    withDelegate:nil];
    [parserObject setReadSuccessBlock:successCallback
                      andFailureBlock:failureCallback];
    [parserObject parseFile];
}

#pragma mark -
#pragma mark Writing CSV  [Object Methods]

- (KTCSVParser *)initWithCSVFileWritePath:(NSString *)filePath
                             withEncoding:(NSStringEncoding)encoding
                           usingDelimiter:(NSString *)delimiter
                             withDelegate:(id<KTCSVParserDelegate>)delegate {
    
    self.delegate = delegate;
    _filePath = filePath;
    _delimiter = delimiter;
    _stringEncoding = encoding ? encoding : NSUTF8StringEncoding;
    _currentOperationMode = KTCSVParserModeWrite;
    return self;
}

- (void)writeContent:(NSArray *)content {
    [self writeContent:content inAsyncMode:YES withError:nil];
}

- (void)writeContent:(NSArray *)content
         inAsyncMode:(BOOL)asyncMode
           withError:(NSError **)err {
    
    if(err){
        _error = *err;
    }
    
    if (_currentOperationMode == KTCSVParserModeWrite) {
        
        if ([self allObjectsAreIdenticalClass:content]) {
            
            NSError *er = [self validateFileWritePath:_filePath];
            if (er != nil) {
                [self cleanCurrentInstance];
                if ([self.delegate
                     respondsToSelector:@selector(parser:didFailWithError:)]) {
                    [self.delegate parser:self didFailWithError:er];
                }
                [self propagateFailure:er];
                return;
            }
            if (asyncMode) {
                dispatch_queue_t currentQueue =
                dispatch_queue_create("com.kt.csvparser.queue", NULL);
                dispatch_async(currentQueue, ^{ [self writeRows:content]; });
            } else {
                [self writeRows:content];
            }
        } else {
            [self cleanCurrentInstance];
            NSError *er = [NSError
                           errorWithDomain:kErrorDomain
                           code:KTCSVParserErrorCodeInvalidAccessMode
                           userInfo:@{
                                      @"error_message" : @"Not valid content to write."
                                      }];
            
            if ([self.delegate
                 respondsToSelector:@selector(parser:didFailWithError:)]) {
                [self.delegate parser:self didFailWithError:er];
            }
            [self propagateFailure:er];
        }
    } else {
        NSError *er =
        [NSError errorWithDomain:kErrorDomain
                            code:KTCSVParserErrorCodeInvalidAccessMode
                        userInfo:@{
                                   @"error_message" :
                                       @"KTCSVParser not set to write files."
                                   }];
        
        if ([self.delegate
             respondsToSelector:@selector(parser:didFailWithError:)]) {
            [self.delegate parser:self didFailWithError:er];
        }
    }
}

- (void)writeLineToStream:(NSArray *)rowItems {
    
    NSMutableString *result = [[NSMutableString alloc]
                               initWithString:[[rowItems valueForKey:@"description"]
                                               componentsJoinedByString:_delimiter]];
    [result appendString:@"\n"];
    NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
    const void *bytes = [data bytes];
    [_outputStream write:bytes maxLength:[data length]];
}

- (void)writeRows:(NSArray *)content {
    
    _outputStream = [NSOutputStream outputStreamToFileAtPath:_filePath append:NO];
    [_outputStream open];
    
    if ([self.delegate respondsToSelector:@selector(parserDidBeginDocument:)]) {
        [self.delegate parserDidEndDocument:self];
    }
    @try {
        
        NSUInteger rowIndex = 0;
        for (NSArray *contentRow in content) {
            [self writeLineToStream:contentRow];
            if ([self.delegate
                 respondsToSelector:@selector(parser:wroteRowAtIndex:)]) {
                [self.delegate parser:self wroteRowAtIndex:rowIndex];
            }
            rowIndex++;
        }
    }
    @catch (NSException *exception) {
        NSError *er =
        [NSError errorWithDomain:kErrorDomain
                            code:KTCSVParserErrorCodeInvalidContent
                        userInfo:@{@"error_message" : exception.description}];
        
        if ([self.delegate
             respondsToSelector:@selector(parser:didFailWithError:)]) {
            [self.delegate parser:self didFailWithError:er];
        }
        
        [self propagateFailure:er];
        [self cleanCurrentInstance];
        return;
    }
    @finally {
    }
    
    [self cleanCurrentInstance];
    
    if ([self.delegate respondsToSelector:@selector(parserDidEndDocument:)]) {
        [self.delegate parserDidEndDocument:self];
    }
    [self propagateWriteSuccess];
}

#pragma mark Writing CSV [Class Methods (Abstraction)]

+ (void)writeCSVFilePath:(NSString *)filePath
             withContent:(NSArray *)content
          usingDelimiter:(NSString *)delimiter
            withEncoding:(NSStringEncoding)encoding
               onSuccess:(SuccessWriteCompleteBlock)successCallback
                 onError:(FailureBlock)failureCallback {
    
    KTCSVParser *parserObject =
    [[KTCSVParser alloc] initWithCSVFileWritePath:filePath
                                     withEncoding:encoding
                                   usingDelimiter:delimiter
                                     withDelegate:nil];
    
    [parserObject setWriteSuccessBlock:successCallback
                       andFailureBlock:failureCallback];
    [parserObject writeContent:content];
}

#pragma mark -
#pragma mark Helper functions (Private)

/**
 Checks for valid delimiter.
 
 @param Delimiter currently selected delimiter.
 @return Boolean if valid delimiter or not.
 */
- (BOOL)isValidDelimiter:(NSString *)delimiter {
    NSArray *invalidDelimiter = @[ @"\"", @"\n", @"\r", @"\r\n", @"#", @"\\" ];
    if ([invalidDelimiter containsObject:delimiter]) {
        return NO;
    } else {
        return YES;
    }
}

/**
 Reads a new line from the `NSInputStream` object.
 
 @param inputStream current instance of `NSInputStream` to be used.
 @return String the next line in the file.
 */
- (NSString *)readNewLine {
    
    uint8_t ch = 0;
    NSMutableString *str = [NSMutableString string];
    while ([_inputStream read:&ch maxLength:1] == 1) {
        if (ch == '\n' || ch == '\r')
            break;
        [str appendFormat:@"%c", ch];
    }
    return str;
}

/**
 Checks the file and delimiter for validity.
 
 @param delimiter currently selected delimiter.
 @param filePath currently selected file's path.
 @return Error if invalid an error is returned else nil.
 */
- (NSError *)validateFile:(NSString *)filePath
             andDelimiter:(NSString *)delimiter {
    
    if (!filePath || filePath.length == 0) {
        return [NSError
                errorWithDomain:kErrorDomain
                code:KTCSVParserErrorCodeInvalidFilePath
                userInfo:@{@"error_message" : @"Enter a valid filename."}];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        if ([self isValidDelimiter:delimiter]) {
            
            return nil;
            
        } else {
            return [NSError
                    errorWithDomain:kErrorDomain
                    code:KTCSVParserErrorCodeInvalidContent
                    userInfo:@{@"error_message" : @"The delimiter is invalid."}];
        }
        
    } else {
        
        return [NSError
                errorWithDomain:kErrorDomain
                code:KTCSVParserErrorCodeInvalidFilePath
                userInfo:@{
                           @"error_message" :
                               @"The file does not exist or is not readable."
                           }];
    }
}

- (NSError *)validateFileWritePath:(NSString *)filePath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath] == YES) {
        
        return [NSError
                errorWithDomain:kErrorDomain
                code:KTCSVParserErrorCodeFileExists
                userInfo:@{@"error_message" : @"The file already exists."}];
    } else {
        if ([fileManager createFileAtPath:filePath contents:nil attributes:nil] ==
            YES) {
            return nil;
        } else {
            return [NSError errorWithDomain:kErrorDomain
                                       code:KTCSVParserErrorCodeInvalidFilePath
                                   userInfo:@{
                                              @"error_message" :
                                                  @"The file path is not writeable."
                                              }];
        }
    }
}

- (BOOL)allObjectsAreIdenticalClass:(NSArray *)content {
    
    if (content.count < 2)
        return YES;
    for (NSUInteger i = 0; i < content.count - 1; i++) {
        if (!([[content objectAtIndex:i] isKindOfClass:[NSArray class]]))
            return NO;
        else {
            for (NSObject *item in [content objectAtIndex:i]) {
                if (![item isKindOfClass:[NSString class]]) {
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (void)cleanCurrentInstance {
    
    if (_inputStream != nil) {
        [_inputStream close];
        _inputStream = nil;
    }
    
    if (_outputStream != nil) {
        [_outputStream close];
        _outputStream = nil;
    }
}

- (void)setReadSuccessBlock:(SuccessReadCompleteBlock)sb
            andFailureBlock:(FailureBlock)fb {
    _successReadBlock = sb;
    _failureBlock = fb;
}

- (void)setWriteSuccessBlock:(SuccessWriteCompleteBlock)sb
             andFailureBlock:(FailureBlock)fb {
    _successWriteBlock = sb;
    _failureBlock = fb;
}

- (void)propogateReadSuccess {
    if (_successReadBlock && _parsedItems) {
        _successReadBlock(_parsedItems);
    }
}

- (void)propagateWriteSuccess {
    if (_successWriteBlock) {
        _successWriteBlock();
    }
}

- (void)propagateFailure:(NSError *)error {
    
    if(_error){
        _error = error;
    }
    
    if (_failureBlock) {
        _failureBlock(error);
    }
}

@end

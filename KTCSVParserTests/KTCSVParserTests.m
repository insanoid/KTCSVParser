//
//  KTCSVParserTests.m
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


#import <XCTest/XCTest.h>
#import "KTCSVParser.h"

@interface KTCSVParserTests : XCTestCase {
    
    NSArray *testElements;
    NSString *tempTestFilePath;
    NSString *delimiter;
    NSStringEncoding stringEncoding;
    NSUInteger repetitionCount;
    
}

@end

@implementation KTCSVParserTests

- (void)setUp
{
    [super setUp];
    tempTestFilePath =
    [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempfile.csv"];
    delimiter = @",";
    stringEncoding = NSUTF8StringEncoding;
    repetitionCount = 3;
    testElements = @[
                     @[ @"a", @"b", @"c", @"d" ],
                     @[ @"e", @"f", @"g", @"h" ],
                     @[ @"i", @"j", @"k", @"l" ]
                     ];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// Testcase based on the sample file with a fixed set of rows and columns.
- (void)testReadFromLocalFile {
    
    [KTCSVParser
     parseCSVFilePath:[[NSBundle mainBundle]
                       pathForResource:@"sample_file_comma_spaced"
                       ofType:@"csv"]
     usingDelimiter:@","
     onSuccess:^(id successObject) {
         
         if ([successObject count] == 3) {
             for (NSArray *row in successObject) {
                 if ([row count] != 12) {
                     XCTFail(
                             @"Parser column count not 12: testReadFileWithoutHeader");
                 }
             }
         } else {
             XCTFail(@"Parser row count not 3: testReadFileWithoutHeader");
         }
     }
     onError:^(NSError *errorObject) {
         XCTFail(@"Test failed: : %@", errorObject);
     }];
}

// Testcase for writing a csv type structure to the file.
- (void)testWriteCSVToFile {
    
    // to avoid throwing an error incase the sample is re-run.
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempTestFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:tempTestFilePath error:nil];
    }
    
    [KTCSVParser writeCSVFilePath:tempTestFilePath
                      withContent:testElements
                   usingDelimiter:delimiter
                     withEncoding:stringEncoding
                        onSuccess:^{}
                          onError:^(NSError *errorObject) {
                              XCTFail(@"Test failed: : %@", errorObject);
                          }];
}

// Testcase based on the sample file with a fixed set of rows and columns.
- (void)testReadWrittenCSVFile {
    
    [KTCSVParser parseCSVFilePath:tempTestFilePath
                   usingDelimiter:delimiter
                        onSuccess:^(id successObject) {
                            
                            if ([successObject count] == [testElements count]) {
                                for (NSArray *row in successObject) {
                                    if ([row count] != [[testElements objectAtIndex:0] count]) {
                                        XCTFail(@"Parser column count not 4: testReadWrittenFile");
                                    }
                                }
                            } else {
                                XCTFail(@"Parser row count not 3: testReadWrittenFile");
                            }
                        }
                          onError:^(NSError *errorObject) {
                              XCTFail(@"Test failed: : %@", errorObject);
                          }];
}


@end

//
//  KTViewController.m
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

#import "KTViewController.h"
#import "KTCSVParser.h"

@interface KTViewController ()

@end

@implementation KTViewController

- (void)viewDidLoad
{
    [self parsingFunctionCalls];
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)parsingFunctionCalls {
    
    // Write CSV to a file.
    NSString *filePath = [NSTemporaryDirectory()
                          stringByAppendingPathComponent:@"tempNewfile.csv"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    [KTCSVParser writeCSVFilePath:filePath
                      withContent:@[
                                    @[ @"a", @"a", @"a", @"a" ],
                                    @[ @"a", @"a", @"a", @"a" ],
                                    @[ @"a", @"a", @"a", @"a" ]
                                    ]
                   usingDelimiter:@","
                     withEncoding:NSUTF8StringEncoding
                        onSuccess:^{ NSLog(@"Success - file written at %@", filePath); }
                          onError:^(NSError *errorObject) {
                              NSLog(@"Error in writing path - %@", errorObject);
                          }];
    
    // Read CSV from a file.
    [KTCSVParser parseCSVFilePath:[[NSBundle mainBundle]
                                   pathForResource:@"sample_file_comma_spaced"
                                   ofType:@"csv"]
                   usingDelimiter:@","
                        onSuccess:^(id responseObject) {
                            NSLog(@"Success - file written at %@ \n %@", filePath,
                                  responseObject);
                        }
                          onError:^(NSError *errorObject) {
                              NSLog(@"Error in reading file - %@", errorObject);
                          }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

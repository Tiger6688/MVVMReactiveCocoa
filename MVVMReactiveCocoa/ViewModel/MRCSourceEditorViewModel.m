//
//  MRCSourceEditorViewModel.m
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 15/2/3.
//  Copyright (c) 2015年 leichunfeng. All rights reserved.
//

#import "MRCSourceEditorViewModel.h"

@interface MRCSourceEditorViewModel ()

@property (strong, nonatomic, readwrite) OCTRepository    *repository;
@property (strong, nonatomic, readwrite) OCTBlobTreeEntry *blobTreeEntry;
@property (strong, nonatomic) OCTRef *reference;
@property (strong, nonatomic) NSString *renderedMarkdown;

@end

@implementation MRCSourceEditorViewModel

- (instancetype)initWithServices:(id<MRCViewModelServices>)services params:(id)params {
    self = [super initWithServices:services params:params];
    if (self) {
        self.repository    = params[@"repository"];
        self.reference     = params[@"reference"];
        self.blobTreeEntry = params[@"blobTreeEntry"];
        self.encoded = YES;
    }
    return self;
}

- (void)initialize {
    [super initialize];
    
    self.title = [self.blobTreeEntry.path componentsSeparatedByString:@"/"].lastObject;
    self.markdown = self.title.isMarkdown;
    
    @weakify(self)
    self.requestBlobCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self)
        return [[self.services.client
            fetchBlob:self.blobTreeEntry.SHA inRepository:self.repository]
            doNext:^(NSData *data) {
                @strongify(self)
                self.rawContent = data.base64EncodedString;
            }];
    }];
    
    self.requestRenderedMarkdownCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self)
        return [[self.services.repositoryService
        	requestRepositoryReadmeRenderedMarkdown:self.repository reference:self.reference.name]
            doNext:^(NSString *renderedMarkdown) {
                @strongify(self)
                self.renderedMarkdown = renderedMarkdown;
            }];
    }];
}

- (NSString *)content {
    if (self.isMarkdown && !self.showRawMarkdown) {
        return self.renderedMarkdown;
    } else {
        return [[NSString alloc] initWithData:[NSData dataFromBase64String:self.rawContent] encoding:NSUTF8StringEncoding];
    }
}

- (NSString *)wrappingActionTitle {
    return self.isLineWrapping ? @"Disable wrapping": @"Enable wrapping";
}

- (NSString *)markdownActionTitle {
    return self.showRawMarkdown ? @"Render markdown": @"Show raw markdown";
}

@end

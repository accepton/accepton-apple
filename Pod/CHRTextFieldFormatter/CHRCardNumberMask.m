//
//  CHRCardNumberMask.m
//
//  Created by Dmitry Nesterenko on 14/05/15.
//  Copyright (c) 2015 e-legion. All rights reserved.
//

#import "CHRCardNumberMask.h"

@implementation CHRCardNumberMask

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    typeof(self) copy = [[self.class alloc] init];
    return copy;
}

#pragma mark - Masking

- (BOOL)shouldChangeText:(NSString *)text withReplacementString:(NSString *)string inRange:(NSRange)range {
    //Calculate new string
    NSString *newString = [text stringByReplacingCharactersInRange:range withString:string];
    
    if (self.brand && [self.brand isEqualToString:@"amex"]) {
        return [newString length] < 16+2; //2 spaces
    } else {
        return [newString length] < 17+3; //3 spaces
    }
    return YES;
}

- (NSString *)filteredStringFromString:(NSString *)string cursorPosition:(NSUInteger *)cursorPosition {
    NSUInteger originalCursorPosition = cursorPosition == NULL ? 0 : *cursorPosition;
    NSMutableString *digitsOnlyString = [NSMutableString new];
    for (NSUInteger i=0; i<[string length]; i++) {
        unichar characterToAdd = [string characterAtIndex:i];
        if (isdigit(characterToAdd)) {
            NSString *stringToAdd = [NSString stringWithCharacters:&characterToAdd length:1];
            
            [digitsOnlyString appendString:stringToAdd];
        }
        else {
            if (i < originalCursorPosition) {
                if (cursorPosition != NULL)
                    (*cursorPosition)--;
            }
        }
    }
    
    return digitsOnlyString;

}

- (NSString *)formattedStringFromString:(NSString *)string cursorPosition:(NSUInteger *)cursorPosition {
    NSRegularExpression *regex;
    
    NSUInteger cursorPositionInSpacelessString = *cursorPosition;
    
    if (self.brand && [self.brand isEqualToString:@"amex"]) {
        regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,4})(\\d{1,6})?(\\d{1,5})?" options:0 error:NULL];
    } else {
        regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,4})" options:0 error:NULL];
    }
    
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, cursorPositionInSpacelessString)];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:matches.count];
    
    for (NSTextCheckingResult *match in matches) {
        for (int i = 1; i < [match numberOfRanges]; i++) {
            NSRange range = [match rangeAtIndex:i];
            
            if (range.length > 0) {
                NSString *matchText = [string substringWithRange:range];
                [result addObject:matchText];
            }
        }
    }
    
    (*cursorPosition) += result.count-1;
    return [result componentsJoinedByString:@" "];
}

@end

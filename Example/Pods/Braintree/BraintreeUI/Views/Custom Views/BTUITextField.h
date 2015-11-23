#import <UIKit/UIKit.h>

@protocol BTUITextFieldEditDelegate;

/// @class A specialized text field that provides more granular callbacks than a standard
/// UITextField as the user edits text
@interface BTUITextField : UITextField

/// The specialized delegate for receiving callbacks about editing
@property (nonatomic, weak) id<BTUITextFieldEditDelegate> editDelegate;

@end

/// A protocol for receiving callbacks when a user edits text in a `BTUITextField`
@protocol BTUITextFieldEditDelegate <NSObject>

@optional

/// The editDelegate receives this message when the user deletes a character, but before the deletion
/// is applied to the `text`
///
/// @param textField The text field
- (void)textFieldWillDeleteBackward:(BTUITextField *)textField;

/// The editDelegate receives this message after the user deletes a character
///
/// @param textField    The text field
/// @param originalText The `text` of the text field before applying the deletion
- (void)textFieldDidDeleteBackward:(BTUITextField *)textField
                      originalText:(NSString *)originalText;

/// The editDelegate receives this message when the user enters text, but
/// before the text is inserted
///
/// @param textField The text field
/// @param text      The text that will be inserted
- (void)textField:(BTUITextField *)textField willInsertText:(NSString *)text;

/// The editDelegate receives this message after the user enters text
///
/// @param textField The text field
/// @param text      The text that was inserted
- (void)textField:(BTUITextField *)textField didInsertText:(NSString *)text;

@end

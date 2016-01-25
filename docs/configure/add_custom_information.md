#Add custom information
In both the storyboard and pure-code only examples, the `AcceptOnViewController` was configured
and had an optional `userInfo` parameter. This parameter can be configured with additional
information to pass along with the transaction.

```swift
//--------------------------------------------------------------------------------
//Create our userInfo object to store our configuration options
//--------------------------------------------------------------------------------
var userInfo = AcceptOnUIMachineOptionalUserInfo()

//--------------------------------------------------------------------------------
//Attach some additional information
//--------------------------------------------------------------------------------
userInfo.extraMetadata["my_internal_identifier"] = "foo-xxxxxx"

//--------------------------------------------------------------------------------
//Set our options in our view controller before we present it
//--------------------------------------------------------------------------------
avc.userInfo = userInfo
```

If you set the extra metadata, this information will appear in your accepton-on meta-data as:
```javascript
{
  my_internal_identifier: "foo-xxxxx"
}
```

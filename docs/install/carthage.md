#Install via Carthage
> This tutorial assumes you already have install carthage installed.  If you haven't already installed carthage, [Install It From Here](https://github.com/Carthage/Carthage#installing-carthage).

## Step 1
Create a new `Cartfile` in your *project folder*. Place the following into it:

```
github "accepton/accepton-apple" ~> 0.5
```

![Cartfile](../images/cartfile.png)

## Step 2
Run `carthage update` in the root of your *project folder*.

## Step 3
Take the newly created `./Carthage/Build/$PLATFORM/accepton.framework` in your project folder and place it in your XCode project's `Linked Frameworks and Libraries` section **without** making a copy.

![Cartfile](../../images/carthange_link.gif)

## Step 4
On your application targets’ “Build Phases” settings tab, click the “+” icon and choose “New Run Script Phase”. Create a Run Script with the following contents:

```
/usr/local/bin/carthage copy-frameworks
```

and add the paths to the `accepton.framework` you want to use under “Input Files”:

```
$(SRCROOT)/Carthage/Build/iOS/accepton.framework
```

![Cartfile](../../images/carthange_run_script.gif)

# Frame-iOS SDK

The Frame iOS SDK simplifies the process of creating a seamless payment experience within your iOS app. It offers versatile, pre-designed UI components that enable you to effortlessly gather payment details from your users. Additionally, it provides access to the underlying APIs that drive these components, allowing you to design fully customized payment workflows tailored to your app's needs.

Table of contents
=================
<!-- NOTE: Use case-sensitive anchor links for docc compatibility -->
<!--ts-->
   * [Requirements](#Requirements)
   * [Features](#Features)
   * [Usage](#Usage)
   * [Examples](#Examples)
   * [Privacy](#Privacy)


## Requirements

The Frame iOS SDK requires Xcode 15 or later and is compatible with apps targeting iOS 17 or above and tvOS 16 or above. We support Catalyst on macOS 14 or later.

## Features

* **Reusable UI Components** We have built two ready-to-use UI components for your payment to make it easy to allow customers to check out with your products and enter
their payment details with encryption.

* **Pre Packaged API Calls** This SDK has built in support for  all available Frame API calls. Each API endpoint has it's own initialization-less class that you can call directly within your code and supports either async/await or completion handlers. See our [API Documentation](https://docs.framepayments.com) here.

* **Payment Card Encryption** Frame supports payment card encryption using Evervault. It's integrated directly into our CREATE payment method API call to ensure all data transmitted is encrypted before hitting our servers.

## Usage

1. Swift Package Manager: add a dependency to your Project.swift:

**.package(url: "https://github.com/Frame-Payments/frame-ios", from: "1.0.0")**

2. In your App Delegate or main App file, initialize the SDK with:

```
FrameNetworking.shared.initializeWithAPIKey("{YOUR_API_SECRET_KEY_HERE}")
```

NOTE: In order to obtain your API key, you will need to sign up for a developer account at https://framepayments.com. Once you have obtained your key from the Developer section of your dashboard, please use the SECRET KEY with this SDK.

3. Start calling any available API within your app:

Example:
```
CustomersAPI.getCustomers { customers in }
```

### Examples

See our Example project within this project that contains:
- How to use our Cart and Checkout Prebuilt UI
- Standard Initialization-less API Usage for all available Frame Payments API calls.

### React Native Support

This package can be used with an iOS app within a React Native project. We have provided instructions below:

**1. Create a Native Module**
- Inside your React Native project, navigate to the `ios` folder.
- Create a new Objective-C or Swift file (e.g., `MySDKBridge`).
- Import your SDK inside this file.

**2. Expose Your SDK to React Native**
- Use `@objc` and `RCT_EXPORT_MODULE()` to expose your native module.
- Use `RCT_EXPORT_METHOD` to expose functions to JavaScript.

```
import Foundation
import Frame-iOS


@objc(MySDKBridge)
class MySDKBridge: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool {
      return true
  }
  
  @objc func initializeSDK(_ apiKey: String) {
      FrameNetworking.shared.initializeWithAPIKey("{YOUR_API_SECRET_KEY_HERE}")
  }
  
  @objc func doSomething(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping
  RCTPromiseRejectBlock) {
      let result = YourSDK.performAction()
      resolve(result)
  }
}
```
**3. Register the Module in React Native**
Modify `AppDelegate.swift` (Swift) to ensure the module is loaded.

**4. Use the Native Module in React Native**
In JavaScript, import the module and call the exposed functions:

```
import { NativeModules } from 'react-native';
const { MySDKBridge } = NativeModules;

MySDKBridge.initializeSDK('your-api-key');
MySDKBridge.doSomething()
  .then(result => console.log(result))
  .catch(error => console.error(error));
```
**5. Link the Native Module**
- If using React Native 0.60+, autolinking should work.
- Otherwise, manually link the native module in Xcode.
#### Privacy

Our privacy policy can be found at [https://framepayments.com/privacy](https://framepayments.com/privacy).


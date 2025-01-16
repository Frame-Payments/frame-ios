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

1. Swift Package Manager: add a dependency to your Project.swift: **.package(url: "https://github.com/Frame-Payments/frame-ios", from: "1.0.0")**

2. In your App Delegate or main App file, initialize the SDK with: **FrameNetworking.shared.initializeWithAPIKey("{YOUR_API_KEY_HERE}")**

3. Start calling any available API within your app: **CustomersAPI.getCustomers { customers in }**

### Examples

See our Example project within this project that contains:
- How to use our Cart and Checkout Prebuilt UI
- Standard Initialization-less API Usage for all available Frame Payments API calls.
 
#### Privacy

Our privacy policy can be found at [https://framepayments.com/privacy](https://framepayments.com/privacy).


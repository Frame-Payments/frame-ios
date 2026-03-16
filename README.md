# Frame iOS SDK

[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen)](https://swift.org/package-manager/)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-15%2B-blue)](https://developer.apple.com/xcode/)

The Frame iOS SDK gives you everything you need to build a polished payment experience in your iOS app. Drop in pre-built UI components for checkout and card entry, or call the underlying APIs directly to build fully customized payment flows.

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Features](#features)
- [API Reference](#api-reference)
- [UI Components](#ui-components)
- [Frame Onboarding](#frame-onboarding)
- [Examples](#examples)
- [React Native](#react-native)
- [Privacy](#privacy)
- [Support](#support)

---

## Requirements

| Dependency | Minimum Version |
|------------|----------------|
| iOS        | 17.0           |
| Xcode      | 15.0           |
| Swift      | 5.9            |

---

## Installation

### Swift Package Manager

Add the Frame iOS SDK as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Frame-Payments/frame-ios", from: "1.0.0")
]
```

Then add the product to your target:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "Frame-iOS", package: "frame-ios")
        ]
    )
]
```

### Xcode

1. Open your project in Xcode.
2. Go to **File → Add Package Dependencies…**
3. Enter the repository URL: `https://github.com/Frame-Payments/frame-ios`
4. Select the version rule and click **Add Package**.
5. Choose `Frame-iOS` (and optionally `Frame-Onboarding`) from the package products list.

---

## Getting Started

### 1. Initialize the SDK

In your `AppDelegate` or top-level `App` file, initialize the SDK with your secret API key:

```swift
import Frame_iOS

@main
struct MyApp: App {
    init() {
        FrameNetworking.shared.initializeWithAPIKey("sk_your_secret_key_here")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

> **Note:** Your API key is available in the **Developer** section of the [Frame dashboard](https://framepayments.com). Always use the **secret key** with this SDK and never expose it in client-side code that is publicly readable.

### 2. Make Your First API Call

Every API is available as a static method — no initialization required:

```swift
// Async/await
let customers = try await CustomersAPI.getCustomers()

// Completion handler
CustomersAPI.getCustomers { customers in
    print(customers)
}
```

---

## Features

### Prebuilt UI Components
Drop-in SwiftUI views for checkout and payment card entry that handle the full payment flow, including card encryption.

### Full API Client
Static, initialization-less API classes covering every Frame endpoint. All methods support both `async/await` and completion handler patterns.

### Payment Card Encryption
Card data is encrypted via [Evervault](https://evervault.com) before it ever leaves the device — integrated directly into the payment method creation flow.

### KYC Onboarding Flows *(Frame-Onboarding module)*
A drop-in, capability-driven onboarding flow for KYC. Declare the verifications your product requires and `OnboardingContainerView` automatically builds and sequences the right steps — identity capture, document upload, phone verification, payment and payout method setup, 3D Secure, and geolocation compliance.

### Fraud Detection
Built-in device intelligence via Sift and FingerprintPro, wired up automatically when the SDK is initialized.

---

## API Reference

All API classes are stateless — call them directly without creating an instance. Each method is available in both async and callback styles.

| Class | Description |
|-------|-------------|
| `CustomersAPI` | Create, retrieve, update, delete, and search customers |
| `PaymentMethodsAPI` | Add and manage payment methods |
| `ChargeIntentsAPI` | Create and manage charge intents |
| `SubscriptionsAPI` | Subscription lifecycle management |
| `InvoicesAPI` | Invoice retrieval and operations |
| `ProductsAPI` | Product catalog management |
| `RefundsAPI` | Initiate and track refunds |
| `DisputesAPI` | Dispute retrieval and management |
| `AccountsAPI` | Account details and configuration |
| `CapabilitiesAPI` | Account capability verification |
| `PhoneOTPVerificationAPI` | Phone number OTP verification |
| `ThreeDSecureVerificationsAPI` | 3D Secure payment verification |
| `GeocomplianceAPI` | Location compliance checking |

For full parameter documentation, see the [Frame API Docs](https://docs.framepayments.com).

### Example: Creating a Customer

```swift
let newCustomer = CreateCustomerRequest(
    email: "jane@example.com",
    name: "Jane Smith"
)

do {
    let customer = try await CustomersAPI.createCustomer(newCustomer)
    print("Created customer: \(customer.id)")
} catch {
    print("Error: \(error)")
}
```

### Example: Creating a Charge Intent

```swift
let chargeIntent = CreateChargeIntentRequest(
    amount: 4999,
    currency: "usd",
    customerId: customer.id
)

let intent = try await ChargeIntentsAPI.createChargeIntent(chargeIntent)
```

---

## UI Components

### FrameCheckoutView

A full, pre-built checkout view. Provide a charge intent ID and a customer ID and the component handles the rest:

```swift
import Frame_iOS

FrameCheckoutView(
    chargeIntentId: intent.id,
    customerId: customer.id
)
```

### FrameCartView

A customizable cart and checkout component. Conform your item model to `FrameCartItem` and pass it in:

```swift
struct CartItem: FrameCartItem {
    var id: String
    var name: String
    var price: Int
    var quantity: Int
}

FrameCartView(
    items: cartItems,
    shippingCost: 599,
    customerId: customer.id
)
```

### EncryptedPaymentCardInput

A secure card entry field that encrypts card data on-device before submission:

```swift
EncryptedPaymentCardInput { encryptedCard in
    // encryptedCard is ready to send to your server
}
```

---

## Frame Onboarding

Frame Onboarding is a separate SDK module (`Frame-Onboarding`) that provides a complete, drop-in KYC and identity verification flow for your iOS app. You declare which capabilities your product requires, and the SDK automatically builds the appropriate sequence of onboarding steps for each user.

### Installation

Add `Frame-Onboarding` alongside `Frame-iOS` in your target dependencies:

```swift
// Package.swift
.product(name: "Frame-Onboarding", package: "frame-ios")
```

Or in Xcode, select both `Frame-iOS` and `Frame-Onboarding` when adding the package.

### How It Works

`OnboardingContainerView` is the single entry point. Pass it the capabilities your product requires and an optional existing account ID. The SDK resolves the capability list into an ordered sequence of verification steps and guides the user through each one automatically.

```swift
import Frame_Onboarding

OnboardingContainerView(
    accountId: existingAccountId,       // nil to create a new account during the flow
    requiredCapabilities: [
        .kycPrefill,
        .cardVerification,
        .bankAccountVerification,
        .ageVerification,
        .geoCompliance
    ]
)
```

If `accountId` is `nil`, a new Frame account is created at the start of the flow. Once the user completes all steps, the view dismisses automatically.

### Capabilities

Each capability maps to one or more onboarding steps. Duplicate steps are automatically deduplicated and sorted into the correct order.

| Capability | Step Triggered | What It Collects |
|---|---|---|
| `.kyc` | Personal Information | Name, email, phone, DOB, SSN, address |
| `.kycPrefill` | Personal Information | Same as above, with Prove prefill |
| `.ageVerification` | Personal Information | Date of birth |
| `.phoneVerification` | Personal Information | Phone number + OTP verification |
| `.creatorShield` | Personal Information | Full identity details |
| `.cardVerification` | Confirm Payment Method | Card selection or addition with 3D Secure |
| `.cardSend` | Confirm Payment Method | Card setup for send |
| `.cardReceive` | Confirm Payment Method | Card setup for receive |
| `.addressVerification` | Confirm Payment Method | Billing address only |
| `.bankAccountVerification` | Confirm Payout Method | Bank account (ACH) setup |
| `.bankAccountSend` | Confirm Payout Method | Bank account for payouts |
| `.bankAccountReceive` | Confirm Payout Method | Bank account for deposits |
| `.geoCompliance` | Geolocation Verification | Location + VPN detection |
| *(any other capability)* | Upload Documents | Government ID + selfie |

### Onboarding Steps

#### Personal Information
Collects identity details and verifies the user's phone number. Supports two phone verification paths:
- **Prove Auth** — prefills identity data using the Prove identity network, with an OTP fallback
- **Twilio SMS** — sends a 6-digit OTP to the user's phone number

#### Confirm Payment Method
Lets the user select an existing card on file or add a new one. When the `.cardVerification` capability is present, the selected card is automatically run through a 3D Secure challenge before the step completes.

#### Confirm Payout Method
Collects a bank account for ACH payouts, including routing number, account number, account type (checking or savings), and billing address.

#### Upload Documents
Guides the user through capturing or uploading identity documents and a selfie. Supported document types:
- Driver's License (front + back)
- State ID (front + back)
- Military ID (front + back)
- Passport

#### Geolocation Verification
Checks the user's location against your configured geofences and detects active VPN connections. A blocked result surfaces a clear reason to the user (restricted territory, VPN detected, or no location data available).

#### Verification Submitted
A final confirmation screen shown after all steps are complete. The user taps **Done** and the flow dismisses.

### Example: Full KYC Onboarding Flow

```swift
import SwiftUI
import Frame_Onboarding

struct OnboardingLaunchView: View {
    @State private var showOnboarding = false

    var body: some View {
        Button("Start Verification") {
            showOnboarding = true
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingContainerView(
                requiredCapabilities: [
                    .kycPrefill,
                    .ageVerification,
                    .cardVerification,
                    .bankAccountVerification,
                    .geoCompliance
                ]
            )
        }
    }
}
```

---

## Examples

The `FrameExample-iOS` app in this repository demonstrates:

- Initializing the SDK and making API calls
- Using `FrameCartView` and `FrameCheckoutView`
- Triggering a full onboarding flow with `OnboardingContainerView`
- Listing customers, payment methods, subscriptions, charge intents, and refunds

To run the example app, open `FrameExample-iOS/FrameExample-iOS.xcodeproj` in Xcode and run the target on a simulator or device.

---

## React Native

The Frame iOS SDK can be bridged into a React Native project through a native module.

### 1. Create a Bridge File

Inside the `ios/` folder of your React Native project, create a new Swift file (e.g. `FrameBridge.swift`):

```swift
import Foundation
import Frame_iOS

@objc(FrameBridge)
class FrameBridge: NSObject {

    @objc static func requiresMainQueueSetup() -> Bool {
        return true
    }

    @objc func initialize(_ apiKey: String) {
        FrameNetworking.shared.initializeWithAPIKey(apiKey)
    }

    @objc func getCustomers(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                let customers = try await CustomersAPI.getCustomers()
                resolve(customers)
            } catch {
                reject("GET_CUSTOMERS_ERROR", error.localizedDescription, error)
            }
        }
    }
}
```

### 2. Register the Module

Ensure the module is registered in your `AppDelegate`. With React Native 0.60+, autolinking handles this automatically.

### 3. Use from JavaScript

```javascript
import { NativeModules } from 'react-native';
const { FrameBridge } = NativeModules;

// Initialize
FrameBridge.initialize('sk_your_secret_key_here');

// Call APIs
FrameBridge.getCustomers()
  .then(customers => console.log(customers))
  .catch(error => console.error(error));
```

---

## Privacy

The Frame iOS SDK collects device signals for fraud prevention purposes. Our full privacy policy is available at [framepayments.com/privacy](https://framepayments.com/privacy).

---

## Support

- **Documentation:** [docs.framepayments.com](https://docs.framepayments.com)
- **Dashboard:** [framepayments.com](https://framepayments.com)
- **Issues:** [github.com/Frame-Payments/frame-ios/issues](https://github.com/Frame-Payments/frame-ios/issues)

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
- [Theming](#theming)
- [Apple Pay](#apple-pay)
- [Frame Onboarding](#frame-onboarding)
- [Examples](#examples)
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
        FrameNetworking.shared.initializeWithAPIKey(
            "sk_your_secret_key_here",
            publishableKey: "pk_your_publishable_key_here",
            applePayMerchantId: "merchant.com.yourcompany.appname", // optional, see Apple Pay section
            debugMode: false
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

> **Note:** Your API key is available in the **Developer** section of the [Frame dashboard](https://framepayments.com). Always use the **secret key** with this SDK and never expose it in client-side code that is publicly readable.

> **Apple Pay merchant ID:** Pass it once to `initializeWithAPIKey` and every Frame surface — `FrameApplePayButton`, `FrameCheckoutView`, `FrameCartView`, `OnboardingContainerView` — picks it up automatically. Skip it if you don't intend to surface Apple Pay; the button hides itself when not configured.

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
Drop-in SwiftUI views for checkout, card entry, and Apple Pay that handle the full payment flow, including card encryption.

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
| `CustomerIdentityAPI` | Customer identity verification |
| `PaymentMethodsAPI` | Add and manage payment methods |
| `ChargeIntentsAPI` | Create and manage charge intents (legacy customer-scoped charges) |
| `TransfersAPI` | Create and manage transfers (account-scoped charge or payout flows) |
| `ApplePayAPI` | Apple Pay token processing |
| `SubscriptionsAPI` | Subscription lifecycle management |
| `SubscriptionPhasesAPI` | Subscription phase management |
| `InvoicesAPI` | Invoice retrieval and operations |
| `InvoiceLineItemsAPI` | Invoice line item management |
| `ProductsAPI` | Product catalog management |
| `ProductPhasesAPI` | Product phase management |
| `RefundsAPI` | Initiate and track refunds |
| `DisputesAPI` | Dispute retrieval and management |
| `AccountsAPI` | Account details and configuration |
| `CapabilitiesAPI` | Account capability verification |
| `TermsOfServiceAPI` | Terms of service management |
| `ConfigurationAPI` | SDK configuration |
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

`ChargeIntent` is the legacy customer-scoped charge resource. For account-scoped checkouts, use `TransfersAPI` (next example).

```swift
let chargeIntent = CreateChargeIntentRequest(
    amount: 4999,
    currency: "usd",
    customerId: customer.id
)

let intent = try await ChargeIntentsAPI.createChargeIntent(chargeIntent)
```

### Example: Creating a Transfer

`TransfersAPI` is the account-scoped equivalent. A Transfer with `sourcePaymentMethodId` charges a payment method into an account (charge flow); a Transfer with `destinationPaymentMethodId` pays out from the account to a payment method (payout flow). See the [Transfers docs](https://docs.framepayments.com/frameos/transfers) for the full request/response schema.

```swift
let request = TransferRequests.CreateTransferRequest(
    amount: 4999,
    accountId: "acc_123",
    currency: "usd",
    sourcePaymentMethodId: "pm_456"   // charge flow
)

let (transfer, error) = try await TransfersAPI.createTransfer(request: request)
```

---

## UI Components

### FrameCheckoutView

A full, pre-built checkout view. Provide a payment amount, an optional account ID, and a checkout callback. The callback fires with `success = true` and the created `Transfer` id when the user completes payment, or `success = false` with `nil` if Apple Pay fails. Provide a `merchantId` to enable Apple Pay at the top of the sheet.

```swift
import Frame_iOS

FrameCheckoutView(
    accountId: "acc_123",
    paymentAmount: 4999,
    merchantId: "merchant.com.yourapp"   // optional — shows Apple Pay when set
) { success, transferId in
    guard success, let transferId else { return }
    print("Transfer created: \(transferId)")
}
```

### FrameCartView

A customizable cart and checkout component. Conform your item model to `FrameCartItem` and pass it in alongside an `accountId`. Pass a `merchantId` to enable Apple Pay during the nested checkout step, and a `checkoutCallback` to receive the resulting Transfer id.

```swift
struct CartItem: FrameCartItem {
    var id: String
    var imageURL: String
    var title: String
    var amountInCents: Int
}

FrameCartView(
    accountId: "acc_123",
    merchantId: "merchant.com.yourapp",   // optional — shows Apple Pay inside checkout
    cartItems: cartItems,
    shippingAmountInCents: 599
) { success, transferId in
    guard success, let transferId else { return }
    print("Transfer created: \(transferId)")
}
```

### EncryptedPaymentCardInput

A secure card entry field that encrypts card data on-device before submission:

```swift
EncryptedPaymentCardInput { encryptedCard in
    // encryptedCard is ready to send to your server
}
```

---

## Theming

Every Frame UI component reads its colors, fonts, and corner radii from a single `FrameTheme` value injected via SwiftUI environment. Apply a theme once at your app boundary and it propagates through cart, checkout, onboarding, and every reusable component.

### Quick start

```swift
import SwiftUI
import Frame

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frameTheme(FrameTheme(
                    colors: .init(primaryButton: .purple, error: .orange),
                    fonts: .init(title: .custom("Inter-Bold", size: 24)),
                    radii: .init(medium: 16)
                ))
        }
    }
}
```

Anything you don't specify falls back to the SDK's default — the asset-catalog-backed palette that already adapts to dark mode.

For terse one-off tweaks, use `with(_:)`:

```swift
.frameTheme(.default.with {
    $0.colors.primaryButton = .purple
    $0.colors.error = .orange
})
```

### Tokens

`FrameTheme.Colors`:

| Token | Default |
|---|---|
| `primaryButton` / `primaryButtonText` | Brand navy / white |
| `secondaryButton` / `secondaryButtonText` | Neutral / brand navy (used by `ContinueButton(style: .secondary)`) |
| `disabledButton` / `disabledButtonStroke` / `disabledButtonText` | Light gray family |
| `surface` / `surfaceStroke` | Form-container background and border |
| `textPrimary` / `textSecondary` | Body text and helper copy |
| `error` | `.red` |
| `onboardingHeaderBackground`, `onboardingProgressFilledOnBrand`, `onboardingProgressEmptyOnBrand` | Onboarding chrome |

`FrameTheme.Fonts`:

| Token | Default |
|---|---|
| `title` | `.title` |
| `heading` | `.system(size: 18, weight: .semibold)` (onboarding screen headers) |
| `headline` | `.headline` (section labels, button text) |
| `body` / `bodySmall` | `.body` / `.system(size: 14)` |
| `label` | `.subheadline` (form headers, dropdown labels) |
| `caption` | `.caption` (errors, hints) |
| `button` | `.headline` (primary action label) |

`FrameTheme.Radii`: `small` (8), `medium` (10), `large` (16).

### Custom fonts

`Font` accepts anything you'd pass elsewhere in SwiftUI — including `.custom("MyFont", size:)`. Register the font in your app's `Info.plist` under `UIAppFonts` and pass it through:

```swift
.frameTheme(FrameTheme(fonts: .init(
    title: .custom("Inter-Bold", size: 28),
    headline: .custom("Inter-SemiBold", size: 17),
    button: .custom("Inter-SemiBold", size: 17)
)))
```

### Dark mode

The default theme reads from a light/dark-adaptive asset catalog, so dark mode works out of the box. If you supply explicit colors and want them to adapt, wrap them in a trait-aware `Color`:

```swift
let adaptiveBrand = Color(uiColor: .init { trait in
    trait.userInterfaceStyle == .dark ? .systemPurple : .purple
})
.frameTheme(FrameTheme(colors: .init(primaryButton: adaptiveBrand)))
```

### Reading the default palette

Need the SDK's stock colors or fonts in your own UI (outside Frame components)? Read them off `FrameTheme.default`:

```swift
.background(FrameTheme.default.colors.primaryButton)
.foregroundColor(FrameTheme.default.colors.primaryButtonText)
```

For live theming inside your own SwiftUI views, read `@Environment(\.frameTheme)` so consumer overrides flow through.

---

## Apple Pay

`FrameApplePayButton` is a drop-in SwiftUI view that presents a native Apple Pay sheet, submits the encrypted payment token to Frame, and returns the resulting charge id (a `ChargeIntent` id for `.customer` owners, a `Transfer` id for `.account` owners) via a callback.

Apple Pay setup is a three-part process: get a merchant ID from Apple, configure your Xcode project, pass the merchant ID to the SDK at init. Once those are done, **let us know** (see [Enabling Apple Pay on your account](#enabling-apple-pay-on-your-account)) and we'll flip the feature on for your business.

### 1. Create a merchant identifier with Apple

If you haven't already:

1. Sign in to [developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → Merchant IDs](https://developer.apple.com/account/resources/identifiers/list/merchant).
2. Click **+**, choose **Merchant IDs**, and create one in reverse-DNS form (e.g. `merchant.com.yourcompany.appname`).

### 2. Add the Apple Pay capability in Xcode

1. Open your project in Xcode and select your **app target** (not the SDK package).
2. Go to **Signing & Capabilities** → **+ Capability** → **Apple Pay**.
3. Under the Apple Pay capability, click **+** and select the merchant identifier you created in step 1.

Xcode adds an entitlements file to your target. Confirm it contains your merchant ID:

```xml
<key>com.apple.developer.in-app-payments</key>
<array>
    <string>merchant.com.yourcompany.appname</string>
</array>
```

> The SDK itself does **not** require this entitlement — only your host app does.

### 3. Pass the merchant ID to the SDK at init

`FrameNetworking` is the single source of truth for the Apple Pay merchant ID. Pass it once when you initialize the SDK and every Frame component — `FrameApplePayButton`, `FrameCheckoutView`, `FrameCartView`, `OnboardingContainerView` — will use it automatically.

```swift
FrameNetworking.shared.initializeWithAPIKey(
    "sk_your_secret_key_here",
    publishableKey: "pk_your_publishable_key_here",
    applePayMerchantId: "merchant.com.yourcompany.appname"
)
```

### Enabling Apple Pay on your account

Once steps 1–3 are complete, contact Frame at [support@framepayments.com](mailto:support@framepayments.com) (or via your [Frame dashboard](https://framepayments.com)) and we'll enable Apple Pay on your account. Apple Pay charges won't succeed until this is done on our side.

### Usage

Drop `FrameApplePayButton` anywhere in your SwiftUI view hierarchy. It renders nothing on devices that do not support Apple Pay or when the merchant ID isn't configured at init — no need to guard it yourself.

The button takes a `mode` (`.charge(amount:currency:)` to charge the user, or `.addToOwner` to attach the wallet card without charging) and a `PaymentMethodOwner` (`.customer(...)` for the legacy ChargeIntent flow, `.account(...)` for the Transfer flow). The completion result carries the created resource's id — the caller decides what it represents based on the owner passed in.

```swift
import Frame_iOS

FrameApplePayButton(
    mode: .charge(amount: 4999, currency: "usd"),
    owner: .account("acc_123")
) { result in
    switch result {
    case .success(.charge(let id)):
        // `.customer` owner → ChargeIntent id
        // `.account`  owner → Transfer id
        print("Payment succeeded: \(id)")
    case .success(.paymentMethod):
        break // not produced in .charge mode
    case .failure(let error):
        print("Payment failed: \(error.localizedDescription)")
    }
}
```

Pass `.customer(...)` instead of `.account(...)` if your integration is customer-based:

```swift
FrameApplePayButton(
    mode: .charge(amount: 4999, currency: "usd"),
    owner: .customer("cus_456")
) { result in ... }
```

Pass `mode: .addToOwner` to attach the wallet card as a PaymentMethod without charging — useful for onboarding flows. The completion delivers `.success(.paymentMethod(FrameObjects.PaymentMethod))`.

### Button Customization

The button type and style can be configured to match your UI:

```swift
FrameApplePayButton(
    mode: .charge(amount: 4999, currency: "usd"),
    owner: .account("acc_123"),
    buttonType: .pay,        // .buy (default), .pay, .checkout, .plain, etc.
    buttonStyle: .white      // .automatic (default), .black, .white, .whiteOutline
) { result in ... }
```

See [`PKPaymentButtonType`](https://developer.apple.com/documentation/passkit/pkpaymentbuttontype) and [`PKPaymentButtonStyle`](https://developer.apple.com/documentation/passkit/pkpaymentbuttonstyle) for all available options.

### Using Apple Pay inside FrameCheckoutView

When a merchant ID is configured at SDK init, `FrameCheckoutView` automatically shows an Apple Pay button at the top of the checkout sheet. The bundled checkout is account-scoped, so the resulting id is always a Transfer id.

```swift
FrameCheckoutView(
    accountId: "acc_123",
    paymentAmount: 4999
) { result in
    switch result {
    case .completed(let transferId):
        print("Transfer created: \(transferId)")
    case .cancelled:
        print("User dismissed checkout")
    case .failed(let error):
        print("Checkout failed: \(error.localizedDescription)")
    }
}
```

`FrameCheckoutView`, `FrameCartView`, and `OnboardingContainerView` all deliver outcomes through the same `FrameResult` enum (`completed(id:)` / `cancelled` / `failed(Error)`). For checkout and cart, the `id` is a Transfer id. For onboarding, it's the selected PaymentMethod id (or empty string if the flow completed without one).

```swift
// Same shape across all three modals.
public enum FrameResult {
    case completed(id: String)
    case cancelled
    case failed(Error)
}
```

If no `applePayMerchantId` was configured at init, the Apple Pay row is hidden and only the card entry form is shown.

### Testing

Apple Pay **requires a physical device** — it cannot be tested on the Simulator. To test in the Frame sandbox:

1. Use a device with a card added to Apple Wallet.
2. Initialize the SDK with your sandbox key (`sk_sandbox_...`) and your merchant ID.
3. The Frame backend returns synthetic card details in sandbox mode — no real charge is made.

### Troubleshooting

| Symptom | Likely cause |
|---|---|
| Button does not appear | Device has no cards in Wallet, the Apple Pay capability is missing from the app target, or `applePayMerchantId` wasn't passed to `initializeWithAPIKey` |
| "Missing entitlement" error at runtime | The merchant ID in your entitlements file doesn't match the one passed to `initializeWithAPIKey` |
| Payment sheet appears but authorization fails | SDK not initialized, or Apple Pay hasn't been enabled on your Frame account — contact [support@framepayments.com](mailto:support@framepayments.com) |

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
- Processing payments with `FrameApplePayButton`
- Triggering a full onboarding flow with `OnboardingContainerView`
- Listing customers, payment methods, subscriptions, charge intents, and refunds

To run the example app, open `FrameExample-iOS/FrameExample-iOS.xcodeproj` in Xcode and run the target on a simulator or device.

---

## Privacy

The Frame iOS SDK collects device signals for fraud prevention purposes. Our full privacy policy is available at [framepayments.com/privacy](https://framepayments.com/privacy).

---

## Support

- **Documentation:** [docs.framepayments.com](https://docs.framepayments.com)
- **Dashboard:** [framepayments.com](https://framepayments.com)
- **Issues:** [github.com/Frame-Payments/frame-ios/issues](https://github.com/Frame-Payments/frame-ios/issues)

# Frame-iOS SDK

The Frame iOS SDK simplifies the process of creating a seamless payment experience within your iOS app. It offers versatile, pre-designed UI components that enable you to effortlessly gather payment details from your users. Additionally, it provides access to the underlying APIs that drive these components, allowing you to design fully customized payment workflows tailored to your app's needs.

Table of contents
=================
<!-- NOTE: Use case-sensitive anchor links for docc compatibility -->
<!--ts-->
   * [Requirements](#Requirements)
   * [Features](#Features)
   * [Getting started](#Getting-started)
   * [Privacy](#Privacy)


## Requirements

The Frame iOS SDK requires Xcode 15 or later and is compatible with apps targeting iOS 17 or above. We support Catalyst on macOS 11 or later.

For iOS 12 support, please use [v22.8.4](https://github.com/stripe/stripe-ios/tree/v22.8.4). For iOS 11 support, please use [v21.13.0](https://github.com/stripe/stripe-ios/tree/v21.13.0). For iOS 10, please use [v19.4.0](https://github.com/stripe/stripe-ios/tree/v19.4.0). If you need to support iOS 9, use [v17.0.2](https://github.com/stripe/stripe-ios/tree/v17.0.2).


## Features

**Simplified security**: We make it simple for you to collect sensitive data such as credit card numbers and remain [PCI compliant](https://stripe.com/docs/security#pci-dss-guidelines). This means the sensitive data is sent directly to Stripe instead of passing through your server. For more information, see our [integration security guide](https://stripe.com/docs/security).

**Apple Pay**: [StripeApplePay](StripeApplePay/README.md) provides a [seamless integration with Apple Pay](https://stripe.com/docs/apple-pay).

## Getting started

### Integration

Get started with our [📚 integration guides](https://stripe.com/docs/payments/accept-a-payment?platform=ios) and [example projects](/Example), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/docs/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Examples

- [Prebuilt UI](Example/PaymentSheet%20Example) (Recommended)
  - This example demonstrates how to build a payment flow using [`PaymentSheet`](https://stripe.com/docs/payments/accept-a-payment?platform=ios), an embeddable native UI component that lets you accept [10+ payment methods](https://stripe.com/docs/payments/payment-methods/integration-options#payment-method-product-support) with a single integration.

- [Non-Card Payment Examples](Example/Non-Card%20Payment%20Examples)
  - This example demonstrates how to manually accept various payment methods using the Stripe API.

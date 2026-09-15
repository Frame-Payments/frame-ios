# Account Events Catalog

The canonical list of `account_events` names and screens emitted across the Frame SDKs — iOS, Android, React Native, and Web. This is the shared naming contract FRA-6548 calls for: `name` and `screen` are free text server-side (no closed enum), so this document is the only thing keeping the dashboard's filters coherent across four independently-shipping codebases.

Wire contract lives on [FRA-6548](https://linear.app/framepayments/issue/FRA-6548/emit-accountsdk-events-from-the-sdks-shared-contract). This document is the naming contract that sits on top of it — every `name`/`screen` pair a platform emits should appear below before it ships. If a platform needs an event this catalog doesn't have, add it here first, in the same PR, so the other three platforms can pick it up.

**Format:** `name` is the literal wire value sent in the `name` field (snake_case, ≤100 chars). The label beside it is the same event in Title Case for readability in this doc — it is not sent anywhere. `screen` is the literal wire value for the `screen` field. `detail` is a one-line description of what the optional `detail` field should carry, when applicable.

Coverage columns show which platforms currently emit the event: ✅ implemented, ⬜ not yet implemented (real gap, should be added), ▪️ not applicable to that platform (flow doesn't exist there). A platform column reflects the codebase audited at the time this catalog was written (September 2026) — keep it current as PRs land.

---

## Onboarding — Session

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `onboarding_started` — Onboarding Started | `Onboarding` | — | ✅ | ⬜ | ✅ | ⬜ |
| `onboarding_step_viewed` — Onboarding Step Viewed | per-step (see below) | step key | ✅ | ⬜ | ✅ | ⬜ |
| `onboarding_step_completed` — Onboarding Step Completed | per-step | step key | ✅ | ⬜ | ✅ | ⬜ |
| `onboarding_completed` — Onboarding Completed | `Onboarding` | final outcome | ✅ | ⬜ | ✅ | ⬜ |
| `onboarding_declined` — Onboarding Declined | `Onboarding` | decline reason | ✅ | ⬜ | ✅ | ⬜ |
| `onboarding_needs_review` — Onboarding Needs Review | `Onboarding` | — | ✅ | ⬜ | ✅ | ⬜ |
| `onboarding_action_required` — Onboarding Action Required | `Onboarding` | what's required | ✅ | ⬜ | ✅ | ⬜ |
| `onboarding_cancelled` — Onboarding Cancelled | last step reached | how far the user got — this is the funnel drop-off signal | ✅ | ⬜ | ✅ | ⬜ |
| `onboarding_blocked` — Onboarding Blocked | `Onboarding` | dead-end reason (capability outstanding, nothing actionable) | ✅ | ⬜ | ✅ | ▪️ |
| `onboarding_session_start_failed` — Failed To Start Onboarding | `Onboarding` | mint/create failure | ✅ | ⬜ | ✅ | ▪️ |
| `onboarding_session_expired` — Onboarding Session Expired | `Onboarding` | — | ▪️ | ▪️ | ▪️ | ⬜ |
| `onboarding_session_not_found` — Onboarding Session Not Found | `Onboarding` | — | ▪️ | ▪️ | ▪️ | ⬜ |

## Onboarding — Phone Verification

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `phone_verification_started` — Started Phone Verification | `PhoneVerification` | — | ✅ | ⬜ | ✅ | ⬜ |
| `phone_code_sent` — Sent Verification Code | `PhoneVerification` | — | ✅ | ⬜ | ✅ | ⬜ |
| `phone_code_send_failed` — Failed To Send Code | `PhoneVerification` | backend rejection reason | ✅ | ⬜ | ✅ | ⬜ |
| `phone_code_entry_started` — Started Code Confirmation | `PhoneVerification` | — | ✅ | ⬜ | ✅ | ⬜ |
| `phone_verified` — Confirmed Phone Number | `PhoneVerification` | — | ✅ | ⬜ | ✅ | ⬜ |
| `phone_code_incorrect` — Entered Incorrect Code | `PhoneVerification` | — | ✅ | ⬜ | ✅ | ⬜ |
| `phone_code_entry_cancelled` — Cancelled Code Entry | `PhoneVerification` | — | ✅ | ⬜ | ✅ | ▪️ |
| `phone_code_resent` — Resent Verification Code | `PhoneVerification` | — | ⬜ | ⬜ | ✅ | ▪️ |
| `phone_code_resend_failed` — Failed To Resend Code | `PhoneVerification` | — | ⬜ | ⬜ | ✅ | ▪️ |
| `silent_phone_auth_started` — Started Silent Phone Auth | `PhoneVerification` | provider: prove | ✅ | ⬜ | ✅ | ▪️ |
| `silent_phone_auth_completed` — Completed Silent Phone Auth | `PhoneVerification` | provider: prove | ✅ | ⬜ | ✅ | ▪️ |
| `silent_phone_auth_fallback` — Fell Back To Code Entry | `PhoneVerification` | why silent auth was abandoned | ✅ | ⬜ | ✅ | ▪️ |
| `silent_phone_auth_failed` — Failed Silent Phone Auth | `PhoneVerification` | terminal failure after fallback also failed | ✅ | ⬜ | ✅ | ▪️ |

## Onboarding — Profile

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `profile_step_started` — Started Profile Step | `PersonalInformation` | — | ✅ | ⬜ | ✅ | ⬜ |
| `profile_updated` — Updated Account Profile | `PersonalInformation` | — | ✅ | ⬜ | ✅ | ⬜ |
| `profile_update_failed` — Failed To Update Profile | `PersonalInformation` | backend rejection reason | ✅ | ⬜ | ✅ | ⬜ |
| `profile_validation_failed` — Profile Validation Failed | `PersonalInformation` | which field(s) | ✅ | ⬜ | ✅ | ⬜ |

## Onboarding — Identity Verification / Step-Up

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `step_up_started` — Started Step Up | `IdentityVerification` | provider: persona | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_completed` — Completed Step Up | `IdentityVerification` | — | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_already_verified` — Already Verified | `IdentityVerification` | pre-check short-circuit, Persona never launched | ✅ | ⬜ | ✅ | ▪️ |
| `step_up_failed` — Failed Step Up | `IdentityVerification` | generic bucket — prefer a category below when known | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_needs_review` — Step Up Needs Review | `IdentityVerification` | category: review | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_data_mismatch` — Step Up Data Mismatch | `IdentityVerification` | category: retriable_with_new_data | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_escalated` — Step Up Escalated | `IdentityVerification` | category: step_up (e.g. SSN path failed, now needs gov ID) | ✅ | ⬜ | ✅ | ▪️ |
| `step_up_declined` — Step Up Declined | `IdentityVerification` | category: terminal | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_unavailable` — Step Up Temporarily Unavailable | `IdentityVerification` | category: transient / provider_error | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_cancelled` — Cancelled Step Up | `IdentityVerification` | user closed the verification UI | ✅ | ⬜ | ✅ | ▪️ |
| `step_up_provider_unavailable` — Step Up Provider Unavailable | `IdentityVerification` | Persona SDK not installed/linked — host misconfiguration | ⬜ | ⬜ | ✅ | ▪️ |

## Onboarding — Payment Method

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `payment_method_step_started` — Started Payment Method Step | `PaymentMethod` | — | ✅ | ⬜ | ✅ | ⬜ |
| `saved_payment_method_selected` — Selected Saved Payment Method | `PaymentMethod` | — | ✅ | ⬜ | ✅ | ⬜ |
| `add_payment_method_started` — Started Add Payment Method | `PaymentMethod` | — | ✅ | ⬜ | ✅ | ⬜ |
| `payment_method_added` — Added Payment Method | `PaymentMethod` | — | ✅ | ⬜ | ✅ | ⬜ |
| `payment_method_add_failed` — Failed To Add Payment Method | `PaymentMethod` | backend rejection reason | ✅ | ⬜ | ✅ | ⬜ |
| `card_validation_failed` — Card Validation Failed | `PaymentMethod` | which field | ✅ | ⬜ | ✅ | ⬜ |
| `billing_address_updated` — Updated Billing Address | `PaymentMethod` | address-only verification path | ✅ | ⬜ | ⬜ | ▪️ |
| `billing_address_update_failed` — Failed To Update Billing Address | `PaymentMethod` | — | ✅ | ⬜ | ⬜ | ▪️ |
| `saved_payment_methods_load_failed` — Failed To Load Saved Methods | `PaymentMethod` | — | ✅ | ⬜ | ✅ | ⬜ |
| `card_input_load_failed` — Card Input Failed To Load | `PaymentMethod` | element/iframe mount failure | ▪️ | ▪️ | ▪️ | ⬜ |

## Onboarding — Payout Method

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `payout_method_step_started` — Started Payout Method Step | `PayoutMethod` | — | ✅ | ⬜ | ✅ | ⬜ |
| `saved_payout_method_selected` — Selected Saved Payout Method | `PayoutMethod` | — | ✅ | ⬜ | ✅ | ⬜ |
| `add_payout_method_started` — Started Add Payout Method | `PayoutMethod` | manual or plaid | ✅ | ⬜ | ✅ | ⬜ |
| `payout_method_added` — Added Payout Method | `PayoutMethod` | manual/ACH path | ✅ | ⬜ | ✅ | ⬜ |
| `payout_method_add_failed` — Failed To Add Payout Method | `PayoutMethod` | backend rejection reason | ✅ | ⬜ | ✅ | ⬜ |
| `bank_link_started` — Started Bank Link | `PayoutMethod` | provider: plaid | ✅ | ⬜ | ✅ | ⬜ |
| `bank_link_completed` — Completed Bank Link | `PayoutMethod` | provider: plaid | ✅ | ⬜ | ✅ | ⬜ |
| `bank_link_cancelled` — Cancelled Bank Link | `PayoutMethod` | user dismissed Plaid | ✅ | ⬜ | ⬜ | ▪️ |
| `bank_link_failed` — Failed Bank Link | `PayoutMethod` | Plaid error message | ✅ | ⬜ | ⬜ | ▪️ |
| `payout_method_elected` — Elected Payout Method | `PayoutMethod` | set as primary | ✅ | ⬜ | ⬜ | ▪️ |
| `payout_method_election_failed` — Failed To Elect Payout Method | `PayoutMethod` | — | ✅ | ⬜ | ⬜ | ▪️ |
| `saved_payout_methods_load_failed` — Failed To Load Saved Payouts | `PayoutMethod` | — | ⬜ | ⬜ | ✅ | ▪️ |

**Note on `bank_link_cancelled`/`bank_link_failed`/`payout_method_elected`/`payout_method_election_failed` on RN:** this catalog originally marked these `▪️` (not applicable) for RN, but `frame-react-native`'s `src/plaid.ts` (`onExit`, ~line 143-149) and `useOnboardingViewModel.ts`'s `electSelectedPayoutMethod` already have the exact code paths these rows describe — Plaid distinguishes a real error (`exit.error` → `PAYMENT_FAILED`) from a user dismiss (`USER_CANCELED`), and election has its own success/failure branch. Corrected to `⬜` (real gap) — these four are ready to instrument on the next RN touch.

## Onboarding — Document Upload

Dormant on iOS today (no capture UI exists at all — only an unused REST client, see iOS notes) and previously dormant on RN (built, just excluded from `computeFlow()`) — now instrumented on RN so it activates under the right names whenever the step is wired back in.

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `document_upload_started` — Started Document Upload | `DocumentUpload` | ID type selected | ⬜ | ⬜ | ✅ | ▪️ |
| `document_photo_captured` — Captured Document Photo | `DocumentUpload` | which side (front/back/selfie) | ⬜ | ⬜ | ✅ | ▪️ |
| `document_photo_retaken` — Retook Document Photo | `DocumentUpload` | — | ⬜ | ⬜ | ✅ | ▪️ |
| `document_upload_completed` — Completed Document Upload | `DocumentUpload` | — | ⬜ | ⬜ | ✅ | ▪️ |
| `document_upload_failed` — Failed Document Upload | `DocumentUpload` | missing fields / no files / backend rejection | ⬜ | ⬜ | ✅ | ▪️ |

## Onboarding — Compliance Check

`compliance_check_detected_vpn` and `compliance_check_continued_anyway` are dormant on iOS today (view exists, not wired into the active flow) — same forward-compatible reasoning as document upload.

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `compliance_check_started` — Started Compliance Check | `Compliance` | — | ✅ | ⬜ | ✅ | ⬜ |
| `compliance_check_passed` — Passed Compliance Check | `Compliance` | — | ✅ | ⬜ | ✅ | ⬜ |
| `compliance_check_failed` — Failed Compliance Check | `Compliance` | non-blocking — flow still advances | ⬜ | ⬜ | ✅ | ⬜ |
| `compliance_check_vpn_detected` — Detected VPN Or Proxy | `Compliance` | — | ✅ | ▪️ | ▪️ | ▪️ |
| `compliance_check_vpn_bypassed` — Continued Despite VPN Warning | `Compliance` | — | ✅ | ▪️ | ▪️ | ▪️ |
| `id_verification_popup_unsupported` — ID Verification Not Yet Supported | `Compliance` | web's `id_verification`/`geo_compliance` steps are launch stubs today — use this name, not `compliance_check_failed`, so it doesn't read as a real failure rate | ▪️ | ▪️ | ▪️ | ⬜ |

## Onboarding — Terms of Service

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `terms_of_service_shown` — Shown Terms Of Service | `TermsOfService` | — | ✅ | ⬜ | ✅ | ⬜ |
| `terms_of_service_accepted` — Accepted Terms Of Service | `TermsOfService` | — | ✅ | ⬜ | ✅ | ⬜ |
| `terms_of_service_token_failed` — Failed To Load Terms Token | `TermsOfService` | — | ✅ | ⬜ | ✅ | ⬜ |
| `terms_of_service_accept_failed` — Failed To Accept Terms | `TermsOfService` | — | ⬜ | ⬜ | ✅ | ⬜ |

## Checkout / Payment Confirmation

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `checkout_started` — Started Checkout | `PaymentSheet` | — | ✅ | ⬜ | ✅ | ⬜ |
| `checkout_payment_method_selected` — Selected Payment Method | `PaymentSheet` | saved or new | ✅ | ⬜ | ✅ | ⬜ |
| `checkout_validation_failed` — Checkout Validation Failed | `PaymentSheet` | which field | ✅ | ⬜ | ✅ | ⬜ |
| `checkout_payment_started` — Started Payment | `PaymentSheet` | pay button tapped | ✅ | ⬜ | ✅ | ⬜ |
| `card_tokenized` — Tokenized Card | `PaymentSheet` | — | ✅ | ⬜ | ✅ | ⬜ |
| `card_tokenization_failed` — Failed To Tokenize Card | `PaymentSheet` | — | ✅ | ⬜ | ✅ | ✅ (as `tokenization_failed`) |
| `card_declined_by_merchant` — Card Declined By Merchant | `PaymentSheet` | merchant-reported via server-side rejection | ▪️ | ▪️ | ▪️ | ⬜ |
| `checkout_payment_succeeded` — Payment Succeeded | `PaymentSheet` | — | ✅ | ⬜ | ✅ | ⬜ |
| `checkout_payment_declined` — Payment Declined | `PaymentSheet` | issuer decline reason if available | ✅ | ⬜ | ✅ | ⬜ |
| `checkout_payment_failed` — Payment Failed | `PaymentSheet` | technical failure, distinct from a decline | ✅ | ⬜ | ✅ | ✅ (as `tokenization_failed` — consider renaming, see note below) |
| `checkout_cancelled` — Cancelled Checkout | `PaymentSheet` | — | ✅ | ⬜ | ▪️ | ▪️ |
| `step_up_challenge_started` — Started Step Up Challenge | `PaymentSheet` | 3DS | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_challenge_completed` — Completed Step Up Challenge | `PaymentSheet` | cardholder finished the UI — not itself a verdict | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_challenge_abandoned` — Abandoned Step Up Challenge | `PaymentSheet` | cardholder cancelled/dismissed | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_challenge_unavailable` — Step Up Challenge Unavailable | `PaymentSheet` | challenge page never loaded | ✅ | ⬜ | ✅ | ⬜ |
| `step_up_challenge_timed_out` — Step Up Challenge Timed Out | `PaymentSheet` | — | ✅ (as `charge_intent_confirmation_polling_exhausted`) | ⬜ | ✅ (as `charge_poll_exhausted` / `charge_poll_timed_out`) | ⬜ |

**Note on existing web names:** `confirmCardPayment.ts` currently reuses `"tokenization_failed"` for both true tokenization failures and broader confirm/decline/3DS failures (`lib/confirmCardPayment.ts:146,379`). Recommend splitting these into `card_tokenization_failed` vs. `checkout_payment_failed` per this catalog next time that file is touched — flagging here rather than silently renaming a shipped event.

**Note on existing native names:** iOS's `charge_intent_confirmation_polling_exhausted` and RN's `charge_poll_exhausted`/`charge_poll_timed_out` predate this catalog (FRA-6549/6551) and both point at the same moment this catalog calls `step_up_challenge_timed_out`. Left as-is rather than force a rename into an already-shipped PR; align on the next touch.

## Apple Pay

iOS and RN only — Android and Web have no Apple Pay surface.

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `apple_pay_started` — Started Apple Pay | `ApplePay` | — | ✅ | ▪️ | ✅ | ▪️ |
| `apple_pay_unavailable` — Apple Pay Unavailable | `ApplePay` | which gate blocked it (merchant id / canMakePayments / attestation) | ✅ | ▪️ | ✅ | ▪️ |
| `apple_pay_authorized` — Authorized Apple Pay Payment | `ApplePay` | — | ✅ | ▪️ | ✅ | ▪️ |
| `apple_pay_failed` — Apple Pay Payment Failed | `ApplePay` | — | ✅ | ▪️ | ✅ | ▪️ |
| `apple_pay_cancelled` — Cancelled Apple Pay | `ApplePay` | sheet dismissed with no result | ✅ | ▪️ | ✅ | ▪️ |
| `apple_pay_card_added` — Added Apple Pay Card | `ApplePay` | mode: add-to-owner (onboarding wallet-card save, no charge) | ✅ | ▪️ | ✅ | ▪️ |
| `apple_pay_assertion_rejected` — Apple Pay Assertion Rejected | `ApplePay` | attestation-linked failure, triggers an attestation reset | ✅ | ▪️ | ✅ | ▪️ |
| `apple_pay_merchant_validation_failed` — Apple Pay Merchant Validation Failed | `ApplePay` | Apple domain-verification handshake failed | ▪️ | ▪️ | ▪️ | ▪️ |

## Google Pay

Android, RN, and Web only — iOS has no Google Pay surface.

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `google_pay_started` — Started Google Pay | `GooglePay` | — | ▪️ | ⬜ | ✅ | ⬜ |
| `google_pay_unavailable` — Google Pay Unavailable | `GooglePay` | — | ▪️ | ⬜ | ✅ | ⬜ |
| `google_pay_authorized` — Authorized Google Pay Payment | `GooglePay` | — | ▪️ | ⬜ | ✅ | ⬜ |
| `google_pay_failed` — Google Pay Payment Failed | `GooglePay` | — | ▪️ | ⬜ | ✅ | ⬜ |
| `google_pay_cancelled` — Cancelled Google Pay | `GooglePay` | — | ▪️ | ⬜ | ✅ | ⬜ |
| `google_pay_misconfigured` — Google Pay Misconfigured | `GooglePay` | e.g. invalid processor from backend config — a real bug signal, not a user-facing failure | ▪️ | ⬜ | ✅ | ⬜ |

## Device Attestation

iOS and RN only. Android has no App Attest equivalent (tracked separately, out of scope here per FRA-6548).

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `attestation_started` — Started Device Attestation | `PaymentSheet` or `ApplePay` depending on trigger | — | ✅ | ▪️ | ✅ | ▪️ |
| `attestation_completed` — Completed Device Attestation | same | one-time per device — currently unemitted on both platforms | ✅ | ▪️ | ✅ | ▪️ |
| `attestation_not_supported` — Device Attestation Not Supported | same | simulator or unsupported OS version | ✅ | ▪️ | ✅ | ▪️ |
| `attestation_failed` — Failed Device Attestation | same | subtype in detail (key gen / challenge fetch / apple attest / backend reject) | ✅ | ▪️ | ✅ (as `device_attestation_failed`) | ▪️ |
| `attestation_reset` — Reset Device Attestation | same | retry-after-reset, or externally triggered by an assertion rejection | ✅ (as `attestation_reset_and_retry`) | ▪️ | ✅ | ▪️ |
| `attestation_assertion_retried` — Retried Assertion After Reset | same | per-payment assertion, distinct from the one-time attestation above | ✅ | ▪️ | ✅ | ▪️ |

## Fraud Session (Sonar)

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `fraud_session_started` — Started Fraud Session | current screen at session bind | — | ✅ | ⬜ | ✅ | ⬜ |
| `fraud_session_refreshed` — Refreshed Fraud Session | current screen | — | ✅ | ⬜ | ✅ | ⬜ |
| `fraud_session_recreated` — Fraud Session Recreated | current screen | refresh failed, fell back to creating fresh — self-healing, not a hard failure | ✅ | ⬜ | ✅ | ⬜ |
| `fraud_session_failed` — Failed Fraud Session | current screen | — | ✅ (as `sonar_session_failed`) | ⬜ | ✅ (as `sonar_session_failed`) | ⬜ |
| `fraud_session_adopted` — Adopted Legacy Fraud Session | current screen | pre-account anonymous session migrated to account-scoped | ✅ | ⬜ | ✅ | ▪️ |

## SDK Initialization

Web only in practice — native SDKs don't have an equivalent loud init-failure moment today, but the names are shared vocabulary in case that changes.

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `sdk_initialized` — SDK Initialized | `SDKInit` | — | ▪️ | ▪️ | ▪️ | ⬜ |
| `sdk_initialization_failed` — SDK Initialization Failed | `SDKInit` | publishable key rejected, or a required dependency never loaded | ▪️ | ▪️ | ▪️ | ⬜ |
| `third_party_script_failed` — Third Party Script Failed | `SDKInit` | which dependency: evervault / fingerprint / sift | ▪️ | ▪️ | ▪️ | ⬜ |

## Address Search

| name (Title Case) | screen | detail | iOS | Android | RN | Web |
|---|---|---|---|---|---|---|
| `address_searched` — Searched Address | wherever the field is mounted | — | ▪️ | ▪️ | ✅ | ⬜ |
| `address_search_failed` — Address Search Failed | same | — | ▪️ | ▪️ | ✅ | ⬜ |
| `address_suggestion_selected` — Selected Address Suggestion | same | — | ▪️ | ▪️ | ✅ | ⬜ |
| `address_lookup_failed` — Address Lookup Failed | same | retrieve-by-id failure, distinct from the search-list failure above | ▪️ | ▪️ | ✅ | ⬜ |

---

## Naming conventions for new events

When a platform needs an event not yet in this catalog:

1. **Title Case, ≤5 words**, verb-first for actions (`Started X`, `Completed X`, `Failed X`, `Cancelled X`). The wire `name` is the same words in `snake_case`.
2. **Reuse an existing `screen` value** if the moment happens on a screen already named here. Screens are free text but should stay stable across platforms doing the same job — check this table before coining a new one.
3. **Distinguish user-cancelled from failed.** Several flows above (Persona, Plaid, Apple/Google Pay sheets, Prove OTP) explicitly separate a user backing out from a real failure — preserve that distinction rather than collapsing both into `..._failed`. It's the difference between a funnel drop-off and a bug.
4. **Prefer a specific failure category over a generic bucket** when the underlying code already classifies the failure (e.g. step-up's `terminal`/`review`/`retriable_with_new_data`/`step_up`/`transient` categories, or `TransferStatus`'s state machine). Fall back to the generic `..._failed` name only when no such classification exists.
5. **Add the row to this file in the same PR** that adds the call site, so the other three platforms see it land and can pick up the identical name instead of inventing a synonym.
6. **No PII in `name`, `screen`, or `detail`.** These are free text with no server-side allowlist — see FRA-6548. `detail` is developer-facing context (error codes, provider names, category labels), never raw customer data.

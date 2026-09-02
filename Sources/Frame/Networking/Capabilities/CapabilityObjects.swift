//
//  CapabilityObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

extension FrameObjects {

    /// Represents the full set of capabilities that can be enabled or required for a Frame account.
    public enum Capabilities: String, Codable {
        // View - Identity and Phone Verification

        /// Capability that enables KYC (Know Your Customer) identity verification for an account.
        case kyc

        /// Capability that enables KYC with pre-fill support; also enables the base `kyc` capability.
        case kycPrefill = "kyc_prefill"

        /// Capability that requires government-issued photo ID verification via Persona. 
        case idv

        /// Capability that enables phone-number verification for an account.
        case phoneVerification = "phone_verification"

        /// Backend capability that enables creator-shield protection; requires a `profile_url` when creating an account.
        case creatorShield = "creator_shield"

        /// Capability that enables age-verification checks for an account.
        case ageVerification = "age_verification"

        // View - Add or Select Payment Method (Card)

        /// Capability that enables card verification; also enables the `cardSend` capability.
        case cardVerification = "card_verification"

        /// Capability that allows an account to send funds via card.
        case cardSend = "card_send"

        /// Capability that allows an account to receive funds via card.
        case cardReceive = "card_receive"

        /// Capability that requires address verification (AVS) for credit and debit cards; performed on the backend.
        case addressVerification = "address_verification"

        // View - Add or Select Payment Method (ACH)

        /// Capability that enables bank-account verification for an account.
        case bankAccountVerification = "bank_account_verification"

        /// Capability that allows an account to send funds via bank account (ACH).
        case bankAccountSend = "bank_account_send"

        /// Capability that allows an account to receive funds via bank account (ACH).
        case bankAccountReceive = "bank_account_receive"

        // View - Geocompliance Flow

        /// Capability that enforces geo-compliance checks for an account.
        case geoCompliance = "geo_compliance"

        // View - Upload Documents
    }

    /// Requirement keys that can appear in a capability's `currently_due`.
    public enum CapabilityRequirementKey {
        /// Government-ID verification, required by whichever capability lists it rather than by a
        /// standalone `idv` capability.
        public static let identityDocument = "individual.identity_document"

        /// A KYC run rejected on complete-but-wrong details, so corrected data is the road forward.
        public static let kyc = "individual.kyc"
    }

    /// Describes a single requirement that must be satisfied in order to enable a capability.
    public struct CapabilityRequirement: Codable, Sendable, Equatable {
        /// Unique identifier for this capability requirement.
        public let id: String

        /// Object type identifier returned by the Frame API.
        public let object: String

        /// The kind of requirement (e.g., `"document"`, `"verification"`).
        public let type: String

        /// Current fulfillment status of the requirement (e.g., `"pending"`, `"satisfied"`).
        public let status: String

        /// Optional source that surfaced this requirement, if applicable.
        @Lenient public private(set) var source: String?

        enum CodingKeys: String, CodingKey {
            case id, object, type, status, source
        }
    }

    /// Represents a Frame capability and its current state on a given account.
    public struct Capability: Codable, Sendable, Equatable {
        /// Unique identifier for this capability record.
        public let id: String

        /// Object type identifier returned by the Frame API.
        public let object: String

        /// Human-readable name of the capability.
        public let name: String

        /// Identifier of the account this capability is associated with.
        public let accountId: String

        /// Current status of the capability (e.g., `"active"`, `"inactive"`, `"pending"`).
        public let status: String

        /// Reason the capability is disabled, if applicable. See ``isOutstanding``.
        @Lenient public private(set) var disabledReason: String?

        /// Reason the account is ineligible to hold this capability, if applicable.
        @Lenient public private(set) var ineligibleReason: String?

        /// Why this capability has not been granted, derived from the latest concluded
        /// identity-verification run. At most one entry, and only for `kyc` today.
        @Lenient public private(set) var errors: [CapabilityError]?

        /// List of requirement keys that are currently outstanding and must be resolved.
        @Lenient public private(set) var currentlyDue: [String]?

        /// ISO 8601 timestamp indicating when the capability was created.
        public let created: String

        /// ISO 8601 timestamp indicating when the capability was last updated.
        public let updated: String

        /// Whether the capability is currently disabled.
        @Lenient public private(set) var disabled: Bool?

        enum CodingKeys: String, CodingKey {
            case id, object, name, status
            case accountId = "account_id"
            case disabledReason = "disabled_reason"
            case ineligibleReason = "ineligible_reason"
            case currentlyDue = "currently_due"
            case created, updated, disabled, errors
        }
    }

    /// Statuses a capability can hold on an account. Mapped from the wire `String`, so a value
    /// added server-side becomes ``unknown`` rather than breaking a shipped app.
    public enum CapabilityStatus: String, Sendable, Equatable {
        /// Never requested for this account.
        case unrequested
        /// Requested, but its requirements are not yet satisfied.
        case pending
        /// Granted and in effect.
        case active
        /// Held but switched off. ``Capability/disabledReason`` says whether that was risk-borne.
        case disabled
        /// The account type may not hold this capability.
        case ineligible
        /// A status this SDK version does not know.
        case unknown
    }

    /// A server-derived conclusion about why a capability has not been granted.
    public struct CapabilityError: Codable, Sendable, Equatable {
        /// Identifier for this derived conclusion.
        public let id: String

        /// Object type identifier returned by the Frame API.
        @Lenient public private(set) var object: String?

        /// Frame's provider-neutral failure type, e.g. `identity_mismatch`, `verification_rejected`.
        @Lenient public private(set) var code: String?

        /// Display-ready explanation. Preferred over client-side copy so every Frame surface
        /// says the same words.
        @Lenient public private(set) var message: String?

        /// The requirement this conclusion is attached to, if any.
        @Lenient public private(set) var requirementId: String?

        enum CodingKeys: String, CodingKey {
            case id, object, code, message
            case requirementId = "requirement_id"
        }
    }
}

extension FrameObjects.Capabilities {
    /// Which capabilities cannot be held without which others, mirroring the server's
    /// `Accounts::Capabilities::DependencyGraph::EDGES`.
    ///
    /// An edge from A to B means "A cannot be held without B": requesting A also provisions B.
    /// The server expands every capability request through this graph, so an account holds more
    /// capabilities than the host asked for — and the KYC verdict lands on the base `kyc` row
    /// even when the host only requested `kycPrefill`.
    ///
    /// A new edge added server-side must be mirrored here.
    private static let dependencyEdges: [FrameObjects.Capabilities: [FrameObjects.Capabilities]] = [
        .kycPrefill: [.kyc, .phoneVerification],
        .creatorShield: [.kyc, .ageVerification],
        .kyc: [.phoneVerification]
    ]

    /// Everything these capabilities drag in with them, themselves included.
    ///
    /// Transitive: `kycPrefill` reaches `phoneVerification` only by way of `kyc`.
    static func withDependencies(of capabilities: [FrameObjects.Capabilities]) -> Set<FrameObjects.Capabilities> {
        var reached: Set<FrameObjects.Capabilities> = []
        var pending = capabilities

        while let capability = pending.popLast() {
            guard reached.insert(capability).inserted else { continue }
            pending.append(contentsOf: dependencyEdges[capability] ?? [])
        }

        return reached
    }
}

extension FrameObjects.Capability {
    /// A commercial disable, not a verdict about the account holder.
    static let productGrantRevokedReason = "product_grant_revoked"

    /// This capability's status, degrading an unrecognized value to `unknown`.
    public var capabilityStatus: FrameObjects.CapabilityStatus {
        FrameObjects.CapabilityStatus(rawValue: status) ?? .unknown
    }

    /// Whether this capability still stands between the account and a successful onboarding.
    ///
    /// Mirrors the server's `Capability#blocks_activation?`. Reads `status`, not `currentlyDue`:
    /// `idv` declares no field keys, so it reports nothing due even when unsatisfied.
    public var isOutstanding: Bool {
        switch capabilityStatus {
        case .active, .unrequested, .ineligible:
            return false
        case .disabled:
            return disabledReason != Self.productGrantRevokedReason
        case .pending, .unknown:
            return true
        }
    }

    /// Whether work listed against this capability can still move it forward — the server blanks
    /// `currently_due` only for `ineligible`, so a disabled capability still publishes dead keys.
    public var hasActionableRequirements: Bool {
        switch capabilityStatus {
        case .pending, .unknown:
            return true
        case .active, .unrequested, .disabled, .ineligible:
            return false
        }
    }

    /// Requirement keys the applicant can actually resolve. Prefer over ``currentlyDue`` when asking them to act.
    public var actionableRequirements: [String] {
        hasActionableRequirements ? (currentlyDue ?? []) : []
    }
}

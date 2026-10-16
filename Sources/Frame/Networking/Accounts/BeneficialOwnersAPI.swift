import Foundation

/// Beneficial owners and controllers on a business account.
public enum BeneficialOwners {
    /// One person on the business, as returned by the beneficial-owners API.
    public struct Owner: Codable, Identifiable, Equatable, Sendable {
        /// The beneficial owner's id.
        public let id: String
        /// `pending`, `invite_sent`, or `completed`.
        @Lenient public var status: String?
        /// The owner's given name.
        @Lenient public var firstName: String?
        /// The owner's family name.
        @Lenient public var lastName: String?
        /// The owner's email address.
        @Lenient public var email: String?
        /// Role names, such as `owner` and `controller`.
        @Lenient public var roles: [String]?

        enum CodingKeys: String, CodingKey {
            case id, status, email, roles
            case firstName = "first_name"
            case lastName = "last_name"
        }
    }

    /// The `data` list returned by the beneficial-owners index.
    public struct ListResponse: Codable, Sendable {
        /// Owners on the account. Missing or malformed payloads decode as `nil`.
        @Lenient public var data: [Owner]?
    }

    /// Fields accepted by create and update. Omitted values are left unchanged on update.
    public struct WriteRequest: Codable, Sendable {
        /// Given name.
        public var firstName: String?
        /// Family name.
        public var lastName: String?
        /// Email address. Required when creating an owner.
        public var email: String?
        /// Date of birth, `YYYY-MM-DD`.
        public var dob: String?
        /// Social Security number. Business onboarding sends all 9 digits.
        public var ssn: String?
        /// Phone number, without the country code.
        public var phoneNumber: String?
        /// Phone country calling code.
        public var phoneCountryCode: String?
        /// Street address line 1.
        public var addressLine1: String?
        /// Street address line 2.
        public var addressLine2: String?
        /// City.
        public var city: String?
        /// State or region. Sent as `state`, which is the key the account write accepts.
        public var state: String?
        /// Postal code.
        public var postalCode: String?
        /// ISO country code.
        public var country: String?
        /// `owner`, `controller`, or both.
        public var roles: [String]?
        /// When `true`, the API emails an invite and skips the identity fields.
        public var invite: Bool?

        /// Creates a create or update body. Pass only the fields this call should send.
        public init(
            firstName: String? = nil,
            lastName: String? = nil,
            email: String? = nil,
            dob: String? = nil,
            ssn: String? = nil,
            phoneNumber: String? = nil,
            phoneCountryCode: String? = nil,
            addressLine1: String? = nil,
            addressLine2: String? = nil,
            city: String? = nil,
            state: String? = nil,
            postalCode: String? = nil,
            country: String? = nil,
            roles: [String]? = nil,
            invite: Bool? = nil
        ) {
            self.firstName = firstName
            self.lastName = lastName
            self.email = email
            self.dob = dob
            self.ssn = ssn
            self.phoneNumber = phoneNumber
            self.phoneCountryCode = phoneCountryCode
            self.addressLine1 = addressLine1
            self.addressLine2 = addressLine2
            self.city = city
            self.state = state
            self.postalCode = postalCode
            self.country = country
            self.roles = roles
            self.invite = invite
        }

        /// Omits unset fields so an update does not send JSON null.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(firstName, forKey: .firstName)
            try container.encodeIfPresent(lastName, forKey: .lastName)
            try container.encodeIfPresent(email, forKey: .email)
            try container.encodeIfPresent(dob, forKey: .dob)
            try container.encodeIfPresent(ssn, forKey: .ssn)
            try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
            try container.encodeIfPresent(phoneCountryCode, forKey: .phoneCountryCode)
            try container.encodeIfPresent(addressLine1, forKey: .addressLine1)
            try container.encodeIfPresent(addressLine2, forKey: .addressLine2)
            try container.encodeIfPresent(city, forKey: .city)
            try container.encodeIfPresent(state, forKey: .state)
            try container.encodeIfPresent(postalCode, forKey: .postalCode)
            try container.encodeIfPresent(country, forKey: .country)
            try container.encodeIfPresent(roles, forKey: .roles)
            try container.encodeIfPresent(invite, forKey: .invite)
        }

        enum CodingKeys: String, CodingKey {
            case email, dob, ssn, state, country, roles, invite
            case firstName = "first_name"
            case lastName = "last_name"
            case phoneNumber = "phone_number"
            case phoneCountryCode = "phone_country_code"
            case addressLine1 = "address_line1"
            case addressLine2 = "address_line2"
            case city
            case postalCode = "postal_code"
        }
    }
}

enum BeneficialOwnerEndpoints: FrameNetworkingEndpoints {
    case list(accountId: String)
    case create(accountId: String)
    case update(accountId: String, ownerId: String)
    case destroy(accountId: String, ownerId: String)
    case confirm(accountId: String)
    case resendInvite(accountId: String, ownerId: String)

    var endpointURL: String {
        switch self {
        case .list(let accountId), .create(let accountId):
            return "/v1/accounts/\(accountId)/beneficial_owners"
        case .update(let accountId, let ownerId), .destroy(let accountId, let ownerId):
            return "/v1/accounts/\(accountId)/beneficial_owners/\(ownerId)"
        case .confirm(let accountId):
            return "/v1/accounts/\(accountId)/beneficial_owners/confirm"
        case .resendInvite(let accountId, let ownerId):
            return "/v1/accounts/\(accountId)/beneficial_owners/\(ownerId)/resend_invite"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .list:
            return .GET
        case .create, .confirm, .resendInvite:
            return .POST
        case .update:
            return .PATCH
        case .destroy:
            return .DELETE
        }
    }

    var queryItems: [URLQueryItem]? { nil }
}

/// Client for `/v1/accounts/:id/beneficial_owners`.
public enum BeneficialOwnersAPI {
    /// Lists the owners and controllers on `accountId`.
    public static func list(accountId: String) async throws -> (BeneficialOwners.ListResponse?, NetworkingError?) {
        let endpoint = BeneficialOwnerEndpoints.list(accountId: accountId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        guard let data else { return (nil, error) }
        return (try? FrameNetworking.shared.jsonDecoder.decode(BeneficialOwners.ListResponse.self, from: data), error)
    }

    /// Creates an owner. Pass `invite: true` to email them instead of collecting identity now.
    public static func create(accountId: String, request: BeneficialOwners.WriteRequest) async throws -> (BeneficialOwners.Owner?, NetworkingError?) {
        try await write(endpoint: .create(accountId: accountId), request: request)
    }

    /// Updates an existing owner.
    public static func update(accountId: String, ownerId: String, request: BeneficialOwners.WriteRequest) async throws -> (BeneficialOwners.Owner?, NetworkingError?) {
        try await write(endpoint: .update(accountId: accountId, ownerId: ownerId), request: request)
    }

    /// Removes an owner. The API refuses to remove the last person holding a required role.
    public static func destroy(accountId: String, ownerId: String) async throws -> NetworkingError? {
        let endpoint = BeneficialOwnerEndpoints.destroy(accountId: accountId, ownerId: ownerId)
        let (_, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        return error
    }

    /// Confirms the roster and returns the account.
    public static func confirm(accountId: String) async throws -> NetworkingError? {
        let endpoint = BeneficialOwnerEndpoints.confirm(accountId: accountId)
        let (_, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        return error
    }

    /// Sends the invite email again.
    public static func resendInvite(accountId: String, ownerId: String) async throws -> NetworkingError? {
        let endpoint = BeneficialOwnerEndpoints.resendInvite(accountId: accountId, ownerId: ownerId)
        let (_, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        return error
    }

    private static func write(endpoint: BeneficialOwnerEndpoints, request: BeneficialOwners.WriteRequest) async throws -> (BeneficialOwners.Owner?, NetworkingError?) {
        let body = try? FrameNetworking.shared.jsonEncoder.encode(request)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: body)
        guard let data else { return (nil, error) }
        return (try? FrameNetworking.shared.jsonDecoder.decode(BeneficialOwners.Owner.self, from: data), error)
    }
}

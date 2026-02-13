import Foundation
import UIKit

// MARK: - Protocol

/// Wraps Plaid's REST API for link token creation, token exchange, and data fetching.
///
/// - Important: For a production app, `createLinkToken` and `exchangePublicToken` must
///   be proxied through your own backend server so the `client_id` and `secret` are never
///   bundled in the iOS binary. Each call site is marked with a TODO.
protocol PlaidServiceProtocol {
    func createLinkToken() async throws -> String
    func exchangePublicToken(_ publicToken: String) async throws -> String
    func fetchTransactions(accessToken: String, cursor: String?) async throws -> PlaidSyncResponse
    func fetchBalances(accessToken: String) async throws -> [PlaidAccount]
}

// MARK: - Codable Request/Response Types

struct PlaidLinkTokenRequest: Encodable {
    let client_id: String
    let secret: String
    let user: PlaidUser
    let client_name: String
    let products: [String]
    let country_codes: [String]
    let language: String
    let redirect_uri: String?

    struct PlaidUser: Encodable {
        let client_user_id: String
    }
}

struct PlaidLinkTokenResponse: Decodable {
    let link_token: String
    let expiration: String
}

struct PlaidExchangeRequest: Encodable {
    let client_id: String
    let secret: String
    let public_token: String
}

struct PlaidExchangeResponse: Decodable {
    let access_token: String
    let item_id: String
}

struct PlaidTransactionsSyncRequest: Encodable {
    let client_id: String
    let secret: String
    let access_token: String
    let cursor: String?
    let count: Int
}

struct PlaidSyncResponse: Decodable {
    let added: [PlaidTransaction]
    let modified: [PlaidTransaction]
    let removed: [PlaidRemovedTransaction]
    let next_cursor: String
    let has_more: Bool
}

struct PlaidTransaction: Decodable {
    let transaction_id: String
    let account_id: String
    let amount: Double          // Positive = debit/expense, negative = credit/income
    let date: String            // "YYYY-MM-DD"
    let name: String            // Merchant display name
    let merchant_name: String?
    let pending: Bool
    let personal_finance_category: PlaidCategory?

    struct PlaidCategory: Decodable {
        let primary: String
        let detailed: String
    }
}

struct PlaidRemovedTransaction: Decodable {
    let transaction_id: String
}

struct PlaidBalancesRequest: Encodable {
    let client_id: String
    let secret: String
    let access_token: String
}

struct PlaidBalancesResponse: Decodable {
    let accounts: [PlaidAccount]
}

struct PlaidAccount: Decodable {
    let account_id: String
    let name: String
    let official_name: String?
    let type: String            // "depository", "credit", "investment", "loan"
    let subtype: String?        // "checking", "savings", "credit card", etc.
    let balances: PlaidBalances

    struct PlaidBalances: Decodable {
        let current: Double?
        let available: Double?
        let limit: Double?
    }
}

// MARK: - Error Types

enum PlaidError: LocalizedError {
    case notConfigured
    case invalidResponse
    case serverError(String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Plaid credentials are not configured. Add PLAID_CLIENT_ID and PLAID_SECRET to your Xcode scheme."
        case .invalidResponse:
            return "Received an invalid response from Plaid."
        case .serverError(let message):
            return "Plaid server error: \(message)"
        case .decodingError(let error):
            return "Failed to parse Plaid response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Implementation

/// Concrete Plaid API client using URLSession.
///
/// - TODO: PRODUCTION — `createLinkToken` and `exchangePublicToken` must route through
///   your own backend. See `docs/api-integrations.md` for architecture guidance.
final class PlaidService: PlaidServiceProtocol {

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Link Token

    func createLinkToken() async throws -> String {
        guard AppConfig.isPlaidConfigured else { throw PlaidError.notConfigured }

        // TODO: PRODUCTION — Call your backend, which calls Plaid with server-side credentials.
        let body = PlaidLinkTokenRequest(
            client_id: AppConfig.plaidClientId,
            secret:    AppConfig.plaidSecret,
            user:      .init(client_user_id: UIDevice.current.identifierForVendor?.uuidString ?? "crown-user"),
            client_name:   "Crown Finance",
            products:      ["transactions"],
            country_codes: ["US"],
            language:      "en",
            redirect_uri:  AppConfig.plaidRedirectUri
        )
        let response: PlaidLinkTokenResponse = try await post(
            to: AppConfig.plaidBaseURL + "/link/token/create",
            body: body
        )
        return response.link_token
    }

    // MARK: - Token Exchange

    func exchangePublicToken(_ publicToken: String) async throws -> String {
        guard AppConfig.isPlaidConfigured else { throw PlaidError.notConfigured }

        // TODO: PRODUCTION — Call your backend for this exchange; never expose secret in client.
        let body = PlaidExchangeRequest(
            client_id:    AppConfig.plaidClientId,
            secret:       AppConfig.plaidSecret,
            public_token: publicToken
        )
        let response: PlaidExchangeResponse = try await post(
            to: AppConfig.plaidBaseURL + "/item/public_token/exchange",
            body: body
        )
        return response.access_token
    }

    // MARK: - Transactions Sync

    func fetchTransactions(accessToken: String, cursor: String? = nil) async throws -> PlaidSyncResponse {
        guard AppConfig.isPlaidConfigured else { throw PlaidError.notConfigured }

        let body = PlaidTransactionsSyncRequest(
            client_id:    AppConfig.plaidClientId,
            secret:       AppConfig.plaidSecret,
            access_token: accessToken,
            cursor:       cursor,
            count:        500
        )
        return try await post(to: AppConfig.plaidBaseURL + "/transactions/sync", body: body)
    }

    // MARK: - Balances

    func fetchBalances(accessToken: String) async throws -> [PlaidAccount] {
        guard AppConfig.isPlaidConfigured else { throw PlaidError.notConfigured }

        let body = PlaidBalancesRequest(
            client_id:    AppConfig.plaidClientId,
            secret:       AppConfig.plaidSecret,
            access_token: accessToken
        )
        let response: PlaidBalancesResponse = try await post(
            to: AppConfig.plaidBaseURL + "/accounts/balance/get",
            body: body
        )
        return response.accounts
    }

    // MARK: - Private Helper

    private func post<Request: Encodable, Response: Decodable>(
        to urlString: String,
        body: Request
    ) async throws -> Response {
        guard let url = URL(string: urlString) else { throw PlaidError.invalidResponse }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let encoded = try JSONEncoder().encode(body)
        request.httpBody = encoded

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw PlaidError.serverError("Request timed out. Check your network and try again.")
            }
            throw PlaidError.serverError(urlError.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw PlaidError.invalidResponse }

        guard (200..<300).contains(http.statusCode) else {
            // Parse Plaid's structured error body
            if let errBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let message = errBody["error_message"] as? String
                    ?? errBody["display_message"] as? String
                    ?? errBody["error_code"] as? String
                    ?? (String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)")
                throw PlaidError.serverError(message)
            }
            throw PlaidError.serverError("HTTP \(http.statusCode)")
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw PlaidError.decodingError(error)
        }
    }
}


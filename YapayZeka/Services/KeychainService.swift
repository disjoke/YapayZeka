import Foundation
import Security

enum KeychainService {
    private static let apiKeyAccount = "com.ekinciler.openai.apikey"
    private static let sessionAccount = "com.ekinciler.session.token"

    static func saveAPIKey(_ key: String) -> Bool {
        save(key, account: apiKeyAccount)
    }

    static func loadAPIKey() -> String? {
        load(account: apiKeyAccount)
    }

    static func deleteAPIKey() {
        delete(account: apiKeyAccount)
    }

    static func saveSessionToken(_ token: String) -> Bool {
        save(token, account: sessionAccount)
    }

    static func loadSessionToken() -> String? {
        load(account: sessionAccount)
    }

    static func deleteSessionToken() {
        delete(account: sessionAccount)
    }

    private static func save(_ value: String, account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private static func load(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    private static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

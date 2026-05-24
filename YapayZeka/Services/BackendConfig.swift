import Foundation

enum BackendConfig {
    private static let urlKey = "ekinciler.backend.url"
    private static let useBackendKey = "ekinciler.backend.enabled"
    private static let didMigrateToCloudKey = "ekinciler.migrated.cloud"

    /// Simülatör: localhost. Gerçek iPhone: Render bulutu (127.0.0.1 telefonda çalışmaz).
    static var developerDefaultURL: String {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:3000"
        #else
        return AppConfig.productionAPIBaseURL
        #endif
    }

    static var baseURL: String {
        get {
            if AppConfig.isAppStoreBuild {
                return AppConfig.productionAPIBaseURL
            }
            return storedOrDefaultURL
        }
        set {
            guard !AppConfig.isAppStoreBuild else { return }
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: urlKey)
        }
    }

    static var storedOrDefaultURL: String {
        UserDefaults.standard.string(forKey: urlKey) ?? developerDefaultURL
    }

    /// App Store sürümünde her zaman bulut backend
    static var useBackend: Bool {
        get {
            if AppConfig.isAppStoreBuild { return true }
            return UserDefaults.standard.object(forKey: useBackendKey) as? Bool ?? true
        }
        set {
            if !AppConfig.isAppStoreBuild {
                UserDefaults.standard.set(newValue, forKey: useBackendKey)
            }
        }
    }

    static var isConfigured: Bool {
        guard let url = URL(string: baseURL), url.scheme != nil else { return false }
        if AppConfig.isAppStoreBuild {
            return url.scheme == "https"
        }
        return true
    }

    /// App Store + gerçek cihazda localhost kaydını buluta çevir
    static func migrateToCloudIfNeeded() {
        UserDefaults.standard.set(true, forKey: useBackendKey)

        if AppConfig.isAppStoreBuild {
            guard !UserDefaults.standard.bool(forKey: didMigrateToCloudKey) else { return }
            UserDefaults.standard.removeObject(forKey: urlKey)
            UserDefaults.standard.set(true, forKey: didMigrateToCloudKey)
            return
        }

        #if !targetEnvironment(simulator)
        let stored = UserDefaults.standard.string(forKey: urlKey) ?? ""
        if stored.isEmpty || stored.contains("127.0.0.1") || stored.contains("localhost") {
            UserDefaults.standard.set(AppConfig.productionAPIBaseURL, forKey: urlKey)
        }
        #endif
    }

    /// DEBUG: localhost yanıt vermezse otomatik buluta geç
    static func preferCloudIfLocalhostUnreachable() async {
        #if DEBUG
        guard !AppConfig.isAppStoreBuild else { return }
        let url = baseURL
        guard url.contains("127.0.0.1") || url.contains("localhost") else { return }
        do {
            _ = try await APIClient.shared.health()
        } catch {
            self.baseURL = AppConfig.productionAPIBaseURL
        }
        #endif
    }
}

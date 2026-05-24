import Foundation

enum BackendConfig {
    private static let urlKey = "ekinciler.backend.url"
    private static let useBackendKey = "ekinciler.backend.enabled"
    private static let didMigrateToCloudKey = "ekinciler.migrated.cloud"

    /// Geliştirme ortamı varsayılanı
    static var developerDefaultURL: String {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:3000"
        #else
        return "http://127.0.0.1:3000"
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

    /// İlk App Store açılışında localhost kaydını temizle
    static func migrateToCloudIfNeeded() {
        guard AppConfig.isAppStoreBuild else { return }
        guard !UserDefaults.standard.bool(forKey: didMigrateToCloudKey) else { return }
        UserDefaults.standard.removeObject(forKey: urlKey)
        UserDefaults.standard.set(true, forKey: useBackendKey)
        UserDefaults.standard.set(true, forKey: didMigrateToCloudKey)
    }
}

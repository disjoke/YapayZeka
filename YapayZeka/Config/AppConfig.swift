import Foundation

/// App Store yayını için merkezi yapılandırma.
/// Release derlemesinde tüm kullanıcılar bulut API'ye bağlanır — Terminal/npm gerekmez.
enum AppConfig {
    /// Canlı API adresiniz (Render/Railway/Fly deploy sonrası güncelleyin).
    /// Örnek: `https://ekinciler-api.onrender.com`
    static let productionAPIBaseURL = "https://ekinciler-api.onrender.com"

    static let appName = "Ekinciler AI"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let supportEmail = "destek@ekinciler.com"

    /// App Store (Release) derlemesi mi?
    static var isAppStoreBuild: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }

    /// Kullanıcıya gösterilecek API açıklaması
    static var apiDisplayName: String {
        isAppStoreBuild ? "Ekinciler Bulut" : "Geliştirici Sunucusu"
    }

    static var cloudUnavailableMessage: String {
        "Bulut sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin."
    }

    static var metaRequiresCloudMessage: String {
        "Facebook ve Instagram bağlantısı için internet ve Ekinciler bulut sunucusu gerekir."
    }
}

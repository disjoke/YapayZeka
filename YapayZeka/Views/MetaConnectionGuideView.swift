import SwiftUI

struct MetaConfigInfo: Decodable {
    let configured: Bool
    let appIdSet: Bool
    let secretSet: Bool
    let redirectUri: String
    let appRedirect: String
    let steps: [String]
}

struct MetaConnectionGuideView: View {
    @EnvironmentObject var session: SessionManager
    @ObservedObject var oauth = MetaOAuthService.shared
    @State private var config: MetaConfigInfo?
    @State private var isLoadingConfig = false

    private var productionRedirectHint: String {
        "\(AppConfig.productionAPIBaseURL)/social/oauth/meta/callback"
    }

    var body: some View {
        AICard(title: "Facebook & Instagram — Gerçek Hesap", icon: "link.circle.fill") {
            statusRow

            if config?.configured != true {
                notConfiguredSection
            } else {
                readySection
            }

            stepsSection

            Link("Meta Developer Console Aç", destination: URL(string: "https://developers.facebook.com/apps/")!)
                .font(.subheadline.bold())
        }
        .task { await loadConfig() }
    }

    @ViewBuilder
    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(config?.configured == true ? AppTheme.success : AppTheme.warning)
                .frame(width: 10, height: 10)
            Text(config?.configured == true ? "Meta API yapılandırıldı" : "Meta API henüz yapılandırılmadı")
                .font(.subheadline.bold())
        }
        if !session.backendOnline {
            AIErrorBanner(message: AppConfig.isAppStoreBuild
                ? AppConfig.cloudUnavailableMessage
                : "Backend kapalı. Geliştirme: cd server && npm start")
        }
    }

    @ViewBuilder
    private var notConfiguredSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if AppConfig.isAppStoreBuild {
                Text("Facebook bağlantısı Ekinciler bulut sunucusu üzerinden çalışır. Sunucu yapılandırması tamamlandığında bu ekranda «Facebook ile Giriş Yap» görünür.")
                    .font(.caption)
            } else {
                Text("Geliştirme: `server/.env` dosyasına ekleyin:")
                    .font(.caption.bold())
                Text("""
                META_APP_ID=facebook_uygulama_id
                META_APP_SECRET=uygulama_gizli_anahtar
                META_REDIRECT_URI=\(productionRedirectHint)
                """)
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private var readySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("OAuth yönlendirme adresi (Meta paneline aynen ekleyin):")
                .font(.caption.bold())
            Text(config?.redirectUri ?? productionRedirectHint)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
        }
        AIButton("Facebook ile Giriş Yap", icon: "f.circle.fill", isLoading: oauth.isAuthenticating) {
            Task { await oauth.startOAuth() }
        }
    }

    @ViewBuilder
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kurulum adımları").font(.headline)
            step(1, "developers.facebook.com → Uygulama oluştur (Tür: İşletme)")
            step(2, "Ürün ekle: Facebook Login + Instagram Graph API")
            step(3, "Facebook Login → Ayarlar → Geçerli OAuth Redirect URI:")
            Text(config?.redirectUri ?? productionRedirectHint)
                .font(.caption2)
                .foregroundStyle(AppTheme.primary)
                .padding(.leading, 28)
            step(4, "Uygulama modunu Geliştirme yapın; test kullanıcısı olarak kendi Facebook hesabınızı ekleyin")
            step(5, "Instagram hesabınız İşletme/Creator olmalı ve bir Facebook Sayfasına bağlı olmalı")
            step(6, AppConfig.isAppStoreBuild
                 ? "Uygulamada Instagram veya Facebook → Bağlan"
                 : "Backend'i yeniden başlatın → uygulamada Bağlan")
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(AppTheme.primary)
                .clipShape(Circle())
            Text(text).font(.caption)
        }
    }

    private func loadConfig() async {
        guard BackendConfig.useBackend, session.backendOnline else { return }
        isLoadingConfig = true
        defer { isLoadingConfig = false }
        do {
            config = try await APIClient.shared.metaOAuthConfig()
        } catch {
            config = nil
        }
    }
}

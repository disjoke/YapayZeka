import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @EnvironmentObject var session: SessionManager
    @State private var showDeleteConfirm = false
    @State private var backendURL = BackendConfig.baseURL
    @State private var useBackend = BackendConfig.useBackend
    @State private var regUsername = ""
    @State private var regPassword = ""
    @State private var regEmail = ""

    var body: some View {
        List {
            cloudStatusSection

            if !AppConfig.isAppStoreBuild {
                developerServerSection
            }

            if !AppConfig.isAppStoreBuild {
                openAISection
            }

            Section("Hesap") {
                if AppConfig.isAppStoreBuild {
                    Text("App Store sürümünde tüm AI işlemleri Ekinciler bulut sunucusu üzerinden çalışır.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Kullanıcı", value: session.currentUsername)
                Section {
                    TextField("Kullanıcı adı", text: $regUsername).textInputAutocapitalization(.never)
                    SecureField("Parola", text: $regPassword)
                    TextField("E-posta", text: $regEmail).keyboardType(.emailAddress)
                    AIButton("Kayıt Ol", icon: "person.badge.plus", isLoading: session.isLoading) {
                        Task { await session.register(username: regUsername, password: regPassword, email: regEmail) }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                Button(role: .destructive) { session.logout() } label: {
                    Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Ayarlar")
        .alert("API anahtarı silinsin mi?", isPresented: $showDeleteConfirm) {
            Button("Sil", role: .destructive) { settings.removeAPIKey() }
            Button("İptal", role: .cancel) {}
        }
        .onAppear {
            settings.refreshAPIKeyStatus()
            backendURL = BackendConfig.baseURL
            useBackend = BackendConfig.useBackend
            Task { await session.checkBackend() }
        }
    }

    private var cloudStatusSection: some View {
        Section("Ekinciler Bulut") {
            HStack(spacing: 8) {
                Circle().fill(session.backendOnline ? AppTheme.success : AppTheme.warning).frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.backendOnline ? "Bulut sunucu aktif" : "Sunucuya bağlanılamıyor")
                        .font(.headline)
                    Text(AppConfig.isAppStoreBuild ? AppConfig.productionAPIBaseURL : BackendConfig.baseURL)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if AppConfig.isAppStoreBuild {
                Text("App Store kullanıcıları için ek kurulum gerekmez. İnternet bağlantısı yeterlidir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            AIButton("Bağlantıyı Yenile", icon: "arrow.clockwise", style: .secondary) {
                Task { await session.checkBackend() }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    private var developerServerSection: some View {
        Section("Geliştirici Sunucusu (sadece DEBUG)") {
            Toggle("Yerel backend", isOn: $useBackend)
                .onChange(of: useBackend) { _, v in BackendConfig.useBackend = v }
            TextField("Sunucu URL", text: $backendURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
            AIButton("Kaydet", icon: "server.rack") {
                BackendConfig.baseURL = backendURL
                Task { await session.checkBackend() }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            Text("Geliştirme: Terminal → cd server && npm start")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var openAISection: some View {
        Section("OpenAI (geliştirici yedek)") {
            SecureField("sk-...", text: $settings.apiKeyInput)
            AIButton("Kaydet", icon: "key.fill") { settings.saveAPIKey() }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            if settings.hasValidAPIKey {
                Button(role: .destructive) { showDeleteConfirm = true } label: {
                    Label("Anahtarı Sil", systemImage: "trash")
                }
            }
        }
    }
}

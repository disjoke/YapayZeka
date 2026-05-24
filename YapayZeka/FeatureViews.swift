import SwiftUI
import AVFoundation

// MARK: - 1. Giriş Sistemi

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @EnvironmentObject var session: SessionManager

    var body: some View {
        ZStack {
            AppTheme.headerGradient.ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                    Text("Ekinciler AI")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Yapay zeka destekli sosyal medya platformu")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.top, 60)

                VStack(spacing: 16) {
                    TextField(AppConfig.isAppStoreBuild ? "Kullanıcı adı" : "Kullanıcı adı (admin)", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField(AppConfig.isAppStoreBuild ? "Parola" : "Parola (1234)", text: $password)
                        .textFieldStyle(.roundedBorder)
                    if let error = session.errorMessage {
                        AIErrorBanner(message: error)
                    }
                    AIButton("Giriş Yap", icon: "lock.open.fill", isLoading: session.isLoading) {
                        Task { await session.login(username: username, password: password) }
                    }
                    HStack {
                        Circle().fill(session.backendOnline ? AppTheme.success : AppTheme.warning).frame(width: 8, height: 8)
                        Text(session.backendOnline
                             ? (AppConfig.isAppStoreBuild ? "Ekinciler Bulut bağlı" : "Backend bağlı")
                             : (AppConfig.isAppStoreBuild ? AppConfig.cloudUnavailableMessage : "Yerel mod (admin/1234)"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    #if DEBUG
                    Text("Geliştirme demo: admin / 1234")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #endif
                }
                .padding(24)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}

struct SessionInfoView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                FeatureHeader(title: "Giriş Sistemi", subtitle: "Kimlik doğrulama ve güvenli oturum", icon: "lock.shield.fill")
                VStack(spacing: 16) {
                    AICard(title: "Oturum Durumu", icon: "person.badge.key.fill") {
                        LabeledContent("Kullanıcı", value: session.currentUsername)
                        LabeledContent("Durum", value: session.isLoggedIn ? "Aktif" : "Kapalı")
                        LabeledContent("Depolama", value: "Keychain (güvenli token)")
                    }
                    AICard(title: "Özellikler", icon: "checkmark.shield") {
                        bullet("JWT backend kimlik doğrulama")
                        bullet("Keychain güvenli token saklama")
                        bullet("Otomatik veri senkronizasyonu")
                        bullet(session.backendOnline ? "Backend aktif" : "Yerel demo modu")
                    }
                    AIButton("Çıkış Yap", icon: "rectangle.portrait.and.arrow.right", style: .destructive) {
                        session.logout()
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.success)
            Text(text).font(.subheadline)
        }
    }
}

// MARK: - 2. Sosyal Medya

struct SocialConnectionsView: View {
    @ObservedObject var manager = SocialMediaManager.shared
    @ObservedObject var oauth = MetaOAuthService.shared
    @EnvironmentObject var session: SessionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                FeatureHeader(title: "Sosyal Medya", subtitle: "Gerçek hesap bağlantıları", icon: "link.circle.fill")
                VStack(spacing: 16) {
                    simpleConnectCard

                    if let msg = manager.lastMessage ?? oauth.lastMessage {
                        AICard(title: "Durum", icon: "info.circle") {
                            Text(msg).font(.subheadline)
                        }
                    }

                    ForEach(AIPlatform.allCases) { platform in
                        platformCard(platform)
                    }

                    otherPlatformsNote

                    DisclosureGroup("Teknik kurulum (geliştirici — bir kez)") {
                        MetaConnectionGuideView()
                            .environmentObject(session)
                    }
                    .font(.subheadline.bold())
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await manager.syncFromBackend() }
        .refreshable { await manager.syncFromBackend() }
    }

  private var simpleConnectCard: some View {
        AICard(title: "Hesabınızı bağlayın", icon: "person.crop.circle.badge.checkmark") {
            VStack(alignment: .leading, spacing: 12) {
                Text("E-posta ve şifrenizi bu uygulamaya yazmayın. Güvenlik için Facebook'un resmi giriş sayfası açılır; orada kendi hesabınızla giriş yaparsınız.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Label("1. Aşağıdaki düğmeye basın", systemImage: "1.circle.fill")
                    Label("2. Facebook sayfasında e-posta + şifre girin", systemImage: "2.circle.fill")
                    Label("3. İzinleri onaylayın → Instagram da bağlanır", systemImage: "3.circle.fill")
                }
                .font(.caption)

                AIButton("Facebook / Instagram ile Bağlan", icon: "f.circle.fill", isLoading: oauth.isAuthenticating) {
                    Task { await connectWithFacebook() }
                }

                if !session.backendOnline {
                    Text(AppConfig.isAppStoreBuild
                         ? "Bulut sunucuya bağlanılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin."
                         : "Geliştirme: Terminal'de cd server && npm start")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.warning)
                }
            }
        }
    }

    private func connectWithFacebook() async {
        if !session.backendOnline {
            await session.checkBackend()
        }
        if !session.backendOnline {
            manager.lastMessage = AppConfig.isAppStoreBuild
                ? "Bulut sunucuya ulaşılamıyor. İnternetinizi kontrol edin veya daha sonra tekrar deneyin."
                : "Sunucu kapalı. Terminal: cd server && npm start"
            return
        }
        await MetaOAuthService.shared.startOAuth()
        await manager.syncFromBackend()
    }

    @ViewBuilder
    private func platformCard(_ platform: AIPlatform) -> some View {
        let conn = manager.connections.first { $0.platform == platform.rawValue }
        let isMeta = platform == .instagram || platform == .facebook

        AICard {
            HStack(spacing: 12) {
                Image(systemName: platform.icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(platform.rawValue).font(.headline)
                    if conn?.isConnected == true {
                        Text(conn?.username ?? "Bağlı")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.success)
                        if let date = conn?.connectedAt {
                            Text(date, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(isMeta ? "Meta OAuth ile bağlanır" : "Yakında — ayrı API gerekir")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if conn?.isConnected == true {
                    Button("Kes") { manager.disconnect(platform: platform) }
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.danger)
                } else if isMeta {
                    Button("Bağlan") {
                        Task { await connectWithFacebook() }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var otherPlatformsNote: some View {
        AICard(title: "Diğer platformlar", icon: "clock.badge.questionmark") {
            Text("TikTok, LinkedIn ve YouTube için her platformun kendi geliştirici API anahtarı gerekir (Meta ile bağlanmaz). Bu entegrasyonlar sonraki sürümde eklenecek.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 3. AI Reklam

struct AdManagerView: View {
    @ObservedObject var manager = AIAdManager.shared
    @State private var product = ""
    @State private var platform = "Instagram"
    @State private var tone = "Profesyonel ve samimi"

    var body: some View {
        aiFeatureScroll(
            header: ("AI Reklam Sistemi", "Reklam metni ve kampanya üretimi", "megaphone.fill")
        ) {
            TextField("Ürün veya hizmet açıklaması", text: $product, axis: .vertical)
                .lineLimit(3...6).textFieldStyle(.roundedBorder)
            Picker("Platform", selection: $platform) {
                ForEach(AIPlatform.allCases) { Text($0.rawValue).tag($0.rawValue) }
            }
            TextField("Ton", text: $tone).textFieldStyle(.roundedBorder)
            AIButton("AI ile Reklam Oluştur", isLoading: manager.isLoading) {
                Task { await manager.generateAdText(product: product, platform: platform, tone: tone) }
            }
            if let err = manager.lastError { AIErrorBanner(message: err) }
            AIResultBox(text: manager.lastResult, isLoading: manager.isLoading)
        }
    }
}

// MARK: - 4. AI Görsel

struct ImageGeneratorView: View {
    @State private var prompt = ""
    @State private var resultURL: URL?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        aiFeatureScroll(header: ("AI Görsel Üretimi", "DALL-E ile reklam görseli", "photo.artframe")) {
            TextField("Görsel prompt (ör: modern cam balkon reklamı, mavi tonlar)", text: $prompt, axis: .vertical)
                .lineLimit(2...5).textFieldStyle(.roundedBorder)
            AIButton("Görsel Üret", icon: "wand.and.stars", isLoading: isLoading) {
                Task {
                    isLoading = true
                    error = nil
                    defer { isLoading = false }
                    let brand = BrandManager.shared.profile.companyName
                    let fullPrompt = "\(prompt). Marka: \(brand). Profesyonel reklam görseli, yüksek kalite."
                    do {
                        if BackendConfig.useBackend {
                            resultURL = try await APIClient.shared.aiImage(prompt: fullPrompt)
                        } else {
                            resultURL = try await AIService.shared.generateImage(prompt: fullPrompt)
                        }
                    } catch let firstError {
                        do { resultURL = try await AIService.shared.generateImage(prompt: fullPrompt) }
                        catch {
                            self.error = firstError.localizedDescription
                            resultURL = nil
                        }
                    }
                }
            }
            if let error { AIErrorBanner(message: error) }
            if isLoading {
                ProgressView("Görsel oluşturuluyor…").frame(maxWidth: .infinity)
            }
            if let url = resultURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        AIErrorBanner(message: "Görsel yüklenemedi")
                    default:
                        ProgressView()
                    }
                }
            }
        }
    }
}

// MARK: - 5. AI Video

struct VideoGeneratorView: View {
    @ObservedObject var video = VideoService.shared
    @ObservedObject var settings = AppSettings.shared
    @EnvironmentObject var session: SessionManager
    @State private var topic = ""
    @State private var duration = "30 saniye"
    @State private var style = "Enerjik Reels"

    var body: some View {
        aiFeatureScroll(header: ("AI Video Sistemi", "Senaryo + video", "video.fill")) {
            if !session.backendOnline && !settings.hasValidAPIKey {
                AIErrorBanner(message: AppConfig.isAppStoreBuild
                    ? AppConfig.cloudUnavailableMessage
                    : "Buluta bağlanılamıyor. Ayarlar → Bağlantıyı Yenile veya çıkış yapıp admin/1234 ile tekrar giriş yapın.")
            } else if session.backendOnline {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.success)
                    Text("Ekinciler Bulut bağlı — video ve senaryo sunucudan").font(.caption)
                }
            } else if settings.hasValidAPIKey && !AppConfig.isAppStoreBuild {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.success)
                    Text("Yedek: senaryo cihazdaki OpenAI ile").font(.caption)
                }
            }

            TextField("Video konusu (zorunlu)", text: $topic).textFieldStyle(.roundedBorder)
            TextField("Süre", text: $duration).textFieldStyle(.roundedBorder)
            TextField("Stil", text: $style).textFieldStyle(.roundedBorder)
            AIButton("Senaryo Oluştur", isLoading: video.isLoading) {
                Task { await video.generateScript(topic: topic, duration: duration, style: style) }
            }
            AIButton("Video Üret", icon: "film", style: .secondary, isLoading: video.isLoading) {
                Task { await video.generateVideo(prompt: video.script.isEmpty ? topic : video.script) }
            }
            if let error = video.error { AIErrorBanner(message: error) }
            if !video.statusMessage.isEmpty {
                Text(video.statusMessage)
                    .font(.caption)
                    .foregroundStyle(video.isSimulatedVideo ? AppTheme.warning : AppTheme.success)
            }
            if video.isSimulatedVideo {
                Text("MP4 için: replicate.com → API token → Render → REPLICATE_API_TOKEN")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            AIResultBox(text: video.script, isLoading: video.isLoading)

            VideoWatchSection(video: video)
        }
        .task {
            await session.checkBackend()
            await video.syncHistoryFromServer()
        }
    }
}

// MARK: - 6. Otomatik Paylaşım

struct SchedulingView: View {
    @ObservedObject var manager = SchedulingManager.shared
    @State private var content = ""
    @State private var platform = "Instagram"
    @State private var date = Date().addingTimeInterval(3600)
    @State private var isStory = false
    @State private var aiContent = ""
    @State private var isLoadingAI = false

    var body: some View {
        aiFeatureScroll(header: ("Otomatik Paylaşım", "Zamanlanmış post ve hikâye", "clock.arrow.circlepath")) {
            TextField("Paylaşım metni", text: $content, axis: .vertical).lineLimit(2...6).textFieldStyle(.roundedBorder)
            Picker("Platform", selection: $platform) {
                ForEach(AIPlatform.allCases) { Text($0.rawValue).tag($0.rawValue) }
            }
            DatePicker("Yayın zamanı", selection: $date)
            Toggle("Hikâye olarak paylaş", isOn: $isStory)
            AIButton("AI ile İçerik Öner", isLoading: isLoadingAI) {
                Task {
                    isLoadingAI = true
                    defer { isLoadingAI = false }
                    do {
                        aiContent = try await AIService.shared.complete(
                            system: "Kısa sosyal medya paylaşım metinleri yaz.",
                            user: "\(platform) için \(BrandManager.shared.profile.companyName) markasına uygun paylaşım metni üret."
                        )
                        content = aiContent
                    } catch let err {
                        aiContent = err.localizedDescription
                    }
                }
            }
            AIButton("Zamanla", icon: "calendar.badge.plus") {
                Task {
                    await manager.schedule(platform: platform, content: content, date: date, isStory: isStory)
                    content = ""
                }
            }
            AIButton("Şimdi Yayınla", icon: "paperplane.fill", style: .secondary) {
                Task { await SocialMediaManager.shared.publish(platform: platform, content: content, imageUrl: nil) }
            }
            if !manager.posts.isEmpty {
                AICard(title: "Planlanan Paylaşımlar", icon: "list.bullet") {
                    ForEach(manager.posts) { post in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(post.platform).font(.caption.bold())
                                Spacer()
                                Text(post.scheduledAt, style: .date).font(.caption2)
                            }
                            Text(post.content).font(.subheadline).lineLimit(2)
                            Text(post.isStory ? "Hikâye" : "Post").font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        if post.id != manager.posts.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: - 7. Reklam Yönetimi

struct AdManagementView: View {
    @ObservedObject var manager = AIAdManager.shared
    @State private var budget: Double = 5000
    @State private var audience = "25-45 yaş, ev sahipleri, İstanbul"
    @State private var goal = "Marka bilinirliği ve lead"

    var body: some View {
        aiFeatureScroll(header: ("Reklam Yönetimi", "Hedefleme, bütçe, performans", "chart.bar.doc.horizontal")) {
            VStack(alignment: .leading) {
                Text("Bütçe: \(Int(budget)) TL")
                Slider(value: $budget, in: 500...100_000, step: 500)
            }
            TextField("Hedef kitle", text: $audience).textFieldStyle(.roundedBorder)
            TextField("Kampanya hedefi", text: $goal).textFieldStyle(.roundedBorder)
            AIButton("AI Kampanya Planı Oluştur", isLoading: manager.isLoading) {
                Task { await manager.planCampaign(budget: budget, audience: audience, goal: goal) }
            }
            if let err = manager.lastError { AIErrorBanner(message: err) }
            AIResultBox(text: manager.lastResult, isLoading: manager.isLoading)
        }
    }
}

// MARK: - 8. WhatsApp AI

struct WhatsAppAssistantView: View {
    @State private var customerMessage = ""
    @State private var phoneNumber = ""
    @State private var reply = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var sentOK = false

    var body: some View {
        aiFeatureScroll(header: ("WhatsApp AI Asistanı", "Otomatik yanıt + gönderim", "message.fill")) {
            TextField("Müşteri telefonu (905xxxxxxxxx)", text: $phoneNumber)
                .textFieldStyle(.roundedBorder).keyboardType(.phonePad)
            TextField("Müşteri mesajı", text: $customerMessage, axis: .vertical)
                .lineLimit(3...8).textFieldStyle(.roundedBorder)
            AIButton("AI Yanıt Üret", isLoading: isLoading) {
                Task {
                    isLoading = true
                    error = nil
                    sentOK = false
                    defer { isLoading = false }
                    let brand = BrandManager.shared.profile
                    let context = "\(brand.companyName), Tel: \(brand.phone), \(brand.tagline)"
                    do {
                        if BackendConfig.useBackend {
                            reply = try await APIClient.shared.aiWhatsAppReply(message: customerMessage, context: context)
                        } else {
                            reply = try await AIService.shared.generateWhatsAppReply(customerMessage: customerMessage, businessContext: context)
                        }
                    } catch let err {
                        self.error = err.localizedDescription
                    }
                }
            }
            AIButton("WhatsApp'tan Gönder", icon: "paperplane.fill", style: .secondary, isLoading: isLoading) {
                Task {
                    isLoading = true
                    error = nil
                    defer { isLoading = false }
                    let brand = BrandManager.shared.profile
                    let context = "\(brand.companyName), \(brand.phone)"
                    do {
                        let result = try await APIClient.shared.sendWhatsApp(
                            to: phoneNumber, message: reply,
                            customerMessage: customerMessage, context: context
                        )
                        reply = result.text ?? reply
                        sentOK = true
                    } catch let err {
                        self.error = err.localizedDescription
                    }
                }
            }
            if sentOK { Text("Mesaj gönderildi!").font(.caption).foregroundStyle(AppTheme.success) }
            if let error { AIErrorBanner(message: error) }
            AIResultBox(text: reply, isLoading: isLoading)
        }
    }
}

// MARK: - 9. Müşteri Kayıt

struct CustomerManagementView: View {
    @ObservedObject var manager = CustomerManager.shared
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""
    @State private var showForm = false

    var body: some View {
        aiFeatureScroll(header: ("Müşteri Kayıt", "Müşteri verisi yönetimi", "person.crop.circle.badge.plus")) {
            AIButton("Yeni Müşteri Ekle", icon: "plus") { showForm.toggle() }
            if showForm {
                AICard(title: "Yeni Kayıt", icon: "person.fill") {
                    TextField("Ad Soyad", text: $name).textFieldStyle(.roundedBorder)
                    TextField("Telefon", text: $phone).textFieldStyle(.roundedBorder).keyboardType(.phonePad)
                    TextField("E-posta", text: $email).textFieldStyle(.roundedBorder).keyboardType(.emailAddress)
                    TextField("Notlar", text: $notes, axis: .vertical).lineLimit(2...4).textFieldStyle(.roundedBorder)
                    AIButton("Kaydet", icon: "checkmark") {
                        Task {
                            await manager.add(name: name, phone: phone, email: email, notes: notes)
                            name = ""; phone = ""; email = ""; notes = ""
                            showForm = false
                        }
                    }
                }
            }
            if manager.customers.isEmpty {
                Text("Henüz müşteri kaydı yok.").foregroundStyle(.secondary)
            } else {
                ForEach(manager.customers) { customer in
                    AICard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(customer.name).font(.headline)
                            Label(customer.phone, systemImage: "phone.fill")
                            if !customer.email.isEmpty {
                                Label(customer.email, systemImage: "envelope.fill")
                            }
                            if !customer.notes.isEmpty {
                                Text(customer.notes).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 10. İstatistik

struct AnalyticsView: View {
    @ObservedObject var manager = AnalyticsManager.shared

    var body: some View {
        aiFeatureScroll(header: ("İstatistik Paneli", "Metrikler ve AI analizi", "chart.xyaxis.line")) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                metricCard("Gösterim", value: formatNumber(manager.snapshot.impressions))
                metricCard("Tıklama", value: formatNumber(manager.snapshot.clicks))
                metricCard("Etkileşim", value: String(format: "%.1f%%", manager.snapshot.engagementRate))
                metricCard("Dönüşüm", value: "\(manager.snapshot.conversions)")
            }
            AIButton("AI Performans Analizi", isLoading: manager.isLoadingInsight) {
                Task { await manager.refreshInsight() }
            }
            AIResultBox(text: manager.aiInsight, isLoading: manager.isLoadingInsight)
        }
    }

    private func metricCard(_ title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1000 { return String(format: "%.1fK", Double(n) / 1000) }
        return "\(n)"
    }
}

// MARK: - 11. İçerik Takvimi

struct ContentCalendarView: View {
    @State private var weeks = 2
    @State private var calendarText = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        aiFeatureScroll(header: ("İçerik Takvimi", "AI ile haftalık plan", "calendar.badge.clock")) {
            Stepper("Hafta sayısı: \(weeks)", value: $weeks, in: 1...8)
            AIButton("AI Takvim Oluştur", isLoading: isLoading) {
                Task {
                    isLoading = true
                    error = nil
                    defer { isLoading = false }
                    let brand = BrandManager.shared.profile.companyName
                    do {
                        if BackendConfig.useBackend {
                            calendarText = try await APIClient.shared.aiContentCalendar(brand: brand, weeks: weeks)
                        } else {
                            calendarText = try await AIService.shared.generateContentCalendar(brand: brand, weeks: weeks)
                        }
                    } catch {
                        do { calendarText = try await AIService.shared.generateContentCalendar(brand: brand, weeks: weeks) }
                        catch let err { self.error = err.localizedDescription }
                    }
                }
            }
            if let error { AIErrorBanner(message: error) }
            AIResultBox(text: calendarText, isLoading: isLoading)
        }
    }
}

// MARK: - 12. Sesli AI Reklam

struct VoiceAdView: View {
    @State private var product = ""
    @State private var voiceStyle = "Güven veren, profesyonel erkek sesi"
    @State private var script = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        aiFeatureScroll(header: ("Sesli AI Reklam", "Metin + seslendirme", "waveform.circle.fill")) {
            TextField("Ürün/Hizmet", text: $product).textFieldStyle(.roundedBorder)
            TextField("Ses tonu", text: $voiceStyle).textFieldStyle(.roundedBorder)
            AIButton("Sesli Reklam Metni Oluştur", isLoading: isLoading) {
                Task {
                    isLoading = true
                    error = nil
                    defer { isLoading = false }
                    do {
                        if BackendConfig.useBackend {
                            script = try await APIClient.shared.aiVoiceAd(product: product, voiceStyle: voiceStyle)
                        } else {
                            script = try await AIService.shared.generateVoiceAdScript(product: product, voiceStyle: voiceStyle)
                        }
                    } catch {
                        do { script = try await AIService.shared.generateVoiceAdScript(product: product, voiceStyle: voiceStyle) }
                        catch let err { self.error = err.localizedDescription }
                    }
                }
            }
            if !script.isEmpty {
                AIButton(isSpeaking ? "Durdur" : "Seslendir (TTS)", icon: "speaker.wave.3.fill", style: .secondary) {
                    if isSpeaking {
                        synthesizer.stopSpeaking(at: .immediate)
                        isSpeaking = false
                    } else {
                        let utterance = AVSpeechUtterance(string: script)
                        utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
                        utterance.rate = 0.48
                        synthesizer.speak(utterance)
                        isSpeaking = true
                    }
                }
            }
            if let error { AIErrorBanner(message: error) }
            AIResultBox(text: script, isLoading: isLoading)
        }
    }
}

// MARK: - 13. Platformlar

struct CrossPlatformInfoView: View {
    var body: some View {
        aiFeatureScroll(header: ("Mobil & Masaüstü", "iOS ve gelecek platformlar", "iphone.and.ipad")) {
            platformRow("iOS", status: "Aktif — bu uygulama", icon: "iphone")
            platformRow("macOS", status: "Planlanıyor — Q3 2026", icon: "desktopcomputer")
            platformRow("Android", status: "Planlanıyor — Q4 2026", icon: "smartphone")
            platformRow("Web Panel", status: "Planlanıyor — Q2 2026", icon: "globe")
            AICard(title: "Senkronizasyon", icon: "arrow.triangle.2.circlepath") {
                Text("Tüm platformlar aynı AI backend ve marka verisi ile senkronize çalışacak.")
                    .font(.subheadline)
            }
        }
    }

    private func platformRow(_ name: String, status: String, icon: String) -> some View {
        AICard {
            HStack {
                Image(systemName: icon).foregroundStyle(AppTheme.primary)
                VStack(alignment: .leading) {
                    Text(name).font(.headline)
                    Text(status).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - 14. Marka

struct BrandInfoView: View {
    @ObservedObject var manager = BrandManager.shared

    var body: some View {
        aiFeatureScroll(header: ("Marka Sistemi", "Logo ve iletişim bilgileri", "building.2.fill")) {
            AICard(title: "Marka Profili", icon: "paintbrush.fill") {
                TextField("Firma adı", text: brandBinding(\.companyName)).textFieldStyle(.roundedBorder)
                TextField("Slogan", text: brandBinding(\.tagline)).textFieldStyle(.roundedBorder)
                TextField("Telefon", text: brandBinding(\.phone)).textFieldStyle(.roundedBorder).keyboardType(.phonePad)
                TextField("E-posta", text: brandBinding(\.email)).textFieldStyle(.roundedBorder).keyboardType(.emailAddress)
                TextField("Web sitesi", text: brandBinding(\.website)).textFieldStyle(.roundedBorder)
                TextField("Adres", text: brandBinding(\.address), axis: .vertical).lineLimit(2...4).textFieldStyle(.roundedBorder)
                AIButton("Kaydet", icon: "square.and.arrow.down") {
                    Task { await manager.save() }
                }
            }
            HStack {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.primary)
                VStack(alignment: .leading) {
                    Text(manager.profile.companyName).font(.title3.bold())
                    Text(manager.profile.tagline).font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func brandBinding(_ keyPath: WritableKeyPath<BrandProfile, String>) -> Binding<String> {
        Binding(
            get: { manager.profile[keyPath: keyPath] },
            set: { manager.profile[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - 15. Gelişmiş AI

struct AdvancedFeaturesView: View {
    @State private var industry = ""
    @State private var competitors = ""
    @State private var result = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        aiFeatureScroll(header: ("Gelişmiş AI", "Rakip analizi ve viral öneriler", "brain.head.profile")) {
            TextField("Sektörünüz", text: $industry).textFieldStyle(.roundedBorder)
            TextField("Rakip markalar (virgülle)", text: $competitors, axis: .vertical)
                .lineLimit(2...4).textFieldStyle(.roundedBorder)
            AIButton("Rakip & Viral Analizi", isLoading: isLoading) {
                Task {
                    isLoading = true
                    error = nil
                    defer { isLoading = false }
                    do {
                        if BackendConfig.useBackend {
                            result = try await APIClient.shared.aiCompetitorAnalysis(industry: industry, competitors: competitors)
                        } else {
                            result = try await AIService.shared.analyzeCompetitors(industry: industry, competitors: competitors)
                        }
                    } catch {
                        do { result = try await AIService.shared.analyzeCompetitors(industry: industry, competitors: competitors) }
                        catch let err { self.error = err.localizedDescription }
                    }
                }
            }
            AIButton("Otomatik Yorum Yanıtı Öner", icon: "bubble.left.and.bubble.right", style: .secondary, isLoading: isLoading) {
                Task {
                    isLoading = true
                    defer { isLoading = false }
                    do {
                        result = try await AIService.shared.complete(
                            system: "Sosyal medya yorumlarına kısa, profesyonel Türkçe yanıtlar öner.",
                            user: "\(BrandManager.shared.profile.companyName) için olumlu bir yoruma 3 farklı yanıt öner."
                        )
                    } catch let err {
                        self.error = err.localizedDescription
                    }
                }
            }
            if let error { AIErrorBanner(message: error) }
            AIResultBox(text: result, isLoading: isLoading)
        }
    }
}

// MARK: - 16. Premium Modüller (FutureFeaturesView → Views/FutureFeaturesModule.swift)

// MARK: - Helpers

@ViewBuilder
private func aiFeatureScroll(
    header: (String, String, String),
    @ViewBuilder content: () -> some View
) -> some View {
    ScrollView {
        VStack(spacing: 0) {
            FeatureHeader(title: header.0, subtitle: header.1, icon: header.2)
            VStack(spacing: 16) { content() }.padding()
        }
    }
    .navigationBarTitleDisplayMode(.inline)
    .background(AppTheme.surface)
}

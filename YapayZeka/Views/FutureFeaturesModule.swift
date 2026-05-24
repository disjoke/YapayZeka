import SwiftUI

// MARK: - Hub

struct FutureFeaturesView: View {
    @ObservedObject var manager = FutureFeaturesManager.shared
    @State private var selected: FutureFeatureKind?

    private var features: [FutureFeature] {
        FutureFeatureKind.allCases.map { kind in
            FutureFeature(
                id: kind.id,
                title: kind.title,
                description: kind.subtitle,
                eta: "Aktif",
                status: "Çalışıyor",
                isActive: true,
                kind: kind
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                FeatureHeader(
                    title: "Premium AI Modülleri",
                    subtitle: "6 gelişmiş özellik tam aktif",
                    icon: "sparkles.rectangle.stack.fill"
                )

                VStack(spacing: 16) {
                    if let err = manager.lastError {
                        AIErrorBanner(message: err)
                    }

                    HStack(spacing: 8) {
                        Circle().fill(AppTheme.success).frame(width: 8, height: 8)
                        Text("Tüm modüller aktif — AI destekli")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.success)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(features) { feature in
                            NavigationLink(destination: destination(for: feature.kind)) {
                                FutureFeatureCard(feature: feature)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !manager.lastResult.isEmpty {
                        AICard(title: "Son AI Sonucu", icon: "text.bubble") {
                            Text(manager.lastResult)
                                .font(.subheadline)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.surface)
        .task { await manager.refreshAll() }
        .refreshable { await manager.refreshAll() }
    }

    @ViewBuilder
    private func destination(for kind: FutureFeatureKind) -> some View {
        switch kind {
        case .videoRender: FutureVideoRenderView()
        case .metaAds: FutureMetaAdsView()
        case .whatsappBot: FutureWhatsAppBotView()
        case .multiLanguage: FutureMultiLanguageView()
        case .competitorBot: FutureCompetitorBotView()
        case .crossPlatform: FutureCrossPlatformView()
        }
    }
}

struct FutureFeatureCard: View {
    let feature: FutureFeature

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: feature.kind.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                Spacer()
                Text("AKTİF")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(AppTheme.success)
                    .clipShape(Capsule())
            }
            Text(feature.title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
            Text(feature.description)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(AppTheme.headerGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - 1. Video Render

struct FutureVideoRenderView: View {
    @ObservedObject var manager = FutureFeaturesManager.shared
    @ObservedObject var video = VideoService.shared
    @State private var prompt = ""
    @State private var style = "Sinematik, profesyonel reklam"

    var body: some View {
        futureDetailLayout(title: "Video Render", subtitle: "Replicate AI video", icon: "film.stack.fill") {
            TextField("Video prompt", text: $prompt, axis: .vertical).lineLimit(2...5).textFieldStyle(.roundedBorder)
            TextField("Stil", text: $style).textFieldStyle(.roundedBorder)
            AIButton("AI Video Render", icon: "play.fill", isLoading: manager.isLoading || video.isLoading) {
                Task {
                    let finalPrompt = prompt.isEmpty ? "Profesyonel reklam videosu" : prompt
                    await video.generateScript(topic: finalPrompt, duration: "15 sn", style: style)
                    await manager.renderVideo(prompt: "\(finalPrompt)\n\(video.script)", style: style)
                }
            }
            if !video.script.isEmpty {
                AIResultBox(text: video.script, isLoading: false)
            }
            if !manager.videoHistory.isEmpty {
                AICard(title: "Render Geçmişi", icon: "clock.arrow.circlepath") {
                    ForEach(manager.videoHistory.prefix(5)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.prompt ?? "-").font(.caption).lineLimit(2)
                            Text(item.status ?? item.message ?? "").font(.caption2).foregroundStyle(.secondary)
                            if let url = item.videoUrl, let link = URL(string: url) {
                                Link("Videoyu aç", destination: link).font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 2. Meta Ads

struct FutureMetaAdsView: View {
    @ObservedObject var manager = FutureFeaturesManager.shared
    @State private var name = ""
    @State private var budget: Double = 500
    @State private var objective = "OUTCOME_AWARENESS"
    @State private var totalBudget: Double = 5000

    var body: some View {
        futureDetailLayout(title: "Meta Ads API", subtitle: "Kampanya yayını ve optimizasyon", icon: "megaphone.fill") {
            TextField("Kampanya adı", text: $name).textFieldStyle(.roundedBorder)
            VStack(alignment: .leading) {
                Text("Günlük bütçe: \(Int(budget)) TL")
                Slider(value: $budget, in: 100...50_000, step: 100)
            }
            Picker("Hedef", selection: $objective) {
                Text("Bilinirlik").tag("OUTCOME_AWARENESS")
                Text("Trafik").tag("OUTCOME_TRAFFIC")
                Text("Dönüşüm").tag("OUTCOME_SALES")
            }
            AIButton("Kampanya Oluştur", icon: "plus.circle.fill", isLoading: manager.isLoading) {
                Task { await manager.createMetaCampaign(name: name, budget: budget, objective: objective) }
            }
            Divider()
            VStack(alignment: .leading) {
                Text("Toplam optimizasyon: \(Int(totalBudget)) TL")
                Slider(value: $totalBudget, in: 1000...200_000, step: 500)
            }
            AIButton("AI Bütçe Optimizasyonu", icon: "chart.pie.fill", style: .secondary, isLoading: manager.isLoading) {
                Task { await manager.optimizeMetaAds(totalBudget: totalBudget) }
            }
            if !manager.metaCampaigns.isEmpty {
                AICard(title: "Kampanyalar", icon: "list.bullet.rectangle") {
                    ForEach(manager.metaCampaigns) { c in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(c.name).font(.headline)
                                Spacer()
                                Text(c.status ?? "—").font(.caption.bold())
                                    .foregroundStyle(AppTheme.primary)
                            }
                            Text("\(Int(c.budget)) TL · \(c.objective ?? "")")
                                .font(.caption).foregroundStyle(.secondary)
                            if c.simulated == true {
                                Text("Simülasyon modu").font(.caption2).foregroundStyle(AppTheme.warning)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            AIResultBox(text: manager.lastResult, isLoading: manager.isLoading)
        }
    }
}

// MARK: - 3. WhatsApp Bot

struct FutureWhatsAppBotView: View {
    @ObservedObject var manager = FutureFeaturesManager.shared
    @State private var greeting = ""
    @State private var hours = "09:00 - 18:00"
    @State private var enabled = false
    @State private var testPhone = ""
    @State private var testMessage = "Merhaba, fiyat alabilir miyim?"

    var body: some View {
        futureDetailLayout(title: "WhatsApp Bot", subtitle: "Otomatik yanıt ve chatbot", icon: "message.badge.filled.fill") {
            Toggle("Bot aktif", isOn: $enabled)
            TextField("Karşılama mesajı", text: $greeting, axis: .vertical).lineLimit(2...4).textFieldStyle(.roundedBorder)
            TextField("Çalışma saatleri", text: $hours).textFieldStyle(.roundedBorder)
            Divider()
            Text("Test gönderimi").font(.caption.bold())
            TextField("Test telefon (905...)", text: $testPhone).keyboardType(.phonePad).textFieldStyle(.roundedBorder)
            TextField("Test mesajı", text: $testMessage).textFieldStyle(.roundedBorder)
            AIButton("Botu Kaydet ve Test Et", icon: "paperplane.fill", isLoading: manager.isLoading) {
                Task {
                    await manager.saveWhatsAppBot(
                        enabled: enabled,
                        greeting: greeting.isEmpty ? manager.whatsappBot.greeting : greeting,
                        hours: hours,
                        testPhone: testPhone.isEmpty ? nil : testPhone,
                        testMessage: testMessage
                    )
                }
            }
            AIResultBox(text: manager.lastResult, isLoading: manager.isLoading)
        }
        .onAppear {
            greeting = manager.whatsappBot.greeting
            enabled = manager.whatsappBot.enabled
            hours = manager.whatsappBot.businessHours
        }
    }
}

// MARK: - 4. Çoklu Dil

struct FutureMultiLanguageView: View {
    @ObservedObject var manager = FutureFeaturesManager.shared
    @State private var sourceText = ""
    @State private var selectedLang = "en"
    @State private var multiMode = false
    @State private var selectedMulti: Set<String> = ["en", "de", "ar"]

    var body: some View {
        futureDetailLayout(title: "Çoklu Dil", subtitle: "12 dilde AI çeviri", icon: "globe") {
            TextField("Kaynak metin", text: $sourceText, axis: .vertical).lineLimit(3...8).textFieldStyle(.roundedBorder)
            Toggle("Çoklu dil modu", isOn: $multiMode)
            if multiMode {
                AICard(title: "Hedef diller", icon: "character.bubble") {
                    ForEach(manager.languages.isEmpty ? defaultLangs : manager.languages) { lang in
                        Toggle(lang.name, isOn: Binding(
                            get: { selectedMulti.contains(lang.code) },
                            set: { on in
                                if on { selectedMulti.insert(lang.code) }
                                else { selectedMulti.remove(lang.code) }
                            }
                        ))
                    }
                }
            } else {
                Picker("Hedef dil", selection: $selectedLang) {
                    ForEach(manager.languages.isEmpty ? defaultLangs : manager.languages) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
            }
            AIButton("AI Çevir", icon: "globe", isLoading: manager.isLoading) {
                Task {
                    await manager.translate(
                        text: sourceText,
                        lang: selectedLang,
                        multi: multiMode ? Array(selectedMulti) : nil
                    )
                }
            }
            AIResultBox(text: manager.lastResult, isLoading: manager.isLoading)
        }
    }

    private var defaultLangs: [LanguageOption] {
        ["tr", "en", "de", "fr", "es", "ar"].map { LanguageOption(code: $0, name: $0.uppercased()) }
    }
}

// MARK: - 5. Rakip Bot

struct FutureCompetitorBotView: View {
    @ObservedObject var manager = FutureFeaturesManager.shared
    @State private var name = ""
    @State private var handle = ""
    @State private var platform = "Instagram"
    @State private var industry = ""

    var body: some View {
        futureDetailLayout(title: "Rakip Takip Botu", subtitle: "AI izleme ve analiz", icon: "binoculars.fill") {
            TextField("Rakip adı", text: $name).textFieldStyle(.roundedBorder)
            TextField("@kullaniciadi", text: $handle).textFieldStyle(.roundedBorder)
            TextField("Sektör", text: $industry).textFieldStyle(.roundedBorder)
            Picker("Platform", selection: $platform) {
                ForEach(AIPlatform.allCases) { Text($0.rawValue).tag($0.rawValue) }
            }
            AIButton("Rakip Ekle", icon: "plus", style: .secondary) {
                Task { await manager.addCompetitor(name: name, platform: platform, handle: handle, industry: industry) }
            }
            AIButton("Tüm Rakipleri Tara (AI)", icon: "antenna.radiowaves.left.and.right", isLoading: manager.isLoading) {
                Task { await manager.scanCompetitors(industry: industry.isEmpty ? "Genel" : industry) }
            }
            if !manager.competitors.isEmpty {
                AICard(title: "İzlenen Rakipler (\(manager.competitors.count))", icon: "eye.fill") {
                    ForEach(manager.competitors) { c in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(c.name).font(.headline)
                                Text("\(c.platform) · \(c.handle ?? "")").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Analiz") {
                                Task { await manager.analyzeCompetitor(id: c.id, industry: industry) }
                            }
                            .font(.caption.bold())
                        }
                    }
                }
            }
            AIResultBox(text: manager.lastResult, isLoading: manager.isLoading)
        }
    }
}

// MARK: - 6. Çapraz Platform

struct FutureCrossPlatformView: View {
    @ObservedObject var manager = FutureFeaturesManager.shared

    var body: some View {
        futureDetailLayout(title: "Android & Web", subtitle: "Çapraz platform senkronizasyon", icon: "arrow.triangle.2.circlepath") {
            if let sync = manager.platformSync {
                platformRow("iOS", detail: sync.ios, icon: "iphone", active: true)
                platformRow("Web Panel", detail: sync.web, icon: "globe", active: sync.web?.active == true)
                platformRow("Android", detail: sync.android, icon: "smartphone", active: sync.android?.active == true)
                if let pending = sync.pendingChanges, pending > 0 {
                    Text("\(pending) bekleyen değişiklik").font(.caption).foregroundStyle(AppTheme.warning)
                }
            }
            AIButton("Şimdi Senkronize Et", icon: "arrow.triangle.2.circlepath", isLoading: manager.isLoading) {
                Task { await manager.syncPlatforms() }
            }
            AICard(title: "Senkronize Veriler", icon: "checkmark.circle") {
                syncItem("Müşteri kayıtları")
                syncItem("Marka profili")
                syncItem("İçerik takvimi")
                syncItem("Reklam kampanyaları")
                syncItem("Sosyal bağlantılar")
            }
            AIResultBox(text: manager.lastResult, isLoading: manager.isLoading)
        }
        .task { await manager.refreshAll() }
    }

    private func platformRow(_ title: String, detail: PlatformSyncInfo.PlatformDetail?, icon: String, active: Bool) -> some View {
        AICard {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title2).foregroundStyle(active ? AppTheme.success : .secondary)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title).font(.headline)
                        if active {
                            Text("AKTİF").font(.caption2.bold()).foregroundStyle(AppTheme.success)
                        } else if let progress = detail?.progress {
                            Text("Beta %\(progress)").font(.caption2).foregroundStyle(AppTheme.warning)
                        }
                    }
                    if let v = detail?.version { Text("v\(v)").font(.caption).foregroundStyle(.secondary) }
                    if let eta = detail?.eta { Text(eta).font(.caption2).foregroundStyle(.secondary) }
                    if let url = detail?.url, let link = URL(string: url) {
                        Link("Panele git", destination: link).font(.caption)
                    }
                }
                Spacer()
            }
        }
    }

    private func syncItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.success)
            Text(text).font(.subheadline)
        }
    }
}

// MARK: - Layout Helper

@ViewBuilder
private func futureDetailLayout(
    title: String,
    subtitle: String,
    icon: String,
    @ViewBuilder content: () -> some View
) -> some View {
    ScrollView {
        VStack(spacing: 0) {
            FeatureHeader(title: title, subtitle: subtitle, icon: icon)
            VStack(spacing: 16) { content() }.padding()
        }
    }
    .navigationBarTitleDisplayMode(.inline)
    .background(AppTheme.surface)
}

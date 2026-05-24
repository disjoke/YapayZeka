import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionManager
    @ObservedObject var settings = AppSettings.shared

    private let features: [AppFeature] = [
        AppFeature(id: 1, title: "Giriş Sistemi", description: "Kimlik doğrulama ve oturum yönetimi", icon: "lock.shield.fill", color: "blue"),
        AppFeature(id: 2, title: "Sosyal Medya", description: "Instagram, Facebook OAuth bağlantıları", icon: "link.circle.fill", color: "purple"),
        AppFeature(id: 3, title: "AI Reklam", description: "Reklam metni ve kampanya üretimi", icon: "megaphone.fill", color: "green"),
        AppFeature(id: 4, title: "AI Görsel", description: "DALL-E ile görsel oluşturma", icon: "photo.artframe", color: "orange"),
        AppFeature(id: 5, title: "AI Video", description: "Reels ve kısa video senaryoları", icon: "video.fill", color: "red"),
        AppFeature(id: 6, title: "Otomatik Paylaşım", description: "Zamanlanmış post ve hikâye", icon: "clock.arrow.circlepath", color: "teal"),
        AppFeature(id: 7, title: "Reklam Yönetimi", description: "Hedefleme, bütçe, performans", icon: "chart.bar.doc.horizontal.fill", color: "indigo"),
        AppFeature(id: 8, title: "WhatsApp AI", description: "Otomatik yanıt ve randevu", icon: "message.fill", color: "green"),
        AppFeature(id: 9, title: "Müşteri Kayıt", description: "Müşteri verisi yönetimi", icon: "person.crop.circle.badge.plus", color: "cyan"),
        AppFeature(id: 10, title: "İstatistik Paneli", description: "Metrikler ve AI analizi", icon: "chart.xyaxis.line", color: "pink"),
        AppFeature(id: 11, title: "İçerik Takvimi", description: "Haftalık/aylık AI planı", icon: "calendar.badge.clock", color: "mint"),
        AppFeature(id: 12, title: "Sesli AI Reklam", description: "Seslendirme ile reklam", icon: "waveform.circle.fill", color: "yellow"),
        AppFeature(id: 13, title: "Platformlar", description: "iOS aktif · Web & Android senkron", icon: "iphone.and.ipad", color: "gray"),
        AppFeature(id: 14, title: "Marka Sistemi", description: "Logo ve iletişim bilgileri", icon: "building.2.fill", color: "brown"),
        AppFeature(id: 15, title: "Gelişmiş AI", description: "Rakip analizi, viral öneriler", icon: "brain.head.profile", color: "purple"),
        AppFeature(id: 16, title: "Premium AI Modülleri", description: "Video, Meta Ads, WhatsApp Bot, çeviri, rakip, senkron", icon: "sparkles.rectangle.stack.fill", color: "blue")
    ]

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape.fill")
                            }
                        }
                    }
            }
            .tabItem { Label("Panel", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                List(features) { feature in
                    NavigationLink(destination: destination(for: feature.id)) {
                        HStack(spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(AppTheme.primary.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(feature.title).font(.headline)
                                Text(feature.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Modüller")
            }
            .tabItem { Label("Modüller", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Ayarlar", systemImage: "gearshape.fill") }
        }
        .tint(AppTheme.primary)
    }

    @ViewBuilder
    private func destination(for id: Int) -> some View {
        switch id {
        case 1: SessionInfoView()
        case 2: SocialConnectionsView()
        case 3: AdManagerView()
        case 4: ImageGeneratorView()
        case 5: VideoGeneratorView()
        case 6: SchedulingView()
        case 7: AdManagementView()
        case 8: WhatsAppAssistantView()
        case 9: CustomerManagementView()
        case 10: AnalyticsView()
        case 11: ContentCalendarView()
        case 12: VoiceAdView()
        case 13: CrossPlatformInfoView()
        case 14: BrandInfoView()
        case 15: AdvancedFeaturesView()
        case 16: FutureFeaturesView()
        default: Text("Modül bulunamadı")
        }
    }
}

import SwiftUI

struct DashboardView: View {
    @ObservedObject var social = SocialMediaManager.shared
    @ObservedObject var customers = CustomerManager.shared
    @ObservedObject var scheduling = SchedulingManager.shared
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var analytics = AnalyticsManager.shared
    @EnvironmentObject var session: SessionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hoş geldiniz, \(session.currentUsername)")
                        .font(.title2.bold())
                    Text("Ekinciler AI — Sosyal medya ve reklam yönetim merkezi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                if !settings.hasValidAPIKey {
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text("AI özellikleri için OpenAI API anahtarınızı ayarlayın")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(AppTheme.warning.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(title: "Bağlı Platform", value: "\(social.connectedCount)", icon: "link", color: AppTheme.primary)
                    StatTile(title: "Müşteri", value: "\(customers.customers.count)", icon: "person.2.fill", color: AppTheme.accent)
                    StatTile(title: "Planlı Paylaşım", value: "\(scheduling.posts.count)", icon: "calendar", color: AppTheme.success)
                    StatTile(title: "Etkileşim", value: String(format: "%.1f%%", analytics.snapshot.engagementRate), icon: "chart.line.uptrend.xyaxis", color: AppTheme.secondary)
                }
                .padding(.horizontal)

                AICard(title: "AI Durumu", icon: "cpu") {
                    HStack {
                        Circle()
                            .fill(settings.hasValidAPIKey ? AppTheme.success : AppTheme.warning)
                            .frame(width: 10, height: 10)
                        Text(settings.hasValidAPIKey ? "İnternet üzerinden AI aktif" : "API anahtarı bekleniyor")
                            .font(.subheadline)
                    }
                    Text(settings.lastAIStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(AppTheme.surface)
        .navigationTitle("Panel")
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

import SwiftUI

enum AppTheme {
    static let primary = Color(red: 0.35, green: 0.22, blue: 0.92)
    static let secondary = Color(red: 0.55, green: 0.35, blue: 0.98)
    static let accent = Color(red: 0.20, green: 0.78, blue: 0.95)
    static let success = Color(red: 0.18, green: 0.80, blue: 0.55)
    static let warning = Color(red: 1.0, green: 0.65, blue: 0.15)
    static let danger = Color(red: 0.95, green: 0.30, blue: 0.35)
    static let surface = Color(.systemBackground)
    static let card = Color(.secondarySystemBackground)

    static let headerGradient = LinearGradient(
        colors: [primary, secondary, accent.opacity(0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardShadow = Color.black.opacity(0.08)
}

struct AICard<Content: View>: View {
    let title: String?
  let icon: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack(spacing: 8) {
                    if let icon {
                        Image(systemName: icon)
                            .foregroundStyle(AppTheme.primary)
                    }
                    Text(title)
                        .font(.headline)
                }
            }
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.cardShadow, radius: 8, y: 4)
    }
}

struct AIButton: View {
    enum Style { case primary, secondary, destructive }

    let title: String
    let icon: String?
    let style: Style
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = "sparkles",
        style: Style = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isLoading)
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            AppTheme.headerGradient
        case .secondary:
            AppTheme.card
        case .destructive:
            AppTheme.danger
        }
    }

    private var foreground: Color {
        style == .secondary ? .primary : .white
    }
}

struct AIResultBox: View {
    let text: String
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Yapay zeka çalışıyor…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            } else if !text.isEmpty {
                ScrollView {
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 280)
                .padding()
            }
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct FeatureHeader: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.headerGradient)
    }
}

struct AIErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.footnote)
        }
        .foregroundStyle(AppTheme.danger)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.danger.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

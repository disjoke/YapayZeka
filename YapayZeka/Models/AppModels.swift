import Foundation

struct Customer: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var phone: String
    var email: String
    var notes: String
    var createdAt: Date = Date()
}

struct ScheduledPost: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var platform: String
    var content: String
    var scheduledAt: Date
    var isStory: Bool
    var status: PostStatus = .pending

    enum PostStatus: String, Codable {
        case pending, published, failed
    }
}

struct AdCampaign: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var budget: Double
    var targetAudience: String
    var platform: String
    var aiStrategy: String
    var createdAt: Date = Date()
}

struct ContentCalendarItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var title: String
    var contentType: String
    var suggestion: String
    var platform: String
}

struct BrandProfile: Codable {
    var companyName: String = "Ekinciler"
    var tagline: String = "Yapay Zeka Destekli Sosyal Medya Yönetimi"
    var phone: String = ""
    var email: String = ""
    var website: String = ""
    var address: String = ""
    var primaryColorHex: String = "#5A38EB"
}

struct AnalyticsSnapshot: Codable {
    var impressions: Int
    var clicks: Int
    var engagementRate: Double
    var adSpend: Double
    var conversions: Int
    var aiInsight: String
}

struct SocialConnection: Identifiable, Codable {
    var id: String { platform }
    var platform: String
    var isConnected: Bool
    var username: String?
    var connectedAt: Date?
}

enum FutureFeatureKind: String, CaseIterable, Identifiable {
    case videoRender = "video"
    case metaAds = "meta_ads"
    case whatsappBot = "whatsapp"
    case multiLanguage = "translate"
    case competitorBot = "competitor"
    case crossPlatform = "platforms"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .videoRender: return "Video Render"
        case .metaAds: return "Meta Ads API"
        case .whatsappBot: return "WhatsApp Bot"
        case .multiLanguage: return "Çoklu Dil"
        case .competitorBot: return "Rakip Takip Botu"
        case .crossPlatform: return "Android & Web"
        }
    }

    var subtitle: String {
        switch self {
        case .videoRender: return "Replicate ile AI video üretimi"
        case .metaAds: return "Canlı kampanya ve bütçe optimizasyonu"
        case .whatsappBot: return "Otomatik yanıt ve chatbot"
        case .multiLanguage: return "12 dilde AI içerik"
        case .competitorBot: return "Rakip izleme ve analiz"
        case .crossPlatform: return "iOS · Web · Android senkron"
        }
    }

    var icon: String {
        switch self {
        case .videoRender: return "film.stack.fill"
        case .metaAds: return "megaphone.fill"
        case .whatsappBot: return "message.badge.filled.fill"
        case .multiLanguage: return "globe"
        case .competitorBot: return "binoculars.fill"
        case .crossPlatform: return "arrow.triangle.2.circlepath"
        }
    }
}

struct FutureFeatureStatus: Codable {
    var videoRender: ModuleStatus?
    var metaAds: ModuleStatus?
    var whatsappBot: ModuleStatus?
    var multiLanguage: LangStatus?
    var competitorBot: ModuleStatus?
    var crossPlatform: CrossPlatformStatus?

    struct ModuleStatus: Codable {
        var active: Bool?
        var configured: Bool?
        var replicate: Bool?
    }

    struct LangStatus: Codable {
        var active: Bool?
        var languages: Int?
    }

    struct CrossPlatformStatus: Codable {
        var ios: PlatformInfo?
        var android: PlatformInfo?
        var web: PlatformInfo?
    }

    struct PlatformInfo: Codable {
        var active: Bool?
        var version: String?
        var progress: Int?
        var eta: String?
        var url: String?
    }
}

struct MetaAdCampaignItem: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var budget: Double
    var objective: String?
    var status: String?
    var simulated: Bool?
    var message: String?
    var createdAt: String?
}

struct CompetitorEntry: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var platform: String
    var handle: String?
    var industry: String?
    var addedAt: String?
}

struct VideoHistoryItem: Identifiable, Codable, Hashable {
    var id: String
    var prompt: String?
    var status: String?
    var videoUrl: String?
    var message: String?
    var createdAt: String?

    init(id: String? = nil, prompt: String? = nil, status: String? = nil, videoUrl: String? = nil, message: String? = nil, createdAt: String? = nil) {
        self.id = id ?? UUID().uuidString
        self.prompt = prompt
        self.status = status
        self.videoUrl = videoUrl
        self.message = message
        self.createdAt = createdAt
    }
}

struct WhatsAppBotConfig: Codable {
    var enabled: Bool
    var greeting: String
    var businessHours: String
    var updatedAt: String?
}

struct LanguageOption: Identifiable, Codable, Hashable {
    var code: String
    var name: String
    var id: String { code }
}

struct PlatformSyncInfo: Codable {
    var ios: PlatformDetail?
    var android: PlatformDetail?
    var web: PlatformDetail?
    var syncEnabled: Bool?
    var pendingChanges: Int?
    var lastSyncMessage: String?
    var iosLastSync: String?

    struct PlatformDetail: Codable {
        var active: Bool?
        var version: String?
        var progress: Int?
        var eta: String?
        var url: String?
        var lastSync: String?
    }
}

struct FutureFeature: Identifiable {
    var id: String
    var title: String
    var description: String
    var eta: String
    var status: String
    var isActive: Bool
    var kind: FutureFeatureKind
}

struct AppFeature: Identifiable {
    var id: Int
    var title: String
    var description: String
    var icon: String
    var color: String
}

enum AIPlatform: String, CaseIterable, Identifiable {
    case instagram = "Instagram"
    case facebook = "Facebook"
    case tiktok = "TikTok"
    case linkedin = "LinkedIn"
    case whatsapp = "WhatsApp"
    case youtube = "YouTube"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .instagram: "camera.fill"
        case .facebook: "f.circle.fill"
        case .tiktok: "music.note"
        case .linkedin: "briefcase.fill"
        case .whatsapp: "message.fill"
        case .youtube: "play.rectangle.fill"
        }
    }
}

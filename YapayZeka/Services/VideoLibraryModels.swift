import Foundation

struct VideoLibraryItem: Identifiable, Codable, Hashable {
    var id: String
    var prompt: String
    var remoteURLString: String?
    var localFileName: String?
    var status: String?
    var createdAt: Date

    var remoteURL: URL? {
        guard let s = remoteURLString, let u = URL(string: s) else { return nil }
        return u
    }

    var hasLocalFile: Bool {
        guard let name = localFileName else { return false }
        return FileManager.default.fileExists(atPath: VideoService.videosDirectory().appendingPathComponent(name).path)
    }

    var localURL: URL? {
        guard let name = localFileName, hasLocalFile else { return nil }
        return VideoService.videosDirectory().appendingPathComponent(name)
    }

    var title: String {
        let p = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if p.count > 40 { return String(p.prefix(40)) + "…" }
        return p.isEmpty ? "AI Video" : p
    }

    var subtitle: String {
        if hasLocalFile { return "İndirildi · \(formattedDate)" }
        if status == "simulated" { return "Çekim planı (MP4 yok)" }
        return "Bulutta · \(formattedDate)"
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: createdAt)
    }
}

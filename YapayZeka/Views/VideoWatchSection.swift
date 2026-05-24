import SwiftUI
import AVKit
import Photos

/// Video izleme, indirme ve geçmiş listesi
struct VideoWatchSection: View {
    @ObservedObject var video: VideoService
    @State private var player: AVPlayer?
    @State private var showShare = false
    @State private var shareItems: [Any] = []

    private var playbackURL: URL? {
        video.localFileURL ?? video.videoURL
    }

    var body: some View {
        AICard(title: "Video İzle & İndir", icon: "play.rectangle.fill") {
            if let url = playbackURL {
                videoPlayer(url: url)
                actionButtons(remote: video.videoURL, local: video.localFileURL)
            } else {
                emptyVideoPlaceholder
            }

            if video.isDownloading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Video indiriliyor…").font(.caption)
                }
            }

            if let msg = video.downloadMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(msg.contains("✓") ? AppTheme.success : AppTheme.warning)
            }

            libraryList
        }
        .onChange(of: playbackURL) { _, newURL in
            if let newURL { player = AVPlayer(url: newURL) }
            else { player = nil }
        }
        .onAppear {
            if let url = playbackURL { player = AVPlayer(url: url) }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
    }

    @ViewBuilder
    private func videoPlayer(url: URL) -> some View {
        if let player {
            VideoPlayer(player: player)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onDisappear { player.pause() }
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.08))
                .frame(height: 220)
                .overlay { ProgressView() }
        }
    }

    @ViewBuilder
    private func actionButtons(remote: URL?, local: URL?) -> some View {
        HStack(spacing: 10) {
            if remote != nil && local == nil {
                Button {
                    Task { await video.downloadCurrentVideo() }
                } label: {
                    Label("İndir", systemImage: "arrow.down.circle.fill")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
            }
            if let file = local ?? remote {
                Button {
                    shareItems = [file]
                    showShare = true
                } label: {
                    Label("Paylaş", systemImage: "square.and.arrow.up")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.bordered)
            }
            if let file = local {
                Button {
                    Task { await video.saveToPhotoLibrary(fileURL: file) }
                } label: {
                    Label("Galeri", systemImage: "photo.on.rectangle")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.bordered)
            }
            if let file = local {
                Button {
                    video.openInFiles(fileURL: file)
                } label: {
                    Label("Dosyalar", systemImage: "folder")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var emptyVideoPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "film")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Henüz video dosyası yok")
                .font(.subheadline.bold())
            Text("«Video Üret» ile MP4 oluşunca burada izleyip indirebilirsiniz. Şimdilik senaryo ve çekim planı yukarıda.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private var libraryList: some View {
        if !video.library.isEmpty {
            Divider().padding(.vertical, 4)
            Text("Geçmiş videolar").font(.subheadline.bold())
            ForEach(video.library) { item in
                Button {
                    Task { await video.selectLibraryItem(item) }
                } label: {
                    HStack {
                        Image(systemName: item.hasLocalFile ? "checkmark.circle.fill" : "cloud")
                            .foregroundStyle(item.hasLocalFile ? AppTheme.success : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.caption.bold())
                                .lineLimit(1)
                            Text(item.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if item.remoteURL != nil && !item.hasLocalFile {
                            Image(systemName: "arrow.down.circle")
                                .font(.caption)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

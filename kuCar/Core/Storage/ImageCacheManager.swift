import Foundation
import CoreImage
import UIKit

/// Two-tier image cache: memory (NSCache) + disk (temporary directory).
/// Used to avoid recomputing segmentation masks and rendered previews.
final class ImageCacheManager: @unchecked Sendable {

    private let memoryCache = NSCache<NSString, CachedImage>()

    // MARK: - Cache Configuration

    private let maxMemoryCost = 50 * 1024 * 1024 // 50 MB
    private let maxDiskSize = 200 * 1024 * 1024  // 200 MB

    init() {
        memoryCache.totalCostLimit = maxMemoryCost
        memoryCache.countLimit = 30 // max 30 items in memory

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    // MARK: - Public API

    func cachedImage(for key: String) -> CGImage? {
        let cacheKey = key as NSString

        // Try memory first
        if let cached = memoryCache.object(forKey: cacheKey) {
            return cached.image
        }

        // Try disk
        if let diskImage = loadFromDisk(key: key) {
            // Promote to memory
            storeInMemory(diskImage, for: key)
            return diskImage
        }

        return nil
    }

    func cacheImage(_ image: CGImage, for key: String) {
        storeInMemory(image, for: key)
        saveToDisk(image, key: key)
    }

    func cacheMask(_ mask: CIImage, for key: String) {
        // Render CIImage to CGImage for cache storage
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        guard let cgImage = context.createCGImage(mask, from: mask.extent) else { return }
        cacheImage(cgImage, for: key)
    }

    func cachedMask(for key: String) -> CIImage? {
        guard let cgImage = cachedImage(for: key) else { return nil }
        return CIImage(cgImage: cgImage)
    }

    func invalidate(key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        removeFromDisk(key: key)
    }

    func clearAll() {
        memoryCache.removeAllObjects()
        clearDiskCache()
    }

    // MARK: - Private

    private func storeInMemory(_ image: CGImage, for key: String) {
        let cost = image.bytesPerRow * image.height
        let cached = CachedImage(image: image)
        memoryCache.setObject(cached, forKey: key as NSString, cost: cost)
    }

    @objc private func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    // MARK: - Disk Cache

    private var diskCacheURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("kuCar", isDirectory: true)
            .appendingPathComponent("ImageCache", isDirectory: true)
    }

    private func ensureDiskCacheDirectory() -> URL {
        let url = diskCacheURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func diskFileURL(for key: String) -> URL {
        let sanitized = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return ensureDiskCacheDirectory().appendingPathComponent("\(sanitized).png")
    }

    private func saveToDisk(_ image: CGImage, key: String) {
        let url = diskFileURL(for: key)
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, "public.png" as CFString, 1, nil
        ) else { return }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
    }

    private func loadFromDisk(key: String) -> CGImage? {
        let url = diskFileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return image
    }

    private func removeFromDisk(key: String) {
        let url = diskFileURL(for: key)
        try? FileManager.default.removeItem(at: url)
    }

    private func clearDiskCache() {
        try? FileManager.default.removeItem(at: diskCacheURL)
    }
}

// MARK: - Cached Image Wrapper

private final class CachedImage {
    let image: CGImage

    init(image: CGImage) {
        self.image = image
    }
}

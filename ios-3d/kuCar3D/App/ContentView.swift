import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebView()
            .ignoresSafeArea()
    }
}

struct WebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.063, alpha: 1.0)
        webView.scrollView.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.063, alpha: 1.0)

        // Load local index.html from app bundle
        // Try www subdirectory first (folder reference), then root
        if let wwwURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www") {
            webView.loadFileURL(wwwURL, allowingReadAccessTo: wwwURL.deletingLastPathComponent())
            print("[kuCar] Loading from www/ subdirectory")
        } else if let rootURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: nil) {
            webView.loadFileURL(rootURL, allowingReadAccessTo: rootURL.deletingLastPathComponent())
            print("[kuCar] Loading from bundle root")
        } else {
            print("[kuCar] ERROR: index.html not found in bundle")
            // List bundle contents for debugging
            if let bundlePath = Bundle.main.resourcePath {
                let fm = FileManager.default
                if let contents = try? fm.contentsOfDirectory(atPath: bundlePath) {
                    print("[kuCar] Bundle root contents: \(contents)")
                }
            }
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("[kuCar] WebView navigation failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("[kuCar] WebView provisional navigation failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("[kuCar] WebView loaded successfully")
        }
    }
}

#Preview {
    ContentView()
}

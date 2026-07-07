import SwiftUI
import WebKit

struct ContentView: View {
    @State private var serverPort: UInt16 = 0

    var body: some View {
        Group {
            if serverPort > 0 {
                WebView(port: serverPort)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("启动引擎...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.039, green: 0.039, blue: 0.063))
            }
        }
        .task {
            await startServer()
        }
    }

    private func startServer() async {
        // Find www directory in app bundle
        var wwwURL: URL?
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www") {
            wwwURL = url.deletingLastPathComponent()
        } else if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: nil) {
            wwwURL = url.deletingLastPathComponent()
        } else if let resourcePath = Bundle.main.resourcePath {
            let fm = FileManager.default
            if let enumerator = fm.enumerator(atPath: resourcePath) {
                while let file = enumerator.nextObject() as? String {
                    if file.hasSuffix("index.html") {
                        wwwURL = URL(fileURLWithPath: "\(resourcePath)/\(file)").deletingLastPathComponent()
                        break
                    }
                }
            }
        }

        guard let www = wwwURL else {
            print("[kuCar] FATAL: www not found")
            return
        }
        print("[kuCar] Serving www from: \(www.path)")

        let httpServer = LocalHTTPServer(wwwURL: www)
        do {
            try httpServer.start()
            for _ in 0..<50 {
                if httpServer.port > 0 { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            if httpServer.port > 0 {
                serverPort = httpServer.port
                print("[kuCar] Server on port \(serverPort)")
            }
        } catch {
            print("[kuCar] Server error: \(error)")
        }
    }
}

// MARK: - WKWebView Wrapper

struct WebView: UIViewRepresentable {
    let port: UInt16

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.063, alpha: 1.0)
        webView.scrollView.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.063, alpha: 1.0)

        if let url = URL(string: "http://127.0.0.1:\(port)/index.html") {
            print("[kuCar] Loading \(url.absoluteString)")
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("[kuCar] Navigation failed: \(error.localizedDescription)")
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("[kuCar] Provisional failed: \(error.localizedDescription)")
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("[kuCar] Page loaded!")
        }
    }
}

#Preview {
    ContentView()
}

import Foundation
import Network

/// Minimal HTTP file server for serving the www bundle to WKWebView.
/// WKWebView blocks ES modules on file:// URLs, so we serve via http://localhost.
final class LocalHTTPServer {
    private var listener: NWListener?
    private let wwwURL: URL
    private(set) var port: UInt16 = 0

    init(wwwURL: URL) {
        self.wwwURL = wwwURL
    }

    func start() throws {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        let listener = try NWListener(using: params)
        listener.service = NWListener.Service(name: "kuCar", type: "_http._tcp")
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                if let port = listener.port {
                    self.port = port.rawValue
                    print("[kuCar] HTTP server started on port \(port.rawValue)")
                }
            case .failed(let error):
                print("[kuCar] HTTP server error: \(error)")
            case .cancelled:
                print("[kuCar] HTTP server stopped")
            default: break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener.start(queue: .global(qos: .userInitiated))
        self.listener = listener
        print("[kuCar] HTTP server listening...")
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    // MARK: - Connection Handling

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        receiveRequest(connection)
    }

    private func receiveRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }
            if let requestStr = String(data: data, encoding: .utf8) {
                self.processRequest(requestStr, connection: connection)
            } else {
                connection.cancel()
            }
        }
    }

    private func processRequest(_ request: String, connection: NWConnection) {
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else { connection.cancel(); return }

        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2, parts[0] == "GET" else {
            sendError(405, connection: connection)
            return
        }

        var path = parts[1]
        // Decode %20 etc
        path = path.removingPercentEncoding ?? path
        // Strip query string
        if let qIndex = path.firstIndex(of: "?") {
            path = String(path[..<qIndex])
        }
        // Default to index.html
        if path == "/" || path.isEmpty {
            path = "/index.html"
        }
        // Remove leading slash
        if path.hasPrefix("/") {
            path = String(path.dropFirst())
        }

        // Security: prevent directory traversal
        guard !path.contains("..") else {
            sendError(403, connection: connection)
            return
        }

        let fileURL = wwwURL.appendingPathComponent(path)

        // Check if file exists and is within www directory
        guard FileManager.default.fileExists(atPath: fileURL.path),
              fileURL.path.hasPrefix(wwwURL.path) else {
            sendError(404, connection: connection)
            return
        }

        serveFile(fileURL, connection: connection)
    }

    // MARK: - File Serving

    private func serveFile(_ url: URL, connection: NWConnection) {
        guard let data = try? Data(contentsOf: url) else {
            sendError(500, connection: connection)
            return
        }

        let mime = mimeType(for: url.pathExtension)
        let header = """
        HTTP/1.1 200 OK\r
        Content-Type: \(mime)\r
        Content-Length: \(data.count)\r
        Access-Control-Allow-Origin: *\r
        Cache-Control: no-cache\r
        Connection: close\r
        \r\n
        """

        var headerData = header.data(using: .utf8)!
        headerData.append(data)

        connection.send(content: headerData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    private func sendError(_ code: Int, connection: NWConnection) {
        let msg: String
        switch code {
        case 403: msg = "Forbidden"
        case 404: msg = "Not Found"
        case 405: msg = "Method Not Allowed"
        default: msg = "Internal Server Error"
        }

        let body = "<html><body><h1>\(code) \(msg)</h1></body></html>"
        let header = """
        HTTP/1.1 \(code) \(msg)\r
        Content-Type: text/html\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r\n
        \(body)
        """

        connection.send(content: header.data(using: .utf8)!, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    // MARK: - MIME Types

    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm":   return "text/html; charset=utf-8"
        case "js":            return "application/javascript; charset=utf-8"
        case "mjs":           return "application/javascript; charset=utf-8"
        case "css":           return "text/css; charset=utf-8"
        case "json":          return "application/json; charset=utf-8"
        case "png":           return "image/png"
        case "jpg", "jpeg":   return "image/jpeg"
        case "svg":           return "image/svg+xml"
        case "wasm":          return "application/wasm"
        case "glb":           return "model/gltf-binary"
        case "gltf":          return "model/gltf+json"
        case "bin":           return "application/octet-stream"
        case "ico":           return "image/x-icon"
        case "xml":           return "application/xml"
        case "txt", "md":     return "text/plain; charset=utf-8"
        default:              return "application/octet-stream"
        }
    }
}

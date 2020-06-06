import WebKit

class Icon: NSObject, WKScriptMessageHandler {
    var url: URL? = nil

    private static let sizes: KeyValuePairs = [
          "16":   "16x16",
          "32":   "16x16@2x",
          "32":   "32x32",
          "64":   "32x32@2x",
          "128":  "128x128",
          "256":  "128x128@2x",
          "256":  "256x256",
          "512":  "256x256@2x",
          "512":  "512x512",
          "1024": "512x512@2x",
    ]

    public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["png"]
        openPanel.beginSheetModal(for: Preferences.window) { (result) in
            if let url = openPanel.url,
                   result == NSApplication.ModalResponse.OK {
                self.select(url, message.webView!)
            }
        }
    }

    func select(_ url: URL, _ webView: WKWebView) {
        self.url = url
        webView.evaluateJavaScript("document.getElementById('path').innerText = '\(url.lastPathComponent)'")
    }

    func createSet(resources: URL) throws {
        guard let url = url else {
            return
        }
        let desktop = try FileManager.default
            .url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let tmp = try FileManager.default
            .url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: desktop, create: true)
            .appendingPathComponent("Icon.iconset")
        try FileManager.default
            .createDirectory(at: tmp, withIntermediateDirectories: false)
        for (dimmension, suffix) in Icon.sizes {
            try Process.execute(URL(fileURLWithPath: "/usr/bin/sips"), arguments: [
                "-z", dimmension, dimmension,
                "--out", tmp.appendingPathComponent("icon_\(suffix).png").path,
                url.path,
            ])
        }
        try Process.execute(URL(fileURLWithPath: "/usr/bin/iconutil"), arguments: [
            "-c", "icns",
            "--output", resources.appendingPathComponent("Icon.icns").path,
            tmp.path
        ])
    }
}

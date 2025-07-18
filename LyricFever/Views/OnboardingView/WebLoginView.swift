import SwiftUI
import WebKit

@MainActor
class NavigationState: NSObject, ObservableObject {
    @Published var url: URL?
    let webView: WKWebView
    
    override init() {
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.pageZoom = 0.7
        super.init()
        webView.navigationDelegate = self
    }
}

extension NavigationState: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.url = webView.url
        
        print("url is \(self.url)")
        
        if ((self.url?.absoluteString.starts(with: "https://open.spotify.com")) ?? false) {
            ViewModel.shared.checkIfLoggedIn()
        }
        
        if (self.url?.absoluteString.starts(with: "https://accounts.google.com/") ?? false) {
            print("google link discovered woah \(self.url?.absoluteString ?? "none" )")
            webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15"
        }
    }
}

struct WebView: NSViewRepresentable {
    let request: URLRequest
    @ObservedObject var navigationState: NavigationState
    
    func makeNSView(context: Context) -> WKWebView {
        navigationState.webView.load(request)
        return navigationState.webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
    }
}

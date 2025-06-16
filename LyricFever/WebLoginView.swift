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
            Task {
                await viewModel.shared.checkIfLoggedIn()
            }
        }
//        Task {
//            if await viewModel.shared. == true {
//                await FriendActivityBackend.shared.checkIfLoggedIn()
//            }
//        }
        
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
        // Update code if needed
    }
}

//struct WebviewLogin: View {
//    @StateObject var navigationState = NavigationState()
//
//    var body: some View {
//        VStack {
//            WebView(request: URLRequest(url: URL(string: "https://accounts.spotify.com/en/login?continue=https%3A%2F%2Fopen.spotify.com%2F")!), navigationState: navigationState)
//        }
////        .onAppear() {
////            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
////            print("All cookies deleted")
////
////            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
////                records.forEach { record in
////                    WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
////                    print("Cookie ::: \(record) deleted")
////                }
////            }
////        }
//    }
//}

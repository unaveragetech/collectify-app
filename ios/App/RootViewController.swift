import UIKit
import WebKit
import CollectifyCore

/// The whole app: a WKWebView on http://127.0.0.1:8321 (served by the in-app Swift server) plus a
/// loading screen with a retry button for first-launch catalog setup.
final class RootViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    let services = Services()
    private let bridge = NativeBridge()
    private var webView: WKWebView?

    private let loadingStack = UIStackView()
    private let loadingLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let retryButton = UIButton(type: .system)

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        buildLoadingUI()
        startServicesAndLoad()
    }

    // ---------------------------------------------------------------- loading UI

    private func buildLoadingUI() {
        let title = UILabel()
        title.text = "Collectify"
        title.font = .systemFont(ofSize: 30, weight: .bold)
        title.textColor = Theme.gold
        loadingLabel.text = "Starting…"
        loadingLabel.textColor = UIColor(white: 0.75, alpha: 1)
        loadingLabel.font = .systemFont(ofSize: 15)
        loadingLabel.numberOfLines = 0
        loadingLabel.textAlignment = .center
        spinner.color = Theme.gold
        spinner.startAnimating()
        retryButton.setTitle("Retry", for: .normal)
        retryButton.setTitleColor(.black, for: .normal)
        retryButton.backgroundColor = Theme.gold
        retryButton.layer.cornerRadius = 10
        retryButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 28, bottom: 10, right: 28)
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        loadingStack.axis = .vertical
        loadingStack.alignment = .center
        loadingStack.spacing = 18
        [title, spinner, loadingLabel, retryButton].forEach { loadingStack.addArrangedSubview($0) }
        loadingStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingStack)
        NSLayoutConstraint.activate([
            loadingStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 28),
            loadingStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -28),
        ])
    }

    private func showLoading(_ text: String, failed: Bool = false) {
        DispatchQueue.main.async {
            self.loadingStack.isHidden = false
            self.loadingLabel.text = text
            self.spinner.isHidden = failed
            self.retryButton.isHidden = !failed
        }
    }

    @objc private func retryTapped() { startServicesAndLoad() }

    // ---------------------------------------------------------------- startup

    private func startServicesAndLoad() {
        showLoading("Setting up the card catalog…")
        if services.isReady {
            loadPage()
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.services.start { text in self.showLoading(text) }
                // notification state is baked into the page's JS shim so canNotify() can answer synchronously
                let sem = DispatchSemaphore(value: 0)
                var granted = false
                Reminders.shared.isAuthorized { granted = $0; sem.signal() }
                _ = sem.wait(timeout: .now() + 2)
                DispatchQueue.main.async {
                    self.buildWebView(notifyGranted: granted)
                    self.loadPage()
                }
            } catch {
                self.showLoading("Couldn't set up the card catalog on this device: \(error)\n\nThis usually means the device ran low on storage during first-time setup. Retry picks up where it left off.", failed: true)
            }
        }
    }

    private func buildWebView(notifyGranted: Bool) {
        if webView != nil { return }
        let info = Bundle.main.infoDictionary ?? [:]
        let version = (info["CFBundleShortVersionString"] as? String) ?? "0"
        let build = Int((info["CFBundleVersion"] as? String) ?? "0") ?? 0
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        let ucc = WKUserContentController()
        ucc.addUserScript(WKUserScript(source: NativeBridge.shimScript(versionName: version, build: build, notifyGranted: notifyGranted), injectionTime: .atDocumentStart, forMainFrameOnly: true))
        ucc.add(bridge, name: NativeBridge.messageName)
        cfg.userContentController = ucc
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.uiDelegate = self
        wv.navigationDelegate = self
        wv.isOpaque = false
        wv.backgroundColor = Theme.background
        wv.scrollView.backgroundColor = Theme.background
        wv.scrollView.contentInsetAdjustmentBehavior = .never
        wv.scrollView.bounces = false
        wv.scrollView.minimumZoomScale = 1
        wv.scrollView.maximumZoomScale = 1
        wv.allowsBackForwardNavigationGestures = false
        #if DEBUG
        if #available(iOS 16.4, *) { wv.isInspectable = true }
        #endif
        wv.translatesAutoresizingMaskIntoConstraints = false
        wv.isHidden = true
        view.addSubview(wv)
        // stay inside the notch / home-indicator areas: the page has no safe-area handling of its own
        NSLayoutConstraint.activate([
            wv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            wv.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            wv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        bridge.webView = wv
        webView = wv
    }

    private func loadPage() {
        webView?.load(URLRequest(url: Services.baseURL, cachePolicy: .reloadIgnoringLocalCacheData))
    }

    // ---------------------------------------------------------------- WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.isHidden = false
        loadingStack.isHidden = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webView.isHidden = true
        showLoading("Couldn't load the local server (\((error as NSError).code)).", failed: true)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // iOS killed the web process (memory): bring the page back instead of showing a blank view
        services.ensureRunning()
        loadPage()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
        if url.host == "127.0.0.1" || url.scheme == "about" || url.scheme == "blob" || url.scheme == "data" { return decisionHandler(.allow) }
        // anything else is not part of the app: only the project's own pages may open, in Safari
        if NativeBridge.isAllowedExternal(url) { UIApplication.shared.open(url) }
        decisionHandler(.cancel)
    }

    // ---------------------------------------------------------------- WKUIDelegate

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        // camera only, and only for the app's own page (iOS shows its own camera permission prompt)
        decisionHandler(origin.host == "127.0.0.1" && type == .camera ? .grant : .deny)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, NativeBridge.isAllowedExternal(url) { UIApplication.shared.open(url) }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(a, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(a, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let a = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        a.addTextField { $0.text = defaultText }
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(a.textFields?.first?.text) })
        present(a, animated: true)
    }
}

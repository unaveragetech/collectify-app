import UIKit
import WebKit

/// iOS counterpart of Android's `CollectifyNative` JavascriptInterface. WKWebView can't expose
/// synchronous native methods, so the page gets a small shim (injected before any page script) with
/// the same method names: simple answers are computed in JS, side effects are posted back as messages.
final class NativeBridge: NSObject, WKScriptMessageHandler {
    static let messageName = "collectify"

    /// Same allow-list as the Android bridge: only the project's own GitHub pages may be opened.
    static func isAllowedExternal(_ url: URL) -> Bool {
        guard url.scheme == "https", let host = url.host else { return false }
        return host == "unaveragetech.github.io" || (host == "github.com" && url.path.hasPrefix("/unaveragetech/"))
    }

    static func shimScript(versionName: String, build: Int, notifyGranted: Bool) -> String {
        let info = "{\"versionName\":\"\(versionName)\",\"versionCode\":\(build),\"package\":\"com.collectify.app\",\"platform\":\"ios\"}"
        return """
        (function () {
          var post = function (o) { try { window.webkit.messageHandlers.\(messageName).postMessage(o); } catch (e) {} };
          window.__collectifyNotify = \(notifyGranted ? "true" : "false");
          window.CollectifyNative = {
            platform: "ios",
            openUrl: function (url) {
              try {
                var u = new URL(url);
                var ok = u.protocol === "https:" && (u.hostname === "unaveragetech.github.io" || (u.hostname === "github.com" && u.pathname.indexOf("/unaveragetech/") === 0));
                if (!ok) return false;
                post({ cmd: "open", url: url });
                return true;
              } catch (e) { return false; }
            },
            canNotify: function () { return !!window.__collectifyNotify; },
            requestNotifyPermission: function () { post({ cmd: "notifyPermission" }); },
            scheduleReminder: function (id, atMs, title, text) { post({ cmd: "schedule", id: id, at: atMs, title: String(title), text: String(text) }); },
            cancelReminders: function () { post({ cmd: "cancel" }); },
            info: function () { return '\(info)'; },
            // iOS doesn't let an app read its own installed package, so there is no checksum to compare
            apkSha256: function () { return ""; }
          };
        })();
        """
    }

    weak var webView: WKWebView?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let cmd = body["cmd"] as? String else { return }
        switch cmd {
        case "open":
            if let s = body["url"] as? String, let u = URL(string: s), NativeBridge.isAllowedExternal(u) {
                DispatchQueue.main.async { UIApplication.shared.open(u) }
            }
        case "notifyPermission":
            Reminders.shared.requestPermission { [weak self] granted in
                DispatchQueue.main.async { self?.webView?.evaluateJavaScript("window.__collectifyNotify = \(granted ? "true" : "false")", completionHandler: nil) }
            }
        case "schedule":
            guard let id = (body["id"] as? NSNumber)?.intValue, let at = (body["at"] as? NSNumber)?.doubleValue else { return }
            Reminders.shared.schedule(id: id, atMs: at, title: (body["title"] as? String) ?? "Collectify", text: (body["text"] as? String) ?? "")
        case "cancel":
            Reminders.shared.cancelAll()
        default:
            break
        }
    }
}

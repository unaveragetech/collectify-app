// Shared bits for every page of the Collectify site: header, footer, release data and a tiny markdown renderer.
(function () {
  var REPO = "https://github.com/unaveragetech/collectify-app";
  var PAGES = [["index.html", "Home"], ["features.html", "Features"], ["install.html", "Install"], ["changelog.html", "Changelog"], ["about.html", "About"]];
  var here = (location.pathname.split("/").pop() || "index.html").toLowerCase();

  var head = document.getElementById("site-header");
  if (head) {
    head.className = "top";
    head.innerHTML =
      '<div class="wrap"><a class="brand" href="index.html"><span class="mark">♠</span> Collectify</a>' +
      '<button class="menu-btn" aria-label="Menu" id="menu-btn">☰</button>' +
      '<nav class="main" id="main-nav">' +
      PAGES.map(function (p) { return '<a href="' + p[0] + '"' + (here === p[0] ? ' class="on"' : "") + ">" + p[1] + "</a>"; }).join("") +
      '<a class="dl" href="install.html#download">Download</a></nav></div>';
    document.getElementById("menu-btn").addEventListener("click", function () { document.getElementById("main-nav").classList.toggle("open"); });
  }
  var foot = document.getElementById("site-footer");
  if (foot) {
    foot.innerHTML =
      '<div class="wrap"><div class="cols"><div><b style="color:var(--text)">Collectify</b><br>Unofficial fan-made collector\'s tool.<br>Prices are estimates, not financial advice.<br>Not affiliated with TCGplayer, The Pokémon Company, Wizards of the Coast, Konami or any other publisher.</div>' +
      '<div class="links"><a href="features.html">Features</a><a href="install.html">Install on Android &amp; iPhone</a><a href="changelog.html">Changelog</a><a href="about.html">About &amp; privacy</a></div>' +
      '<div class="links"><a href="' + REPO + '/releases">All releases on GitHub</a><a href="' + REPO + '/issues">Report a problem</a><a href="releases.json">releases.json</a></div></div></div>';
  }

  window.Site = {
    REPO: REPO,
    fmtSize: function (n) { return (n / 1048576).toFixed(0) + " MB"; },
    fmtDate: function (s) { try { return new Date(s).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" }); } catch (e) { return ""; } },
    esc: function (s) { return String(s).replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; }); },
    releases: function () {
      if (!window.__rel) window.__rel = fetch("releases.json", { cache: "no-store" }).then(function (r) { return r.json(); }).then(function (d) { return d.releases || []; });
      return window.__rel;
    },
    // very small markdown: ## / ### headings, - lists, **bold**, `code`, [links](url), paragraphs
    md: function (src) {
      var esc = window.Site.esc;
      function inline(t) {
        return esc(t)
          .replace(/`([^`]+)`/g, "<code>$1</code>")
          .replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>")
          .replace(/\[([^\]]+)\]\((https?:[^)]+)\)/g, '<a href="$2" rel="noopener">$1</a>');
      }
      var out = [], list = false, para = [];
      function flush() { if (para.length) { out.push("<p>" + inline(para.join(" ")) + "</p>"); para = []; } }
      function close() { if (list) { out.push("</ul>"); list = false; } }
      String(src || "").split(/\r?\n/).forEach(function (line) {
        var m;
        if ((m = line.match(/^#{1,2}\s+(.*)/)) && !/^#{3}/.test(line)) { flush(); close(); return; } // the release title repeats the header
        if ((m = line.match(/^#{3,4}\s+(.*)/))) { flush(); close(); out.push("<h3>" + inline(m[1]) + "</h3>"); return; }
        if ((m = line.match(/^\s*[-*]\s+(.*)/))) { flush(); if (!list) { out.push("<ul>"); list = true; } out.push("<li>" + inline(m[1]) + "</li>"); return; }
        if (!line.trim()) { flush(); close(); return; }
        if (list && /^\s{2,}\S/.test(line)) { out[out.length - 1] = out[out.length - 1].replace(/<\/li>$/, " " + inline(line.trim()) + "</li>"); return; }
        close(); para.push(line.trim());
      });
      flush(); close();
      return out.join("");
    },
    copyButtons: function (root) {
      (root || document).querySelectorAll("button.copy").forEach(function (b) {
        b.addEventListener("click", function () { navigator.clipboard && navigator.clipboard.writeText(b.dataset.h); b.textContent = "copied"; setTimeout(function () { b.textContent = "copy"; }, 1200); });
      });
    },
  };
})();

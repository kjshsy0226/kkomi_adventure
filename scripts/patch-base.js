// scripts/patch-base.js
const fs = require("fs");
const path = require("path");

const indexPath = path.join(__dirname, "..", "build", "web", "index.html");
let html = fs.readFileSync(indexPath, "utf8");

// <base href="/"> -> <base href="./">
html = html.replace(/<base\s+href="\/"\s*\/?>/i, '<base href="./">');

fs.writeFileSync(indexPath, html, "utf8");
console.log('[patch-base] Rewrote <base href> to "./" in build/web/index.html');

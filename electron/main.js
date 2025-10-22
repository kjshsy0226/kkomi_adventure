// electron/main.js
const { app, BrowserWindow, shell } = require("electron");
const path = require("path");

function createWindow() {
  const win = new BrowserWindow({
    width: 1280,
    height: 720,
    show: false,
    autoHideMenuBar: true,
    backgroundColor: "#000000",
    webPreferences: {
      contextIsolation: true,
      sandbox: true,
      preload: path.join(__dirname, "preload.js"),
    },
  });

  const webDir = app.isPackaged
    ? path.join(process.resourcesPath, "app", "web") // 패키지 후 경로
    : path.join(__dirname, "build", "web"); // 개발 시 경로 (electron/build/web이 아니라 __dirname 기준!)
  // 개발 시 __dirname = <프로젝트>/electron

  const indexPath = path.join(webDir, "index.html");
  console.log("[Electron] loading:", indexPath);
  win.loadFile(indexPath);

  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: "deny" };
  });

  win.once("ready-to-show", () => win.show());
  // 디버깅 원하면 ↓ 주석 해제
  // win.webContents.openDevTools();
}

app.whenReady().then(() => {
  createWindow();
  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});
app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});

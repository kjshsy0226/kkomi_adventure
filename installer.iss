; installer.iss — Kkomi Adventure (Flutter Windows)
#define AppName "Kkomi Adventure"
#define AppVersion "1.0.0"
#define Publisher "Luke"
#define ExeName "kkomi_adventure.exe"
#define BuildDir "build\\windows\\x64\\runner\\Release"

[Setup]
AppId={{3C4F5B6E-2A6E-4C12-9F6F-12D5B7F0A1A1}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#Publisher}
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
OutputBaseFilename={#AppName}_Setup_{#AppVersion}
OutputDir=dist
Compression=lzma2/max
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern
SetupIconFile=assets\installer.ico
UninstallDisplayIcon={app}\{#ExeName}
DisableDirPage=no
DisableProgramGroupPage=no
PrivilegesRequired=admin

[Languages]
Name: "korean";  MessagesFile: "compiler:Languages\Korean.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; 앱 본체 (Release)
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

; VC++ 런타임 인스톨러
Source: "redist\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
; VC++ 런타임 자동 설치
Filename: "{tmp}\vc_redist.x64.exe"; \
    Parameters: "/install /quiet /norestart"; \
    StatusMsg: "필수 구성요소(Visual C++ 런타임)를 설치하는 중입니다..."; \
    Flags: waituntilterminated

; 앱 실행
Filename: "{app}\{#ExeName}"; \
    Description: "{cm:LaunchProgram,{#AppName}}"; \
    Flags: nowait postinstall skipifsilent

[Icons]
Name: "{group}\{#AppName}";       Filename: "{app}\{#ExeName}"
Name: "{commondesktop}\{#AppName}"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

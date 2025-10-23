; installer.iss — Kkomi Adventure (Flutter Windows) 설치 스크립트 예시
#define AppName "Kkomi Adventure"
#define AppVersion "1.0.0"
#define Publisher "I-DESIGN-LAB"
#define ExeName "kkomi_adventure.exe"
#define BuildDir "build\\windows\\x64\\runner\\Release"

[Setup]
AppId={{A5B8B0D1-3E0E-4B7D-9A7D-FA2E7B2BDE11}   ; 새 GUID로 바꾸세요
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
SetupIconFile=assets\installer.ico
UninstallDisplayIcon={app}\{#ExeName}
DisableDirPage=no
DisableProgramGroupPage=no
WizardStyle=modern
; (코드서명 사용 시 Inno Setup의 SignTool 설정을 추가할 수 있음)

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
; (선택) VC++ 재배포 패키지 포함 시:
; Source: "third_party\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#ExeName}"
Name: "{commondesktop}\{#AppName}"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

[Run]
; 설치 완료 후 바로 실행 체크박스
Filename: "{app}\{#ExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

; (선택) VC++ 재배포 패키지 선행 설치
; Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; Flags: waituntilterminated; StatusMsg: "Installing VC++ Runtime..."

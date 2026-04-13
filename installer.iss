#define MyAppName "BillKaro ChillKaro"
#define MyAppVersion "1.0.0"
#define MyAppExeName "BillKaro-ChillKaro.exe"
#define BuildOutput "build\windows\x64\runner\Release"

[Setup]
AppId={{B9F8A7C6-1234-5678-9ABC-DEF012345678}
AppName={#MyAppName}
AppVersion={#MyAppVersion}

DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}

OutputDir=installer_output
OutputBaseFilename=BillKaro_Setup

Compression=lzma
SolidCompression=no

WizardStyle=modern

PrivilegesRequired=admin

ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

; ✅ IMPORTANT FIX
UninstallDisplayIcon={sys}\shell32.dll

CloseApplications=yes
RestartApplications=no


[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"


[Files]
Source: "{#BuildOutput}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion


[Icons]
Name: "{group}\BillKaro"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall BillKaro"; Filename: "{uninstallexe}"
Name: "{autodesktop}\BillKaro"; Filename: "{app}\{#MyAppExeName}"


[Run]
Filename: "{app}\{#MyAppExeName}"; Flags: nowait postinstall skipifsilent
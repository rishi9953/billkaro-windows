#define MyAppName "BillKaro ChillKaro"
#define MyAppVersion "1.0.0"
#define MyAppExeName "billkaro_windows.exe"
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

UninstallDisplayIcon={app}\{#MyAppExeName}

CloseApplications=yes
RestartApplications=no


[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"


[Files]
Source: "{#BuildOutput}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion; Excludes: "*.pdb,*.lib,*.exp"
Source: "{#BuildOutput}\data\flutter_assets\.env"; DestDir: "{app}\data\flutter_assets"; Flags: ignoreversion skipifsourcedoesntexist


[Icons]
Name: "{group}\BillKaro"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\Uninstall BillKaro"; Filename: "{uninstallexe}"
Name: "{autodesktop}\BillKaro"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"


[Run]
Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent skipifdoesntexist

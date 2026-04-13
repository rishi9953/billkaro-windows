#define MyAppName "BillKaro ChillKaro"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Ace One Universal Pvt Ltd"
#define MyAppURL "https://billkrochillkro.com/"
#define MyAppExeName "billkaro_windows.exe"
#define MyProjectRoot ".."
#define MyBuildDir AddBackslash(MyProjectRoot) + "build\windows\x64\runner\Release"
#define MyOutputDir AddBackslash(MyProjectRoot) + "Installers"
#define MyIconPath AddBackslash(MyProjectRoot) + "windows\runner\resources\app_icon.ico"

[Setup]
AppId={{4670F8C2-9250-4753-B1EB-414267FFD1A1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
PrivilegesRequired=admin
OutputDir={#MyOutputDir}
OutputBaseFilename=BillKaro_Setup
SetupIconFile={#MyIconPath}
Compression=lzma
SolidCompression=no
WizardStyle=modern dynamic
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MyBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.pdb,*.lib,*.exp"
Source: "{#MyBuildDir}\data\flutter_assets\.env"; DestDir: "{app}\data\flutter_assets"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent skipifdoesntexist


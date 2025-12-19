[Setup]
AppName=Pinheiro Society
AppVersion=1.0
DefaultDirName={autopf}\Pinheiro Society
OutputBaseFilename=InstaladorWindows
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
OutputDir=Output

[Files]
; Packages the entire Release folder contents (exe, dlls, data)
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Pinheiro Society"; Filename: "{app}\pinheirosociety.exe"
Name: "{autodesktop}\Pinheiro Society"; Filename: "{app}\pinheirosociety.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

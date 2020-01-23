#include "config.txt"
[Setup]
PrivilegesRequired=admin
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
DisableDirPage=true
DefaultDirName={pf}\InnoSetupTemplate
DefaultGroupName=InnoSetupTemplate
Compression=lzma2
SolidCompression=yes               
OutputDir=output\setup
OutputBaseFilename=InnoSetupTemplateInstaller
; SetupIconFile=innoSetupTemplate.ico
; ChangesEnvironment=yes 
; "ArchitecturesInstallIn64BitMode=x64" requests that the install be
; done in "64-bit mode" on x64, meaning it should use the native
; 64-bit Program Files directory and the 64-bit view of the registry.
; On all other architectures it will install in "32-bit mode".
ArchitecturesInstallIn64BitMode=x64
; Note: We don't set ProcessorsAllowed because we want this
; installation to run on all architectures (including Itanium,
; since it's capable of running 32-bit code too).

[Files]   
; JRE
Source: "cots\jre-8u221-x64.exe"; DestDir: "{tmp}"; DestName: "JREInstall.exe"; Check: IsWin64 AND InstallJava(); Flags: deleteafterinstall
; VcRedist
Source: "cots\vcredist_x64.exe"; DestDir: "{tmp}"; DestName: "VcRedist.exe"; Flags: deleteafterinstall

Source: "cots\mysql-5.7.27-winx64\**"; DestDir: "{app}\mysql"; Flags: ignoreversion recursesubdirs createallsubdirs

Source: "cots\apache-tomcat-8.5.46-x64\**"; DestDir: "{app}\tomcat"; Flags: ignoreversion recursesubdirs createallsubdirs
 
Source: "cots\apache-tomcat-8.5.46-x64\conf\**"; DestDir: "C:\ProgramData\InnoSetupTemplate\Tomcat\conf";

Source: "app\Sample.war"; DestDir: "C:\ProgramData\InnoSetupTemplate\Tomcat\webapps";

Source: "app\start.bat"; DestDir: "{app}"; DestName: "start.bat";

Source: "app\stop.bat"; DestDir: "{app}"; DestName: "stop.bat";

Source: "app\sample-database-dump.bat"; DestDir: "{app}";

Source: "initial-scripts\sample-tomcat-config.bat"; DestDir: "{tmp}"; DestName: "sample-tomcat-config.bat"; Flags: deleteafterinstall

Source: "initial-scripts\sample-database-dump.sql"; DestDir: "{app}"; Flags: deleteafterinstall;

Source: "initial-scripts\mysql-database-initializer.bat"; DestDir: "{tmp}"; Flags: deleteafterinstall;


[Dirs]
Name: "C:\ProgramData\InnoSetupTemplate\Backup"
Name: "C:\ProgramData\InnoSetupTemplate\MySQL"
Name: "C:\ProgramData\InnoSetupTemplate\MySQL\Data"
Name: "C:\ProgramData\InnoSetupTemplate\MySQL\Uploads"
Name: "C:\ProgramData\InnoSetupTemplate\Tomcat\bin"
Name: "C:\ProgramData\InnoSetupTemplate\Tomcat\conf"
Name: "C:\ProgramData\InnoSetupTemplate\Tomcat\lib"
Name: "C:\ProgramData\InnoSetupTemplate\Tomcat\logs" 
Name: "C:\ProgramData\InnoSetupTemplate\Tomcat\temp"
Name: "C:\ProgramData\InnoSetupTemplate\Tomcat\webapps"
Name: "C:\ProgramData\InnoSetupTemplate\Tomcat\work"

[Icons]    
Name: "{group}\Start InnoSetupTemplate"; Filename: "{app}\start.bat"
Name: "{group}\Stop InnoSetupTemplate"; Filename: "{app}\stop.bat"

[Run]
; install JRE
Filename: "{tmp}\JREInstall.exe"; Parameters: "/s"; Flags: nowait runhidden runascurrentuser; Check: InstallJava()

; install VcRedist
Filename: "{tmp}\VcRedist.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: Installing VcRedist... ; Check: VCRedistNeedsInstall; Flags: runhidden

; install mysql and tomcat as services
Filename: "{app}\mysql\bin\mysqld.exe"; Parameters: "--install InnoSetupTemplate_MySQL --defaults-file=""{app}\mysql\my.ini"""; StatusMsg: Installing MySQL...; Flags: runhidden
Filename: "{app}\mysql\bin\mysqld.exe"; Parameters: "--initialize-insecure "; StatusMsg:  Initializing MySQL Data...; Flags: runhidden
Filename: "{sys}\cmd.exe"; Parameters: "/c ""{tmp}\sample-tomcat-config.bat"""; StatusMsg:  Installing Tomcat Service...; Flags: runascurrentuser runhidden

Filename: "{sys}\sc.exe"; Parameters: "config InnoSetupTemplate_Tomcat depend= InnoSetupTemplate_MySQL start= auto" ; Flags: runhidden

Filename: "{sys}\net.exe"; Parameters: "start InnoSetupTemplate_MySQL" ; StatusMsg: Starting MySQL Service... ; Flags: waituntilterminated runhidden
Filename: "{sys}\cmd.exe"; Parameters: "/c ""{tmp}\mysql-database-initializer.bat"""; StatusMsg: Initializing MySQL Database... ; Flags: waituntilterminated runhidden
Filename: "{sys}\net.exe"; Parameters: "start InnoSetupTemplate_Tomcat" ; StatusMsg: Starting Tomcat Service... ; Flags: waituntilterminated runhidden

Filename: http://localhost:8080/InnoSetupTemplate/; Description: {cm:LaunchProgram,{cm:AppName}}; Flags: postinstall shellexec


[UninstallRun]                                                                                                                  
Filename: "{app}\mysql-database-dump.bat"; Parameters: "sample-username sample-password sample-database"; StatusMsg: Backup MySQL Database... ; Flags: waituntilterminated runhidden;   
Filename: "{app}\stop.bat"; Flags: runascurrentuser waituntilterminated 
Filename: "{app}\mysql\bin\mysqld.exe"; Parameters: "--remove InnoSetupTemplate_MySQL"; Flags: runascurrentuser 
Filename: "{app}\tomcat\bin\tomcat8.exe"; Parameters: "//DS//InnoSetupTemplate_Tomcat"; Flags: runascurrentuser

[InstallDelete]
Type: filesandordirs; Name: "{app}\tomcat\webapps\**"
Type: filesandordirs; Name: "{app}\tomcat\conf\**"

[UninstallDelete]
Type: filesandordirs; Name: "C:\ProgramData\InnoSetupTemplate"; 
Type: filesandordirs; Name: "{app}"

;[Registry]
; set PATH
;Root: HKCU; Subkey: "Environment"; ValueType:string; ValueName:"JRE_HOME"; ValueData: "C:\Program Files\Java\jre1.8.0_221"; Flags: preservestringtype
; Root: HKCU; Subkey: "Environment"; ValueType:string; ValueName:"CATALINA_HOME"; ValueData:"{app}\tomcat"; Flags: preservestringtype

[CustomMessages]
AppName=InnoSetupTemplate
LaunchProgram=Start InnoSetupTemplate after finishing installation

[Code]
// Check Java
procedure DecodeVersion(verstr: String; var verint: array of Integer);
var
  i,p: Integer; s: string;
begin
  { initialize array }
  verint := [0,0,0,0];
  i := 0;
  while ((Length(verstr) > 0) and (i < 4)) do
  begin
    p := pos ('.', verstr);
    if p > 0 then
    begin
      if p = 1 then s:= '0' else s:= Copy (verstr, 1, p - 1);
      verint[i] := StrToInt(s);
      i := i + 1;
      verstr := Copy (verstr, p+1, Length(verstr));
    end
    else
    begin
      verint[i] := StrToInt (verstr);
      verstr := '';
    end;
  end;
end;

function CompareVersion (ver1, ver2: String) : Integer;
var
  verint1, verint2: array of Integer;
  i: integer;
begin
  SetArrayLength (verint1, 4);
  DecodeVersion (ver1, verint1);

  SetArrayLength (verint2, 4);
  DecodeVersion (ver2, verint2);

  Result := 0; i := 0;
  while ((Result = 0) and ( i < 4 )) do
  begin
    if verint1[i] > verint2[i] then
      Result := 1
    else
      if verint1[i] < verint2[i] then
        Result := -1
      else
        Result := 0;
    i := i + 1;
  end;
end;

function InstallJava() : Boolean;
var
  ErrCode: Integer;
  JVer: String;
  InstallJ: Boolean;
begin
  RegQueryStringValue(
    HKLM, 'SOFTWARE\JavaSoft\Java Runtime Environment', 'CurrentVersion', JVer);
  InstallJ := true;
  if Length( JVer ) > 0 then
  begin
    if CompareVersion(JVer, '1.8') >= 0 then
    begin
      InstallJ := false;
    end;
  end;
  Result := InstallJ;
end;

// Check VcRedist
#IFDEF UNICODE
  #DEFINE AW "W"
#ELSE
  #DEFINE AW "A"
#ENDIF
type
  INSTALLSTATE = Longint;
const
  INSTALLSTATE_INVALIDARG = -2;  { An invalid parameter was passed to the function. }
  INSTALLSTATE_UNKNOWN = -1;     { The product is neither advertised or installed. }
  INSTALLSTATE_ADVERTISED = 1;   { The product is advertised but not installed. }
  INSTALLSTATE_ABSENT = 2;       { The product is installed for a different user. }
  INSTALLSTATE_DEFAULT = 5;      { The product is installed for the current user. }

  VC_2005_REDIST_X86 = '{A49F249F-0C91-497F-86DF-B2585E8E76B7}';
  VC_2005_REDIST_X64 = '{6E8E85E8-CE4B-4FF5-91F7-04999C9FAE6A}';
  VC_2005_REDIST_IA64 = '{03ED71EA-F531-4927-AABD-1C31BCE8E187}';
  VC_2005_SP1_REDIST_X86 = '{7299052B-02A4-4627-81F2-1818DA5D550D}';
  VC_2005_SP1_REDIST_X64 = '{071C9B48-7C32-4621-A0AC-3F809523288F}';
  VC_2005_SP1_REDIST_IA64 = '{0F8FB34E-675E-42ED-850B-29D98C2ECE08}';
  VC_2005_SP1_ATL_SEC_UPD_REDIST_X86 = '{837B34E3-7C30-493C-8F6A-2B0F04E2912C}';
  VC_2005_SP1_ATL_SEC_UPD_REDIST_X64 = '{6CE5BAE9-D3CA-4B99-891A-1DC6C118A5FC}';
  VC_2005_SP1_ATL_SEC_UPD_REDIST_IA64 = '{85025851-A784-46D8-950D-05CB3CA43A13}';

  VC_2008_REDIST_X86 = '{FF66E9F6-83E7-3A3E-AF14-8DE9A809A6A4}';
  VC_2008_REDIST_X64 = '{350AA351-21FA-3270-8B7A-835434E766AD}';
  VC_2008_REDIST_IA64 = '{2B547B43-DB50-3139-9EBE-37D419E0F5FA}';
  VC_2008_SP1_REDIST_X86 = '{9A25302D-30C0-39D9-BD6F-21E6EC160475}';
  VC_2008_SP1_REDIST_X64 = '{8220EEFE-38CD-377E-8595-13398D740ACE}';
  VC_2008_SP1_REDIST_IA64 = '{5827ECE1-AEB0-328E-B813-6FC68622C1F9}';
  VC_2008_SP1_ATL_SEC_UPD_REDIST_X86 = '{1F1C2DFC-2D24-3E06-BCB8-725134ADF989}';
  VC_2008_SP1_ATL_SEC_UPD_REDIST_X64 = '{4B6C7001-C7D6-3710-913E-5BC23FCE91E6}';
  VC_2008_SP1_ATL_SEC_UPD_REDIST_IA64 = '{977AD349-C2A8-39DD-9273-285C08987C7B}';
  VC_2008_SP1_MFC_SEC_UPD_REDIST_X86 = '{9BE518E6-ECC6-35A9-88E4-87755C07200F}';
  VC_2008_SP1_MFC_SEC_UPD_REDIST_X64 = '{5FCE6D76-F5DC-37AB-B2B8-22AB8CEDB1D4}';
  VC_2008_SP1_MFC_SEC_UPD_REDIST_IA64 = '{515643D1-4E9E-342F-A75A-D1F16448DC04}';

  VC_2010_REDIST_X86 = '{196BB40D-1578-3D01-B289-BEFC77A11A1E}';
  VC_2010_REDIST_X64 = '{DA5E371C-6333-3D8A-93A4-6FD5B20BCC6E}';
  VC_2010_REDIST_IA64 = '{C1A35166-4301-38E9-BA67-02823AD72A1B}';
  VC_2010_SP1_REDIST_X86 = '{F0C3E5D1-1ADE-321E-8167-68EF0DE699A5}';
  VC_2010_SP1_REDIST_X64 = '{1D8E6291-B0D5-35EC-8441-6616F567A0F7}';
  VC_2010_SP1_REDIST_IA64 = '{88C73C1C-2DE5-3B01-AFB8-B46EF4AB41CD}';

  { Microsoft Visual C++ 2012 x86 Minimum Runtime - 11.0.61030.0 (Update 4) }
  VC_2012_REDIST_MIN_UPD4_X86 = '{BD95A8CD-1D9F-35AD-981A-3E7925026EBB}';
  VC_2012_REDIST_MIN_UPD4_X64 = '{CF2BEA3C-26EA-32F8-AA9B-331F7E34BA97}';
  { Microsoft Visual C++ 2012 x86 Additional Runtime - 11.0.61030.0 (Update 4)  }
  VC_2012_REDIST_ADD_UPD4_X86 = '{B175520C-86A2-35A7-8619-86DC379688B9}';
  VC_2012_REDIST_ADD_UPD4_X64 = '{37B8F9C7-03FB-3253-8781-2517C99D7C00}';

  { Visual C++ 2013 Redistributable 12.0.21005 }
  VC_2013_REDIST_X86_MIN = '{13A4EE12-23EA-3371-91EE-EFB36DDFFF3E}';
  VC_2013_REDIST_X64_MIN = '{A749D8E6-B613-3BE3-8F5F-045C84EBA29B}';

  VC_2013_REDIST_X86_ADD = '{F8CFEB22-A2E7-3971-9EDA-4B11EDEFC185}';
  VC_2013_REDIST_X64_ADD = '{929FBD26-9020-399B-9A7A-751D61F0B942}';

  { Visual C++ 2015 Redistributable 14.0.23026 }
  VC_2015_REDIST_X86_MIN = '{A2563E55-3BEC-3828-8D67-E5E8B9E8B675}';
  VC_2015_REDIST_X64_MIN = '{0D3E9E15-DE7A-300B-96F1-B4AF12B96488}';

  VC_2015_REDIST_X86_ADD = '{BE960C1C-7BAD-3DE6-8B1A-2616FE532845}';
  VC_2015_REDIST_X64_ADD = '{BC958BD2-5DAC-3862-BB1A-C1BE0790438D}';

  { Visual C++ 2015 Redistributable 14.0.24210 }
  VC_2015_REDIST_X86 = '{8FD71E98-EE44-3844-9DAD-9CB0BBBC603C}';
  VC_2015_REDIST_X64 = '{C0B2C673-ECAA-372D-94E5-E89440D087AD}';

function MsiQueryProductState(szProduct: string): INSTALLSTATE; 
  external 'MsiQueryProductState{#AW}@msi.dll stdcall';

function VCVersionInstalled(const ProductID: string): Boolean;
begin
  Result := MsiQueryProductState(ProductID) = INSTALLSTATE_DEFAULT;
end;

function VCRedistNeedsInstall: Boolean;
begin
  { here the Result must be True when you need to install your VCRedist }
  { or False when you don't need to, so now it's upon you how you build }
  { this statement, the following won't install your VC redist only when }
  { the Visual C++ 2010 Redist (x86) and Visual C++ 2010 SP1 Redist(x86) }
  { are installed for the current user }
  Result := not (VCVersionInstalled(VC_2013_REDIST_X64_MIN));
end;


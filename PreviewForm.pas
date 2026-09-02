unit PreviewForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  SynEdit, SynEditWrappedView,
  SynHighlighterPas, SynHighlighterPython, SynHighlighterXML, SynHighlighterHTML,
  SynHighlighterCSS, SynHighlighterJScript, SynHighlighterPHP, SynHighlighterCpp,
  SynHighlighterJava, SynHighlighterSQL, SynHighlighterBat, SynHighlighterIni,
  SynHighlighterDiff, SynHighlighterUnixShellScript, SynHighlighterPerl, SynHighlighterVB,
  LConvEncoding;

type

  { TfrmPreview }

  TfrmPreview = class(TForm)
    pnlTop: TPanel;
    lblFileName: TLabel;
    lblFileMeta: TLabel;
    btnOpenInNotepad: TButton;
    btnClose: TButton;

    pnlContent: TPanel;
    pnlImage: TPanel;
    imgPreview: TImage;
    lblImageDetails: TLabel;

    synPreview: TSynEdit;

    pnlInfo: TPanel;
    imgIcon: TImage;
    lblInfoName: TLabel;
    lblInfoType: TLabel;
    lblInfoSize: TLabel;
    lblInfoModified: TLabel;
    lblHexTitle: TLabel;
    memHex: TMemo;

    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnOpenInNotepadClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);

  private
    FCurrentPath: string;
    FDarkMode: Boolean;
    FWrapPlugin: TLazSynEditLineWrapPlugin;

    FHighlighterPas: TSynPasSyn;
    FHighlighterPython: TSynPythonSyn;
    FHighlighterXML: TSynXMLSyn;
    FHighlighterHTML: TSynHTMLSyn;
    FHighlighterPHP: TSynPHPSyn;
    FHighlighterCSS: TSynCssSyn;
    FHighlighterJS: TSynJScriptSyn;
    FHighlighterCpp: TSynCppSyn;
    FHighlighterJava: TSynJavaSyn;
    FHighlighterSQL: TSynSQLSyn;
    FHighlighterBat: TSynBatSyn;
    FHighlighterIni: TSynIniSyn;
    FHighlighterDiff: TSynDiffSyn;
    FHighlighterSh: TSynUNIXShellScriptSyn;
    FHighlighterPerl: TSynPerlSyn;
    FHighlighterVB: TSynVBSyn;

    procedure AutoDetectHighlighter(const AFileName: string);
    procedure ApplyHighlighterTheme(ADark: Boolean);
    function ConvertToUTF8(const S: string): string;
    procedure LoadPreviewLines(const AFilePath: string; Lines: TStrings; MaxLines: Integer);
    procedure ShowInfoCard(const AFilePath, AName, ASizeStr, ADateStr, ATypeStr: string; ASizeBytes: Int64);
    procedure SetWindowsTitleBarDark(AForm: TForm; ADark: Boolean);
    function IsTextFile(const APath: string): Boolean;

  public
    destructor Destroy; override;
    procedure ShowFile(const APath: string; const AName, ASizeStr, ADateStr, ATypeStr: string;
      ASizeBytes: Int64; ADarkMode: Boolean);
    procedure ApplyTheme(ADark: Boolean);
    property CurrentPath: string read FCurrentPath;
  end;

var
  frmPreview: TfrmPreview;

implementation

{$R *.lfm}

uses
  {$IFDEF WINDOWS}
  Windows, ShellAPI,
  {$ENDIF}
  MainForm;

type
  TDwmSetWindowAttribute = function(hwnd: HWND; dwAttribute: DWORD; pvAttribute: LPCVOID; cbAttribute: DWORD): HRESULT; stdcall;

destructor TfrmPreview.Destroy;
begin
  FreeAndNil(FWrapPlugin);
  inherited Destroy;
end;

procedure TfrmPreview.FormCreate(Sender: TObject);
begin
  FCurrentPath := '';
  FDarkMode := True;

  // Highlighters
  FHighlighterPas := TSynPasSyn.Create(Self);
  FHighlighterPython := TSynPythonSyn.Create(Self);
  FHighlighterXML := TSynXMLSyn.Create(Self);
  FHighlighterHTML := TSynHTMLSyn.Create(Self);
  FHighlighterPHP := TSynPHPSyn.Create(Self);
  FHighlighterCSS := TSynCssSyn.Create(Self);
  FHighlighterJS := TSynJScriptSyn.Create(Self);
  FHighlighterCpp := TSynCppSyn.Create(Self);
  FHighlighterJava := TSynJavaSyn.Create(Self);
  FHighlighterSQL := TSynSQLSyn.Create(Self);
  FHighlighterBat := TSynBatSyn.Create(Self);
  FHighlighterIni := TSynIniSyn.Create(Self);
  FHighlighterDiff := TSynDiffSyn.Create(Self);
  FHighlighterSh := TSynUNIXShellScriptSyn.Create(Self);
  FHighlighterPerl := TSynPerlSyn.Create(Self);
  FHighlighterVB := TSynVBSyn.Create(Self);

  FormStyle := fsStayOnTop;
  Position := poMainFormCenter;

  DoubleBuffered := True;
  pnlContent.DoubleBuffered := True;
  synPreview.DoubleBuffered := True;

  FWrapPlugin := TLazSynEditLineWrapPlugin.Create(synPreview);
  synPreview.ScrollBars := ssVertical;
end;

procedure TfrmPreview.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
  FCurrentPath := '';
end;

procedure TfrmPreview.btnCloseClick(Sender: TObject);
begin
  Close;
end;

function TfrmPreview.IsTextFile(const APath: string): Boolean;
var
  Ext: string;
begin
  if (APath = '') or DirectoryExists(APath) then Exit(False);
  Ext := LowerCase(ExtractFileExt(APath));
  Result := (Ext = '.txt') or (Ext = '.md') or (Ext = '.markdown') or
            (Ext = '.pas') or (Ext = '.pp') or (Ext = '.lpr') or (Ext = '.lfm') or (Ext = '.inc') or (Ext = '.dpr') or
            (Ext = '.py') or (Ext = '.pyw') or
            (Ext = '.html') or (Ext = '.htm') or (Ext = '.xhtml') or (Ext = '.xml') or (Ext = '.svg') or
            (Ext = '.php') or (Ext = '.php3') or (Ext = '.php4') or (Ext = '.php5') or (Ext = '.phtml') or
            (Ext = '.css') or (Ext = '.scss') or (Ext = '.less') or
            (Ext = '.js') or (Ext = '.jsx') or (Ext = '.ts') or (Ext = '.tsx') or (Ext = '.json') or (Ext = '.mjs') or
            (Ext = '.sql') or (Ext = '.bat') or (Ext = '.cmd') or (Ext = '.ps1') or
            (Ext = '.ini') or (Ext = '.cfg') or (Ext = '.conf') or (Ext = '.inf') or (Ext = '.log') or
            (Ext = '.csv') or (Ext = '.tsv') or (Ext = '.diff') or (Ext = '.patch') or
            (Ext = '.c') or (Ext = '.cpp') or (Ext = '.cc') or (Ext = '.cxx') or
            (Ext = '.h') or (Ext = '.hpp') or (Ext = '.hxx') or (Ext = '.cs') or
            (Ext = '.java') or (Ext = '.go') or (Ext = '.rs') or
            (Ext = '.sh') or (Ext = '.bash') or (Ext = '.zsh') or (Ext = '.env') or
            (Ext = '.pl') or (Ext = '.pm') or (Ext = '.cgi') or
            (Ext = '.vbs') or (Ext = '.vb') or (Ext = '.bas') or (Ext = '.vba') or
            (Ext = '.yaml') or (Ext = '.yml') or (Ext = '.toml');
end;

procedure TfrmPreview.btnOpenInNotepadClick(Sender: TObject);
begin
  if (FCurrentPath <> '') and FileExists(FCurrentPath) and IsTextFile(FCurrentPath) then
  begin
    if Assigned(frmMain) then
    begin
      frmMain.OpenFileInNotepad(FCurrentPath);
      frmMain.PageControl1.ActivePage := frmMain.tabNotepad;
      frmMain.BringToFront;
    end;
  end;
end;

procedure TfrmPreview.SetWindowsTitleBarDark(AForm: TForm; ADark: Boolean);
var
  DwmDll: HMODULE;
  SetAttr: TDwmSetWindowAttribute;
  DwmVal: DWORD;
begin
  {$IFDEF WINDOWS}
  DwmDll := LoadLibrary('dwmapi.dll');
  if DwmDll <> 0 then
  begin
    try
      SetAttr := TDwmSetWindowAttribute(GetProcAddress(DwmDll, 'DwmSetWindowAttribute'));
      if Assigned(SetAttr) then
      begin
        if ADark then DwmVal := 1 else DwmVal := 0;
        if SetAttr(AForm.Handle, 20, @DwmVal, SizeOf(DwmVal)) <> 0 then
          SetAttr(AForm.Handle, 19, @DwmVal, SizeOf(DwmVal));
      end;
    finally
      FreeLibrary(DwmDll);
    end;
  end;
  {$ENDIF}
end;

procedure TfrmPreview.ApplyTheme(ADark: Boolean);
var
  BgColor, PanelColor, HeaderBg, EditBg, TextColor, GutterBg: TColor;
begin
  FDarkMode := ADark;

  if ADark then
  begin
    BgColor := $001A1816;
    PanelColor := $0024211E;
    HeaderBg := $002D2925;
    EditBg := $0034302B;
    TextColor := $00F0F0F0;
    GutterBg := $00201E1C;
  end
  else
  begin
    BgColor := clBtnFace;
    PanelColor := clBtnFace;
    HeaderBg := $00EBEBEB;
    EditBg := clWindow;
    TextColor := clWindowText;
    GutterBg := clBtnFace;
  end;

  SetWindowsTitleBarDark(Self, ADark);

  Color := BgColor;
  pnlTop.Color := HeaderBg;
  lblFileName.Font.Color := TextColor;
  lblFileMeta.Font.Color := TextColor;

  pnlContent.Color := PanelColor;
  pnlImage.Color := PanelColor;
  lblImageDetails.Font.Color := TextColor;

  pnlInfo.Color := PanelColor;
  lblInfoName.Font.Color := TextColor;
  lblInfoType.Font.Color := TextColor;
  lblInfoSize.Font.Color := TextColor;
  lblInfoModified.Font.Color := TextColor;
  lblHexTitle.Font.Color := TextColor;

  memHex.Color := EditBg;
  memHex.Font.Color := TextColor;

  synPreview.Color := EditBg;
  synPreview.Font.Color := TextColor;
  synPreview.Gutter.Color := GutterBg;
  synPreview.SelectedColor.Background := $006B4D2B;
  synPreview.SelectedColor.Foreground := clWhite;

  ApplyHighlighterTheme(ADark);
end;

function TfrmPreview.ConvertToUTF8(const S: string): string;
var
  Enc: string;
  Dummy: Boolean;
begin
  if S = '' then Exit('');
  // Check for UTF-8 BOM
  if (Length(S) >= 3) and (S[1] = #$EF) and (S[2] = #$BB) and (S[3] = #$BF) then
    Exit(Copy(S, 4, Length(S) - 3));

  // Check for UTF-16 LE BOM
  if (Length(S) >= 2) and (S[1] = #$FF) and (S[2] = #$FE) then
    Exit(ConvertEncodingToUTF8(S, 'ucs-2le', Dummy));

  // Check for UTF-16 BE BOM
  if (Length(S) >= 2) and (S[1] = #$FE) and (S[2] = #$FF) then
    Exit(ConvertEncodingToUTF8(S, 'ucs-2be', Dummy));

  Enc := GuessEncoding(S);
  if (Enc = '') or (SameText(Enc, 'utf-8')) or (SameText(Enc, 'utf8')) then
    Result := UTF8BOMToUTF8(S)
  else
    Result := ConvertEncodingToUTF8(S, Enc, Dummy);
end;

procedure TfrmPreview.ApplyHighlighterTheme(ADark: Boolean);
var
  CommentCol, KeyCol, StringCol, NumberCol, SymbolCol, TagCol, AttrCol, ValCol: TColor;
begin
  if ADark then
  begin
    CommentCol := $0068AA68;  // Soft Sage Green
    KeyCol     := $00569CD6;  // Vibrant Blue / Amber ($00E08050)
    StringCol  := $0080B0FF;  // Light Peach / Sky Blue
    NumberCol  := $0070DF90;  // Emerald Green
    SymbolCol  := $00D4D4D4;  // Crisp light gray
    TagCol     := $004EC9B0;  // Teal / Cyan
    AttrCol    := $009CDCFE;  // Sky blue
    ValCol     := $00CE9178;  // Warm peach
  end
  else
  begin
    CommentCol := $00008000;  // Forest green
    KeyCol     := $00B00000;  // Royal blue / Navy
    StringCol  := $00000099;  // Deep maroon / crimson
    NumberCol  := $000060A0;  // Deep teal/amber
    SymbolCol  := $00333333;  // Dark charcoal
    TagCol     := $00800000;  // Navy
    AttrCol    := $00804000;  // Dark cyan
    ValCol     := $00000080;  // Maroon
  end;

  // 1. Pascal
  FHighlighterPas.CommentAttri.Foreground := CommentCol;
  FHighlighterPas.KeyAttri.Foreground := KeyCol;
  FHighlighterPas.StringAttri.Foreground := StringCol;
  FHighlighterPas.NumberAttri.Foreground := NumberCol;
  FHighlighterPas.SymbolAttri.Foreground := SymbolCol;

  // 2. Python
  FHighlighterPython.CommentAttri.Foreground := CommentCol;
  FHighlighterPython.KeyAttri.Foreground := KeyCol;
  FHighlighterPython.StringAttri.Foreground := StringCol;
  FHighlighterPython.NumberAttri.Foreground := NumberCol;

  // 3. JavaScript / JSON / TypeScript
  FHighlighterJS.CommentAttri.Foreground := CommentCol;
  FHighlighterJS.KeyAttri.Foreground := KeyCol;
  FHighlighterJS.StringAttri.Foreground := StringCol;
  FHighlighterJS.NumberAttri.Foreground := NumberCol;
  FHighlighterJS.SymbolAttri.Foreground := SymbolCol;
  FHighlighterJS.BracketAttri.Foreground := TagCol;

  // 4. HTML
  FHighlighterHTML.CommentAttri.Foreground := CommentCol;
  FHighlighterHTML.KeyAttri.Foreground := TagCol;
  FHighlighterHTML.ValueAttri.Foreground := ValCol;
  FHighlighterHTML.TextAttri.Foreground := AttrCol;

  // 5. XML / SVG
  FHighlighterXML.CommentAttri.Foreground := CommentCol;
  FHighlighterXML.ElementAttri.Foreground := TagCol;
  FHighlighterXML.AttributeAttri.Foreground := AttrCol;
  FHighlighterXML.AttributeValueAttri.Foreground := ValCol;
  FHighlighterXML.TextAttri.Foreground := StringCol;

  // 6. CSS
  FHighlighterCSS.CommentAttri.Foreground := CommentCol;
  FHighlighterCSS.SelectorAttri.Foreground := TagCol;
  FHighlighterCSS.KeyAttri.Foreground := KeyCol;
  FHighlighterCSS.StringAttri.Foreground := StringCol;
  FHighlighterCSS.NumberAttri.Foreground := NumberCol;
  FHighlighterCSS.SymbolAttri.Foreground := SymbolCol;

  // 7. C / C++ / C#
  FHighlighterCpp.CommentAttri.Foreground := CommentCol;
  FHighlighterCpp.KeyAttri.Foreground := KeyCol;
  FHighlighterCpp.StringAttri.Foreground := StringCol;
  FHighlighterCpp.NumberAttri.Foreground := NumberCol;
  FHighlighterCpp.DirecAttri.Foreground := TagCol;
  FHighlighterCpp.SymbolAttri.Foreground := SymbolCol;

  // 8. Java
  FHighlighterJava.CommentAttri.Foreground := CommentCol;
  FHighlighterJava.KeyAttri.Foreground := KeyCol;
  FHighlighterJava.StringAttri.Foreground := StringCol;
  FHighlighterJava.NumberAttri.Foreground := NumberCol;
  FHighlighterJava.SymbolAttri.Foreground := SymbolCol;

  // 9. PHP
  FHighlighterPHP.CommentAttri.Foreground := CommentCol;
  FHighlighterPHP.KeyAttri.Foreground := KeyCol;
  FHighlighterPHP.VariableAttri.Foreground := AttrCol;
  FHighlighterPHP.StringAttri.Foreground := StringCol;
  FHighlighterPHP.NumberAttri.Foreground := NumberCol;
  FHighlighterPHP.SymbolAttri.Foreground := SymbolCol;

  // 10. SQL
  FHighlighterSQL.CommentAttri.Foreground := CommentCol;
  FHighlighterSQL.KeyAttri.Foreground := KeyCol;
  FHighlighterSQL.TableNameAttri.Foreground := TagCol;
  FHighlighterSQL.StringAttri.Foreground := StringCol;
  FHighlighterSQL.NumberAttri.Foreground := NumberCol;
  FHighlighterSQL.SymbolAttri.Foreground := SymbolCol;

  // 11. Batch
  FHighlighterBat.CommentAttri.Foreground := CommentCol;
  FHighlighterBat.KeyAttri.Foreground := KeyCol;
  FHighlighterBat.VariableAttri.Foreground := AttrCol;
  FHighlighterBat.NumberAttri.Foreground := NumberCol;

  // 12. INI / Config
  FHighlighterIni.CommentAttri.Foreground := CommentCol;
  FHighlighterIni.SectionAttri.Foreground := TagCol;
  FHighlighterIni.KeyAttri.Foreground := AttrCol;
  FHighlighterIni.StringAttri.Foreground := StringCol;
  FHighlighterIni.NumberAttri.Foreground := NumberCol;
  FHighlighterIni.SymbolAttri.Foreground := SymbolCol;
end;

procedure TfrmPreview.AutoDetectHighlighter(const AFileName: string);
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));

  // Pascal / Delphi / Lazarus
  if (Ext = '.pas') or (Ext = '.pp') or (Ext = '.lpr') or (Ext = '.lfm') or (Ext = '.inc') or (Ext = '.dpr') then
    synPreview.Highlighter := FHighlighterPas

  // Python
  else if (Ext = '.py') or (Ext = '.pyw') then
    synPreview.Highlighter := FHighlighterPython

  // HTML
  else if (Ext = '.html') or (Ext = '.htm') or (Ext = '.xhtml') then
    synPreview.Highlighter := FHighlighterHTML

  // XML / SVG
  else if (Ext = '.xml') or (Ext = '.svg') or (Ext = '.xaml') or (Ext = '.plist') or (Ext = '.rss') then
    synPreview.Highlighter := FHighlighterXML

  // PHP
  else if (Ext = '.php') or (Ext = '.php3') or (Ext = '.php4') or (Ext = '.php5') or (Ext = '.phtml') then
    synPreview.Highlighter := FHighlighterPHP

  // CSS / Styling
  else if (Ext = '.css') or (Ext = '.scss') or (Ext = '.less') then
    synPreview.Highlighter := FHighlighterCSS

  // JavaScript / TypeScript / JSON
  else if (Ext = '.js') or (Ext = '.jsx') or (Ext = '.ts') or (Ext = '.tsx') or (Ext = '.json') or (Ext = '.mjs') then
    synPreview.Highlighter := FHighlighterJS

  // C / C++ / C#
  else if (Ext = '.c') or (Ext = '.cpp') or (Ext = '.cc') or (Ext = '.cxx') or
          (Ext = '.h') or (Ext = '.hpp') or (Ext = '.hxx') or (Ext = '.cs') then
    synPreview.Highlighter := FHighlighterCpp

  // Java
  else if (Ext = '.java') then
    synPreview.Highlighter := FHighlighterJava

  // SQL
  else if (Ext = '.sql') then
    synPreview.Highlighter := FHighlighterSQL

  // Batch / Windows Command
  else if (Ext = '.bat') or (Ext = '.cmd') then
    synPreview.Highlighter := FHighlighterBat

  // Shell / Bash / Unix
  else if (Ext = '.sh') or (Ext = '.bash') or (Ext = '.zsh') or (Ext = '.env') then
    synPreview.Highlighter := FHighlighterSh

  // Perl
  else if (Ext = '.pl') or (Ext = '.pm') or (Ext = '.cgi') then
    synPreview.Highlighter := FHighlighterPerl

  // Visual Basic / VBScript
  else if (Ext = '.vbs') or (Ext = '.vb') or (Ext = '.bas') or (Ext = '.vba') then
    synPreview.Highlighter := FHighlighterVB

  // Diff / Patches
  else if (Ext = '.diff') or (Ext = '.patch') then
    synPreview.Highlighter := FHighlighterDiff

  // Config / INI / Markdown / YAML / TOML
  else if (Ext = '.ini') or (Ext = '.cfg') or (Ext = '.conf') or (Ext = '.inf') or
          (Ext = '.md') or (Ext = '.markdown') or (Ext = '.toml') or (Ext = '.yaml') or (Ext = '.yml') then
    synPreview.Highlighter := FHighlighterIni

  else
    synPreview.Highlighter := nil;
end;

procedure TfrmPreview.LoadPreviewLines(const AFilePath: string; Lines: TStrings; MaxLines: Integer);
var
  FS: TFileStream;
  SL: TStringList;
  RawBytes, CleanStr: string;
  i: Integer;
begin
  Lines.BeginUpdate;
  try
    Lines.Clear;
    SL := TStringList.Create;
    try
      FS := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
      try
        SetLength(RawBytes, FS.Size);
        if FS.Size > 0 then
          FS.ReadBuffer(RawBytes[1], FS.Size);
      finally
        FS.Free;
      end;

      CleanStr := ConvertToUTF8(RawBytes);
      SL.Text := CleanStr;

      for i := 0 to SL.Count - 1 do
      begin
        if i >= MaxLines then Break;
        Lines.Add(SL[i]);
      end;
    finally
      SL.Free;
    end;
  finally
    Lines.EndUpdate;
  end;
end;

procedure TfrmPreview.ShowInfoCard(const AFilePath, AName, ASizeStr, ADateStr, ATypeStr: string; ASizeBytes: Int64);
var
  {$IFDEF WINDOWS}
  ShInfo: TSHFileInfo;
  {$ENDIF}
begin
  pnlImage.Visible := False;
  synPreview.Visible := False;
  pnlInfo.Visible := True;

  lblInfoName.Caption := AName;
  lblInfoType.Caption := ATypeStr;
  lblInfoSize.Caption := 'Size: ' + ASizeStr + Format(' (%d bytes)', [ASizeBytes]);
  lblInfoModified.Caption := 'Modified: ' + ADateStr;

  // Load Windows Shell Icon
  {$IFDEF WINDOWS}
  FillChar(ShInfo, SizeOf(ShInfo), 0);
  if SHGetFileInfo(PChar(AFilePath), 0, ShInfo, SizeOf(ShInfo), SHGFI_ICON or SHGFI_LARGEICON) <> 0 then
  begin
    imgIcon.Picture.Icon.Handle := ShInfo.hIcon;
  end;
  {$ENDIF}

  lblHexTitle.Caption := 'No preview available for this file type.';
  memHex.Text := '';
end;

procedure TfrmPreview.ShowFile(const APath: string; const AName, ASizeStr, ADateStr, ATypeStr: string;
  ASizeBytes: Int64; ADarkMode: Boolean);
var
  Ext: string;
begin
  // Guard against duplicate loads if this file is already displayed
  if (FCurrentPath = APath) and Visible then
    Exit;

  FCurrentPath := APath;

  // Only re-apply DWM / colors if the theme actually changed
  if FDarkMode <> ADarkMode then
    ApplyTheme(ADarkMode);

  lblFileName.Caption := AName;
  lblFileMeta.Caption := Format('%s | %s | %s', [ATypeStr, ASizeStr, ADateStr]);
  Caption := 'Preview - ' + AName;

  // Center on main form if not already visible
  if not Visible then
  begin
    if Assigned(frmMain) and frmMain.Visible then
    begin
      Left := frmMain.Left + (frmMain.Width - Width) div 2;
      Top := frmMain.Top + (frmMain.Height - Height) div 2;
    end;
  end;

  // Only allow opening in Notepad if the file is text-based
  btnOpenInNotepad.Visible := IsTextFile(APath);
  btnOpenInNotepad.Enabled := btnOpenInNotepad.Visible;

  if not FileExists(APath) then
  begin
    pnlImage.Visible := False;
    synPreview.Visible := False;
    pnlInfo.Visible := True;
    lblInfoName.Caption := AName;
    lblInfoType.Caption := 'File not found';
    lblInfoSize.Caption := '';
    lblInfoModified.Caption := '';
    lblHexTitle.Caption := '';
    memHex.Text := '';
    Exit;
  end;

  Ext := LowerCase(ExtractFileExt(APath));

  // 1. Image Preview
  if (Ext = '.png') or (Ext = '.jpg') or (Ext = '.jpeg') or (Ext = '.bmp') or
     (Ext = '.ico') or (Ext = '.gif') or (Ext = '.jfif') or (Ext = '.tif') or
     (Ext = '.tiff') or (Ext = '.xpm') then
  begin
    try
      imgPreview.Picture.Clear;
      imgPreview.Picture.LoadFromFile(APath);
      lblImageDetails.Caption := Format('%d x %d pixels | %s', [
        imgPreview.Picture.Width, imgPreview.Picture.Height, ASizeStr]);
      pnlImage.Visible := True;
      synPreview.Visible := False;
      pnlInfo.Visible := False;
    except
      on E: Exception do
      begin
        pnlImage.Visible := False;
        ShowInfoCard(APath, AName, ASizeStr, ADateStr, ATypeStr, ASizeBytes);
      end;
    end;
    Exit;
  end;

  // 2. Text, Code, Scripts, Markdown Preview
  if IsTextFile(APath) then
  begin
    try
      AutoDetectHighlighter(APath);
      LoadPreviewLines(APath, synPreview.Lines, 300);
      synPreview.Invalidate;
      pnlImage.Visible := False;
      synPreview.Visible := True;
      pnlInfo.Visible := False;
    except
      ShowInfoCard(APath, AName, ASizeStr, ADateStr, ATypeStr, ASizeBytes);
    end;
    Exit;
  end;

  // 3. Fallback for any unknown format
  ShowInfoCard(APath, AName, ASizeStr, ADateStr, ATypeStr, ASizeBytes);
end;

end.

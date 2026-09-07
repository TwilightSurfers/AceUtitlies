unit PreviewForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus, Clipbrd, LazUTF8,
  SynEdit, SynEditWrappedView, SynEditHighlighter,
  SynHighlighterPas, SynHighlighterPython, SynHighlighterXML, SynHighlighterHTML,
  SynHighlighterCSS, SynHighlighterJScript, SynHighlighterPHP, SynHighlighterCpp,
  SynHighlighterJava, SynHighlighterSQL, SynHighlighterBat, SynHighlighterIni,
  SynHighlighterDiff, SynHighlighterUnixShellScript, SynHighlighterPerl, SynHighlighterVB,
  SynHighlighterTeX, SynHighlighterLFM, SynHighlighterPo,
  SynHighlighterMarkdown, LConvEncoding, LMessages;

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

    popPreview: TPopupMenu;
    miPrevOpenAssociated: TMenuItem;
    miPrevOpenNotepad: TMenuItem;
    miPrevSep0: TMenuItem;
    miPrevCopy: TMenuItem;
    miPrevSep: TMenuItem;
    miPrevSelectAll: TMenuItem;

    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormHide(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure btnOpenInNotepadClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure miPrevOpenAssociatedClick(Sender: TObject);
    procedure miPrevOpenNotepadClick(Sender: TObject);
    procedure miPrevCopyClick(Sender: TObject);
    procedure miPrevSelectAllClick(Sender: TObject);
    procedure popPreviewPopup(Sender: TObject);

  protected
    procedure WndProc(var Message: TLMessage); override;

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
    FHighlighterTeX: TSynTeXSyn;
    FHighlighterLFM: TSynLFMSyn;
    FHighlighterPo: TSynPoSyn;
    FHighlighterMarkdown: TSynMarkdownSyn;

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
  MainForm, lazsynedittext;

type
  TDwmSetWindowAttribute = function(hwnd: HWND; dwAttribute: DWORD; pvAttribute: LPCVOID; cbAttribute: DWORD): HRESULT; stdcall;

type
  TSynTextViewsManagerCracker = class
  public
    FTextViewsList: TList;
    FTextBuffer: TSynEditStringListBase;
    FTopViewChangedCallback: TNotifyEvent;
  end;

procedure SafelyFreeWrapPlugin(var APlugin: TLazSynEditLineWrapPlugin; AEditor: TCustomSynEdit);
var
  ViewToRemove: TSynEditStringsLinked;
  Mgr: TSynTextViewsManager;
  Cracker: TSynTextViewsManagerCracker;
  Idx: Integer;
begin
  if APlugin = nil then Exit;
  try
    if (AEditor <> nil) and (not (csDestroying in AEditor.ComponentState)) then
    begin
      ViewToRemove := APlugin.FLineMapView;
      if ViewToRemove <> nil then
      begin
        APlugin.FLineMapView := nil; // Detach from plugin so its destructor won't call buggy RemoveSynTextView
        Mgr := AEditor.TextViewsManager;
        if Mgr <> nil then
        begin
          Cracker := TSynTextViewsManagerCracker(Pointer(Mgr));
          if Cracker.FTextViewsList <> nil then
          begin
            Idx := Cracker.FTextViewsList.IndexOf(ViewToRemove);
            if Idx >= 0 then
            begin
              Cracker.FTextViewsList.Delete(Idx);
              Mgr.ReconnectViews;
            end;
          end;
        end;
        ViewToRemove.Free;
      end;
    end;
  finally
    FreeAndNil(APlugin);
  end;
end;

destructor TfrmPreview.Destroy;
begin
  SafelyFreeWrapPlugin(FWrapPlugin, synPreview);
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
  FHighlighterTeX := TSynTeXSyn.Create(Self);
  FHighlighterLFM := TSynLFMSyn.Create(Self);
  FHighlighterPo := TSynPoSyn.Create(Self);
  FHighlighterMarkdown := TSynMarkdownSyn.Create(Self);

  FormStyle := fsStayOnTop;
  Position := poMainFormCenter;

  DoubleBuffered := True;
  pnlContent.DoubleBuffered := True;
  synPreview.DoubleBuffered := True;

  FWrapPlugin := TLazSynEditLineWrapPlugin.Create(synPreview);
  synPreview.ScrollBars := ssVertical;
  synPreview.Keystrokes.ResetDefaults;

  // Initialize theme and highlighters for immediate crisp dark/light styling
  ApplyTheme(FDarkMode);
end;

procedure TfrmPreview.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
  FormHide(Sender);
end;

procedure TfrmPreview.FormHide(Sender: TObject);
begin
  FCurrentPath := '';
  if Assigned(frmMain) and Assigned(frmMain.cbExpPreviewAlways) then
    frmMain.cbExpPreviewAlways.Checked := False;
end;

procedure TfrmPreview.btnCloseClick(Sender: TObject);
begin
  Close;
end;

function TfrmPreview.IsTextFile(const APath: string): Boolean;
var
  Ext, BaseName: string;
  FS: TFileStream;
  Buf: array[0..1023] of Byte;
  BytesRead, i: Integer;
begin
  if (APath = '') or DirectoryExists(APath) then Exit(False);
  Ext := LowerCase(ExtractFileExt(APath));
  BaseName := LowerCase(ExtractFileName(APath));

  // 1. Common extensionless files & dotfiles
  if (BaseName = 'dockerfile') or (BaseName = 'makefile') or (BaseName = 'gnumakefile') or
     (BaseName = 'license') or (BaseName = 'readme') or (BaseName = 'authors') or
     (BaseName = 'gemfile') or (BaseName = 'procfile') or (BaseName = 'vagrantfile') or
     (BaseName = 'rakefile') or (BaseName = '.gitignore') or (BaseName = '.gitattributes') or
     (BaseName = '.gitmodules') or (BaseName = '.editorconfig') or (BaseName = '.env') or
     (Pos('.env.', BaseName) = 1) or (BaseName = '.bashrc') or (BaseName = '.bash_profile') or
     (BaseName = '.zshrc') or (BaseName = '.profile') then
    Exit(True);

  // 2. Known code, script, web, markup, data & config extensions
  if (Ext = '.txt') or (Ext = '.md') or (Ext = '.markdown') or (Ext = '.mdown') or (Ext = '.mkd') or
     (Ext = '.pas') or (Ext = '.pp') or (Ext = '.p') or (Ext = '.lpr') or (Ext = '.lfm') or (Ext = '.dfm') or
     (Ext = '.fmx') or (Ext = '.inc') or (Ext = '.dpr') or (Ext = '.dpk') or
     (Ext = '.py') or (Ext = '.pyw') or (Ext = '.pyi') or (Ext = '.pyx') or (Ext = '.pxd') or
     (Ext = '.html') or (Ext = '.htm') or (Ext = '.xhtml') or (Ext = '.shtml') or (Ext = '.asp') or
     (Ext = '.jsp') or (Ext = '.vue') or (Ext = '.svelte') or (Ext = '.twig') or
     (Ext = '.xml') or (Ext = '.svg') or (Ext = '.xaml') or (Ext = '.plist') or (Ext = '.rss') or
     (Ext = '.atom') or (Ext = '.xsd') or (Ext = '.xsl') or (Ext = '.xslt') or (Ext = '.resx') or
     (Ext = '.manifest') or (Ext = '.pom') or (Ext = '.kml') or (Ext = '.gpx') or (Ext = '.config') or
     (Ext = '.nuspec') or (Ext = '.props') or (Ext = '.targets') or (Ext = '.csproj') or
     (Ext = '.vbproj') or (Ext = '.fsproj') or (Ext = '.vcxproj') or
     (Ext = '.php') or (Ext = '.php3') or (Ext = '.php4') or (Ext = '.php5') or (Ext = '.php7') or
     (Ext = '.php8') or (Ext = '.phtml') or (Ext = '.phps') or
     (Ext = '.css') or (Ext = '.scss') or (Ext = '.sass') or (Ext = '.less') or (Ext = '.pcss') or
     (Ext = '.js') or (Ext = '.jsx') or (Ext = '.ts') or (Ext = '.tsx') or (Ext = '.mjs') or
     (Ext = '.cjs') or (Ext = '.json') or (Ext = '.json5') or (Ext = '.jsonc') or (Ext = '.map') or
     (Ext = '.webmanifest') or
     (Ext = '.sql') or (Ext = '.ddl') or (Ext = '.dml') or (Ext = '.bat') or (Ext = '.cmd') or
     (Ext = '.btm') or (Ext = '.ps1') or (Ext = '.psm1') or (Ext = '.psd1') or
     (Ext = '.ini') or (Ext = '.cfg') or (Ext = '.conf') or (Ext = '.inf') or (Ext = '.log') or
     (Ext = '.properties') or (Ext = '.desktop') or (Ext = '.service') or (Ext = '.gitconfig') or
     (Ext = '.toml') or (Ext = '.yaml') or (Ext = '.yml') or
     (Ext = '.csv') or (Ext = '.tsv') or (Ext = '.diff') or (Ext = '.patch') or
     (Ext = '.c') or (Ext = '.cpp') or (Ext = '.cc') or (Ext = '.cxx') or (Ext = '.h') or
     (Ext = '.hpp') or (Ext = '.hxx') or (Ext = '.hh') or (Ext = '.cs') or (Ext = '.ino') or
     (Ext = '.java') or (Ext = '.kt') or (Ext = '.kts') or (Ext = '.groovy') or (Ext = '.gradle') or
     (Ext = '.go') or (Ext = '.rs') or (Ext = '.dart') or (Ext = '.zig') or (Ext = '.lua') or
     (Ext = '.r') or (Ext = '.swift') or (Ext = '.sh') or (Ext = '.bash') or (Ext = '.zsh') or
     (Ext = '.fish') or (Ext = '.env') or (Ext = '.pl') or (Ext = '.pm') or (Ext = '.cgi') or
     (Ext = '.vb') or (Ext = '.vbs') or (Ext = '.bas') or (Ext = '.cls') or (Ext = '.frm') or
     (Ext = '.vba') or (Ext = '.tex') or (Ext = '.ltx') or (Ext = '.sty') or (Ext = '.bib') or
     (Ext = '.po') or (Ext = '.pot') then
    Exit(True);

  // 3. Fallback binary probe: check first 1KB for null bytes (#0)
  Result := False;
  try
    FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    try
      if (FS.Size > 0) and (FS.Size <= 50 * 1024 * 1024) then
      begin
        BytesRead := FS.Read(Buf[0], SizeOf(Buf));
        if BytesRead > 0 then
        begin
          Result := True;
          for i := 0 to BytesRead - 1 do
          begin
            if Buf[i] = 0 then
            begin
              Result := False;
              Break;
            end;
          end;
        end;
      end;
    finally
      FS.Free;
    end;
  except
    Result := False;
  end;
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
      Close;
    end;
  end;
end;


procedure TfrmPreview.FormWindowStateChange(Sender: TObject);
begin
  if WindowState = wsMinimized then
    WindowState := wsNormal;
end;

procedure TfrmPreview.WndProc(var Message: TLMessage);
begin
  {$IFDEF WINDOWS}
  if (Message.Msg = WM_SYSCOMMAND) and ((Message.wParam and $FFF0) = SC_MINIMIZE) then
  begin
    Message.Result := 0;
    Exit;
  end;
  {$ENDIF}
  inherited WndProc(Message);
end;

procedure TfrmPreview.popPreviewPopup(Sender: TObject);
var
  HasPath, HasSel: Boolean;
begin
  HasPath := (FCurrentPath <> '') and FileExists(FCurrentPath);
  HasSel := (synPreview.SelText <> '');
  miPrevOpenAssociated.Enabled := HasPath;
  miPrevOpenNotepad.Enabled := HasPath and IsTextFile(FCurrentPath);
  miPrevCopy.Enabled := HasSel;
  miPrevSelectAll.Enabled := (synPreview.Lines.Count > 0);
end;

procedure TfrmPreview.miPrevOpenAssociatedClick(Sender: TObject);
begin
  if (FCurrentPath <> '') and FileExists(FCurrentPath) then
  begin
    {$IFDEF WINDOWS}
    ShellExecute(0, 'open', PChar(FCurrentPath), nil, nil, SW_SHOWNORMAL);
    {$ELSE}
    OpenDocument(FCurrentPath);
    {$ENDIF}
  end;
end;

procedure TfrmPreview.miPrevOpenNotepadClick(Sender: TObject);
begin
  btnOpenInNotepadClick(Sender);
end;

procedure TfrmPreview.miPrevCopyClick(Sender: TObject);
begin
  synPreview.CopyToClipboard;
end;

procedure TfrmPreview.miPrevSelectAllClick(Sender: TObject);
begin
  synPreview.SelectAll;
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
  Clean: string;
begin
  if S = '' then Exit('');
  Clean := S;
  // Strip UTF-8 BOM if present
  if (Length(Clean) >= 3) and (Clean[1] = #$EF) and (Clean[2] = #$BB) and (Clean[3] = #$BF) then
    Delete(Clean, 1, 3);

  // If already valid UTF-8, DO NOT convert (prevents double-encoding mojibake on em-dash, emojis, smart quotes)
  if FindInvalidUTF8Codepoint(PChar(Clean), Length(Clean)) = -1 then
    Exit(Clean);

  // Check for UTF-16 LE BOM
  if (Length(S) >= 2) and (S[1] = #$FF) and (S[2] = #$FE) then
    Exit(ConvertEncodingToUTF8(S, 'ucs-2le', Dummy));

  // Check for UTF-16 BE BOM
  if (Length(S) >= 2) and (S[1] = #$FE) and (S[2] = #$FF) then
    Exit(ConvertEncodingToUTF8(S, 'ucs-2be', Dummy));

  Enc := GuessEncoding(Clean);
  if (Enc = '') or (SameText(Enc, 'utf-8')) or (SameText(Enc, 'utf8')) then
    Result := Clean
  else
    Result := ConvertEncodingToUTF8(Clean, Enc, Dummy);
end;

procedure TfrmPreview.ApplyHighlighterTheme(ADark: Boolean);
var
  CommentCol, KeyCol, StringCol, NumberCol, SymbolCol, BracketCol, TagCol, AttrCol, ValCol: TColor;
  DiffAddCol, DiffDelCol, DiffModCol: TColor;

  procedure ResetHighlighterBackgrounds(AHL: TSynCustomHighlighter);
  var
    i: Integer;
  begin
    if AHL = nil then Exit;
    for i := 0 to AHL.AttrCount - 1 do
    begin
      AHL.Attribute[i].Background := clNone;
    end;
  end;

begin
  if ADark then
  begin
    CommentCol := $0068AA68;  // Soft Sage Green
    KeyCol     := $00569CD6;  // Bright Cyan / Sky Blue
    StringCol  := $009CDCFE;  // Light Sky Blue / Cyan
    NumberCol  := $0070DF90;  // Emerald Green
    SymbolCol  := $00D4D4D4;  // Crisp Silver
    BracketCol := $0050D0FF;  // Golden Yellow
    TagCol     := $004EC9B0;  // Teal / Cyan
    AttrCol    := $009CDCFE;  // Sky blue
    ValCol     := $00CE9178;  // Warm peach
    DiffAddCol := $0070DF90;  // Emerald Green
    DiffDelCol := $007070FF;  // Coral Red
    DiffModCol := $0050D0FF;  // Golden Amber
  end
  else
  begin
    CommentCol := $00008000;  // Forest Green
    KeyCol     := $00B00000;  // Royal Blue / Navy
    StringCol  := $00007700;  // Clean Dark Green
    NumberCol  := $000060C0;  // Amber / Dark Orange
    SymbolCol  := $00202020;  // Dark Charcoal
    BracketCol := $00800080;  // Vivid Purple
    TagCol     := $00800000;  // Navy
    AttrCol    := $00804000;  // Dark cyan
    ValCol     := $00007700;  // Dark green
    DiffAddCol := $00007700;  // Forest Green
    DiffDelCol := $000000C0;  // Deep Red
    DiffModCol := $000060C0;  // Dark Amber
  end;

  // Clear any default opaque backgrounds across all highlighters
  ResetHighlighterBackgrounds(FHighlighterPas);
  ResetHighlighterBackgrounds(FHighlighterPython);
  ResetHighlighterBackgrounds(FHighlighterJS);
  ResetHighlighterBackgrounds(FHighlighterHTML);
  ResetHighlighterBackgrounds(FHighlighterXML);
  ResetHighlighterBackgrounds(FHighlighterCSS);
  ResetHighlighterBackgrounds(FHighlighterPHP);
  ResetHighlighterBackgrounds(FHighlighterCpp);
  ResetHighlighterBackgrounds(FHighlighterJava);
  ResetHighlighterBackgrounds(FHighlighterSQL);
  ResetHighlighterBackgrounds(FHighlighterBat);
  ResetHighlighterBackgrounds(FHighlighterIni);
  ResetHighlighterBackgrounds(FHighlighterSh);
  ResetHighlighterBackgrounds(FHighlighterPerl);
  ResetHighlighterBackgrounds(FHighlighterVB);
  ResetHighlighterBackgrounds(FHighlighterDiff);
  ResetHighlighterBackgrounds(FHighlighterTeX);
  ResetHighlighterBackgrounds(FHighlighterLFM);
  ResetHighlighterBackgrounds(FHighlighterPo);
  ResetHighlighterBackgrounds(FHighlighterMarkdown);

  // 1. Pascal
  FHighlighterPas.CommentAttri.Foreground := CommentCol;
  FHighlighterPas.KeyAttri.Foreground := KeyCol;
  FHighlighterPas.StringAttri.Foreground := StringCol;
  FHighlighterPas.NumberAttri.Foreground := NumberCol;
  FHighlighterPas.SymbolAttri.Foreground := SymbolCol;

  // 2. Python
  FHighlighterPython.CommentAttri.Foreground := CommentCol;
  FHighlighterPython.KeyAttri.Foreground := KeyCol;
  FHighlighterPython.NonKeyAttri.Foreground := TagCol;
  FHighlighterPython.SystemAttri.Foreground := ValCol;
  FHighlighterPython.StringAttri.Foreground := StringCol;
  FHighlighterPython.DocStringAttri.Foreground := StringCol;
  FHighlighterPython.NumberAttri.Foreground := NumberCol;
  FHighlighterPython.HexAttri.Foreground := NumberCol;
  FHighlighterPython.FloatAttri.Foreground := NumberCol;
  FHighlighterPython.SymbolAttri.Foreground := SymbolCol;

  // 3. JavaScript / JSON / TypeScript
  FHighlighterJS.CommentAttri.Foreground := CommentCol;
  FHighlighterJS.KeyAttri.Foreground := KeyCol;
  FHighlighterJS.NonReservedKeyAttri.Foreground := TagCol;
  FHighlighterJS.EventAttri.Foreground := ValCol;
  FHighlighterJS.IdentifierAttri.Foreground := SymbolCol;
  FHighlighterJS.StringAttri.Foreground := StringCol;
  FHighlighterJS.NumberAttri.Foreground := NumberCol;
  FHighlighterJS.SymbolAttri.Foreground := SymbolCol;
  FHighlighterJS.BracketAttri.Foreground := BracketCol;

  // 4. HTML
  FHighlighterHTML.CommentAttri.Foreground := CommentCol;
  FHighlighterHTML.KeyAttri.Foreground := TagCol;
  FHighlighterHTML.UndefKeyAttri.Foreground := TagCol;
  FHighlighterHTML.IdentifierAttri.Foreground := AttrCol;
  FHighlighterHTML.ValueAttri.Foreground := ValCol;
  FHighlighterHTML.TextAttri.Foreground := SymbolCol;
  FHighlighterHTML.SymbolAttri.Foreground := SymbolCol;
  FHighlighterHTML.AndAttri.Foreground := NumberCol;
  FHighlighterHTML.DOCTYPEAttri.Foreground := KeyCol;
  FHighlighterHTML.CDATAAttri.Foreground := ValCol;
  FHighlighterHTML.ASPAttri.Foreground := ValCol;

  // 5. XML / SVG
  FHighlighterXML.CommentAttri.Foreground := CommentCol;
  FHighlighterXML.ElementAttri.Foreground := TagCol;
  FHighlighterXML.AttributeAttri.Foreground := AttrCol;
  FHighlighterXML.AttributeValueAttri.Foreground := ValCol;
  FHighlighterXML.NamespaceAttributeAttri.Foreground := AttrCol;
  FHighlighterXML.NamespaceAttributeValueAttri.Foreground := ValCol;
  FHighlighterXML.TextAttri.Foreground := SymbolCol;
  FHighlighterXML.SymbolAttri.Foreground := SymbolCol;
  FHighlighterXML.ProcessingInstructionAttri.Foreground := KeyCol;
  FHighlighterXML.DocTypeAttri.Foreground := KeyCol;
  FHighlighterXML.CDATAAttri.Foreground := ValCol;
  FHighlighterXML.EntityRefAttri.Foreground := NumberCol;

  // 6. CSS
  FHighlighterCSS.CommentAttri.Foreground := CommentCol;
  FHighlighterCSS.SelectorAttri.Foreground := TagCol;
  FHighlighterCSS.KeyAttri.Foreground := KeyCol;
  FHighlighterCSS.IdentifierAttri.Foreground := AttrCol;
  FHighlighterCSS.MeasurementUnitAttri.Foreground := NumberCol;
  FHighlighterCSS.StringAttri.Foreground := StringCol;
  FHighlighterCSS.NumberAttri.Foreground := NumberCol;
  FHighlighterCSS.SymbolAttri.Foreground := SymbolCol;

  // 7. PHP
  FHighlighterPHP.CommentAttri.Foreground := CommentCol;
  FHighlighterPHP.KeyAttri.Foreground := KeyCol;
  FHighlighterPHP.VariableAttri.Foreground := AttrCol;
  FHighlighterPHP.IdentifierAttri.Foreground := TagCol;
  FHighlighterPHP.StringAttri.Foreground := StringCol;
  FHighlighterPHP.NumberAttri.Foreground := NumberCol;
  FHighlighterPHP.SymbolAttri.Foreground := SymbolCol;

  // 8. C / C++ / C#
  FHighlighterCpp.CommentAttri.Foreground := CommentCol;
  FHighlighterCpp.KeyAttri.Foreground := KeyCol;
  FHighlighterCpp.StringAttri.Foreground := StringCol;
  FHighlighterCpp.NumberAttri.Foreground := NumberCol;
  FHighlighterCpp.DirecAttri.Foreground := TagCol;
  FHighlighterCpp.SymbolAttri.Foreground := SymbolCol;

  // 9. Java / Kotlin
  FHighlighterJava.CommentAttri.Foreground := CommentCol;
  FHighlighterJava.KeyAttri.Foreground := KeyCol;
  FHighlighterJava.IdentifierAttri.Foreground := SymbolCol;
  FHighlighterJava.StringAttri.Foreground := StringCol;
  FHighlighterJava.NumberAttri.Foreground := NumberCol;
  FHighlighterJava.SymbolAttri.Foreground := SymbolCol;

  // 10. SQL
  FHighlighterSQL.CommentAttri.Foreground := CommentCol;
  FHighlighterSQL.KeyAttri.Foreground := KeyCol;
  FHighlighterSQL.DataTypeAttri.Foreground := TagCol;
  FHighlighterSQL.FunctionAttri.Foreground := TagCol;
  FHighlighterSQL.TableNameAttri.Foreground := AttrCol;
  FHighlighterSQL.VariableAttri.Foreground := AttrCol;
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

  // 13. Unix Shell Script
  FHighlighterSh.CommentAttri.Foreground := CommentCol;
  FHighlighterSh.KeyAttri.Foreground := KeyCol;
  FHighlighterSh.SecondKeyAttri.Foreground := KeyCol;
  FHighlighterSh.VarAttri.Foreground := AttrCol;
  FHighlighterSh.IdentifierAttri.Foreground := SymbolCol;
  FHighlighterSh.StringAttri.Foreground := StringCol;
  FHighlighterSh.NumberAttri.Foreground := NumberCol;
  FHighlighterSh.SymbolAttri.Foreground := SymbolCol;

  // 14. Perl
  FHighlighterPerl.CommentAttri.Foreground := CommentCol;
  FHighlighterPerl.KeyAttri.Foreground := KeyCol;
  FHighlighterPerl.PragmaAttri.Foreground := TagCol;
  FHighlighterPerl.VariableAttri.Foreground := AttrCol;
  FHighlighterPerl.OperatorAttri.Foreground := SymbolCol;
  FHighlighterPerl.IdentifierAttri.Foreground := SymbolCol;
  FHighlighterPerl.StringAttri.Foreground := StringCol;
  FHighlighterPerl.NumberAttri.Foreground := NumberCol;
  FHighlighterPerl.SymbolAttri.Foreground := SymbolCol;

  // 15. Visual Basic
  FHighlighterVB.CommentAttri.Foreground := CommentCol;
  FHighlighterVB.KeyAttri.Foreground := KeyCol;
  FHighlighterVB.IdentifierAttri.Foreground := SymbolCol;
  FHighlighterVB.StringAttri.Foreground := StringCol;
  FHighlighterVB.NumberAttri.Foreground := NumberCol;
  FHighlighterVB.SymbolAttri.Foreground := SymbolCol;

  // 16. Diff / Patch
  FHighlighterDiff.OrigFileAttri.Foreground := TagCol;
  FHighlighterDiff.NewFileAttri.Foreground := TagCol;
  FHighlighterDiff.ChunkMarkerAttri.Foreground := BracketCol;
  FHighlighterDiff.ChunkNewAttri.Foreground := DiffAddCol;
  FHighlighterDiff.ChunkOldAttri.Foreground := DiffDelCol;
  FHighlighterDiff.ChunkMixedAttri.Foreground := DiffModCol;
  FHighlighterDiff.LineAddedAttri.Foreground := DiffAddCol;
  FHighlighterDiff.LineRemovedAttri.Foreground := DiffDelCol;
  FHighlighterDiff.LineChangedAttri.Foreground := DiffModCol;
  FHighlighterDiff.LineContextAttri.Foreground := SymbolCol;

  // 17. TeX / LaTeX
  FHighlighterTeX.CommentAttri.Foreground := CommentCol;
  FHighlighterTeX.ControlSequenceAttri.Foreground := TagCol;
  FHighlighterTeX.MathmodeAttri.Foreground := ValCol;
  FHighlighterTeX.TextAttri.Foreground := SymbolCol;
  FHighlighterTeX.BraceAttri.Foreground := BracketCol;
  FHighlighterTeX.BracketAttri.Foreground := BracketCol;

  // 18. LFM Form
  FHighlighterLFM.CommentAttri.Foreground := CommentCol;
  FHighlighterLFM.KeyAttri.Foreground := KeyCol;
  FHighlighterLFM.IdentifierAttri.Foreground := TagCol;
  FHighlighterLFM.StringAttri.Foreground := StringCol;
  FHighlighterLFM.NumberAttri.Foreground := NumberCol;

  // 19. PO Gettext
  FHighlighterPo.CommentAttri.Foreground := CommentCol;
  FHighlighterPo.KeyAttri.Foreground := KeyCol;
  FHighlighterPo.TextAttri.Foreground := StringCol;

  // 20. Markdown
  FHighlighterMarkdown.HeaderAttri.Foreground := KeyCol;
  FHighlighterMarkdown.HeaderAttri.Style := [fsBold];
  FHighlighterMarkdown.CodeBlockAttri.Foreground := ValCol;
  FHighlighterMarkdown.InlineCodeAttri.Foreground := ValCol;
  FHighlighterMarkdown.BlockQuoteAttri.Foreground := SymbolCol;
  FHighlighterMarkdown.BlockQuoteAttri.Style := [fsItalic];
  FHighlighterMarkdown.ListAttri.Foreground := BracketCol;
  FHighlighterMarkdown.ListAttri.Style := [fsBold];
  if ADark then
  begin
    FHighlighterMarkdown.BoldAttri.Foreground := clWhite;
    FHighlighterMarkdown.ItalicAttri.Foreground := StringCol;
    FHighlighterMarkdown.LinkTextAttri.Foreground := TagCol;
    FHighlighterMarkdown.LinkUrlAttri.Foreground := $00808080;
  end
  else
  begin
    FHighlighterMarkdown.BoldAttri.Foreground := clBlack;
    FHighlighterMarkdown.ItalicAttri.Foreground := $00303030;
    FHighlighterMarkdown.LinkTextAttri.Foreground := KeyCol;
    FHighlighterMarkdown.LinkUrlAttri.Foreground := $00707070;
  end;
  FHighlighterMarkdown.BoldAttri.Style := [fsBold];
  FHighlighterMarkdown.ItalicAttri.Style := [fsItalic];
  FHighlighterMarkdown.LinkTextAttri.Style := [fsUnderline];
  FHighlighterMarkdown.RuleAttri.Foreground := CommentCol;
  FHighlighterMarkdown.TagAttri.Foreground := TagCol;
  FHighlighterMarkdown.CommentAttri.Foreground := CommentCol;
  FHighlighterMarkdown.CommentAttri.Style := [fsItalic];
  FHighlighterMarkdown.TextAttri.Foreground := SymbolCol;
end;

procedure TfrmPreview.AutoDetectHighlighter(const AFileName: string);
var
  Ext, BaseName: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  BaseName := LowerCase(ExtractFileName(AFileName));

  // Special extensionless or dot-files
  if (BaseName = 'dockerfile') or (BaseName = 'makefile') or (BaseName = 'gnumakefile') then
    synPreview.Highlighter := FHighlighterSh
  else if (BaseName = '.gitignore') or (BaseName = '.gitattributes') or (BaseName = '.gitmodules') or
          (BaseName = '.editorconfig') then
    synPreview.Highlighter := FHighlighterIni
  else if (BaseName = '.env') or (Pos('.env.', BaseName) = 1) or (BaseName = '.bashrc') or
          (BaseName = '.bash_profile') or (BaseName = '.zshrc') or (BaseName = '.profile') then
    synPreview.Highlighter := FHighlighterSh

  // 1. Pascal / Delphi / Free Pascal
  else if (Ext = '.pas') or (Ext = '.pp') or (Ext = '.p') or (Ext = '.inc') or
          (Ext = '.lpr') or (Ext = '.dpr') or (Ext = '.dpk') then
    synPreview.Highlighter := FHighlighterPas

  // 2. Python
  else if (Ext = '.py') or (Ext = '.pyw') or (Ext = '.pyi') or (Ext = '.pyx') or
          (Ext = '.pxd') or (Ext = '.tac') or (Ext = '.wsgi') then
    synPreview.Highlighter := FHighlighterPython

  // 3. JavaScript / TypeScript / JSON
  else if (Ext = '.js') or (Ext = '.jsx') or (Ext = '.ts') or (Ext = '.tsx') or
          (Ext = '.mjs') or (Ext = '.cjs') or (Ext = '.json') or (Ext = '.json5') or
          (Ext = '.jsonc') or (Ext = '.map') or (Ext = '.webmanifest') then
    synPreview.Highlighter := FHighlighterJS

  // 4. HTML & Web Templates
  else if (Ext = '.html') or (Ext = '.htm') or (Ext = '.xhtml') or (Ext = '.shtml') or
          (Ext = '.asp') or (Ext = '.jsp') or (Ext = '.vue') or (Ext = '.svelte') or
          (Ext = '.twig') then
    synPreview.Highlighter := FHighlighterHTML

  // 5. XML / SVG
  else if (Ext = '.xml') or (Ext = '.svg') or (Ext = '.xaml') or (Ext = '.plist') or
          (Ext = '.rss') or (Ext = '.atom') or (Ext = '.xsd') or (Ext = '.xsl') or
          (Ext = '.xslt') or (Ext = '.resx') or (Ext = '.manifest') or (Ext = '.pom') or
          (Ext = '.kml') or (Ext = '.gpx') or (Ext = '.config') or (Ext = '.nuspec') or
          (Ext = '.props') or (Ext = '.targets') or (Ext = '.wxs') or (Ext = '.wxi') or
          (Ext = '.csproj') or (Ext = '.vbproj') or (Ext = '.fsproj') or (Ext = '.vcxproj') then
    synPreview.Highlighter := FHighlighterXML

  // 6. CSS & Stylesheets
  else if (Ext = '.css') or (Ext = '.scss') or (Ext = '.sass') or (Ext = '.less') or (Ext = '.pcss') then
    synPreview.Highlighter := FHighlighterCSS

  // 7. PHP
  else if (Ext = '.php') or (Ext = '.php3') or (Ext = '.php4') or (Ext = '.php5') or
          (Ext = '.php7') or (Ext = '.php8') or (Ext = '.phtml') or (Ext = '.phps') then
    synPreview.Highlighter := FHighlighterPHP

  // 8. C / C++ / C#
  else if (Ext = '.c') or (Ext = '.cpp') or (Ext = '.cc') or (Ext = '.cxx') or
          (Ext = '.h') or (Ext = '.hpp') or (Ext = '.hxx') or (Ext = '.hh') or
          (Ext = '.cs') or (Ext = '.ino') or (Ext = '.cu') or (Ext = '.cuh') or
          (Ext = '.m') or (Ext = '.mm') or (Ext = '.idl') then
    synPreview.Highlighter := FHighlighterCpp

  // 9. Java & Kotlin / JVM
  else if (Ext = '.java') or (Ext = '.kt') or (Ext = '.kts') or (Ext = '.groovy') or (Ext = '.gradle') then
    synPreview.Highlighter := FHighlighterJava

  // 10. SQL & Databases
  else if (Ext = '.sql') or (Ext = '.ddl') or (Ext = '.dml') or (Ext = '.pgsql') or
          (Ext = '.plsql') or (Ext = '.sqlite') or (Ext = '.cql') then
    synPreview.Highlighter := FHighlighterSQL

  // 11. Batch / Windows Command
  else if (Ext = '.bat') or (Ext = '.cmd') or (Ext = '.btm') then
    synPreview.Highlighter := FHighlighterBat

  // 12. INI & Config / YAML / TOML
  else if (Ext = '.ini') or (Ext = '.cfg') or (Ext = '.conf') or (Ext = '.inf') or
          (Ext = '.properties') or (Ext = '.desktop') or (Ext = '.service') or
          (Ext = '.gitconfig') or (Ext = '.toml') or (Ext = '.yaml') or (Ext = '.yml') then
    synPreview.Highlighter := FHighlighterIni

  // 13. Unix Shell Script / Bash / Zsh
  else if (Ext = '.sh') or (Ext = '.bash') or (Ext = '.zsh') or (Ext = '.ksh') or
          (Ext = '.csh') or (Ext = '.tcsh') or (Ext = '.fish') then
    synPreview.Highlighter := FHighlighterSh

  // 14. Perl
  else if (Ext = '.pl') or (Ext = '.pm') or (Ext = '.t') or (Ext = '.pod') or (Ext = '.cgi') then
    synPreview.Highlighter := FHighlighterPerl

  // 15. Visual Basic / VBScript
  else if (Ext = '.vb') or (Ext = '.vbs') or (Ext = '.bas') or (Ext = '.cls') or
          (Ext = '.frm') or (Ext = '.vba') then
    synPreview.Highlighter := FHighlighterVB

  // 16. Diff & Patch
  else if (Ext = '.diff') or (Ext = '.patch') then
    synPreview.Highlighter := FHighlighterDiff

  // 17. TeX & LaTeX
  else if (Ext = '.tex') or (Ext = '.ltx') or (Ext = '.sty') or (Ext = '.cls') or
          (Ext = '.bib') or (Ext = '.dtx') or (Ext = '.ins') then
    synPreview.Highlighter := FHighlighterTeX

  // 18. Form (LFM / DFM)
  else if (Ext = '.lfm') or (Ext = '.dfm') or (Ext = '.fmx') then
    synPreview.Highlighter := FHighlighterLFM

  // 19. PO Gettext
  else if (Ext = '.po') or (Ext = '.pot') then
    synPreview.Highlighter := FHighlighterPo

  // 20. Markdown
  else if (Ext = '.md') or (Ext = '.markdown') or (Ext = '.mdown') or (Ext = '.mkd') or
          (Ext = '.mkdn') or (Ext = '.mdwn') or (Ext = '.mdtxt') or (Ext = '.mdtext') then
    synPreview.Highlighter := FHighlighterMarkdown

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

  // Always stay on top and prevent minimized state
  FormStyle := fsStayOnTop;
  if WindowState = wsMinimized then
    WindowState := wsNormal;

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

unit PreviewForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus, Clipbrd, LazUTF8,
  SynEdit, SynEditWrappedView,
  SynHighlighterPas, SynHighlighterPython, SynHighlighterXML, SynHighlighterHTML,
  SynHighlighterCSS, SynHighlighterJScript, SynHighlighterPHP, SynHighlighterCpp,
  SynHighlighterJava, SynHighlighterSQL, SynHighlighterBat, SynHighlighterIni,
  SynHighlighterDiff, SynHighlighterUnixShellScript, SynHighlighterPerl, SynHighlighterVB,
  SynHighlighterMarkdown, LConvEncoding;

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
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOpenInNotepadClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure miPrevOpenAssociatedClick(Sender: TObject);
    procedure miPrevOpenNotepadClick(Sender: TObject);
    procedure miPrevCopyClick(Sender: TObject);
    procedure miPrevSelectAllClick(Sender: TObject);
    procedure popPreviewPopup(Sender: TObject);

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
  FHighlighterMarkdown := TSynMarkdownSyn.Create(Self);

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
      Close;
    end;
  end;
end;

procedure TfrmPreview.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if ssCtrl in Shift then
  begin
    case Key of
      VK_C:
        if synPreview.Visible and (synPreview.SelText <> '') then
        begin
          synPreview.CopyToClipboard;
          Key := 0;
        end;
      VK_A:
        if synPreview.Visible then
        begin
          synPreview.SelectAll;
          Key := 0;
        end;
    end;
  end;
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
  FHighlighterJS.BracketAttri.Foreground := BracketCol;

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

  // 13. Markdown
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

  // Markdown
  else if (Ext = '.md') or (Ext = '.markdown') or (Ext = '.mdown') or (Ext = '.mkd') then
    synPreview.Highlighter := FHighlighterMarkdown

  // Config / INI / YAML / TOML
  else if (Ext = '.ini') or (Ext = '.cfg') or (Ext = '.conf') or (Ext = '.inf') or
          (Ext = '.toml') or (Ext = '.yaml') or (Ext = '.yml') then
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

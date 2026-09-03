unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, ShellCtrls, Menus, IniFiles, Registry, Clipbrd,
  SynEdit, SynEditTypes, SynEditWrappedView,
  SynHighlighterPas, SynHighlighterPython, SynHighlighterXML, SynHighlighterHTML,
  SynHighlighterCSS, SynHighlighterJScript, SynHighlighterPHP, SynHighlighterCpp,
  SynHighlighterJava, SynHighlighterSQL, SynHighlighterBat, SynHighlighterIni,
  SynHighlighterDiff, SynHighlighterUnixShellScript, LConvEncoding, LazUTF8, LCLType,
  ImgList, SynHighlighterMarkdown;

type
  PResultInfo = ^TResultInfo;
  TResultInfo = record
    Size: Int64;
    Date: TDateTime;
    IsFolder: Boolean;
  end;

  { TfrmMain }

  TfrmMain = class(TForm)
    // Top Bar
    pnlHeader: TPanel;
    lblAppTitle: TLabel;
    cbRunInTray: TCheckBox;
    btnRegisterAssoc: TButton;
    btnToggleDarkMode: TButton;

    // Page Control
    PageControl1: TPageControl;
    tabSearch: TTabSheet;
    tabNotepad: TTabSheet;

    // Tab 1: Search Controls
    pnlSearchTop: TPanel;
    lblPattern: TLabel;
    edtPattern: TEdit;
    lblSearchIn: TLabel;
    edtSearchPath: TEdit;
    btnBrowse: TButton;
    lblContent: TLabel;
    edtContent: TEdit;
    btnSearch: TButton;
    btnStop: TButton;
    btnClear: TButton;
    btnOpenInNotepad: TButton;
    cbSubfolders: TCheckBox;
    cbCaseSensitive: TCheckBox;
    cbIncludeFolders: TCheckBox;
    cbEnablePreview: TCheckBox;

    pnlSearchProgress: TPanel;
    lblActivity: TLabel;
    ProgressBar1: TProgressBar;

    pnlSearchBody: TPanel;
    pnlLeft: TPanel;
    pnlLeftHeader: TPanel;
    lblFolders: TLabel;
    btnDriveC: TButton;
    btnUserHome: TButton;
    btnDesktop: TButton;
    ShellTreeView1: TShellTreeView;
    splMain: TSplitter;

    pnlRight: TPanel;
    lvResults: TListView;

    // Tab 2: Notepad Controls
    pnlNotepadToolbar: TPanel;
    btnNewFile: TButton;
    btnOpenFile: TButton;
    btnSaveFile: TButton;
    btnSaveAs: TButton;
    btnUndo: TButton;
    btnRedo: TButton;
    btnFindDialog: TButton;
    cbWordWrap: TCheckBox;
    lblSyntax: TLabel;
    cmbSyntax: TComboBox;
    btnFontColor: TButton;
    lblCurrentFile: TLabel;

    pnlFindReplace: TPanel;
    lblFindText: TLabel;
    edtFindText: TEdit;
    btnFindNext: TButton;
    lblReplaceText: TLabel;
    edtReplaceText: TEdit;
    btnReplaceNext: TButton;
    btnReplaceAll: TButton;
    cbMatchCase: TCheckBox;
    cbWholeWord: TCheckBox;
    btnCloseFind: TButton;

    SynEdit1: TSynEdit;

    pnlNotepadStatus: TPanel;
    lblNotepadStatus: TLabel;

    // Global Status Bar
    StatusBar1: TStatusBar;

    // Dialogs & Menus
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    ColorDialog1: TColorDialog;
    pmResults: TPopupMenu;
    miOpenInNotepad: TMenuItem;
    miRevealInExplorer: TMenuItem;
    miOpenFile: TMenuItem;
    miSepResults1: TMenuItem;
    miCopyFileName: TMenuItem;
    miCopyFilePath: TMenuItem;
    miCopyFullPath: TMenuItem;
    miCopyPath: TMenuItem;

    TrayIcon1: TTrayIcon;
    pmTray: TPopupMenu;
    miTrayOpen: TMenuItem;
    miTrayNotepad: TMenuItem;
    miTraySep: TMenuItem;
    miTrayExit: TMenuItem;

    popNotepad: TPopupMenu;
    miCut: TMenuItem;
    miCopy: TMenuItem;
    miPaste: TMenuItem;
    miDelete: TMenuItem;
    miSepNotepad1: TMenuItem;
    miSelectAll: TMenuItem;
    miSepNotepad2: TMenuItem;
    miUndo: TMenuItem;
    miRedo: TMenuItem;

    // Context Menu Tab Components
    tabContextMenu: TTabSheet;
    pnlContextMenuToolbar: TPanel;
    btnRefreshContextMenu: TButton;
    btnDeleteContextVerb: TButton;
    btnCleanStaleVerbs: TButton;
    btnTakeoverAssoc: TButton;
    lblContextMenuStatus: TLabel;
    pnlContextMenuBottom: TPanel;
    lblEditVerbLabel: TLabel;
    edtEditVerbLabel: TEdit;
    lblEditVerbCmd: TLabel;
    edtEditVerbCmd: TEdit;
    btnBrowseRemapExe: TButton;
    btnApplyRemap: TButton;
    lblRemapHelp: TLabel;
    lvContextMenu: TListView;
    ImageList1: TImageList;

    // Form Events
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    // Header & Tray Events
    procedure btnToggleDarkModeClick(Sender: TObject);
    procedure btnRegisterAssocClick(Sender: TObject);
    procedure cbRunInTrayChange(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure miTrayOpenClick(Sender: TObject);
    procedure miTrayNotepadClick(Sender: TObject);
    procedure miTrayExitClick(Sender: TObject);

    // Search Tab Events
    procedure btnBrowseClick(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnOpenInNotepadClick(Sender: TObject);
    procedure btnDriveCClick(Sender: TObject);
    procedure btnUserHomeClick(Sender: TObject);
    procedure btnDesktopClick(Sender: TObject);
    procedure ShellTreeView1SelectionChanged(Sender: TObject);
    procedure cbEnablePreviewChange(Sender: TObject);
    procedure lvResultsClick(Sender: TObject);
    procedure lvResultsDblClick(Sender: TObject);
    procedure lvResultsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvResultsColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvResultsCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure lvResultsDeletion(Sender: TObject; Item: TListItem);
    procedure lvResultsContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure miOpenInNotepadClick(Sender: TObject);
    procedure miRevealInExplorerClick(Sender: TObject);
    procedure miOpenFileClick(Sender: TObject);
    procedure miCopyFileNameClick(Sender: TObject);
    procedure miCopyFilePathClick(Sender: TObject);
    procedure miCopyFullPathClick(Sender: TObject);
    procedure miCopyPathClick(Sender: TObject);

    // Context Menu Management Events
    procedure PageControl1Change(Sender: TObject);
    procedure btnRefreshContextMenuClick(Sender: TObject);
    procedure btnDeleteContextVerbClick(Sender: TObject);
    procedure btnCleanStaleVerbsClick(Sender: TObject);
    procedure btnTakeoverAssocClick(Sender: TObject);
    procedure btnBrowseRemapExeClick(Sender: TObject);
    procedure btnApplyRemapClick(Sender: TObject);
    procedure lvContextMenuSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvContextMenuCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);

    // Notepad Tab Events
    procedure btnNewFileClick(Sender: TObject);
    procedure btnOpenFileClick(Sender: TObject);
    procedure btnSaveFileClick(Sender: TObject);
    procedure btnSaveAsClick(Sender: TObject);
    procedure btnUndoClick(Sender: TObject);
    procedure btnRedoClick(Sender: TObject);
    procedure btnFindDialogClick(Sender: TObject);
    procedure cbWordWrapClick(Sender: TObject);
    procedure btnFontColorClick(Sender: TObject);
    procedure cmbSyntaxChange(Sender: TObject);
    procedure btnFindNextClick(Sender: TObject);
    procedure btnReplaceNextClick(Sender: TObject);
    procedure btnReplaceAllClick(Sender: TObject);
    procedure btnCloseFindClick(Sender: TObject);
    procedure SynEdit1Change(Sender: TObject);
    procedure SynEdit1StatusChange(Sender: TObject; Changes: TSynStatusChanges);
    procedure miCutClick(Sender: TObject);
    procedure miCopyClick(Sender: TObject);
    procedure miPasteClick(Sender: TObject);
    procedure miDeleteClick(Sender: TObject);
    procedure miSelectAllClick(Sender: TObject);
    procedure miUndoClick(Sender: TObject);
    procedure miRedoClick(Sender: TObject);
    procedure popNotepadPopup(Sender: TObject);

  private
    // Search Engine State
    FStopSearch: Boolean;
    FFileCount: Integer;
    FDirCount: Integer;
    FSearching: Boolean;
    FSelectedPath: string;
    FSortColumn: Integer;
    FSortAscending: Boolean;

    // Notepad State
    FCurrentFileName: string;
    FIsModified: Boolean;
    FWrapPlugin: TLazSynEditLineWrapPlugin;
    FCustomFontColor: TColor;

    // Dark Mode State
    FDarkMode: Boolean;
    FAllowClose: Boolean;

    // Highlighters
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
    FHighlighterMarkdown: TSynMarkdownSyn;

    // Search Helpers
    procedure DoSearch(const APath, APattern, AContent: string; ARecursive, ACaseSensitive, AIncludeFolders: Boolean);
    procedure AddResult(const AFileName, AFolder: string; ASize: Int64; ADate: TDateTime; const AType: string);
    procedure SetStatus(const AMsg: string);
    procedure SetActivity(const AMsg: string);
    procedure SetCounts;
    procedure SetSearching(AValue: Boolean);
    function MatchesPattern(const AFileName, APattern: string; ACaseSensitive: Boolean): Boolean;
    function MatchWildcard(const AStr, APattern: string): Boolean;
    function FileContainsText(const AFilePath, AText: string; ACaseSensitive: Boolean): Boolean;
    function SafeFileDateToDateTime(ATime: LongInt): TDateTime;
    function FormatFileSize(ASize: Int64): string;
    function IsImageFile(const APath: string): Boolean;
    function IsTextFile(const APath: string): Boolean;
    function IsPreviewableFile(const APath: string): Boolean;
    procedure TriggerFilePreview(Item: TListItem);

    // Application & Tray State
    procedure AppMinimize(Sender: TObject);

    // Notepad Helpers
    function SaveCurrentFile: Boolean;
    function PromptSaveIfModified: Boolean;
    procedure UpdateNotepadStatus;
    procedure AutoDetectHighlighter(const AFileName: string);
    procedure ApplySyntax(Index: Integer);
    procedure ApplyHighlighterTheme(ADark: Boolean);
    function ConvertToUTF8(const S: string): string;

    // Dark Mode Helpers
    procedure ApplyTheme(ADark: Boolean);
    procedure SetWindowsTitleBarDark(AForm: TForm; ADark: Boolean);
    function DetectWindowsDarkMode: Boolean;

    // Config & Shell Helpers
    function GetIniPath: string;
    procedure LoadAllOptions;
    procedure SaveAllOptions;

    // Context Menu Management Helpers
    procedure ScanContextMenuEntries;
    procedure DeleteKeyRecurse(const AKeyPath: string);
    function ExtractExecutableFromCommand(const Cmd: string): string;
    function ValidateCommandTarget(const Cmd: string): Boolean;
    procedure EnsureTrayIconLoaded;
    procedure CheckAndPromptFileAssociation;
    procedure RegisterFileAssociations(ARegister: Boolean);
  public
    procedure OpenFileInNotepad(const AFileName: string);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

uses
  {$IFDEF WINDOWS}
  Windows, ShellAPI,
  {$ENDIF}
  LResources, DateUtils, PreviewForm;

const
  FILE_ATTRIBUTE_REPARSE_POINT = $00000400;

type
  TDwmSetWindowAttribute = function(hwnd: HWND; dwAttribute: DWORD; pvAttribute: LPCVOID; cbAttribute: DWORD): HRESULT; stdcall;

{ ----------------------------------------------------------------------------
  Lifecycle & Initialization
  ---------------------------------------------------------------------------- }

procedure TfrmMain.EnsureTrayIconLoaded;
var
  IcoPath: string;
  {$IFDEF WINDOWS}
  H: HICON;
  {$ENDIF}
  Bmp: Graphics.TBitmap;
begin
  IcoPath := ExtractFilePath(Application.ExeName) + 'aceutils.ico';
  if FileExists(IcoPath) then
  begin
    try
      TrayIcon1.Icon.LoadFromFile(IcoPath);
      Application.Icon.LoadFromFile(IcoPath);
      Self.Icon.LoadFromFile(IcoPath);
    except
      // Continue to fallbacks if file fails to load
    end;
  end;

  // Fallback 1: Windows API LoadIcon
  {$IFDEF WINDOWS}
  if TrayIcon1.Icon.Empty then
  begin
    H := LoadIcon(MainInstance, 'MAINICON');
    if H = 0 then
      H := LoadIcon(0, IDI_APPLICATION);
    if H <> 0 then
    begin
      TrayIcon1.Icon.Handle := H;
      if Application.Icon.Empty then
        Application.Icon.Handle := H;
      if Self.Icon.Empty then
        Self.Icon.Handle := H;
    end;
  end;
  {$ENDIF}

  // Fallback 2: Generate sharp in-memory icon
  if TrayIcon1.Icon.Empty then
  begin
    Bmp := Graphics.TBitmap.Create;
    try
      Bmp.SetSize(32, 32);
      Bmp.Canvas.Brush.Color := $000F172A; // Deep Slate
      Bmp.Canvas.FillRect(0, 0, 32, 32);
      Bmp.Canvas.Pen.Color := $00E9A50E;   // Electric Blue border
      Bmp.Canvas.Pen.Width := 2;
      Bmp.Canvas.Ellipse(2, 2, 30, 30);
      Bmp.Canvas.Font.Color := clWhite;
      Bmp.Canvas.Font.Name := 'Segoe UI';
      Bmp.Canvas.Font.Size := 13;
      Bmp.Canvas.Font.Style := [fsBold];
      Bmp.Canvas.TextOut(8, 5, 'A');
      TrayIcon1.Icon.Assign(Bmp);
      if Application.Icon.Empty then
        Application.Icon.Assign(Bmp);
    finally
      Bmp.Free;
    end;
  end;
end;

procedure TfrmMain.LoadAllOptions;
var
  Ini: TIniFile;
  UserPrefersDark: Boolean;
  ColorStr: string;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    // General Options
    UserPrefersDark := Ini.ReadBool('General', 'DarkMode', DetectWindowsDarkMode);
    cbRunInTray.Checked := Ini.ReadBool('General', 'RunInTray', False);

    // Search Options
    cbSubfolders.Checked := Ini.ReadBool('Search', 'Subfolders', True);
    cbCaseSensitive.Checked := Ini.ReadBool('Search', 'CaseSensitive', False);
    cbIncludeFolders.Checked := Ini.ReadBool('Search', 'IncludeFolders', False);
    cbEnablePreview.Checked := Ini.ReadBool('Search', 'EnablePreview', True);
    FSelectedPath := Ini.ReadString('Search', 'LastSearchPath', 'C:\');
    if DirectoryExists(FSelectedPath) then
      edtSearchPath.Text := FSelectedPath
    else
      edtSearchPath.Text := 'C:\';

    // Notepad Options
    cbWordWrap.Checked := Ini.ReadBool('Notepad', 'WordWrap', False);
    ColorStr := Ini.ReadString('Notepad', 'FontColor', '');
    if ColorStr <> '' then
    begin
      try
        FCustomFontColor := StringToColor(ColorStr);
      except
        FCustomFontColor := clNone;
      end;
    end
    else
      FCustomFontColor := clNone;

  finally
    Ini.Free;
  end;

  // Apply WordWrap
  if cbWordWrap.Checked then
  begin
    if FWrapPlugin = nil then
      FWrapPlugin := TLazSynEditLineWrapPlugin.Create(SynEdit1);
    SynEdit1.ScrollBars := ssVertical;
  end
  else
  begin
    FreeAndNil(FWrapPlugin);
    SynEdit1.ScrollBars := ssBoth;
  end;

  // Apply Tray & Theme
  EnsureTrayIconLoaded;
  TrayIcon1.Visible := cbRunInTray.Checked;
  ApplyTheme(UserPrefersDark);
end;

procedure TfrmMain.SaveAllOptions;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    // General Options
    Ini.WriteBool('General', 'DarkMode', FDarkMode);
    Ini.WriteBool('General', 'RunInTray', cbRunInTray.Checked);

    // Search Options
    Ini.WriteBool('Search', 'Subfolders', cbSubfolders.Checked);
    Ini.WriteBool('Search', 'CaseSensitive', cbCaseSensitive.Checked);
    Ini.WriteBool('Search', 'IncludeFolders', cbIncludeFolders.Checked);
    Ini.WriteBool('Search', 'EnablePreview', cbEnablePreview.Checked);
    if (edtSearchPath.Text <> '') and DirectoryExists(edtSearchPath.Text) then
      Ini.WriteString('Search', 'LastSearchPath', edtSearchPath.Text);

    // Notepad Options
    Ini.WriteBool('Notepad', 'WordWrap', cbWordWrap.Checked);
    if FCustomFontColor <> clNone then
      Ini.WriteString('Notepad', 'FontColor', ColorToString(FCustomFontColor))
    else
      Ini.DeleteKey('Notepad', 'FontColor');
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FStopSearch := False;
  FSearching := False;
  FSelectedPath := 'C:\';
  FCurrentFileName := '';
  FIsModified := False;
  FSortColumn := -1;
  FSortAscending := True;
  FCustomFontColor := clNone;
  FWrapPlugin := nil;

  // Setup Highlighters
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
  FHighlighterMarkdown := TSynMarkdownSyn.Create(Self);

  cmbSyntax.ItemIndex := 0;
  SynEdit1.Highlighter := nil;
  SynEdit1.ScrollBars := ssBoth;

  // Default Search Status
  ProgressBar1.Style := pbstMarquee;
  ProgressBar1.Visible := False;
  lblActivity.Caption := 'Ready.';
  StatusBar1.Panels[0].Text := ' Ready. Enter pattern or select folder to search.';
  StatusBar1.Panels[1].Text := 'Files: 0';
  StatusBar1.Panels[2].Text := 'Dirs: 0';
  UpdateNotepadStatus;

  {$IFNDEF WINDOWS}
  tabContextMenu.TabVisible := False;
  {$ENDIF}

  FAllowClose := False;
  Application.OnMinimize := @AppMinimize;

  // Initialize tab glyphs into ImageList1
  ImageList1.Clear;
  ImageList1.Width := 16;
  ImageList1.Height := 16;
  ImageList1.AddLazarusResource('chaicon-search');
  ImageList1.AddLazarusResource('chaicon-page-edit');
  ImageList1.AddLazarusResource('chaicon-settings');
  PageControl1.Images := ImageList1;
  tabSearch.ImageIndex := 0;
  tabNotepad.ImageIndex := 1;
  tabContextMenu.ImageIndex := 2;

  // Load and apply all saved settings
  LoadAllOptions;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  // Check command-line arguments
  if ParamCount >= 1 then
  begin
    if SameText(ParamStr(1), '/register') or SameText(ParamStr(1), '-register') or SameText(ParamStr(1), '--register') then
    begin
      RegisterFileAssociations(True);
      Application.Terminate;
      Exit;
    end
    else if SameText(ParamStr(1), '/unregister') or SameText(ParamStr(1), '-unregister') or SameText(ParamStr(1), '--unregister') then
    begin
      RegisterFileAssociations(False);
      Application.Terminate;
      Exit;
    end
    else if FileExists(ParamStr(1)) then
    begin
      OpenFileInNotepad(ParamStr(1));
      PageControl1.ActivePage := tabNotepad;
    end;
  end;

  // Check file association prompt from INI
  CheckAndPromptFileAssociation;

  {$IFDEF WINDOWS}
  ScanContextMenuEntries;
  {$ENDIF}
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FWrapPlugin);
  SaveAllOptions;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if cbRunInTray.Checked and (not FAllowClose) then
  begin
    CanClose := False;
    EnsureTrayIconLoaded;
    Hide;
    TrayIcon1.Show;
    Exit;
  end;
  CanClose := PromptSaveIfModified;
end;

procedure TfrmMain.AppMinimize(Sender: TObject);
begin
  if cbRunInTray.Checked then
  begin
    EnsureTrayIconLoaded;
    Hide;
    TrayIcon1.Show;
  end;
end;

procedure TfrmMain.cbRunInTrayChange(Sender: TObject);
begin
  EnsureTrayIconLoaded;
  TrayIcon1.Visible := cbRunInTray.Checked;
  SaveAllOptions;
end;

procedure TfrmMain.TrayIcon1Click(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
  BringToFront;
end;

procedure TfrmMain.miTrayOpenClick(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
  BringToFront;
end;

procedure TfrmMain.miTrayNotepadClick(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
  PageControl1.ActivePage := tabNotepad;
  BringToFront;
end;

procedure TfrmMain.miTrayExitClick(Sender: TObject);
begin
  FAllowClose := True;
  Close;
end;

function TfrmMain.GetIniPath: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'AceUtils.ini';
end;

{ ----------------------------------------------------------------------------
  Shell Integration & INI Logic
  ---------------------------------------------------------------------------- }

procedure TfrmMain.CheckAndPromptFileAssociation;
var
  Ini: TIniFile;
  Prompted: Boolean;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    Prompted := Ini.ReadBool('FileAssociations', 'Prompted', False);
    if not Prompted then
    begin
      // Ask user to add associations and context menu
      if MessageDlg('File Association',
        'Would you like to associate .txt and .md files with Ace''s Utilities and add Explorer context menu integration?' + sLineBreak + sLineBreak +
        '(This enables opening .txt and .md files directly in Ace''s Utilities and bypasses the Windows 11 Notepad.)',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        RegisterFileAssociations(True);
        Ini.WriteBool('FileAssociations', 'Registered', True);
      end
      else
        Ini.WriteBool('FileAssociations', 'Registered', False);

      Ini.WriteBool('FileAssociations', 'Prompted', True);
    end;
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.DeleteKeyRecurse(const AKeyPath: string);
{$IFDEF WINDOWS}
var
  LReg: TRegistry;
  SubKeys: TStringList;
  i: Integer;
begin
  LReg := TRegistry.Create(KEY_ALL_ACCESS);
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    if LReg.OpenKey(AKeyPath, False) then
    begin
      SubKeys := TStringList.Create;
      try
        LReg.GetKeyNames(SubKeys);
        for i := 0 to SubKeys.Count - 1 do
          DeleteKeyRecurse(AKeyPath + '\' + SubKeys[i]);
      finally
        SubKeys.Free;
      end;
      LReg.CloseKey;
    end;
    LReg.DeleteKey(AKeyPath);
  finally
    LReg.Free;
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}

procedure TfrmMain.RegisterFileAssociations(ARegister: Boolean);
var
  Reg: TRegistry;
  AppExe, ExeTitle, CmdStr: string;

  procedure RegisterProgId(const AProgId, ADescription: string);
  begin
    // HKCU\Software\Classes\<ProgId>
    if Reg.OpenKey('Software\Classes\' + AProgId, True) then
    begin
      Reg.WriteString('', ADescription);
      Reg.CloseKey;
    end;
    if Reg.OpenKey('Software\Classes\' + AProgId + '\DefaultIcon', True) then
    begin
      Reg.WriteString('', AppExe + ',0');
      Reg.CloseKey;
    end;
    if Reg.OpenKey('Software\Classes\' + AProgId + '\shell\open', True) then
    begin
      Reg.WriteString('', 'Open with ' + ExeTitle);
      Reg.CloseKey;
    end;
    if Reg.OpenKey('Software\Classes\' + AProgId + '\shell\open\command', True) then
    begin
      Reg.WriteString('', CmdStr);
      Reg.CloseKey;
    end;
  end;

  procedure AssociateExtension(const AExt, AProgId, AContentType: string);
  begin
    // HKCU\Software\Classes\<ext>
    if Reg.OpenKey('Software\Classes\' + AExt, True) then
    begin
      Reg.WriteString('', AProgId);
      Reg.WriteString('PerceivedType', 'text');
      if AContentType <> '' then
        Reg.WriteString('Content Type', AContentType);
      Reg.CloseKey;
    end;

    // Direct shell\open\command under HKCU\Software\Classes\<ext> for maximum reliability
    if Reg.OpenKey('Software\Classes\' + AExt + '\shell\open', True) then
    begin
      Reg.WriteString('', 'Open with ' + ExeTitle);
      Reg.CloseKey;
    end;
    if Reg.OpenKey('Software\Classes\' + AExt + '\shell\open\command', True) then
    begin
      Reg.WriteString('', CmdStr);
      Reg.CloseKey;
    end;

    // HKCU\Software\Classes\<ext>\OpenWithProgids
    if Reg.OpenKey('Software\Classes\' + AExt + '\OpenWithProgids', True) then
    begin
      Reg.WriteString(AProgId, '');
      Reg.CloseKey;
    end;

    // HKCU\Software\Classes\SystemFileAssociations\<ext>\shell\AceUtils
    if Reg.OpenKey('Software\Classes\SystemFileAssociations\' + AExt + '\shell\AceUtils', True) then
    begin
      Reg.WriteString('', 'Open with ' + ExeTitle);
      Reg.WriteString('Icon', AppExe);
      Reg.CloseKey;
    end;
    if Reg.OpenKey('Software\Classes\SystemFileAssociations\' + AExt + '\shell\AceUtils\command', True) then
    begin
      Reg.WriteString('', CmdStr);
      Reg.CloseKey;
    end;

    // Windows 11 Explorer overrides: remove UserChoice and UserChoiceLatest to prevent modern Notepad hijacking
    DeleteKeyRecurse('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' + AExt + '\UserChoiceLatest');
    DeleteKeyRecurse('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' + AExt + '\UserChoice');

    // Add to FileExts\<ext>\OpenWithProgids
    if Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' + AExt + '\OpenWithProgids', True) then
    begin
      Reg.WriteString(AProgId, '');
      Reg.CloseKey;
    end;
  end;

  procedure UnassociateExtension(const AExt, AProgId: string);
  var
    CurVal: string;
  begin
    // Remove ProgID association if it matches ours
    if Reg.OpenKey('Software\Classes\' + AExt, False) then
    begin
      CurVal := Reg.ReadString('');
      Reg.CloseKey;
      if CurVal = AProgId then
      begin
        if Reg.OpenKey('Software\Classes\' + AExt, False) then
        begin
          Reg.DeleteValue('');
          Reg.CloseKey;
        end;
      end;
    end;

    DeleteKeyRecurse('Software\Classes\' + AExt + '\shell\open');

    if Reg.OpenKey('Software\Classes\' + AExt + '\OpenWithProgids', False) then
    begin
      Reg.DeleteValue(AProgId);
      Reg.CloseKey;
    end;

    if Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' + AExt + '\OpenWithProgids', False) then
    begin
      Reg.DeleteValue(AProgId);
      Reg.CloseKey;
    end;

    DeleteKeyRecurse('Software\Classes\SystemFileAssociations\' + AExt + '\shell\AceUtils');
  end;

begin
  AppExe := Application.ExeName;
  ExeTitle := 'Ace''s Utilities';
  CmdStr := '"' + AppExe + '" "%1"';

  Reg := TRegistry.Create(KEY_ALL_ACCESS);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if ARegister then
    begin
      // Clean up stale AceFileSearch registrations if any exist
      DeleteKeyRecurse('Software\Classes\SystemFileAssociations\.txt\shell\AceFileSearch');
      DeleteKeyRecurse('Software\Classes\SystemFileAssociations\.md\shell\AceFileSearch');
      DeleteKeyRecurse('Software\Classes\*\shell\AceFileSearch');

      // 1. Register ProgIDs for markdown and text files
      RegisterProgId('AceUtils.AssocFile.md', 'Markdown Document');
      RegisterProgId('AceUtils.AssocFile.txt', 'Text Document');

      // 2. Associate Extensions (.md, .markdown, .txt)
      AssociateExtension('.md', 'AceUtils.AssocFile.md', 'text/markdown');
      AssociateExtension('.markdown', 'AceUtils.AssocFile.md', 'text/markdown');
      AssociateExtension('.txt', 'AceUtils.AssocFile.txt', 'text/plain');

      // 3. Register Application under HKCU\Software\Classes\Applications\<exe>
      if Reg.OpenKey('Software\Classes\Applications\' + ExtractFileName(AppExe) + '\shell\open\command', True) then
      begin
        Reg.WriteString('', CmdStr);
        Reg.CloseKey;
      end;
      if Reg.OpenKey('Software\Classes\Applications\' + ExtractFileName(AppExe) + '\SupportedTypes', True) then
      begin
        Reg.WriteString('.md', '');
        Reg.WriteString('.markdown', '');
        Reg.WriteString('.txt', '');
        Reg.CloseKey;
      end;

      // 4. Global context menu under *
      if Reg.OpenKey('Software\Classes\*\shell\AceUtils', True) then
      begin
        Reg.WriteString('', 'Open with ' + ExeTitle);
        Reg.WriteString('Icon', AppExe);
        Reg.CloseKey;
      end;
      if Reg.OpenKey('Software\Classes\*\shell\AceUtils\command', True) then
      begin
        Reg.WriteString('', CmdStr);
        Reg.CloseKey;
      end;
    end
    else
    begin
      // 1. Unassociate Extensions
      UnassociateExtension('.md', 'AceUtils.AssocFile.md');
      UnassociateExtension('.markdown', 'AceUtils.AssocFile.md');
      UnassociateExtension('.txt', 'AceUtils.AssocFile.txt');

      // 2. Delete ProgIDs
      DeleteKeyRecurse('Software\Classes\AceUtils.AssocFile.md');
      DeleteKeyRecurse('Software\Classes\AceUtils.AssocFile.txt');

      // 3. Delete Application registration
      DeleteKeyRecurse('Software\Classes\Applications\' + ExtractFileName(AppExe));

      // 4. Delete global context menu
      DeleteKeyRecurse('Software\Classes\*\shell\AceUtils');
      DeleteKeyRecurse('Software\Classes\*\shell\AceFileSearch');
    end;
  finally
    Reg.Free;
  end;

  {$IFDEF WINDOWS}
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
  {$ENDIF}
end;

procedure TfrmMain.btnRegisterAssocClick(Sender: TObject);
var
  Ini: TIniFile;
  IsReg: Boolean;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    IsReg := Ini.ReadBool('FileAssociations', 'Registered', False);
    if IsReg then
    begin
      if MessageDlg('File Association',
        '"Open with Ace''s Utilities" and file associations are currently enabled.' + sLineBreak +
        'Would you like to REMOVE associations for .txt and .md files?',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        RegisterFileAssociations(False);
        Ini.WriteBool('FileAssociations', 'Registered', False);
        ShowMessage('File associations and context menu integration removed.');
      end;
    end
    else
    begin
      if MessageDlg('File Association',
        'Would you like to associate .txt and .md files with Ace''s Utilities?' + sLineBreak + sLineBreak +
        'This enables opening .txt and .md files in Ace''s Utilities and overcomes Windows 11 Notepad hijacking.',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        RegisterFileAssociations(True);
        Ini.WriteBool('FileAssociations', 'Registered', True);
        ShowMessage('File association enabled!' + sLineBreak + '.txt and .md files will now open in Ace''s Utilities.');
      end;
    end;
  finally
    Ini.Free;
  end;
end;

{ ----------------------------------------------------------------------------
  Dark Mode & Modern Theming
  ---------------------------------------------------------------------------- }

function TfrmMain.DetectWindowsDarkMode: Boolean;
var
  Reg: TRegistry;
begin
  Result := True; // Default to dark mode on modern Windows
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Themes\Personalize') then
    begin
      if Reg.ValueExists('AppsUseLightTheme') then
        Result := (Reg.ReadInteger('AppsUseLightTheme') = 0);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TfrmMain.SetWindowsTitleBarDark(AForm: TForm; ADark: Boolean);
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
        // 20 = DWMWA_USE_IMMERSIVE_DARK_MODE (Windows 10 19041+ & Windows 11)
        if SetAttr(AForm.Handle, 20, @DwmVal, SizeOf(DwmVal)) <> 0 then
        begin
          // 19 = older Windows 10 fallback
          SetAttr(AForm.Handle, 19, @DwmVal, SizeOf(DwmVal));
        end;
      end;
    finally
      FreeLibrary(DwmDll);
    end;
  end;
  {$ENDIF}
end;

procedure TfrmMain.ApplyTheme(ADark: Boolean);
var
  BgColor, PanelColor, EditBg, TextColor, GutterBg, HeaderBg: TColor;
begin
  FDarkMode := ADark;

  if ADark then
  begin
    // Modern Dark Charcoal / Slate Palette
    BgColor := $001A1816;
    PanelColor := $0024211E;
    HeaderBg := $002D2925;
    EditBg := $0034302B;
    TextColor := $00F0F0F0;
    GutterBg := $00201E1C;

    btnToggleDarkMode.Caption := '🌙 Dark Mode: ON';
  end
  else
  begin
    // Standard Light Theme
    BgColor := clBtnFace;
    PanelColor := clBtnFace;
    HeaderBg := $00EBEBEB;
    EditBg := clWindow;
    TextColor := clWindowText;
    GutterBg := clBtnFace;

    btnToggleDarkMode.Caption := '☀️ Dark Mode: OFF';
  end;

  // Window Title Bar
  SetWindowsTitleBarDark(Self, ADark);

  // Form & Panels
  Color := BgColor;
  pnlHeader.Color := HeaderBg;
  lblAppTitle.Font.Color := TextColor;

  pnlSearchTop.Color := PanelColor;
  pnlSearchProgress.Color := PanelColor;
  pnlSearchBody.Color := PanelColor;
  pnlLeft.Color := PanelColor;
  pnlLeftHeader.Color := HeaderBg;
  pnlRight.Color := PanelColor;
  pnlNotepadToolbar.Color := HeaderBg;
  pnlFindReplace.Color := PanelColor;
  pnlNotepadStatus.Color := HeaderBg;

  // Context Menu Management Tab
  pnlContextMenuToolbar.Color := HeaderBg;
  pnlContextMenuBottom.Color := HeaderBg;
  lvContextMenu.Color := EditBg;
  lvContextMenu.Font.Color := TextColor;
  edtEditVerbLabel.Color := EditBg;
  edtEditVerbLabel.Font.Color := TextColor;
  edtEditVerbCmd.Color := EditBg;
  edtEditVerbCmd.Font.Color := TextColor;
  lblContextMenuStatus.Font.Color := TextColor;
  lblEditVerbLabel.Font.Color := TextColor;
  lblEditVerbCmd.Font.Color := TextColor;
  if ADark then
    lblRemapHelp.Font.Color := $00A0A0A0
  else
    lblRemapHelp.Font.Color := clGray;

  // Labels
  lblPattern.Font.Color := TextColor;
  lblSearchIn.Font.Color := TextColor;
  lblContent.Font.Color := TextColor;
  lblActivity.Font.Color := TextColor;
  lblFolders.Font.Color := TextColor;
  lblSyntax.Font.Color := TextColor;
  lblCurrentFile.Font.Color := TextColor;
  lblFindText.Font.Color := TextColor;
  lblReplaceText.Font.Color := TextColor;
  lblNotepadStatus.Font.Color := TextColor;

  // Edits
  edtPattern.Color := EditBg;
  edtPattern.Font.Color := TextColor;
  edtSearchPath.Color := EditBg;
  edtSearchPath.Font.Color := TextColor;
  edtContent.Color := EditBg;
  edtContent.Font.Color := TextColor;
  edtFindText.Color := EditBg;
  edtFindText.Font.Color := TextColor;
  edtReplaceText.Color := EditBg;
  edtReplaceText.Font.Color := TextColor;

  // Checkboxes
  cbSubfolders.Font.Color := TextColor;
  cbCaseSensitive.Font.Color := TextColor;
  cbIncludeFolders.Font.Color := TextColor;
  cbEnablePreview.Font.Color := TextColor;
  cbRunInTray.Font.Color := TextColor;
  cbWordWrap.Font.Color := TextColor;
  cbMatchCase.Font.Color := TextColor;
  cbWholeWord.Font.Color := TextColor;

  // TreeView & ListView
  ShellTreeView1.Color := EditBg;
  ShellTreeView1.Font.Color := TextColor;
  lvResults.Color := EditBg;
  lvResults.Font.Color := TextColor;

  // SynEdit
  SynEdit1.Color := EditBg;
  if FCustomFontColor <> clNone then
    SynEdit1.Font.Color := FCustomFontColor
  else
    SynEdit1.Font.Color := TextColor;
  SynEdit1.Gutter.Color := GutterBg;
  SynEdit1.SelectedColor.Background := $006B4D2B;
  SynEdit1.SelectedColor.Foreground := clWhite;

  ApplyHighlighterTheme(ADark);

  if Assigned(frmPreview) then
    frmPreview.ApplyTheme(ADark);
end;

function TfrmMain.ConvertToUTF8(const S: string): string;
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

procedure TfrmMain.ApplyHighlighterTheme(ADark: Boolean);
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

procedure TfrmMain.btnToggleDarkModeClick(Sender: TObject);
begin
  ApplyTheme(not FDarkMode);
  SaveAllOptions;
end;

{ ----------------------------------------------------------------------------
  Search Tab Implementation
  ---------------------------------------------------------------------------- }

procedure TfrmMain.btnBrowseClick(Sender: TObject);
begin
  SelectDirectoryDialog1.InitialDir := edtSearchPath.Text;
  if SelectDirectoryDialog1.Execute then
  begin
    edtSearchPath.Text := SelectDirectoryDialog1.FileName;
    FSelectedPath := SelectDirectoryDialog1.FileName;
  end;
end;

procedure TfrmMain.btnDriveCClick(Sender: TObject);
begin
  edtSearchPath.Text := 'C:\';
  FSelectedPath := 'C:\';
end;

procedure TfrmMain.btnUserHomeClick(Sender: TObject);
var
  HomeDir: string;
begin
  HomeDir := SysUtils.GetEnvironmentVariable('USERPROFILE');
  if HomeDir = '' then
    HomeDir := GetUserDir;
  if HomeDir <> '' then
  begin
    edtSearchPath.Text := HomeDir;
    FSelectedPath := HomeDir;
  end;
end;

procedure TfrmMain.btnDesktopClick(Sender: TObject);
var
  DesktopDir: string;
begin
  DesktopDir := SysUtils.GetEnvironmentVariable('USERPROFILE') + '\Desktop';
  if DirectoryExists(DesktopDir) then
  begin
    edtSearchPath.Text := DesktopDir;
    FSelectedPath := DesktopDir;
  end;
end;

procedure TfrmMain.ShellTreeView1SelectionChanged(Sender: TObject);
var
  NodePath: string;
begin
  if ShellTreeView1.Selected <> nil then
  begin
    NodePath := ShellTreeView1.GetPathFromNode(ShellTreeView1.Selected);
    if NodePath <> '' then
    begin
      FSelectedPath := NodePath;
      edtSearchPath.Text := NodePath;
      SetStatus(' Selected: ' + NodePath);
    end;
  end;
end;

procedure TfrmMain.btnSearchClick(Sender: TObject);
var
  SearchPath, Pattern, Content: string;
begin
  Pattern := Trim(edtPattern.Text);
  if Pattern = '' then
  begin
    MessageDlg('Please enter a search pattern (e.g. *.png, readme, or *.*)',
      mtWarning, [mbOK], 0);
    Exit;
  end;

  SearchPath := Trim(edtSearchPath.Text);
  if SearchPath = '' then
    SearchPath := FSelectedPath;
  if SearchPath = '' then
    SearchPath := 'C:\';

  SearchPath := IncludeTrailingPathDelimiter(SearchPath);

  if not DirectoryExists(SearchPath) then
  begin
    MessageDlg('Directory does not exist: ' + SearchPath, mtError, [mbOK], 0);
    Exit;
  end;

  Content := Trim(edtContent.Text);

  // Clear previous results
  lvResults.Items.BeginUpdate;
  try
    lvResults.Items.Clear;
  finally
    lvResults.Items.EndUpdate;
  end;

  FFileCount := 0;
  FDirCount := 0;
  FStopSearch := False;
  SetSearching(True);
  SetActivity('Starting search in ' + SearchPath + ' ...');
  SetStatus(' Searching...');
  Application.ProcessMessages;

  try
    DoSearch(SearchPath, Pattern, Content, cbSubfolders.Checked,
      cbCaseSensitive.Checked, cbIncludeFolders.Checked);
  finally
    SetSearching(False);
    SetCounts;
    if FStopSearch then
    begin
      SetActivity(Format('Search stopped. Found %d item(s) across %d folder(s).', [FFileCount, FDirCount]));
      SetStatus(Format(' Stopped. %d item(s) found, %d folder(s) scanned.', [FFileCount, FDirCount]));
    end
    else
    begin
      if FFileCount = 0 then
        SetActivity(Format('Search complete. No matches found in %d folder(s).', [FDirCount]))
      else
        SetActivity(Format('Search complete. Found %d match(es) across %d folder(s).', [FFileCount, FDirCount]));
      SetStatus(Format(' Done. %d item(s) found, %d folder(s) scanned.', [FFileCount, FDirCount]));
    end;
  end;
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  FStopSearch := True;
  SetActivity('Stopping...');
end;

procedure TfrmMain.btnClearClick(Sender: TObject);
begin
  lvResults.Items.BeginUpdate;
  try
    lvResults.Items.Clear;
  finally
    lvResults.Items.EndUpdate;
  end;
  FFileCount := 0;
  FDirCount := 0;
  SetCounts;
  SetActivity('Ready.');
  SetStatus(' Results cleared.');
end;

procedure TfrmMain.btnOpenInNotepadClick(Sender: TObject);
begin
  miOpenInNotepadClick(Sender);
end;

function TfrmMain.IsImageFile(const APath: string): Boolean;
var
  Ext: string;
begin
  if (APath = '') or DirectoryExists(APath) then Exit(False);
  Ext := LowerCase(ExtractFileExt(APath));
  Result := (Ext = '.png') or (Ext = '.jpg') or (Ext = '.jpeg') or (Ext = '.bmp') or
            (Ext = '.ico') or (Ext = '.gif') or (Ext = '.jfif') or (Ext = '.tif') or
            (Ext = '.tiff') or (Ext = '.xpm');
end;

function TfrmMain.IsTextFile(const APath: string): Boolean;
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

function TfrmMain.IsPreviewableFile(const APath: string): Boolean;
begin
  Result := IsImageFile(APath) or IsTextFile(APath);
end;

procedure TfrmMain.TriggerFilePreview(Item: TListItem);
var
  FullPath, SizeStr, DateStr, TypeStr: string;
  SizeBytes: Int64;
  Info: PResultInfo;
begin
  if not cbEnablePreview.Checked then Exit;
  if Item = nil then
    Item := lvResults.Selected;
  if Item = nil then Exit;

  // Do not preview folders
  if (Item.SubItems.Count > 3) and (Item.SubItems[3] = 'Folder') then
    Exit;

  FullPath := IncludeTrailingPathDelimiter(Item.SubItems[0]) + Item.Caption;
  if not FileExists(FullPath) then Exit;

  // STRICTLY only preview files it knows how to preview
  if not IsPreviewableFile(FullPath) then
    Exit;

  // Deduplication guard: if already visible and displaying this file, avoid duplicate reload
  if Assigned(frmPreview) and frmPreview.Visible and (frmPreview.CurrentPath = FullPath) then
    Exit;

  Info := PResultInfo(Item.Data);
  if Info <> nil then
    SizeBytes := Info^.Size
  else
    SizeBytes := 0;

  if Item.SubItems.Count > 1 then
    SizeStr := Item.SubItems[1]
  else
    SizeStr := '';

  if Item.SubItems.Count > 2 then
    DateStr := Item.SubItems[2]
  else
    DateStr := '';

  if Item.SubItems.Count > 3 then
    TypeStr := Item.SubItems[3]
  else
    TypeStr := 'File';

  if Assigned(frmPreview) then
  begin
    frmPreview.ShowFile(FullPath, Item.Caption, SizeStr, DateStr, TypeStr, SizeBytes, FDarkMode);
    if not frmPreview.Visible then
      frmPreview.Show;
    frmPreview.BringToFront;
  end;
end;

procedure TfrmMain.cbEnablePreviewChange(Sender: TObject);
begin
  if not cbEnablePreview.Checked then
  begin
    if Assigned(frmPreview) then
      frmPreview.Hide;
  end
  else
  begin
    if lvResults.Selected <> nil then
      TriggerFilePreview(lvResults.Selected);
  end;
end;

procedure TfrmMain.lvResultsClick(Sender: TObject);
begin
  TriggerFilePreview(lvResults.Selected);
end;

procedure TfrmMain.lvResultsDblClick(Sender: TObject);
var
  FullPath: string;
begin
  if lvResults.Selected <> nil then
  begin
    FullPath := IncludeTrailingPathDelimiter(lvResults.Selected.SubItems[0]) + lvResults.Selected.Caption;
    if IsTextFile(FullPath) then
      miOpenInNotepadClick(Sender)
    else if FileExists(FullPath) then
      miOpenFileClick(Sender)
    else if DirectoryExists(FullPath) then
    begin
      edtSearchPath.Text := FullPath;
      PageControl1.ActivePage := tabSearch;
    end;
  end;
end;

procedure TfrmMain.lvResultsSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected and (Item <> nil) then
    TriggerFilePreview(Item);
end;

procedure TfrmMain.lvResultsColumnClick(Sender: TObject; Column: TListColumn);
var
  i: Integer;
  BaseCaption: string;
begin
  if FSortColumn = Column.Index then
    FSortAscending := not FSortAscending
  else
  begin
    FSortColumn := Column.Index;
    FSortAscending := True;
  end;

  // Update column header captions with ▲ / ▼
  for i := 0 to lvResults.Columns.Count - 1 do
  begin
    BaseCaption := lvResults.Columns[i].Caption;
    BaseCaption := StringReplace(BaseCaption, ' ▲', '', [rfReplaceAll]);
    BaseCaption := StringReplace(BaseCaption, ' ▼', '', [rfReplaceAll]);
    if i = FSortColumn then
    begin
      if FSortAscending then
        BaseCaption := BaseCaption + ' ▲'
      else
        BaseCaption := BaseCaption + ' ▼';
    end;
    lvResults.Columns[i].Caption := BaseCaption;
  end;

  // Sort list view using OnCompare
  lvResults.AlphaSort;
end;

procedure TfrmMain.lvResultsCompare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
var
  Info1, Info2: PResultInfo;
begin
  Compare := 0;
  if (Item1 = nil) or (Item2 = nil) then Exit;

  Info1 := PResultInfo(Item1.Data);
  Info2 := PResultInfo(Item2.Data);

  case FSortColumn of
    0: // File Name
      Compare := CompareText(Item1.Caption, Item2.Caption);

    1: // Folder
      if (Item1.SubItems.Count > 0) and (Item2.SubItems.Count > 0) then
        Compare := CompareText(Item1.SubItems[0], Item2.SubItems[0]);

    2: // Size (Int64 numeric)
      begin
        if (Info1 <> nil) and (Info2 <> nil) then
        begin
          if Info1^.IsFolder and (not Info2^.IsFolder) then
            Compare := -1
          else if (not Info1^.IsFolder) and Info2^.IsFolder then
            Compare := 1
          else if Info1^.Size < Info2^.Size then
            Compare := -1
          else if Info1^.Size > Info2^.Size then
            Compare := 1
          else
            Compare := 0;
        end;
      end;

    3: // Modified Date
      begin
        if (Info1 <> nil) and (Info2 <> nil) then
        begin
          if Info1^.Date < Info2^.Date then
            Compare := -1
          else if Info1^.Date > Info2^.Date then
            Compare := 1
          else
            Compare := 0;
        end;
      end;

    4: // Type
      if (Item1.SubItems.Count > 3) and (Item2.SubItems.Count > 3) then
        Compare := CompareText(Item1.SubItems[3], Item2.SubItems[3]);
  end;

  if not FSortAscending then
    Compare := -Compare;
end;

procedure TfrmMain.lvResultsDeletion(Sender: TObject; Item: TListItem);
begin
  if (Item <> nil) and (Item.Data <> nil) then
  begin
    Dispose(PResultInfo(Item.Data));
    Item.Data := nil;
  end;
end;

procedure TfrmMain.miOpenInNotepadClick(Sender: TObject);
var
  FullPath: string;
begin
  if lvResults.Selected <> nil then
  begin
    FullPath := IncludeTrailingPathDelimiter(lvResults.Selected.SubItems[0]) + lvResults.Selected.Caption;
    if FileExists(FullPath) then
    begin
      if not IsTextFile(FullPath) then
      begin
        MessageDlg('Notepad',
          'Only text-based and source code files can be opened in Notepad.' + sLineBreak + sLineBreak +
          'Selected file: ' + ExtractFileName(FullPath) + ' (' + UpperCase(ExtractFileExt(FullPath)) + ')',
          mtInformation, [mbOK], 0);
        Exit;
      end;
      OpenFileInNotepad(FullPath);
      PageControl1.ActivePage := tabNotepad;
    end
    else if DirectoryExists(FullPath) then
    begin
      edtSearchPath.Text := FullPath;
      PageControl1.ActivePage := tabSearch;
    end;
  end;
end;

procedure TfrmMain.miRevealInExplorerClick(Sender: TObject);
var
  FullPath: string;
begin
  {$IFDEF WINDOWS}
  if lvResults.Selected <> nil then
  begin
    FullPath := IncludeTrailingPathDelimiter(lvResults.Selected.SubItems[0]) + lvResults.Selected.Caption;
    ShellExecute(0, 'open', 'explorer.exe', PChar('/select,"' + FullPath + '"'), nil, SW_SHOWNORMAL);
  end;
  {$ENDIF}
end;

procedure TfrmMain.miOpenFileClick(Sender: TObject);
var
  FullPath: string;
begin
  {$IFDEF WINDOWS}
  if lvResults.Selected <> nil then
  begin
    FullPath := IncludeTrailingPathDelimiter(lvResults.Selected.SubItems[0]) + lvResults.Selected.Caption;
    ShellExecute(0, 'open', PChar(FullPath), nil, nil, SW_SHOWNORMAL);
  end;
  {$ENDIF}
end;

procedure TfrmMain.lvResultsContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  Item: TListItem;
  HasSelection: Boolean;
begin
  if (MousePos.X <> -1) and (MousePos.Y <> -1) then
  begin
    Item := lvResults.GetItemAt(MousePos.X, MousePos.Y);
    if Item <> nil then
      lvResults.Selected := Item;
  end;

  HasSelection := (lvResults.Selected <> nil);
  miOpenInNotepad.Enabled := HasSelection;
  miRevealInExplorer.Enabled := HasSelection;
  miOpenFile.Enabled := HasSelection;
  if Assigned(miCopyFileName) then miCopyFileName.Enabled := HasSelection;
  if Assigned(miCopyFilePath) then miCopyFilePath.Enabled := HasSelection;
  if Assigned(miCopyFullPath) then miCopyFullPath.Enabled := HasSelection;
  if Assigned(miCopyPath) then miCopyPath.Enabled := HasSelection;
end;

procedure TfrmMain.miCopyFileNameClick(Sender: TObject);
var
  S: string;
  i: Integer;
  SL: TStringList;
begin
  if lvResults.Selected = nil then Exit;

  if lvResults.SelCount > 1 then
  begin
    SL := TStringList.Create;
    try
      for i := 0 to lvResults.Items.Count - 1 do
        if lvResults.Items[i].Selected then
          SL.Add(lvResults.Items[i].Caption);
      Clipboard.AsText := SL.Text;
      SetStatus(Format(' %d filenames copied to clipboard', [SL.Count]));
    finally
      SL.Free;
    end;
  end
  else
  begin
    S := lvResults.Selected.Caption;
    Clipboard.AsText := S;
    SetStatus(' Filename copied to clipboard: ' + S);
  end;
end;

procedure TfrmMain.miCopyFilePathClick(Sender: TObject);
var
  S: string;
  i: Integer;
  SL: TStringList;
begin
  if lvResults.Selected = nil then Exit;

  if lvResults.SelCount > 1 then
  begin
    SL := TStringList.Create;
    try
      for i := 0 to lvResults.Items.Count - 1 do
        if lvResults.Items[i].Selected and (lvResults.Items[i].SubItems.Count > 0) then
          SL.Add(lvResults.Items[i].SubItems[0]);
      Clipboard.AsText := SL.Text;
      SetStatus(Format(' %d file paths copied to clipboard', [SL.Count]));
    finally
      SL.Free;
    end;
  end
  else
  begin
    if lvResults.Selected.SubItems.Count > 0 then
      S := lvResults.Selected.SubItems[0]
    else
      S := '';
    Clipboard.AsText := S;
    SetStatus(' File path copied to clipboard: ' + S);
  end;
end;

procedure TfrmMain.miCopyFullPathClick(Sender: TObject);
var
  S: string;
  i: Integer;
  SL: TStringList;
begin
  if lvResults.Selected = nil then Exit;

  if lvResults.SelCount > 1 then
  begin
    SL := TStringList.Create;
    try
      for i := 0 to lvResults.Items.Count - 1 do
        if lvResults.Items[i].Selected then
        begin
          if lvResults.Items[i].SubItems.Count > 0 then
            SL.Add(IncludeTrailingPathDelimiter(lvResults.Items[i].SubItems[0]) + lvResults.Items[i].Caption)
          else
            SL.Add(lvResults.Items[i].Caption);
        end;
      Clipboard.AsText := SL.Text;
      SetStatus(Format(' %d full paths copied to clipboard', [SL.Count]));
    finally
      SL.Free;
    end;
  end
  else
  begin
    if lvResults.Selected.SubItems.Count > 0 then
      S := IncludeTrailingPathDelimiter(lvResults.Selected.SubItems[0]) + lvResults.Selected.Caption
    else
      S := lvResults.Selected.Caption;
    Clipboard.AsText := S;
    SetStatus(' Path and filename copied to clipboard: ' + S);
  end;
end;

procedure TfrmMain.miCopyPathClick(Sender: TObject);
begin
  miCopyFullPathClick(Sender);
end;

{ ----------------------------------------------------------------------------
  Context Menu Management Implementation
  ---------------------------------------------------------------------------- }

procedure TfrmMain.PageControl1Change(Sender: TObject);
begin
  {$IFDEF WINDOWS}
  if PageControl1.ActivePage = tabContextMenu then
  begin
    if lvContextMenu.Items.Count = 0 then
      ScanContextMenuEntries;
  end;
  {$ENDIF}
end;

function TfrmMain.ExtractExecutableFromCommand(const Cmd: string): string;
var
  S: string;
  P: Integer;
begin
  Result := '';
  S := Trim(Cmd);
  if S = '' then Exit;

  if S[1] = '"' then
  begin
    Delete(S, 1, 1);
    P := Pos('"', S);
    if P > 0 then
      Result := Copy(S, 1, P - 1)
    else
      Result := S;
  end
  else
  begin
    P := Pos(' ', S);
    if P > 0 then
      Result := Copy(S, 1, P - 1)
    else
      Result := S;
  end;
end;

function TfrmMain.ValidateCommandTarget(const Cmd: string): Boolean;
{$IFDEF WINDOWS}
var
  ExePath: string;
begin
  ExePath := ExtractExecutableFromCommand(Cmd);
  if ExePath = '' then
    Exit(False);

  if FileExists(ExePath) or DirectoryExists(ExePath) then
    Exit(True);

  if ExtractFilePath(ExePath) = '' then
  begin
    if FileExists('C:\Windows\System32\' + ExePath) or
       FileExists('C:\Windows\' + ExePath) then
      Exit(True);
  end;

  Result := FileExists(ExePath);
end;
{$ELSE}
begin
  Result := True;
end;
{$ENDIF}

procedure TfrmMain.ScanContextMenuEntries;
{$IFDEF WINDOWS}
var
  Reg: TRegistry;
  StaleCount: Integer;

  procedure ScanShellKey(const ARootPath, AScopeName: string);
  var
    Verbs: TStringList;
    i: Integer;
    VerbKey, VerbPath, MenuText, CmdStr: string;
    Item: TListItem;
    IsValid: Boolean;
  begin
    if not Reg.OpenKeyReadOnly(ARootPath) then Exit;
    Verbs := TStringList.Create;
    try
      Reg.GetKeyNames(Verbs);
      Reg.CloseKey;

      for i := 0 to Verbs.Count - 1 do
      begin
        VerbKey := Verbs[i];
        VerbPath := ARootPath + '\' + VerbKey;

        MenuText := '';
        CmdStr := '';

        if Reg.OpenKeyReadOnly(VerbPath) then
        begin
          if Reg.ValueExists('') then
            MenuText := Reg.ReadString('');
          if (MenuText = '') and Reg.ValueExists('MUIVerb') then
            MenuText := Reg.ReadString('MUIVerb');
          Reg.CloseKey;
        end;

        if MenuText = '' then
          MenuText := VerbKey;

        if Reg.OpenKeyReadOnly(VerbPath + '\command') then
        begin
          if Reg.ValueExists('') then
            CmdStr := Reg.ReadString('');
          Reg.CloseKey;
        end;

        Item := lvContextMenu.Items.Add;
        Item.Caption := AScopeName;              // Col 0: Scope
        Item.SubItems.Add(VerbKey);              // Col 1: Verb Key
        Item.SubItems.Add(MenuText);             // Col 2: Display Text
        Item.SubItems.Add(CmdStr);               // Col 3: Command
        if CmdStr <> '' then
        begin
          IsValid := ValidateCommandTarget(CmdStr);
          if IsValid then
            Item.SubItems.Add('Active (OK)')
          else
          begin
            Item.SubItems.Add('STALE - File missing!');
            Inc(StaleCount);
          end;
        end
        else
        begin
          Item.SubItems.Add('No Command');
          Inc(StaleCount);
        end;
        Item.SubItems.Add(VerbPath);             // Col 5: SubKey Path
      end;
    finally
      Verbs.Free;
      Reg.CloseKey;
    end;
  end;

  procedure ScanApplications;
  var
    Apps: TStringList;
    i: Integer;
    AppKey, AppPath, CmdStr: string;
    Item: TListItem;
    IsValid: Boolean;
  begin
    if not Reg.OpenKeyReadOnly('Software\Classes\Applications') then Exit;
    Apps := TStringList.Create;
    try
      Reg.GetKeyNames(Apps);
      Reg.CloseKey;

      for i := 0 to Apps.Count - 1 do
      begin
        AppKey := Apps[i];
        AppPath := 'Software\Classes\Applications\' + AppKey + '\shell\open';
        if Reg.KeyExists(AppPath + '\command') then
        begin
          CmdStr := '';
          if Reg.OpenKeyReadOnly(AppPath + '\command') then
          begin
            if Reg.ValueExists('') then
              CmdStr := Reg.ReadString('');
            Reg.CloseKey;
          end;

          Item := lvContextMenu.Items.Add;
          Item.Caption := 'Applications';
          Item.SubItems.Add(AppKey);
          Item.SubItems.Add('Open with ' + AppKey);
          Item.SubItems.Add(CmdStr);
          if CmdStr <> '' then
          begin
            IsValid := ValidateCommandTarget(CmdStr);
            if IsValid then
              Item.SubItems.Add('Active (OK)')
            else
            begin
              Item.SubItems.Add('STALE - File missing!');
              Inc(StaleCount);
            end;
          end
          else
          begin
            Item.SubItems.Add('No Command');
            Inc(StaleCount);
          end;
          Item.SubItems.Add('Software\Classes\Applications\' + AppKey);
        end;
      end;
    finally
      Apps.Free;
      Reg.CloseKey;
    end;
  end;

begin
  lvContextMenu.Items.BeginUpdate;
  try
    lvContextMenu.Items.Clear;
    StaleCount := 0;

    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := HKEY_CURRENT_USER;

      ScanShellKey('Software\Classes\*\shell', 'All Files (*)');
      ScanShellKey('Software\Classes\Directory\shell', 'Folders (Directory)');
      ScanShellKey('Software\Classes\Directory\Background\shell', 'Desktop / Folder BG');
      ScanShellKey('Software\Classes\SystemFileAssociations\.txt\shell', 'Text Files (.txt)');
      ScanShellKey('Software\Classes\SystemFileAssociations\.md\shell', 'Markdown (.md)');
      ScanApplications;
    finally
      Reg.Free;
    end;
  finally
    lvContextMenu.Items.EndUpdate;
  end;

  if StaleCount > 0 then
    lblContextMenuStatus.Caption := Format('Total: %d entries found (%d STALE / broken targets)', [lvContextMenu.Items.Count, StaleCount])
  else
    lblContextMenuStatus.Caption := Format('Total: %d entries found (all targets valid)', [lvContextMenu.Items.Count]);
end;
{$ELSE}
begin
  lblContextMenuStatus.Caption := 'Context menu management is only available on Windows.';
end;
{$ENDIF}

procedure TfrmMain.btnRefreshContextMenuClick(Sender: TObject);
begin
  ScanContextMenuEntries;
  SetStatus(' Context menu list refreshed.');
end;

procedure TfrmMain.lvContextMenuSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected and (Item <> nil) and (Item.SubItems.Count >= 3) then
  begin
    edtEditVerbLabel.Text := Item.SubItems[1]; // Display Text
    edtEditVerbCmd.Text := Item.SubItems[2];   // Command
  end
  else
  begin
    edtEditVerbLabel.Text := '';
    edtEditVerbCmd.Text := '';
  end;
end;

procedure TfrmMain.lvContextMenuCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if (Item <> nil) and (Item.SubItems.Count >= 4) and (Pos('STALE', Item.SubItems[3]) > 0) then
  begin
    if FDarkMode then
      Sender.Canvas.Font.Color := $008080FF
    else
      Sender.Canvas.Font.Color := $000000C8;
  end;
  DefaultDraw := True;
end;

procedure TfrmMain.btnDeleteContextVerbClick(Sender: TObject);
{$IFDEF WINDOWS}
var
  SubKeyPath, VerbName: string;
begin
  if (lvContextMenu.Selected = nil) or (lvContextMenu.Selected.SubItems.Count < 5) then
  begin
    MessageDlg('Please select a context menu entry to remove.', mtInformation, [mbOK], 0);
    Exit;
  end;

  VerbName := lvContextMenu.Selected.SubItems[0];
  SubKeyPath := lvContextMenu.Selected.SubItems[4];

  if MessageDlg('Remove Context Menu Entry',
    Format('Are you sure you want to delete "%s"?' + sLineBreak + sLineBreak +
           'Registry SubKey: HKCU\%s' + sLineBreak + sLineBreak +
           'This only removes the per-user entry and requires no reboot.', [VerbName, SubKeyPath]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    DeleteKeyRecurse(SubKeyPath);
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
    ScanContextMenuEntries;
    SetStatus(' Context menu entry removed: ' + VerbName);
  end;
end;
{$ELSE}
begin
  ShowMessage('Context menu management is only available on Windows.');
end;
{$ENDIF}

procedure TfrmMain.btnCleanStaleVerbsClick(Sender: TObject);
{$IFDEF WINDOWS}
var
  i, RemovedCount: Integer;
  Item: TListItem;
  SubKeyPath: string;
begin
  RemovedCount := 0;
  for i := 0 to lvContextMenu.Items.Count - 1 do
    if (lvContextMenu.Items[i].SubItems.Count >= 4) and
       (Pos('STALE', lvContextMenu.Items[i].SubItems[3]) > 0) then
      Inc(RemovedCount);

  if RemovedCount = 0 then
  begin
    ShowMessage('No stale or orphaned context menu entries found.');
    Exit;
  end;

  if MessageDlg('Clean Stale Entries',
    Format('Found %d stale context menu entries with missing target executables.' + sLineBreak + sLineBreak +
           'Would you like to remove all of them from HKCU now?', [RemovedCount]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    for i := lvContextMenu.Items.Count - 1 downto 0 do
    begin
      Item := lvContextMenu.Items[i];
      if (Item.SubItems.Count >= 5) and (Pos('STALE', Item.SubItems[3]) > 0) then
      begin
        SubKeyPath := Item.SubItems[4];
        DeleteKeyRecurse(SubKeyPath);
      end;
    end;

    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
    ScanContextMenuEntries;
    ShowMessage(Format('Successfully cleaned %d stale context menu entries.', [RemovedCount]));
    SetStatus(Format(' Cleaned %d stale context menu entries.', [RemovedCount]));
  end;
end;
{$ELSE}
begin
  ShowMessage('Context menu management is only available on Windows.');
end;
{$ENDIF}

procedure TfrmMain.btnApplyRemapClick(Sender: TObject);
{$IFDEF WINDOWS}
var
  SubKeyPath, NewLabel, NewCmd: string;
  Reg: TRegistry;
begin
  if (lvContextMenu.Selected = nil) or (lvContextMenu.Selected.SubItems.Count < 5) then
  begin
    MessageDlg('Please select an entry to edit.', mtInformation, [mbOK], 0);
    Exit;
  end;

  SubKeyPath := lvContextMenu.Selected.SubItems[4];
  NewLabel := Trim(edtEditVerbLabel.Text);
  NewCmd := Trim(edtEditVerbCmd.Text);

  if NewCmd = '' then
  begin
    MessageDlg('Command line cannot be empty.', mtWarning, [mbOK], 0);
    Exit;
  end;

  Reg := TRegistry.Create(KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(SubKeyPath, False) then
    begin
      if NewLabel <> '' then
        Reg.WriteString('', NewLabel);
      Reg.CloseKey;
    end;

    if Reg.OpenKey(SubKeyPath + '\command', True) then
    begin
      Reg.WriteString('', NewCmd);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;

  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
  ScanContextMenuEntries;
  ShowMessage('Context menu entry updated successfully.');
  SetStatus(' Updated context menu entry: ' + SubKeyPath);
end;
{$ELSE}
begin
  ShowMessage('Context menu management is only available on Windows.');
end;
{$ENDIF}

procedure TfrmMain.btnBrowseRemapExeClick(Sender: TObject);
begin
  OpenDialog1.Title := 'Select Target Executable';
  OpenDialog1.Filter := 'Executable Files (*.exe;*.bat;*.cmd)|*.exe;*.bat;*.cmd|All Files (*.*)|*.*';
  if OpenDialog1.Execute then
    edtEditVerbCmd.Text := '"' + OpenDialog1.FileName + '" "%1"';
end;

procedure TfrmMain.btnTakeoverAssocClick(Sender: TObject);
{$IFDEF WINDOWS}
var
  Ini: TIniFile;
begin
  if MessageDlg('Take Back File Associations',
    'Enforce Ace''s Utilities as default handler for .txt and .md files?' + sLineBreak + sLineBreak +
    'This removes Windows 11 UserChoice overrides that redirect files to UWP Notepad, ' +
    'registers clean ProgIDs, and refreshes the Windows shell without admin rights.',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    RegisterFileAssociations(True);
    Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'AceUtils.ini');
    try
      Ini.WriteBool('FileAssociations', 'Registered', True);
    finally
      Ini.Free;
    end;
    ScanContextMenuEntries;
    ShowMessage('File associations reclaimed successfully!' + sLineBreak +
                '.txt and .md files will now open in Ace''s Utilities.');
    SetStatus(' File associations enforced for .txt and .md.');
  end;
end;
{$ELSE}
begin
  ShowMessage('File associations are only available on Windows.');
end;
{$ENDIF}

{ ----------------------------------------------------------------------------
  Core Search Engine
  ---------------------------------------------------------------------------- }

procedure TfrmMain.DoSearch(const APath, APattern, AContent: string;
  ARecursive, ACaseSensitive, AIncludeFolders: Boolean);
var
  DirQueue: TStringList;
  SR: TSearchRec;
  CurrentDir, FullFilePath: string;
  QueueIndex: Integer;
  TickCount, LastTick: QWord;
  HasContentFilter: Boolean;
  IsFolder, NameMatches: Boolean;
begin
  HasContentFilter := (AContent <> '');
  DirQueue := TStringList.Create;
  try
    DirQueue.Add(APath);
    QueueIndex := 0;
    LastTick := GetTickCount64;

    while (QueueIndex < DirQueue.Count) and (not FStopSearch) do
    begin
      CurrentDir := IncludeTrailingPathDelimiter(DirQueue[QueueIndex]);
      Inc(QueueIndex);
      Inc(FDirCount);

      // Periodically update UI
      TickCount := GetTickCount64;
      if (TickCount - LastTick) >= 80 then
      begin
        LastTick := TickCount;
        SetActivity('Scanning: ' + CurrentDir + ' (' + IntToStr(FFileCount) + ' found)');
        SetCounts;
        Application.ProcessMessages;
      end;

      // Scan folder
      if FindFirst(CurrentDir + '*', faAnyFile, SR) = 0 then
      begin
        try
          repeat
            if FStopSearch then Break;

            // Skip '.' and '..'
            if (SR.Name = '.') or (SR.Name = '..') then
              Continue;

            IsFolder := (SR.Attr and faDirectory) <> 0;

            if IsFolder then
            begin
              // Check folder name if user requested folder inclusion
              if AIncludeFolders and (not HasContentFilter) then
              begin
                if MatchesPattern(SR.Name, APattern, ACaseSensitive) then
                begin
                  AddResult(SR.Name, CurrentDir, 0, SafeFileDateToDateTime(SR.Time), 'Folder');
                  Inc(FFileCount);
                end;
              end;

              // Enqueue subfolders if recursive and NOT a reparse point (avoids junction infinite loops in Win11)
              if ARecursive and ((SR.Attr and FILE_ATTRIBUTE_REPARSE_POINT) = 0) then
              begin
                DirQueue.Add(CurrentDir + SR.Name);
              end;
            end
            else
            begin
              // File checks
              NameMatches := MatchesPattern(SR.Name, APattern, ACaseSensitive);
              if NameMatches then
              begin
                FullFilePath := CurrentDir + SR.Name;
                if (not HasContentFilter) or FileContainsText(FullFilePath, AContent, ACaseSensitive) then
                begin
                  AddResult(SR.Name, CurrentDir, SR.Size, SafeFileDateToDateTime(SR.Time), 'File');
                  Inc(FFileCount);

                  // Keep UI responsive during frequent finds
                  TickCount := GetTickCount64;
                  if (TickCount - LastTick) >= 100 then
                  begin
                    LastTick := TickCount;
                    SetActivity('Scanning: ' + CurrentDir + ' (' + IntToStr(FFileCount) + ' found)');
                    SetCounts;
                    Application.ProcessMessages;
                  end;
                end;
              end;
            end;

          until FindNext(SR) <> 0;
        finally
          SysUtils.FindClose(SR);
        end;
      end;
    end;
  finally
    DirQueue.Free;
  end;
end;

function TfrmMain.SafeFileDateToDateTime(ATime: LongInt): TDateTime;
begin
  try
    Result := FileDateToDateTime(ATime);
  except
    Result := 0;
  end;
end;

function TfrmMain.FormatFileSize(ASize: Int64): string;
begin
  if ASize < 1024 then
    Result := Format('%d B', [ASize])
  else if ASize < 1024 * 1024 then
    Result := Format('%.1f KB', [ASize / 1024.0])
  else if ASize < 1024 * 1024 * 1024 then
    Result := Format('%.1f MB', [ASize / (1024.0 * 1024.0)])
  else
    Result := Format('%.2f GB', [ASize / (1024.0 * 1024.0 * 1024.0)]);
end;

procedure TfrmMain.AddResult(const AFileName, AFolder: string; ASize: Int64;
  ADate: TDateTime; const AType: string);
var
  Item: TListItem;
  DateStr: string;
  Info: PResultInfo;
begin
  if ADate > 0 then
    DateStr := FormatDateTime('yyyy-mm-dd hh:nn:ss', ADate)
  else
    DateStr := '-';

  New(Info);
  Info^.Size := ASize;
  Info^.Date := ADate;
  Info^.IsFolder := (AType = 'Folder');

  Item := lvResults.Items.Add;
  Item.Data := Info;
  Item.Caption := AFileName;
  Item.SubItems.Add(ExcludeTrailingPathDelimiter(AFolder));
  if AType = 'Folder' then
    Item.SubItems.Add('<DIR>')
  else
    Item.SubItems.Add(FormatFileSize(ASize));
  Item.SubItems.Add(DateStr);
  Item.SubItems.Add(AType);
end;

procedure TfrmMain.SetStatus(const AMsg: string);
begin
  StatusBar1.Panels[0].Text := AMsg;
end;

procedure TfrmMain.SetActivity(const AMsg: string);
begin
  lblActivity.Caption := AMsg;
end;

procedure TfrmMain.SetCounts;
begin
  StatusBar1.Panels[1].Text := Format('Files: %d', [FFileCount]);
  StatusBar1.Panels[2].Text := Format('Dirs: %d', [FDirCount]);
end;

procedure TfrmMain.SetSearching(AValue: Boolean);
begin
  FSearching := AValue;
  btnSearch.Enabled := not AValue;
  btnStop.Enabled := AValue;
  btnClear.Enabled := not AValue;
  edtPattern.Enabled := not AValue;
  edtSearchPath.Enabled := not AValue;
  edtContent.Enabled := not AValue;
  btnBrowse.Enabled := not AValue;
  ShellTreeView1.Enabled := not AValue;
  ProgressBar1.Visible := AValue;
  if AValue then
    Screen.Cursor := crHourGlass
  else
    Screen.Cursor := crDefault;
end;

function TfrmMain.MatchesPattern(const AFileName, APattern: string;
  ACaseSensitive: Boolean): Boolean;
var
  Patterns: TStringList;
  i: Integer;
  FN, Pat: string;
begin
  Result := False;
  Patterns := TStringList.Create;
  try
    Patterns.Delimiter := ';';
    Patterns.StrictDelimiter := True;
    Patterns.DelimitedText := APattern;

    if ACaseSensitive then
      FN := AFileName
    else
      FN := LowerCase(AFileName);

    for i := 0 to Patterns.Count - 1 do
    begin
      if ACaseSensitive then
        Pat := Trim(Patterns[i])
      else
        Pat := LowerCase(Trim(Patterns[i]));

      if Pat = '' then Continue;

      // Smart match: If no wildcards (* or ?) are used, treat as a "contains" substring search
      if (Pos('*', Pat) = 0) and (Pos('?', Pat) = 0) then
      begin
        if Pos(Pat, FN) > 0 then
        begin
          Result := True;
          Exit;
        end;
      end
      else
      begin
        // Full wildcard match
        if MatchWildcard(FN, Pat) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  finally
    Patterns.Free;
  end;
end;

function TfrmMain.MatchWildcard(const AStr, APattern: string): Boolean;
var
  SP, PP: Integer;
  StarP, MatchP: Integer;
begin
  SP := 1;
  PP := 1;
  StarP := 0;
  MatchP := 1;

  while SP <= Length(AStr) do
  begin
    if (PP <= Length(APattern)) and
       ((APattern[PP] = '?') or (APattern[PP] = AStr[SP])) then
    begin
      Inc(SP);
      Inc(PP);
    end
    else if (PP <= Length(APattern)) and (APattern[PP] = '*') then
    begin
      StarP := PP;
      MatchP := SP;
      Inc(PP);
    end
    else if StarP > 0 then
    begin
      PP := StarP + 1;
      Inc(MatchP);
      SP := MatchP;
    end
    else
    begin
      Result := False;
      Exit;
    end;
  end;

  while (PP <= Length(APattern)) and (APattern[PP] = '*') do
    Inc(PP);

  Result := PP > Length(APattern);
end;

function TfrmMain.FileContainsText(const AFilePath, AText: string;
  ACaseSensitive: Boolean): Boolean;
var
  FS: TFileStream;
  Buffer: string;
  TargetText: string;
  ReadBytes: Integer;
  MaxRead: Integer;
begin
  Result := False;
  Buffer := '';
  if AText = '' then Exit(True);

  try
    FS := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
    try
      // Limit text search on files larger than 30MB for responsiveness
      if FS.Size > 30 * 1024 * 1024 then
        MaxRead := 30 * 1024 * 1024
      else
        MaxRead := FS.Size;

      SetLength(Buffer, MaxRead);
      ReadBytes := FS.Read(Buffer[1], MaxRead);
      SetLength(Buffer, ReadBytes);

      if ACaseSensitive then
        Result := (Pos(AText, Buffer) > 0)
      else
      begin
        TargetText := LowerCase(AText);
        Result := (Pos(TargetText, LowerCase(Buffer)) > 0);
      end;
    finally
      FS.Free;
    end;
  except
    Result := False;
  end;
end;

{ ----------------------------------------------------------------------------
  Notepad Tab Implementation
  ---------------------------------------------------------------------------- }

procedure TfrmMain.OpenFileInNotepad(const AFileName: string);
var
  FS: TFileStream;
  RawBytes, CleanStr: string;
begin
  if not PromptSaveIfModified then Exit;

  try
    FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(RawBytes, FS.Size);
      if FS.Size > 0 then
        FS.ReadBuffer(RawBytes[1], FS.Size);
    finally
      FS.Free;
    end;

    CleanStr := ConvertToUTF8(RawBytes);
    AutoDetectHighlighter(AFileName);
    SynEdit1.Text := CleanStr;
    SynEdit1.Invalidate;

    FCurrentFileName := AFileName;
    FIsModified := False;
    lblCurrentFile.Caption := ExtractFileName(AFileName) + ' (' + AFileName + ')';
    UpdateNotepadStatus;
    SetStatus(' Opened file: ' + AFileName);
  except
    on E: Exception do
      MessageDlg('Error opening file: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

function TfrmMain.SaveCurrentFile: Boolean;
begin
  if FCurrentFileName = '' then
  begin
    btnSaveAsClick(nil);
    Result := (FCurrentFileName <> '');
  end
  else
  begin
    try
      SynEdit1.Lines.SaveToFile(FCurrentFileName);
      FIsModified := False;
      lblCurrentFile.Caption := ExtractFileName(FCurrentFileName) + ' (' + FCurrentFileName + ')';
      UpdateNotepadStatus;
      SetStatus(' File saved: ' + FCurrentFileName);
      Result := True;
    except
      on E: Exception do
      begin
        MessageDlg('Error saving file: ' + E.Message, mtError, [mbOK], 0);
        Result := False;
      end;
    end;
  end;
end;

function TfrmMain.PromptSaveIfModified: Boolean;
var
  Res: Integer;
begin
  Result := True;
  if FIsModified then
  begin
    Res := MessageDlg('Save Changes',
      'The current document has unsaved modifications. Would you like to save before continuing?',
      mtConfirmation, [mbYes, mbNo, mbCancel], 0);
    if Res = mrYes then
      Result := SaveCurrentFile
    else if Res = mrCancel then
      Result := False;
  end;
end;

procedure TfrmMain.UpdateNotepadStatus;
var
  ModStr: string;
begin
  if FIsModified then ModStr := 'Modified' else ModStr := 'Saved';
  lblNotepadStatus.Caption := Format('Line: %d  Col: %d | Lines: %d | Chars: %d | UTF-8 | %s',
    [SynEdit1.CaretY, SynEdit1.CaretX, SynEdit1.Lines.Count, Length(SynEdit1.Text), ModStr]);
end;

procedure TfrmMain.AutoDetectHighlighter(const AFileName: string);
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  if (Ext = '.pas') or (Ext = '.pp') or (Ext = '.lpr') or (Ext = '.lfm') or (Ext = '.inc') or (Ext = '.dpr') then
    cmbSyntax.ItemIndex := 1
  else if (Ext = '.py') or (Ext = '.pyw') then
    cmbSyntax.ItemIndex := 2
  else if (Ext = '.html') or (Ext = '.htm') or (Ext = '.xhtml') or (Ext = '.xml') or (Ext = '.svg') then
    cmbSyntax.ItemIndex := 3
  else if (Ext = '.css') or (Ext = '.scss') or (Ext = '.less') then
    cmbSyntax.ItemIndex := 4
  else if (Ext = '.js') or (Ext = '.jsx') or (Ext = '.ts') or (Ext = '.tsx') or (Ext = '.json') or (Ext = '.mjs') then
    cmbSyntax.ItemIndex := 5
  else if Ext = '.sql' then
    cmbSyntax.ItemIndex := 6
  else if (Ext = '.bat') or (Ext = '.cmd') then
    cmbSyntax.ItemIndex := 7
  else if (Ext = '.ini') or (Ext = '.cfg') or (Ext = '.conf') or (Ext = '.inf') or
          (Ext = '.toml') or (Ext = '.yaml') or (Ext = '.yml') then
    cmbSyntax.ItemIndex := 8
  else if (Ext = '.php') or (Ext = '.php3') or (Ext = '.php4') or (Ext = '.php5') or (Ext = '.phtml') then
    cmbSyntax.ItemIndex := 9
  else if (Ext = '.c') or (Ext = '.cpp') or (Ext = '.cc') or (Ext = '.cxx') or
          (Ext = '.h') or (Ext = '.hpp') or (Ext = '.hxx') or (Ext = '.cs') then
    cmbSyntax.ItemIndex := 10
  else if (Ext = '.java') then
    cmbSyntax.ItemIndex := 11
  else if (Ext = '.diff') or (Ext = '.patch') then
    cmbSyntax.ItemIndex := 12
  else if (Ext = '.sh') or (Ext = '.bash') or (Ext = '.zsh') or (Ext = '.env') then
    cmbSyntax.ItemIndex := 13
  else if (Ext = '.md') or (Ext = '.markdown') or (Ext = '.mdown') or (Ext = '.mkd') then
    cmbSyntax.ItemIndex := 14
  else
    cmbSyntax.ItemIndex := 0;

  ApplySyntax(cmbSyntax.ItemIndex);
end;

procedure TfrmMain.ApplySyntax(Index: Integer);
begin
  case Index of
    1: SynEdit1.Highlighter := FHighlighterPas;
    2: SynEdit1.Highlighter := FHighlighterPython;
    3: SynEdit1.Highlighter := FHighlighterHTML;
    4: SynEdit1.Highlighter := FHighlighterCSS;
    5: SynEdit1.Highlighter := FHighlighterJS;
    6: SynEdit1.Highlighter := FHighlighterSQL;
    7: SynEdit1.Highlighter := FHighlighterBat;
    8: SynEdit1.Highlighter := FHighlighterIni;
    9: SynEdit1.Highlighter := FHighlighterPHP;
    10: SynEdit1.Highlighter := FHighlighterCpp;
    11: SynEdit1.Highlighter := FHighlighterJava;
    12: SynEdit1.Highlighter := FHighlighterDiff;
    13: SynEdit1.Highlighter := FHighlighterSh;
    14: SynEdit1.Highlighter := FHighlighterMarkdown;
    else
      SynEdit1.Highlighter := nil;
  end;
  SynEdit1.Invalidate;
end;

procedure TfrmMain.cmbSyntaxChange(Sender: TObject);
begin
  ApplySyntax(cmbSyntax.ItemIndex);
end;

procedure TfrmMain.btnNewFileClick(Sender: TObject);
begin
  if not PromptSaveIfModified then Exit;

  SynEdit1.Clear;
  FCurrentFileName := '';
  FIsModified := False;
  lblCurrentFile.Caption := 'Untitled';
  cmbSyntax.ItemIndex := 0;
  ApplySyntax(0);
  UpdateNotepadStatus;
end;

procedure TfrmMain.btnOpenFileClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    OpenFileInNotepad(OpenDialog1.FileName);
  end;
end;

procedure TfrmMain.btnSaveFileClick(Sender: TObject);
begin
  SaveCurrentFile;
end;

procedure TfrmMain.btnSaveAsClick(Sender: TObject);
begin
  if FCurrentFileName <> '' then
    SaveDialog1.FileName := FCurrentFileName
  else
    SaveDialog1.FileName := 'Untitled.txt';

  if SaveDialog1.Execute then
  begin
    FCurrentFileName := SaveDialog1.FileName;
    SaveCurrentFile;
    AutoDetectHighlighter(FCurrentFileName);
  end;
end;

procedure TfrmMain.btnUndoClick(Sender: TObject);
begin
  SynEdit1.Undo;
end;

procedure TfrmMain.btnRedoClick(Sender: TObject);
begin
  SynEdit1.Redo;
end;

procedure TfrmMain.cbWordWrapClick(Sender: TObject);
begin
  if cbWordWrap.Checked then
  begin
    if FWrapPlugin = nil then
      FWrapPlugin := TLazSynEditLineWrapPlugin.Create(SynEdit1);
    SynEdit1.ScrollBars := ssVertical;
  end
  else
  begin
    FreeAndNil(FWrapPlugin);
    SynEdit1.ScrollBars := ssBoth;
  end;
  SaveAllOptions;
end;

procedure TfrmMain.btnFontColorClick(Sender: TObject);
begin
  if FCustomFontColor <> clNone then
    ColorDialog1.Color := FCustomFontColor
  else
    ColorDialog1.Color := SynEdit1.Font.Color;

  if ColorDialog1.Execute then
  begin
    FCustomFontColor := ColorDialog1.Color;
    SynEdit1.Font.Color := FCustomFontColor;
    SaveAllOptions;
  end;
end;

procedure TfrmMain.btnFindDialogClick(Sender: TObject);
begin
  pnlFindReplace.Visible := not pnlFindReplace.Visible;
  if pnlFindReplace.Visible then
  begin
    if SynEdit1.SelText <> '' then
      edtFindText.Text := SynEdit1.SelText;
    edtFindText.SetFocus;
  end;
end;

procedure TfrmMain.btnCloseFindClick(Sender: TObject);
begin
  pnlFindReplace.Visible := False;
end;

procedure TfrmMain.btnFindNextClick(Sender: TObject);
var
  FindOpts: TSynSearchOptions;
begin
  if edtFindText.Text = '' then Exit;

  FindOpts := [ssoFindContinue];
  if cbMatchCase.Checked then
    Include(FindOpts, ssoMatchCase);
  if cbWholeWord.Checked then
    Include(FindOpts, ssoWholeWord);

  if SynEdit1.SearchReplace(edtFindText.Text, '', FindOpts) = 0 then
  begin
    // Wrap around search
    Exclude(FindOpts, ssoFindContinue);
    if SynEdit1.SearchReplace(edtFindText.Text, '', FindOpts) = 0 then
      ShowMessage('Text "' + edtFindText.Text + '" not found.');
  end;
end;

procedure TfrmMain.btnReplaceNextClick(Sender: TObject);
var
  FindOpts: TSynSearchOptions;
begin
  if edtFindText.Text = '' then Exit;

  FindOpts := [ssoReplace];
  if cbMatchCase.Checked then
    Include(FindOpts, ssoMatchCase);
  if cbWholeWord.Checked then
    Include(FindOpts, ssoWholeWord);

  if SynEdit1.SearchReplace(edtFindText.Text, edtReplaceText.Text, FindOpts) = 0 then
    ShowMessage('Text not found to replace.');
end;

procedure TfrmMain.btnReplaceAllClick(Sender: TObject);
var
  FindOpts: TSynSearchOptions;
  Count: Integer;
begin
  if edtFindText.Text = '' then Exit;

  FindOpts := [ssoReplaceAll];
  if cbMatchCase.Checked then
    Include(FindOpts, ssoMatchCase);
  if cbWholeWord.Checked then
    Include(FindOpts, ssoWholeWord);

  Count := SynEdit1.SearchReplace(edtFindText.Text, edtReplaceText.Text, FindOpts);
  ShowMessage(Format('Replaced %d occurrence(s).', [Count]));
end;

procedure TfrmMain.SynEdit1Change(Sender: TObject);
begin
  if not FIsModified then
  begin
    FIsModified := True;
    if FCurrentFileName <> '' then
      lblCurrentFile.Caption := '*' + ExtractFileName(FCurrentFileName) + ' (' + FCurrentFileName + ')'
    else
      lblCurrentFile.Caption := '*Untitled';
  end;
  UpdateNotepadStatus;
end;

procedure TfrmMain.SynEdit1StatusChange(Sender: TObject; Changes: TSynStatusChanges);
begin
  UpdateNotepadStatus;
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (PageControl1.ActivePage = tabNotepad) and (ssCtrl in Shift) then
  begin
    case Key of
      VK_C:
        if SynEdit1.Focused and (SynEdit1.SelText <> '') then
        begin
          SynEdit1.CopyToClipboard;
          Key := 0;
        end;
      VK_X:
        if SynEdit1.Focused and (SynEdit1.SelText <> '') then
        begin
          SynEdit1.CutToClipboard;
          Key := 0;
        end;
      VK_V:
        if SynEdit1.Focused then
        begin
          SynEdit1.PasteFromClipboard;
          Key := 0;
        end;
      VK_A:
        if SynEdit1.Focused then
        begin
          SynEdit1.SelectAll;
          Key := 0;
        end;
    end;
  end;
end;

procedure TfrmMain.popNotepadPopup(Sender: TObject);
begin
  miCut.Enabled := (SynEdit1.SelText <> '');
  miCopy.Enabled := (SynEdit1.SelText <> '');
  miPaste.Enabled := Clipboard.HasFormat(CF_TEXT);
  miDelete.Enabled := (SynEdit1.SelText <> '');
  miUndo.Enabled := SynEdit1.CanUndo;
  miRedo.Enabled := SynEdit1.CanRedo;
  miSelectAll.Enabled := (SynEdit1.Lines.Count > 0);
end;

procedure TfrmMain.miCutClick(Sender: TObject);
begin
  SynEdit1.CutToClipboard;
end;

procedure TfrmMain.miCopyClick(Sender: TObject);
begin
  SynEdit1.CopyToClipboard;
end;

procedure TfrmMain.miPasteClick(Sender: TObject);
begin
  SynEdit1.PasteFromClipboard;
end;

procedure TfrmMain.miDeleteClick(Sender: TObject);
begin
  SynEdit1.ClearSelection;
end;

procedure TfrmMain.miSelectAllClick(Sender: TObject);
begin
  SynEdit1.SelectAll;
end;

procedure TfrmMain.miUndoClick(Sender: TObject);
begin
  SynEdit1.Undo;
end;

procedure TfrmMain.miRedoClick(Sender: TObject);
begin
  SynEdit1.Redo;
end;

initialization
  {$I tabicons.lrs}
end.

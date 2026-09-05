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
  ImgList, LCLIntf, SynHighlighterMarkdown, LMessages;

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
    btnTabStyle: TButton;

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

    pnlEditorHeader: TPanel;
    btnCloseFile: TButton;

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
    popTabOptions: TPopupMenu;
    miTabStyleTabs: TMenuItem;
    miTabStyleFlat: TMenuItem;
    miTabStyleButtons: TMenuItem;
    miTabSep1: TMenuItem;
    miTabHighlightDot: TMenuItem;
    miTabTallHeight: TMenuItem;

    popNotepad: TPopupMenu;
    miNotepadSave: TMenuItem;
    miNotepadSaveAs: TMenuItem;
    miNotepadClose: TMenuItem;
    miSepNotepad0: TMenuItem;
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

    // The Real Explorer Components
    tabExplorer: TTabSheet;
    pnlExplorerTop: TPanel;
    pnlExplorerNav: TPanel;
    btnExpBack: TButton;
    btnExpForward: TButton;
    btnExpUp: TButton;
    btnExpRefresh: TButton;
    btnExpDefault: TButton;
    edtExpPath: TEdit;
    btnExpGo: TButton;
    btnExpSetDefault: TButton;
    btnExpPreview: TButton;
    btnExpNewFolder: TButton;
    pnlExpQuickBar: TPanel;
    lblExpQuick: TLabel;
    btnJumpDesktop: TButton;
    btnJumpDownloads: TButton;
    btnJumpDocuments: TButton;
    btnJumpPictures: TButton;
    btnJumpDriveC: TButton;
    btnJumpUserHome: TButton;
    cbExpPreviewAlways: TCheckBox;
    pnlExpBody: TPanel;
    pnlExpLeft: TPanel;
    ShellTreeViewExplorer: TShellTreeView;
    splExplorer: TSplitter;
    pnlExpRight: TPanel;
    ShellListViewExplorer: TShellListView;
    popExplorer: TPopupMenu;
    miExpOpen: TMenuItem;
    miExpOpenAssociated: TMenuItem;
    miExpNotepad: TMenuItem;
    miExpPreview: TMenuItem;
    miExpReveal: TMenuItem;
    miExpSep1: TMenuItem;
    miExpCopyPath: TMenuItem;
    miExpCopyName: TMenuItem;
    miExpSep2: TMenuItem;
    miExpNewFolder: TMenuItem;
    miExpRename: TMenuItem;
    miExpDelete: TMenuItem;

    // About Tab Components
    tabAbout: TTabSheet;
    pnlAboutHeader: TPanel;
    lblAboutTitle: TLabel;
    lblAboutSubtitle: TLabel;
    lblAboutAuthor: TLabel;
    pnlAboutLinks: TPanel;
    pnlLinkWeb: TPanel;
    pnlImgContainerWeb: TPanel;
    imgLinkWeb: TImage;
    lblLinkWebTitle: TLabel;
    lblLinkWebUrl: TLabel;
    pnlLinkFavAmp: TPanel;
    pnlImgContainerFavAmp: TPanel;
    imgLinkFavAmp: TImage;
    lblLinkFavAmpTitle: TLabel;
    lblLinkFavAmpUrl: TLabel;
    pnlLinkRankGalactic: TPanel;
    pnlImgContainerRankGalactic: TPanel;
    imgLinkRankGalactic: TImage;
    lblLinkRankGalacticTitle: TLabel;
    lblLinkRankGalacticUrl: TLabel;
    pnlLinkX: TPanel;
    pnlImgContainerX: TPanel;
    imgLinkX: TImage;
    lblLinkXTitle: TLabel;
    lblLinkXUrl: TLabel;
    pnlLinkGithub: TPanel;
    pnlImgContainerGithub: TPanel;
    imgLinkGithub: TImage;
    lblLinkGithubTitle: TLabel;
    lblLinkGithubUrl: TLabel;
    pcAboutInfo: TPageControl;
    tabAboutFeatures: TTabSheet;
    mmoAboutFeatures: TMemo;
    tabAboutBuildLog: TTabSheet;
    mmoAboutBuildLog: TMemo;
    tabAboutLicense: TTabSheet;
    mmoAboutLicense: TMemo;
    tmrStatus: TTimer;

    // Form Events
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tmrStatusTimer(Sender: TObject);

    // About Tab Events
    procedure pnlLinkWebClick(Sender: TObject);
    procedure pnlLinkFavAmpClick(Sender: TObject);
    procedure pnlLinkRankGalacticClick(Sender: TObject);
    procedure pnlLinkXClick(Sender: TObject);
    procedure pnlLinkGithubClick(Sender: TObject);

    // The Real Explorer Events
    procedure btnExpBackClick(Sender: TObject);
    procedure btnExpForwardClick(Sender: TObject);
    procedure btnExpUpClick(Sender: TObject);
    procedure btnExpRefreshClick(Sender: TObject);
    procedure btnExpDefaultClick(Sender: TObject);
    procedure edtExpPathKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnExpGoClick(Sender: TObject);
    procedure btnExpSetDefaultClick(Sender: TObject);
    procedure btnExpPreviewClick(Sender: TObject);
    procedure cbExpPreviewAlwaysChange(Sender: TObject);
    procedure miExpPreviewClick(Sender: TObject);
    procedure btnExpNewFolderClick(Sender: TObject);
    procedure btnJumpDesktopClick(Sender: TObject);
    procedure btnJumpDownloadsClick(Sender: TObject);
    procedure btnJumpDocumentsClick(Sender: TObject);
    procedure btnJumpPicturesClick(Sender: TObject);
    procedure btnJumpDriveCClick(Sender: TObject);
    procedure btnJumpUserHomeClick(Sender: TObject);
    procedure ShellTreeViewExplorerSelectionChanged(Sender: TObject);
    procedure ShellListViewExplorerDblClick(Sender: TObject);
    procedure ShellListViewExplorerSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ShellListViewExplorerKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure popExplorerPopup(Sender: TObject);
    procedure miExpOpenClick(Sender: TObject);
    procedure miExpOpenAssociatedClick(Sender: TObject);
    procedure miExpNotepadClick(Sender: TObject);
    procedure miExpRevealClick(Sender: TObject);
    procedure miExpCopyPathClick(Sender: TObject);
    procedure miExpCopyNameClick(Sender: TObject);
    procedure miExpRenameClick(Sender: TObject);
    procedure miExpDeleteClick(Sender: TObject);
    procedure ShellListViewExplorerColumnClick(Sender: TObject; Column: TListColumn);
    procedure ShellListViewExplorerCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure ShellListViewExplorerFileAdded(Sender: TObject; Item: TListItem);

    // Header & Tray Events
    procedure btnToggleDarkModeClick(Sender: TObject);
    procedure btnRegisterAssocClick(Sender: TObject);
    procedure btnTabStyleClick(Sender: TObject);
    procedure miTabStyleClick(Sender: TObject);
    procedure miTabHighlightDotClick(Sender: TObject);
    procedure miTabTallHeightClick(Sender: TObject);
    procedure popTabOptionsPopup(Sender: TObject);
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
    procedure lvContextMenuColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvContextMenuCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);

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
    procedure btnCloseFileClick(Sender: TObject);
    procedure SynEdit1Change(Sender: TObject);
    procedure SynEdit1Enter(Sender: TObject);
    procedure SynEdit1Exit(Sender: TObject);
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

    // Context Menu State
    FContextSortColumn: Integer;
    FContextSortAscending: Boolean;

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
    function MatchesParsedPattern(const AFileName: string; APatterns: TStrings; ACaseSensitive: Boolean): Boolean;
    function MatchesPattern(const AFileName, APattern: string; ACaseSensitive: Boolean): Boolean;
    function MatchWildcard(const AStr, APattern: string): Boolean;
    function FileContainsText(const AFilePath, AText: string; ACaseSensitive: Boolean): Boolean;
    function SafeFileDateToDateTime(ATime: LongInt): TDateTime;
    function FormatFileSize(ASize: Int64; IsFolder: Boolean = False): string;
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
    procedure UpdateSaveButtonState;
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

    // Status Bar & About Helpers
    procedure UpdateKeyboardAndTimerStatus;
    procedure LoadAboutContent;

  protected
    procedure WndProc(var Message: TLMessage); override;

  private
    // The Real Explorer State & Helpers
    FExpDefaultFolder: string;
    FExpHistory: TStringList;
    FExpHistoryIndex: Integer;
    FExpNavigating: Boolean;
    FExpSortColumn: Integer;
    FExpSortAscending: Boolean;
    FExpPreviewSyncing: Boolean;

    // Tab Styling & Highlighting State & Helpers
    FTabStyle: Integer;
    FHighlightActiveTab: Boolean;
    FTallTabs: Boolean;

    procedure UpdateTabHighlight;
    procedure SetTabStyle(AStyle: Integer);
    procedure UpdateTabOptionsMenu;

    procedure EnsureExplorerSystemImageList;
    procedure NavigateExplorerTo(const APath: string; AddToHistory: Boolean = True);
    procedure UpdateExplorerNavButtons;
    procedure PreviewExplorerFile(const APath: string);
    function GetExplorerSelectedPath: string;
    function GetUserDesktopPath: string;
    function GetUserSpecialPath(const AFoId: string): string;
  public
    procedure AutoFitListViewColumns(ALV: TWinControl; AColumns: TListColumns; MaxColWidth: Integer = 450);
    procedure OpenFileInNotepad(const AFileName: string);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

uses
  {$IFDEF WINDOWS}
  Windows, ShellAPI, ShlObj, CommCtrl,
  {$ENDIF}
  LResources, DateUtils, Math, PreviewForm, lazsynedittext;

const
  FILE_ATTRIBUTE_REPARSE_POINT = $00000400;

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

var
  WM_ACEUTILS_RESTORE: UINT = 0;

function CleanTabCaption(const ACap: string): string;
begin
  Result := StringReplace(ACap, '● ', '', [rfReplaceAll]);
  Result := StringReplace(Result, '▶ ', '', [rfReplaceAll]);
  Result := StringReplace(Result, '■ ', '', [rfReplaceAll]);
  Result := Trim(Result);
end;

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
  i: Integer;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    // General Options
    UserPrefersDark := Ini.ReadBool('General', 'DarkMode', DetectWindowsDarkMode);
    cbRunInTray.Checked := Ini.ReadBool('General', 'RunInTray', False);
    FTabStyle := Ini.ReadInteger('General', 'TabStyle', 0);
    FHighlightActiveTab := Ini.ReadBool('General', 'HighlightActiveTab', True);
    FTallTabs := Ini.ReadBool('General', 'TallTabs', True);

    if FTallTabs then
      PageControl1.TabHeight := 28
    else
      PageControl1.TabHeight := 0;

    case FTabStyle of
      1: PageControl1.Style := tsButtons;
      2: PageControl1.Style := tsFlatButtons;
      else
      begin
        FTabStyle := 0;
        PageControl1.Style := tsTabs;
      end;
    end;

    // Active Tab (defaults to The Real Explorer on initial launch)
    ColorStr := Ini.ReadString('General', 'ActiveTab', 'The Real Explorer');
    for i := 0 to PageControl1.PageCount - 1 do
      if CleanTabCaption(PageControl1.Pages[i].Caption) = CleanTabCaption(ColorStr) then
      begin
        PageControl1.ActivePageIndex := i;
        Break;
      end;

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
    cbWordWrap.Checked := Ini.ReadBool('Notepad', 'WordWrap', True);
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

    // Explorer Options
    FExpDefaultFolder := Ini.ReadString('Explorer', 'DefaultFolder', '');
    if (FExpDefaultFolder = '') or (not DirectoryExists(FExpDefaultFolder)) then
      FExpDefaultFolder := GetUserDesktopPath;
    cbExpPreviewAlways.Checked := Ini.ReadBool('Explorer', 'PreviewAlways', False);
    NavigateExplorerTo(FExpDefaultFolder);

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
    SafelyFreeWrapPlugin(FWrapPlugin, SynEdit1);
    SynEdit1.ScrollBars := ssBoth;
  end;

  // Apply Tray & Theme
  EnsureTrayIconLoaded;
  TrayIcon1.Visible := cbRunInTray.Checked;
  ApplyTheme(UserPrefersDark);
  UpdateTabHighlight;
  UpdateTabOptionsMenu;
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
    Ini.WriteInteger('General', 'TabStyle', FTabStyle);
    Ini.WriteBool('General', 'HighlightActiveTab', FHighlightActiveTab);
    Ini.WriteBool('General', 'TallTabs', FTallTabs);
    if Assigned(PageControl1.ActivePage) then
      Ini.WriteString('General', 'ActiveTab', CleanTabCaption(PageControl1.ActivePage.Caption));

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

    // Explorer Options
    Ini.WriteString('Explorer', 'DefaultFolder', FExpDefaultFolder);
    Ini.WriteBool('Explorer', 'PreviewAlways', cbExpPreviewAlways.Checked);
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  {$IFDEF WINDOWS}
  WM_ACEUTILS_RESTORE := RegisterWindowMessage('AceUtils_Restore_SingleInstance');
  {$ENDIF}
  FStopSearch := False;
  FSearching := False;
  FSelectedPath := 'C:\';
  FCurrentFileName := '';
  FIsModified := False;
  FSortColumn := -1;
  FSortAscending := True;
  FContextSortColumn := -1;
  FContextSortAscending := True;
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
  ImageList1.AddLazarusResource('chaicon-folder-open');
  ImageList1.AddLazarusResource('chaicon-info');
  PageControl1.Images := ImageList1;
  tabSearch.ImageIndex := 0;
  tabNotepad.ImageIndex := 1;
  tabContextMenu.ImageIndex := 2;
  tabExplorer.ImageIndex := 3;
  tabAbout.ImageIndex := 4;

  // Initialize The Real Explorer state
  FExpHistory := TStringList.Create;
  FExpHistoryIndex := -1;
  FExpNavigating := False;
  FExpSortColumn := -1;
  FExpSortAscending := True;
  FExpPreviewSyncing := False;
  FExpDefaultFolder := GetUserDesktopPath;

  ShellListViewExplorer.AutoSizeColumns := False;

  // Ensure Explorer has 4 standard columns: Name, Size, Type, Date Modified
  while ShellListViewExplorer.Columns.Count < 4 do
    ShellListViewExplorer.Columns.Add;
  ShellListViewExplorer.Columns[0].Caption := 'Name';
  ShellListViewExplorer.Columns[0].Width := 260;
  ShellListViewExplorer.Columns[1].Caption := 'Size';
  ShellListViewExplorer.Columns[1].Width := 90;
  ShellListViewExplorer.Columns[1].Alignment := taRightJustify;
  ShellListViewExplorer.Columns[2].Caption := 'Type';
  ShellListViewExplorer.Columns[2].Width := 100;
  ShellListViewExplorer.Columns[3].Caption := 'Date Modified';
  ShellListViewExplorer.Columns[3].Width := 140;

  ShellListViewExplorer.OnFileAdded := @ShellListViewExplorerFileAdded;

  LoadAboutContent;
  UpdateKeyboardAndTimerStatus;

  // Load and apply all saved settings
  LoadAllOptions;
  UpdateSaveButtonState;
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
  EnsureExplorerSystemImageList;
  ScanContextMenuEntries;
  AutoFitListViewColumns(ShellListViewExplorer, ShellListViewExplorer.Columns);
  AutoFitListViewColumns(lvResults, lvResults.Columns, 380);
  {$ENDIF}
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FExpHistory);
  SafelyFreeWrapPlugin(FWrapPlugin, SynEdit1);
  SaveAllOptions;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FSearching then
  begin
    FStopSearch := True;
    Application.ProcessMessages;
  end;
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
  UpdateTabHighlight;
  BringToFront;
end;

procedure TfrmMain.miTrayExitClick(Sender: TObject);
begin
  FAllowClose := True;
  Close;
end;

procedure TfrmMain.WndProc(var Message: TLMessage);
{$IFDEF WINDOWS}
var
  FWI: FLASHWINFO;
{$ENDIF}
begin
{$IFDEF WINDOWS}
  if (WM_ACEUTILS_RESTORE <> 0) and (Message.Msg = WM_ACEUTILS_RESTORE) then
  begin
    // Restore window even if minimized or hidden in the system tray
    if not Visible then
      Show;
    if WindowState = wsMinimized then
      WindowState := wsNormal;
    Application.Restore;
    Show;
    WindowState := wsNormal;
    BringToFront;

    // Force to the front of the screen stack (Z-order)
    SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_SHOWWINDOW);
    SetWindowPos(Handle, HWND_NOTOPMOST, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_SHOWWINDOW);
    SetForegroundWindow(Handle);
    BringWindowToTop(Handle);

    // Flash the window title and taskbar to alert the user
    FillChar(FWI, SizeOf(FWI), 0);
    FWI.cbSize := SizeOf(FWI);
    FWI.hwnd := Handle;
    FWI.dwFlags := FLASHW_ALL or FLASHW_TIMERNOFG;
    FWI.uCount := 4;
    FWI.dwTimeout := 0;
    FlashWindowEx(@FWI);

    Message.Result := 1;
    Exit;
  end;
{$ENDIF}
  inherited WndProc(Message);
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

procedure TfrmMain.UpdateTabHighlight;
var
  i: Integer;
  BaseCap: string;
begin
  for i := 0 to PageControl1.PageCount - 1 do
  begin
    BaseCap := CleanTabCaption(PageControl1.Pages[i].Caption);
    if FHighlightActiveTab and (PageControl1.Pages[i] = PageControl1.ActivePage) then
      PageControl1.Pages[i].Caption := '● ' + BaseCap
    else
      PageControl1.Pages[i].Caption := BaseCap;
  end;
end;

procedure TfrmMain.SetTabStyle(AStyle: Integer);
begin
  FTabStyle := AStyle;
  case AStyle of
    1: PageControl1.Style := tsButtons;
    2: PageControl1.Style := tsFlatButtons;
    else
    begin
      FTabStyle := 0;
      PageControl1.Style := tsTabs;
    end;
  end;
  UpdateTabOptionsMenu;
  SaveAllOptions;
end;

procedure TfrmMain.UpdateTabOptionsMenu;
begin
  if Assigned(miTabStyleTabs) then
    miTabStyleTabs.Checked := (FTabStyle = 0);
  if Assigned(miTabStyleFlat) then
    miTabStyleFlat.Checked := (FTabStyle = 2);
  if Assigned(miTabStyleButtons) then
    miTabStyleButtons.Checked := (FTabStyle = 1);
  if Assigned(miTabHighlightDot) then
    miTabHighlightDot.Checked := FHighlightActiveTab;
  if Assigned(miTabTallHeight) then
    miTabTallHeight.Checked := FTallTabs;
end;

procedure TfrmMain.btnTabStyleClick(Sender: TObject);
var
  P: TPoint;
begin
  UpdateTabOptionsMenu;
  P.X := 0;
  P.Y := btnTabStyle.Height;
  P := btnTabStyle.ClientToScreen(P);
  popTabOptions.PopUp(P.X, P.Y);
end;

procedure TfrmMain.miTabStyleClick(Sender: TObject);
begin
  if Sender = miTabStyleButtons then
    SetTabStyle(1)
  else if Sender = miTabStyleFlat then
    SetTabStyle(2)
  else
    SetTabStyle(0);
end;

procedure TfrmMain.miTabHighlightDotClick(Sender: TObject);
begin
  FHighlightActiveTab := not FHighlightActiveTab;
  UpdateTabOptionsMenu;
  UpdateTabHighlight;
  SaveAllOptions;
end;

procedure TfrmMain.miTabTallHeightClick(Sender: TObject);
begin
  FTallTabs := not FTallTabs;
  if FTallTabs then
    PageControl1.TabHeight := 28
  else
    PageControl1.TabHeight := 0;
  UpdateTabOptionsMenu;
  SaveAllOptions;
end;

procedure TfrmMain.popTabOptionsPopup(Sender: TObject);
begin
  UpdateTabOptionsMenu;
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
  pnlEditorHeader.Color := HeaderBg;
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

  // About Tab
  pnlAboutHeader.Color := HeaderBg;
  pnlAboutLinks.Color := HeaderBg;
  pnlLinkWeb.Color := PanelColor;
  pnlLinkFavAmp.Color := PanelColor;
  pnlLinkRankGalactic.Color := PanelColor;
  pnlLinkX.Color := PanelColor;
  pnlLinkGithub.Color := PanelColor;

  if ADark then
  begin
    pnlImgContainerWeb.Color := $002E2E2E;
    pnlImgContainerFavAmp.Color := $002E2E2E;
    pnlImgContainerRankGalactic.Color := $002E2E2E;
    pnlImgContainerX.Color := $002E2E2E;
    pnlImgContainerGithub.Color := $002E2E2E;

    lblAboutSubtitle.Font.Color := $00C0C0C0;
    lblAboutAuthor.Font.Color := $00A0A0A0;
    lblLinkWebUrl.Font.Color := $00FFB060;
    lblLinkFavAmpUrl.Font.Color := $00FFB060;
    lblLinkRankGalacticUrl.Font.Color := $00FFB060;
    lblLinkXUrl.Font.Color := $00FFB060;
    lblLinkGithubUrl.Font.Color := $00FFB060;
  end
  else
  begin
    pnlImgContainerWeb.Color := $00E8E8E8;
    pnlImgContainerFavAmp.Color := $00E8E8E8;
    pnlImgContainerRankGalactic.Color := $00E8E8E8;
    pnlImgContainerX.Color := $00E8E8E8;
    pnlImgContainerGithub.Color := $00E8E8E8;

    lblAboutSubtitle.Font.Color := clGray;
    lblAboutAuthor.Font.Color := clGray;
    lblLinkWebUrl.Font.Color := clHighlight;
    lblLinkFavAmpUrl.Font.Color := clHighlight;
    lblLinkRankGalacticUrl.Font.Color := clHighlight;
    lblLinkXUrl.Font.Color := clHighlight;
    lblLinkGithubUrl.Font.Color := clHighlight;
  end;

  lblAboutTitle.Font.Color := TextColor;
  lblLinkWebTitle.Font.Color := TextColor;
  lblLinkFavAmpTitle.Font.Color := TextColor;
  lblLinkRankGalacticTitle.Font.Color := TextColor;
  lblLinkXTitle.Font.Color := TextColor;
  lblLinkGithubTitle.Font.Color := TextColor;
  mmoAboutFeatures.Color := EditBg;
  mmoAboutFeatures.Font.Color := TextColor;
  mmoAboutBuildLog.Color := EditBg;
  mmoAboutBuildLog.Font.Color := TextColor;
  mmoAboutLicense.Color := EditBg;
  mmoAboutLicense.Font.Color := TextColor;

  // The Real Explorer Tab
  pnlExplorerTop.Color := HeaderBg;
  pnlExplorerNav.Color := HeaderBg;
  pnlExpQuickBar.Color := PanelColor;
  lblExpQuick.Font.Color := TextColor;
  edtExpPath.Color := EditBg;
  edtExpPath.Font.Color := TextColor;
  pnlExpLeft.Color := PanelColor;
  pnlExpRight.Color := PanelColor;
  ShellTreeViewExplorer.Color := EditBg;
  ShellTreeViewExplorer.Font.Color := TextColor;
  ShellListViewExplorer.Color := EditBg;
  ShellListViewExplorer.Font.Color := TextColor;

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
  if Assigned(cbExpPreviewAlways) then
    cbExpPreviewAlways.Font.Color := TextColor;
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
  while (Length(SearchPath) > 0) and (SearchPath[1] in ['"', '''']) do
    Delete(SearchPath, 1, 1);
  while (Length(SearchPath) > 0) and (SearchPath[Length(SearchPath)] in ['"', '''']) do
    Delete(SearchPath, Length(SearchPath), 1);
  SearchPath := Trim(SearchPath);

  if SearchPath = '' then
    SearchPath := FSelectedPath;
  if SearchPath = '' then
    SearchPath := 'C:\';

  // If user pasted a file path instead of folder, extract directory
  if FileExists(SearchPath) and (not DirectoryExists(SearchPath)) then
  begin
    SearchPath := ExtractFileDir(SearchPath);
    edtSearchPath.Text := SearchPath;
  end;

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
    Application.ProcessMessages; // Drain any clicks queued while search was running
    SetSearching(False);
    SetCounts;
    if lvResults.Items.Count > 0 then
      AutoFitListViewColumns(lvResults, lvResults.Columns, 380);
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
  btnStop.Enabled := False;
  SetActivity('Stopping search...');
  SetStatus(' Stopping...');
end;

procedure TfrmMain.btnClearClick(Sender: TObject);
begin
  lvResults.Items.BeginUpdate;
  try
    lvResults.Items.Clear;
  finally
    lvResults.Items.EndUpdate;
  end;
  AutoFitListViewColumns(lvResults, lvResults.Columns, 380);
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
  AutoFitListViewColumns(lvResults, lvResults.Columns, 380);
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
  if lvResults.Selected <> nil then
  begin
    FullPath := IncludeTrailingPathDelimiter(lvResults.Selected.SubItems[0]) + lvResults.Selected.Caption;
    {$IFDEF WINDOWS}
    ShellExecute(0, 'open', PChar(FullPath), nil, nil, SW_SHOWNORMAL);
    {$ELSE}
    OpenDocument(FullPath);
    {$ENDIF}
  end;
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
  UpdateTabHighlight;
  UpdateSaveButtonState;
  {$IFDEF WINDOWS}
  if PageControl1.ActivePage = tabContextMenu then
  begin
    if lvContextMenu.Items.Count = 0 then
      ScanContextMenuEntries;
  end
  else if PageControl1.ActivePage = tabExplorer then
  begin
    EnsureExplorerSystemImageList;
    AutoFitListViewColumns(ShellListViewExplorer, ShellListViewExplorer.Columns);
    if cbExpPreviewAlways.Checked and (ShellListViewExplorer.Selected <> nil) then
      PreviewExplorerFile(GetExplorerSelectedPath);
  end
  else if PageControl1.ActivePage = tabSearch then
  begin
    AutoFitListViewColumns(lvResults, lvResults.Columns, 380);
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

  if FContextSortColumn >= 0 then
    lvContextMenu.AlphaSort;
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

procedure TfrmMain.lvContextMenuColumnClick(Sender: TObject; Column: TListColumn);
var
  i: Integer;
  BaseCaption: string;
begin
  if FContextSortColumn = Column.Index then
    FContextSortAscending := not FContextSortAscending
  else
  begin
    FContextSortColumn := Column.Index;
    FContextSortAscending := True;
  end;

  // Update column header captions with ▲ / ▼
  for i := 0 to lvContextMenu.Columns.Count - 1 do
  begin
    BaseCaption := lvContextMenu.Columns[i].Caption;
    BaseCaption := StringReplace(BaseCaption, ' ▲', '', [rfReplaceAll]);
    BaseCaption := StringReplace(BaseCaption, ' ▼', '', [rfReplaceAll]);
    if i = FContextSortColumn then
    begin
      if FContextSortAscending then
        BaseCaption := BaseCaption + ' ▲'
      else
        BaseCaption := BaseCaption + ' ▼';
    end;
    lvContextMenu.Columns[i].Caption := BaseCaption;
  end;

  // Sort list view using OnCompare
  lvContextMenu.AlphaSort;
end;

procedure TfrmMain.lvContextMenuCompare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
var
  S1, S2: string;
  Idx: Integer;
begin
  Compare := 0;
  if (Item1 = nil) or (Item2 = nil) then Exit;

  if FContextSortColumn = 0 then
  begin
    S1 := Item1.Caption;
    S2 := Item2.Caption;
  end
  else
  begin
    Idx := FContextSortColumn - 1;
    if Idx < Item1.SubItems.Count then S1 := Item1.SubItems[Idx] else S1 := '';
    if Idx < Item2.SubItems.Count then S2 := Item2.SubItems[Idx] else S2 := '';
  end;

  Compare := CompareText(S1, S2);

  if not FContextSortAscending then
    Compare := -Compare;
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
  PatternList: TStringList;
  SR: TSearchRec;
  CurrentDir, FullFilePath: string;
  QueueIndex: Integer;
  TickCount, LastTick: QWord;
  HasContentFilter: Boolean;
  IsFolder, NameMatches: Boolean;
  FilesScannedInDir: Integer;
begin
  HasContentFilter := (AContent <> '');
  DirQueue := TStringList.Create;
  PatternList := TStringList.Create;
  try
    PatternList.Delimiter := ';';
    PatternList.StrictDelimiter := True;
    PatternList.DelimitedText := APattern;

    DirQueue.Add(APath);
    QueueIndex := 0;
    LastTick := GetTickCount64;

    while (QueueIndex < DirQueue.Count) and (not FStopSearch) do
    begin
      CurrentDir := IncludeTrailingPathDelimiter(DirQueue[QueueIndex]);
      Inc(QueueIndex);
      Inc(FDirCount);

      // Periodically update UI and process cancellation
      TickCount := GetTickCount64;
      if (TickCount - LastTick) >= 50 then
      begin
        LastTick := TickCount;
        SetActivity('Scanning: ' + CurrentDir + ' (' + IntToStr(FFileCount) + ' found)');
        SetCounts;
        Application.ProcessMessages;
        if FStopSearch then Break;
      end;

      if FStopSearch then Break;

      FilesScannedInDir := 0;

      // Scan folder
      if FindFirst(CurrentDir + '*', faAnyFile, SR) = 0 then
      begin
        try
          repeat
            if FStopSearch then Break;

            // Keep UI responsive during folder enumeration even when files do not match
            Inc(FilesScannedInDir);
            if (FilesScannedInDir and 31 = 0) then
            begin
              TickCount := GetTickCount64;
              if (TickCount - LastTick) >= 50 then
              begin
                LastTick := TickCount;
                SetActivity('Scanning: ' + CurrentDir + ' (' + IntToStr(FFileCount) + ' found)');
                SetCounts;
                Application.ProcessMessages;
                if FStopSearch then Break;
              end;
            end;

            // Skip '.' and '..'
            if (SR.Name = '.') or (SR.Name = '..') then
              Continue;

            IsFolder := (SR.Attr and faDirectory) <> 0;

            if IsFolder then
            begin
              // Check folder name if user requested folder inclusion
              if AIncludeFolders and (not HasContentFilter) then
              begin
                if MatchesParsedPattern(SR.Name, PatternList, ACaseSensitive) then
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
              NameMatches := MatchesParsedPattern(SR.Name, PatternList, ACaseSensitive);
              if NameMatches then
              begin
                if FStopSearch then Break;
                FullFilePath := CurrentDir + SR.Name;
                if (not HasContentFilter) or FileContainsText(FullFilePath, AContent, ACaseSensitive) then
                begin
                  AddResult(SR.Name, CurrentDir, SR.Size, SafeFileDateToDateTime(SR.Time), 'File');
                  Inc(FFileCount);

                  // Keep UI responsive during frequent finds
                  TickCount := GetTickCount64;
                  if (TickCount - LastTick) >= 50 then
                  begin
                    LastTick := TickCount;
                    SetActivity('Scanning: ' + CurrentDir + ' (' + IntToStr(FFileCount) + ' found)');
                    SetCounts;
                    Application.ProcessMessages;
                    if FStopSearch then Break;
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
    PatternList.Free;
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

function TfrmMain.FormatFileSize(ASize: Int64; IsFolder: Boolean = False): string;
var
  Val: Double;
begin
  if IsFolder then
  begin
    Result := '';
    Exit;
  end;

  if ASize <= 0 then
  begin
    Result := '0 KB';
    Exit;
  end;

  if ASize < 1024 then
  begin
    Val := ASize / 1024.0;
    Result := Format('%.2f KB', [Val]);
  end
  else if ASize < 100 * 1024 then
  begin
    Val := ASize / 1024.0;
    if Val >= 10.0 then
      Result := Format('%.1f KB', [Val])
    else
      Result := Format('%.2f KB', [Val]);
  end
  else if ASize < 1024 * 1024 * 1024 then
  begin
    Val := ASize / (1024.0 * 1024.0);
    Result := Format('%.2f MB', [Val]);
  end
  else
  begin
    Val := ASize / (1024.0 * 1024.0 * 1024.0);
    Result := Format('%.2f GB', [Val]);
  end;
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
    Item.SubItems.Add('')
  else
    Item.SubItems.Add(FormatFileSize(ASize, False));
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

function TfrmMain.MatchesParsedPattern(const AFileName: string;
  APatterns: TStrings; ACaseSensitive: Boolean): Boolean;
var
  i: Integer;
  FN, Pat: string;
begin
  Result := False;
  if (APatterns = nil) or (APatterns.Count = 0) then Exit(True);

  if ACaseSensitive then
    FN := AFileName
  else
    FN := LowerCase(AFileName);

  for i := 0 to APatterns.Count - 1 do
  begin
    if ACaseSensitive then
      Pat := Trim(APatterns[i])
    else
      Pat := LowerCase(Trim(APatterns[i]));

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
end;

function TfrmMain.MatchesPattern(const AFileName, APattern: string;
  ACaseSensitive: Boolean): Boolean;
var
  Patterns: TStringList;
begin
  Patterns := TStringList.Create;
  try
    Patterns.Delimiter := ';';
    Patterns.StrictDelimiter := True;
    Patterns.DelimitedText := APattern;
    Result := MatchesParsedPattern(AFileName, Patterns, ACaseSensitive);
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
  if FStopSearch or (AText = '') then Exit(False);

  try
    FS := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
    try
      if FStopSearch then Exit(False);

      // Limit text search on files larger than 30MB for responsiveness
      if FS.Size > 30 * 1024 * 1024 then
        MaxRead := 30 * 1024 * 1024
      else
        MaxRead := FS.Size;

      if MaxRead <= 0 then Exit(False);

      SetLength(Buffer, MaxRead);
      ReadBytes := FS.Read(Buffer[1], MaxRead);
      SetLength(Buffer, ReadBytes);

      if FStopSearch then Exit(False);

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
    SynEdit1.Modified := False;
    SynEdit1.ClearUndo;
    SynEdit1.Invalidate;

    FCurrentFileName := AFileName;
    FIsModified := False;
    lblCurrentFile.Caption := ExtractFileName(AFileName) + ' (' + AFileName + ')';
    PageControl1.ActivePage := tabNotepad;
    UpdateTabHighlight;
    UpdateNotepadStatus;
    UpdateSaveButtonState;
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
      UpdateSaveButtonState;
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

procedure TfrmMain.UpdateSaveButtonState;
var
  OnNotepadTab: Boolean;
  HasContent: Boolean;
  CanSave: Boolean;
  CanSaveAs: Boolean;
  CanClose: Boolean;
begin
  OnNotepadTab := (PageControl1.ActivePage = tabNotepad);
  HasContent := (SynEdit1.Lines.Count > 1) or ((SynEdit1.Lines.Count = 1) and (Trim(SynEdit1.Lines[0]) <> ''));

  // Save is enabled if on Notepad tab, document has modifications, and is not empty
  CanSave := OnNotepadTab and HasContent and FIsModified;

  // Save As is enabled if on Notepad tab and document has content or an open file
  CanSaveAs := OnNotepadTab and (HasContent or (FCurrentFileName <> ''));

  // Close is enabled whenever a file is open or editor has content (regardless of whether modified)
  CanClose := (FCurrentFileName <> '') or HasContent;

  btnSaveFile.Enabled := CanSave;
  btnSaveAs.Enabled := CanSaveAs;
  if Assigned(btnCloseFile) then
    btnCloseFile.Enabled := CanClose;

  if Assigned(miNotepadSave) then
    miNotepadSave.Enabled := CanSave;
  if Assigned(miNotepadSaveAs) then
    miNotepadSaveAs.Enabled := CanSaveAs;
  if Assigned(miNotepadClose) then
    miNotepadClose.Enabled := CanClose;
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
  UpdateSaveButtonState;
end;

procedure TfrmMain.btnCloseFileClick(Sender: TObject);
begin
  if not PromptSaveIfModified then Exit;

  SynEdit1.Clear;
  FCurrentFileName := '';
  FIsModified := False;
  lblCurrentFile.Caption := 'Untitled';
  cmbSyntax.ItemIndex := 0;
  ApplySyntax(0);
  UpdateNotepadStatus;
  UpdateSaveButtonState;
  SetStatus(' Closed file.');
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
    UpdateSaveButtonState;
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
    SafelyFreeWrapPlugin(FWrapPlugin, SynEdit1);
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
  UpdateSaveButtonState;
end;

procedure TfrmMain.SynEdit1Enter(Sender: TObject);
begin
  UpdateSaveButtonState;
end;

procedure TfrmMain.SynEdit1Exit(Sender: TObject);
begin
  UpdateSaveButtonState;
end;

procedure TfrmMain.SynEdit1StatusChange(Sender: TObject; Changes: TSynStatusChanges);
begin
  UpdateNotepadStatus;
  UpdateSaveButtonState;
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  UpdateKeyboardAndTimerStatus;
  if (PageControl1.ActivePage = tabNotepad) and (ssCtrl in Shift) then
  begin
    if (ssShift in Shift) and (Key = VK_S) then
    begin
      if btnSaveAs.Enabled then
        btnSaveAsClick(nil);
      Key := 0;
      Exit;
    end
    else if (Key = VK_S) then
    begin
      if btnSaveFile.Enabled then
        btnSaveFileClick(nil);
      Key := 0;
      Exit;
    end;

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
  UpdateSaveButtonState;
  miCut.Enabled := (SynEdit1.SelText <> '');
  miCopy.Enabled := (SynEdit1.SelText <> '');
  miPaste.Enabled := Clipboard.HasFormat(CF_TEXT);
  miDelete.Enabled := (SynEdit1.SelText <> '');
  miUndo.Enabled := SynEdit1.CanUndo;
  miRedo.Enabled := SynEdit1.CanRedo;
  miSelectAll.Enabled := (SynEdit1.Lines.Count > 0);
  miNotepadSave.Enabled := btnSaveFile.Enabled;
  miNotepadSaveAs.Enabled := btnSaveAs.Enabled;
  if Assigned(miNotepadClose) and Assigned(btnCloseFile) then
    miNotepadClose.Enabled := btnCloseFile.Enabled;
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

{ ----------------------------------------------------------------------------
  Keyboard Status, Timer, and About Tab Implementation
  ---------------------------------------------------------------------------- }

procedure TfrmMain.tmrStatusTimer(Sender: TObject);
begin
  UpdateKeyboardAndTimerStatus;
end;

procedure TfrmMain.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  UpdateKeyboardAndTimerStatus;
end;

procedure TfrmMain.UpdateKeyboardAndTimerStatus;
{$IFDEF WINDOWS}
var
  CapsLockOn, NumLockOn, InsertOn: Boolean;
begin
  CapsLockOn := (GetKeyState(VK_CAPITAL) and 1) <> 0;
  NumLockOn  := (GetKeyState(VK_NUMLOCK) and 1) <> 0;
  InsertOn   := (GetKeyState(VK_INSERT) and 1) <> 0;

  if CapsLockOn then
    StatusBar1.Panels[3].Text := 'CAPS'
  else
    StatusBar1.Panels[3].Text := '';

  if NumLockOn then
    StatusBar1.Panels[4].Text := 'NUM'
  else
    StatusBar1.Panels[4].Text := '';

  if InsertOn then
    StatusBar1.Panels[5].Text := 'OVR'
  else
    StatusBar1.Panels[5].Text := 'INS';

  StatusBar1.Panels[6].Text := FormatDateTime('hh:nn:ss am/pm', Now);
end;
{$ELSE}
begin
  StatusBar1.Panels[6].Text := FormatDateTime('hh:nn:ss am/pm', Now);
end;
{$ENDIF}

procedure TfrmMain.pnlLinkWebClick(Sender: TObject);
begin
  OpenURL('http://twilightsurfers.net');
end;

procedure TfrmMain.pnlLinkFavAmpClick(Sender: TObject);
begin
  OpenURL('https://player.favamp.com');
end;

procedure TfrmMain.pnlLinkRankGalacticClick(Sender: TObject);
begin
  OpenURL('https://rankgalactic.com');
end;

procedure TfrmMain.pnlLinkXClick(Sender: TObject);
begin
  OpenURL('https://x.com/TwilightSurfers');
end;

procedure TfrmMain.pnlLinkGithubClick(Sender: TObject);
begin
  OpenURL('https://github.com/TwilightSurfers/AceUtitlies');
end;

procedure TfrmMain.LoadAboutContent;
begin
  try
    imgLinkWeb.Picture.PNG.LoadFromLazarusResource('search-the-web');
  except
  end;
  try
    imgLinkFavAmp.Picture.PNG.LoadFromLazarusResource('favAMP');
  except
  end;
  try
    imgLinkRankGalactic.Picture.PNG.LoadFromLazarusResource('Rank-Galactic-SEO');
  except
  end;
  try
    imgLinkX.Picture.PNG.LoadFromLazarusResource('x-logo');
  except
  end;
  try
    imgLinkGithub.Picture.PNG.LoadFromLazarusResource('maven-mvp');
  except
  end;

  mmoAboutFeatures.Lines.Clear;
  mmoAboutFeatures.Lines.Add('=== ACE''S UTILITIES (AceUtils) ===');
  mmoAboutFeatures.Lines.Add('Fast Windows Search, Modern Notepad Replacement & Shell Management');
  mmoAboutFeatures.Lines.Add('Developed by Twilight Surfers Development | Released under the MIT License.');
  mmoAboutFeatures.Lines.Add('');
  mmoAboutFeatures.Lines.Add('KEY CAPABILITIES:');
  mmoAboutFeatures.Lines.Add('-----------------');
  mmoAboutFeatures.Lines.Add('1. CONTEXT MENU MANAGEMENT & WINDOWS 11 ASSOCIATION TAKEOVER:');
  mmoAboutFeatures.Lines.Add('   - Reclaims .txt and .md associations hijacked by Windows 11 UWP Notepad.');
  mmoAboutFeatures.Lines.Add('   - Cleans UserChoice/UserChoiceLatest per-user with ZERO admin rights.');
  mmoAboutFeatures.Lines.Add('   - Audits HKCU shell verbs across *, Directory, Background, .txt, .md, Applications.');
  mmoAboutFeatures.Lines.Add('   - Identifies and highlights broken/stale verbs pointing to missing executables.');
  mmoAboutFeatures.Lines.Add('   - Allows one-click purging, label editing, and command-line remapping.');
  mmoAboutFeatures.Lines.Add('   - Interactive multi-column header sorting with Ascending/Descending indicators.');
  mmoAboutFeatures.Lines.Add('');
  mmoAboutFeatures.Lines.Add('2. REAL WINDOWS FILE SEARCH:');
  mmoAboutFeatures.Lines.Add('   - Safe Breadth-First Search (BFS) directory traversal engine.');
  mmoAboutFeatures.Lines.Add('   - Automatic NTFS junction & reparse point loop prevention ($00000400).');
  mmoAboutFeatures.Lines.Add('   - Fast pattern search with wildcards (*.pas, *.md) or substring matching.');
  mmoAboutFeatures.Lines.Add('   - Content searching inside files with configurable case sensitivity.');
  mmoAboutFeatures.Lines.Add('   - Results list multi-column sorting by Name, Folder, True Byte Size, Date, Type.');
  mmoAboutFeatures.Lines.Add('   - Copy Filename Only, Copy File Path Only, Copy File Path and Name.');
  mmoAboutFeatures.Lines.Add('');
  mmoAboutFeatures.Lines.Add('3. THE REAL EXPLORER:');
  mmoAboutFeatures.Lines.Add('   - Full classic Explorer view with folders first and permanent Details columns.');
  mmoAboutFeatures.Lines.Add('   - Smart Address Bar: Automatically detects pasted file paths (with or without quotes), navigates to the parent folder, selects the file, and previews it.');
  mmoAboutFeatures.Lines.Add('   - Full navigation history (Back/Forward/Up/Refresh) and quick jump chips for Desktop, Downloads, Docs, Pics, C:\, Home.');
  mmoAboutFeatures.Lines.Add('   - Configurable default start folder with 1-click Set Default.');
  mmoAboutFeatures.Lines.Add('   - Instant Preview toggle and comprehensive context menus.');
  mmoAboutFeatures.Lines.Add('');
  mmoAboutFeatures.Lines.Add('4. FLOATING LIVE PREVIEW:');
  mmoAboutFeatures.Lines.Add('   - Modeless floating preview window updating in real-time as results are clicked.');
  mmoAboutFeatures.Lines.Add('   - Image scaling preview (.png, .jpg, .bmp, .ico, .gif) with dimension readouts.');
  mmoAboutFeatures.Lines.Add('   - TSynEdit code preview with line numbers and syntax coloring.');
  mmoAboutFeatures.Lines.Add('   - High-res shell icon rendering and 16-column Hex + ASCII byte peek.');
  mmoAboutFeatures.Lines.Add('');
  mmoAboutFeatures.Lines.Add('5. NOTEPAD REPLACEMENT:');
  mmoAboutFeatures.Lines.Add('   - Tabbed editor powered by TSynEdit with dirty tracking.');
  mmoAboutFeatures.Lines.Add('   - Dedicated custom Markdown highlighter (headers, code blocks, lists, links).');
  mmoAboutFeatures.Lines.Add('   - Highlighters for Pascal, Python, HTML, XML, CSS, JS, SQL, Batch, INI, Diff.');
  mmoAboutFeatures.Lines.Add('   - Slide-down Find & Replace bar with regex, match case, and whole words.');
  mmoAboutFeatures.Lines.Add('');
  mmoAboutFeatures.Lines.Add('6. NATIVE WINDOWS 11 POLISH:');
  mmoAboutFeatures.Lines.Add('   - Native DWM dark title bar via dwmapi.dll Desktop Window Manager attribute.');
  mmoAboutFeatures.Lines.Add('   - System tray minimize/close with quick actions context menu.');
  mmoAboutFeatures.Lines.Add('   - Live keyboard status (CAPS, NUM, INS) and ticking System Clock in status bar.');
  mmoAboutFeatures.Lines.Add('   - Embedded 16x16 chaicon modern icon set (727 icons under MIT License).');

  mmoAboutBuildLog.Lines.Clear;
  mmoAboutBuildLog.Lines.Add('================================================================');
  mmoAboutBuildLog.Lines.Add('ACE''S UTILITIES - BUILD HISTORY & CHANGELOG');
  mmoAboutBuildLog.Lines.Add('================================================================');
  mmoAboutBuildLog.Lines.Add('');
  mmoAboutBuildLog.Lines.Add('[v1.3.1] - 2026-09-04');
  mmoAboutBuildLog.Lines.Add('  * Smart File Path Handling: Pasting full file paths or filenames into Explorer address bar automatically resolves to parent folder, selects target item, and previews it.');
  mmoAboutBuildLog.Lines.Add('  * Robust Path Normalization: Strips single, double, and mismatched quotes across Explorer and Search inputs.');
  mmoAboutBuildLog.Lines.Add('  * SynHighlighterMarkdown & Live Preview: Fixed highlighter GetEol contract and token loop advancement that caused TLazSynEditLineWrapPlugin to hang when previewing Markdown files.');
  mmoAboutBuildLog.Lines.Add('  * Clipboard Shortcut Fix: Removed global form shortcuts from popNotepad menu items so all edit fields natively handle Windows paste.');
  mmoAboutBuildLog.Lines.Add('  * Instant Search Cancellation: Fixed Stop button hang during long scans by pumping messages every 50ms / 32 items regardless of match state.');
  mmoAboutBuildLog.Lines.Add('  * Search Optimization: Search patterns are pre-parsed once per search instead of allocating/freeing TStringList on every enumerated file.');
  mmoAboutBuildLog.Lines.Add('  * Race Condition Guard: Stop button disables immediately on click and pending queued clicks are drained to prevent phantom actions.');
  mmoAboutBuildLog.Lines.Add('  * Search Path Smart Detection: Search tab path input also auto-extracts directory if a file path is pasted.');
  mmoAboutBuildLog.Lines.Add('  * Single Instance Guard & Tray Restore: Enforces single-instance execution via named mutex. Duplicate launches wake up and restore the existing window from the system tray and flash the title bar.');
  mmoAboutBuildLog.Lines.Add('');
  mmoAboutBuildLog.Lines.Add('[v1.3.0] - 2026-09-03');
  mmoAboutBuildLog.Lines.Add('  * Added "The Real Explorer" tab with permanent Details view and folders first.');
  mmoAboutBuildLog.Lines.Add('  * Configured default launch folder to user Desktop with 1-click Set Default.');
  mmoAboutBuildLog.Lines.Add('  * Added full navigation history (Back/Fwd/Up/Refresh), address bar, and quick jump chips.');
  mmoAboutBuildLog.Lines.Add('  * Integrated floating live preview for on-the-fly image, syntax, and hex inspection.');
  mmoAboutBuildLog.Lines.Add('  * Added complete context menu with Recycle Bin delete, rename, and Notepad tab routing.');
  mmoAboutBuildLog.Lines.Add('');
  mmoAboutBuildLog.Lines.Add('[v1.2.0] - 2026-09-03');
  mmoAboutBuildLog.Lines.Add('  * Added comprehensive About tab with project info, MIT License, and links.');
  mmoAboutBuildLog.Lines.Add('  * Integrated Twilight Surfers Development credentials and exe VersionInfo.');
  mmoAboutBuildLog.Lines.Add('  * Added live keyboard status indicators in StatusBar (CAPS, NUM, INS/OVR).');
  mmoAboutBuildLog.Lines.Add('  * Added real-time ticking System Clock panel to StatusBar.');
  mmoAboutBuildLog.Lines.Add('  * Added clickable link cards with proportional image thumbnails for web/X/GitHub.');
  mmoAboutBuildLog.Lines.Add('  * Embedded About tab chaicon-info glyph and social image assets.');
  mmoAboutBuildLog.Lines.Add('');
  mmoAboutBuildLog.Lines.Add('[v1.1.5] - 2026-09-03');
  mmoAboutBuildLog.Lines.Add('  * Added interactive multi-column header sorting to Context Menu Mgtmt tab.');
  mmoAboutBuildLog.Lines.Add('  * Column sorting toggles between Ascending (▲) and Descending (▼).');
  mmoAboutBuildLog.Lines.Add('  * Auto-persists active sort column and direction across list refreshes.');
  mmoAboutBuildLog.Lines.Add('');
  mmoAboutBuildLog.Lines.Add('[v1.1.0] - 2026-09-03');
  mmoAboutBuildLog.Lines.Add('  * Added TImageList (16x16) and connected to PageControl1 notebook tabs.');
  mmoAboutBuildLog.Lines.Add('  * Imported modern chaicon package: 727 MIT-licensed 16x16 PNG glyphs.');
  mmoAboutBuildLog.Lines.Add('  * Compiled tabicons.lrs resource embedding glyphs for 100% portable standalone binary.');
  mmoAboutBuildLog.Lines.Add('  * Assigned custom icons: Search, Notepad, Context Menu, and About tabs.');
  mmoAboutBuildLog.Lines.Add('');
  mmoAboutBuildLog.Lines.Add('[v1.0.5] - 2026-09-03');
  mmoAboutBuildLog.Lines.Add('  * Built "Context Menu Mgtmt" tab for auditing HKCU user shell verbs.');
  mmoAboutBuildLog.Lines.Add('  * Added automatic stale entry detection with red visual highlight for missing targets.');
  mmoAboutBuildLog.Lines.Add('  * Added one-click stale verb cleanup and shell verb removal via SHChangeNotify.');
  mmoAboutBuildLog.Lines.Add('  * Added verb command-line remapping with interactive executable file browser.');
  mmoAboutBuildLog.Lines.Add('  * Added "Take Back .txt & .md Associations" to reclaim Windows 11 defaults.');
  mmoAboutBuildLog.Lines.Add('  * Added cross-platform {$IFDEF WINDOWS} guards for seamless Linux compilation.');
  mmoAboutBuildLog.Lines.Add('');
  mmoAboutBuildLog.Lines.Add('[v1.0.0] - 2026-09-03');
  mmoAboutBuildLog.Lines.Add('  * Initial release under Ace''s Utilities (AceUtils).');
  mmoAboutBuildLog.Lines.Add('  * Fast BFS search engine with junction loop skip and content search.');
  mmoAboutBuildLog.Lines.Add('  * Floating live preview with image scaling, syntax preview, and hex peek.');
  mmoAboutBuildLog.Lines.Add('  * Built-in SynEdit Notepad editor with custom Markdown syntax highlighter.');
  mmoAboutBuildLog.Lines.Add('  * Native Windows 11 DWM dark title bar and system tray background integration.');

  mmoAboutLicense.Lines.Clear;
  mmoAboutLicense.Lines.Add('MIT License');
  mmoAboutLicense.Lines.Add('');
  mmoAboutLicense.Lines.Add('Copyright (c) 2026 Twilight Surfers Development');
  mmoAboutLicense.Lines.Add('');
  mmoAboutLicense.Lines.Add('Permission is hereby granted, free of charge, to any person obtaining a copy');
  mmoAboutLicense.Lines.Add('of this software and associated documentation files (the "Software"), to deal');
  mmoAboutLicense.Lines.Add('in the Software without restriction, including without limitation the rights');
  mmoAboutLicense.Lines.Add('to use, copy, modify, merge, publish, distribute, sublicense, and/or sell');
  mmoAboutLicense.Lines.Add('copies of the Software, and to permit persons to whom the Software is');
  mmoAboutLicense.Lines.Add('furnished to do so, subject to the following conditions:');
  mmoAboutLicense.Lines.Add('');
  mmoAboutLicense.Lines.Add('The above copyright notice and this permission notice shall be included in all');
  mmoAboutLicense.Lines.Add('copies or substantial portions of the Software.');
  mmoAboutLicense.Lines.Add('');
  mmoAboutLicense.Lines.Add('THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR');
  mmoAboutLicense.Lines.Add('IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,');
  mmoAboutLicense.Lines.Add('FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE');
  mmoAboutLicense.Lines.Add('AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER');
  mmoAboutLicense.Lines.Add('LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,');
  mmoAboutLicense.Lines.Add('OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE');
  mmoAboutLicense.Lines.Add('SOFTWARE.');
end;

{ ----------------------------------------------------------------------------
  The Real Explorer Implementation
  ---------------------------------------------------------------------------- }

function TfrmMain.GetUserDesktopPath: string;
{$IFDEF WINDOWS}
var
  PathBuf: array[0..MAX_PATH] of Char;
{$ENDIF}
begin
  Result := '';
  {$IFDEF WINDOWS}
  if SHGetFolderPath(0, CSIDL_DESKTOPDIRECTORY, 0, 0, PathBuf) = S_OK then
    Result := PathBuf;
  if (Result = '') or (not DirectoryExists(Result)) then
    Result := SysUtils.GetEnvironmentVariable('USERPROFILE') + '\Desktop';
  if not DirectoryExists(Result) then
    Result := SysUtils.GetEnvironmentVariable('ONEDRIVE') + '\Desktop';
  {$ENDIF}
  if (Result = '') or (not DirectoryExists(Result)) then
    Result := GetUserDir + 'Desktop';
  if not DirectoryExists(Result) then
    Result := GetUserDir;
end;

function TfrmMain.GetUserSpecialPath(const AFoId: string): string;
begin
  {$IFDEF WINDOWS}
  if SameText(AFoId, 'Downloads') then
    Result := SysUtils.GetEnvironmentVariable('USERPROFILE') + '\Downloads'
  else if SameText(AFoId, 'Documents') then
    Result := SysUtils.GetEnvironmentVariable('USERPROFILE') + '\Documents'
  else if SameText(AFoId, 'Pictures') then
    Result := SysUtils.GetEnvironmentVariable('USERPROFILE') + '\Pictures'
  else
    Result := SysUtils.GetEnvironmentVariable('USERPROFILE');
  {$ELSE}
  Result := GetUserDir + AFoId;
  {$ENDIF}
  if not DirectoryExists(Result) then
    Result := GetUserDir;
end;

function TfrmMain.GetExplorerSelectedPath: string;
begin
  Result := '';
  if Assigned(ShellListViewExplorer.Selected) then
    Result := ShellListViewExplorer.GetPathFromItem(ShellListViewExplorer.Selected)
  else
    Result := ShellListViewExplorer.Root;
end;

procedure TfrmMain.UpdateExplorerNavButtons;
begin
  btnExpBack.Enabled := (FExpHistoryIndex > 0);
  btnExpForward.Enabled := (FExpHistoryIndex < FExpHistory.Count - 1);
end;

procedure TfrmMain.EnsureExplorerSystemImageList;
{$IFDEF WINDOWS}
var
  SFI: TSHFileInfoW;
  SysImageList: HIMAGELIST;
  OldStyle: NativeInt;
begin
  if ShellListViewExplorer.HandleAllocated then
  begin
    SysImageList := HIMAGELIST(SHGetFileInfoW('', 0, SFI, SizeOf(SFI),
      SHGFI_SYSICONINDEX or SHGFI_SMALLICON));
    if SysImageList <> 0 then
    begin
      OldStyle := GetWindowLongPtr(ShellListViewExplorer.Handle, GWL_STYLE);
      SetWindowLongPtr(ShellListViewExplorer.Handle, GWL_STYLE, OldStyle or LVS_SHAREIMAGELISTS);
      ListView_SetImageList(ShellListViewExplorer.Handle, SysImageList, LVSIL_SMALL);
    end;
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}

procedure TfrmMain.AutoFitListViewColumns(ALV: TWinControl; AColumns: TListColumns; MaxColWidth: Integer = 450);
var
  i, ItemW, HdrW, FinalW: Integer;
  Cap: string;
  LV: TCustomListView;
begin
  if (ALV = nil) or (AColumns = nil) or (AColumns.Count = 0) then Exit;
  {$IFDEF WINDOWS}
  if not ALV.HandleAllocated then Exit;

  if ALV is TCustomListView then
    LV := TCustomListView(ALV)
  else
    LV := nil;

  SendMessage(ALV.Handle, WM_SETREDRAW, WPARAM(False), 0);
  try
    for i := 0 to AColumns.Count - 1 do
    begin
      if (LV <> nil) and (LV.Items.Count > 0) then
      begin
        SendMessage(ALV.Handle, LVM_SETCOLUMNWIDTH, WPARAM(i), LPARAM(LVSCW_AUTOSIZE));
        ItemW := SendMessage(ALV.Handle, LVM_GETCOLUMNWIDTH, WPARAM(i), 0);
      end
      else
        ItemW := 0;

      Cap := AColumns[i].Caption;
      if LV <> nil then
        HdrW := LV.Canvas.TextWidth(Cap) + 24
      else
        HdrW := Length(Cap) * 8 + 24;

      FinalW := Max(ItemW, HdrW);

      // Ensure first column has enough space for icon and caption
      if (i = 0) and (FinalW < 60) then
        FinalW := 60;

      if (MaxColWidth > 0) and (FinalW > MaxColWidth) then
        FinalW := MaxColWidth;

      SendMessage(ALV.Handle, LVM_SETCOLUMNWIDTH, WPARAM(i), LPARAM(FinalW));
      AColumns[i].Width := FinalW;
    end;
  finally
    SendMessage(ALV.Handle, WM_SETREDRAW, WPARAM(True), 0);
    ALV.Invalidate;
  end;
  {$ENDIF}
end;

procedure TfrmMain.NavigateExplorerTo(const APath: string; AddToHistory: Boolean = True);
var
  CleanPath, TargetFile, TargetName: string;
  i: Integer;
begin
  CleanPath := Trim(APath);
  while (Length(CleanPath) > 0) and (CleanPath[1] in ['"', '''']) do
    Delete(CleanPath, 1, 1);
  while (Length(CleanPath) > 0) and (CleanPath[Length(CleanPath)] in ['"', '''']) do
    Delete(CleanPath, Length(CleanPath), 1);
  CleanPath := Trim(CleanPath);

  if CleanPath = '' then Exit;

  TargetFile := '';
  // Smart detection: if user pasted a file path, navigate to parent directory and preview the file
  if FileExists(CleanPath) and (not DirectoryExists(CleanPath)) then
  begin
    TargetFile := CleanPath;
    CleanPath := ExtractFileDir(CleanPath);
  end
  else if (not DirectoryExists(CleanPath)) and DirectoryExists(ExtractFileDir(CleanPath)) and (ExtractFileName(CleanPath) <> '') then
  begin
    if FileExists(CleanPath) then
      TargetFile := CleanPath;
    CleanPath := ExtractFileDir(CleanPath);
  end;

  if not DirectoryExists(CleanPath) then
  begin
    MessageDlg('Cannot Find Folder', 'The path "' + CleanPath + '" does not exist.', mtError, [mbOK], 0);
    Exit;
  end;

  FExpNavigating := True;
  try
    ShellListViewExplorer.Root := CleanPath;
    edtExpPath.Text := CleanPath;
    EnsureExplorerSystemImageList;

    try
      ShellTreeViewExplorer.Path := CleanPath;
    except
    end;

    if AddToHistory then
    begin
      while FExpHistory.Count > FExpHistoryIndex + 1 do
        FExpHistory.Delete(FExpHistory.Count - 1);
      FExpHistory.Add(CleanPath);
      FExpHistoryIndex := FExpHistory.Count - 1;
    end;

    UpdateExplorerNavButtons;
    SetStatus(' Explorer: ' + CleanPath);

    if FExpSortColumn >= 0 then
      ShellListViewExplorer.AlphaSort;

    // If a target file was identified, select it in the explorer list and preview it
    if TargetFile <> '' then
    begin
      TargetName := ExtractFileName(TargetFile);
      for i := 0 to ShellListViewExplorer.Items.Count - 1 do
      begin
        if SameText(ShellListViewExplorer.Items[i].Caption, TargetName) then
        begin
          ShellListViewExplorer.ItemIndex := i;
          ShellListViewExplorer.Selected := ShellListViewExplorer.Items[i];
          ShellListViewExplorer.Items[i].MakeVisible(False);
          Break;
        end;
      end;

      if FileExists(TargetFile) then
        PreviewExplorerFile(TargetFile);
    end;
  finally
    FExpNavigating := False;
  end;

  Application.ProcessMessages;
  AutoFitListViewColumns(ShellListViewExplorer, ShellListViewExplorer.Columns);
end;

procedure TfrmMain.btnExpBackClick(Sender: TObject);
begin
  if FExpHistoryIndex > 0 then
  begin
    Dec(FExpHistoryIndex);
    NavigateExplorerTo(FExpHistory[FExpHistoryIndex], False);
  end;
end;

procedure TfrmMain.btnExpForwardClick(Sender: TObject);
begin
  if FExpHistoryIndex < FExpHistory.Count - 1 then
  begin
    Inc(FExpHistoryIndex);
    NavigateExplorerTo(FExpHistory[FExpHistoryIndex], False);
  end;
end;

procedure TfrmMain.btnExpUpClick(Sender: TObject);
var
  CurPath, ParentPath: string;
begin
  CurPath := ShellListViewExplorer.Root;
  ParentPath := ExtractFileDir(ExcludeTrailingPathDelimiter(CurPath));
  if (ParentPath <> '') and DirectoryExists(ParentPath) and (ParentPath <> CurPath) then
    NavigateExplorerTo(ParentPath);
end;

procedure TfrmMain.btnExpRefreshClick(Sender: TObject);
var
  CurPath: string;
begin
  CurPath := ShellListViewExplorer.Root;
  if not DirectoryExists(CurPath) then Exit;
  ShellListViewExplorer.UpdateView;
  if FExpSortColumn >= 0 then
    ShellListViewExplorer.AlphaSort;
  AutoFitListViewColumns(ShellListViewExplorer, ShellListViewExplorer.Columns);
  SetStatus(' Refreshed: ' + CurPath);
end;

procedure TfrmMain.btnExpDefaultClick(Sender: TObject);
begin
  NavigateExplorerTo(FExpDefaultFolder);
end;

procedure TfrmMain.btnExpSetDefaultClick(Sender: TObject);
var
  CurPath: string;
begin
  CurPath := ShellListViewExplorer.Root;
  if DirectoryExists(CurPath) then
  begin
    FExpDefaultFolder := CurPath;
    SaveAllOptions;
    MessageDlg('Default Folder Saved', 'The Real Explorer will now always open to:'#13#10 + CurPath,
      mtInformation, [mbOK], 0);
  end;
end;

procedure TfrmMain.btnExpPreviewClick(Sender: TObject);
begin
  cbExpPreviewAlways.Checked := not cbExpPreviewAlways.Checked;
end;

procedure TfrmMain.miExpPreviewClick(Sender: TObject);
begin
  cbExpPreviewAlways.Checked := not cbExpPreviewAlways.Checked;
end;

procedure TfrmMain.cbExpPreviewAlwaysChange(Sender: TObject);
var
  SelPath: string;
begin
  if FExpPreviewSyncing then Exit;
  FExpPreviewSyncing := True;
  try
    if cbExpPreviewAlways.Checked then
    begin
      SelPath := GetExplorerSelectedPath;
      if (SelPath <> '') and FileExists(SelPath) then
        PreviewExplorerFile(SelPath)
      else if Assigned(frmPreview) then
      begin
        if not frmPreview.Visible then
          frmPreview.Show;
        frmPreview.BringToFront;
      end;
    end
    else
    begin
      if Assigned(frmPreview) and frmPreview.Visible then
        frmPreview.Hide;
    end;

    if Assigned(miExpPreview) then
      miExpPreview.Checked := cbExpPreviewAlways.Checked;

    SaveAllOptions;
  finally
    FExpPreviewSyncing := False;
  end;
end;

procedure TfrmMain.PreviewExplorerFile(const APath: string);
var
  FS: TFileStream;
  SizeBytes: Int64;
  SizeStr, DateStr, TypeStr, FileName: string;
begin
  if not FileExists(APath) then Exit;
  if Assigned(frmPreview) and frmPreview.Visible and (frmPreview.CurrentPath = APath) then Exit;

  FileName := ExtractFileName(APath);
  try
    FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    try
      SizeBytes := FS.Size;
    finally
      FS.Free;
    end;
  except
    SizeBytes := 0;
  end;

  SizeStr := FormatFileSize(SizeBytes);
  DateStr := FormatDateTime('yyyy-mm-dd hh:nn', SafeFileDateToDateTime(FileAge(APath)));
  TypeStr := UpperCase(ExtractFileExt(APath));
  if TypeStr = '' then TypeStr := 'File';

  if Assigned(frmPreview) then
  begin
    frmPreview.ShowFile(APath, FileName, SizeStr, DateStr, TypeStr, SizeBytes, FDarkMode);
    if not frmPreview.Visible then
    begin
      frmPreview.Show;
      frmPreview.BringToFront;
    end;
  end;
end;

procedure TfrmMain.btnExpNewFolderClick(Sender: TObject);
var
  FolderName, NewPath: string;
begin
  FolderName := 'New Folder';
  if InputQuery('New Folder', 'Enter name for the new folder:', FolderName) then
  begin
    NewPath := IncludeTrailingPathDelimiter(ShellListViewExplorer.Root) + FolderName;
    if CreateDir(NewPath) then
    begin
      ShellListViewExplorer.UpdateView;
      SetStatus(' Created folder: ' + NewPath);
    end
    else
      MessageDlg('Error', 'Could not create folder: ' + NewPath, mtError, [mbOK], 0);
  end;
end;

procedure TfrmMain.btnJumpDesktopClick(Sender: TObject);
begin
  NavigateExplorerTo(GetUserDesktopPath);
end;

procedure TfrmMain.btnJumpDownloadsClick(Sender: TObject);
begin
  NavigateExplorerTo(GetUserSpecialPath('Downloads'));
end;

procedure TfrmMain.btnJumpDocumentsClick(Sender: TObject);
begin
  NavigateExplorerTo(GetUserSpecialPath('Documents'));
end;

procedure TfrmMain.btnJumpPicturesClick(Sender: TObject);
begin
  NavigateExplorerTo(GetUserSpecialPath('Pictures'));
end;

procedure TfrmMain.btnJumpDriveCClick(Sender: TObject);
begin
  NavigateExplorerTo('C:\');
end;

procedure TfrmMain.btnJumpUserHomeClick(Sender: TObject);
begin
  NavigateExplorerTo(GetUserDir);
end;

procedure TfrmMain.edtExpPathKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    NavigateExplorerTo(edtExpPath.Text);
  end;
end;

procedure TfrmMain.btnExpGoClick(Sender: TObject);
begin
  NavigateExplorerTo(edtExpPath.Text);
end;

procedure TfrmMain.ShellTreeViewExplorerSelectionChanged(Sender: TObject);
var
  NodePath: string;
begin
  if FExpNavigating then Exit;
  if ShellTreeViewExplorer.Selected <> nil then
  begin
    NodePath := ShellTreeViewExplorer.GetPathFromNode(ShellTreeViewExplorer.Selected);
    if (NodePath <> '') and DirectoryExists(NodePath) then
      NavigateExplorerTo(NodePath);
  end;
end;

procedure TfrmMain.ShellListViewExplorerDblClick(Sender: TObject);
var
  SelPath, Ext: string;
begin
  SelPath := GetExplorerSelectedPath;
  if SelPath = '' then Exit;

  if DirectoryExists(SelPath) then
  begin
    NavigateExplorerTo(SelPath);
    Exit;
  end;

  Ext := LowerCase(ExtractFileExt(SelPath));
  if (Ext = '.txt') or (Ext = '.md') or (Ext = '.markdown') or (Ext = '.log') or
     (Ext = '.pas') or (Ext = '.pp') or (Ext = '.lpr') or (Ext = '.lfm') or
     (Ext = '.py') or (Ext = '.json') or (Ext = '.xml') or (Ext = '.html') or
     (Ext = '.css') or (Ext = '.js') or (Ext = '.sql') or (Ext = '.bat') or
     (Ext = '.ini') or (Ext = '.cfg') or (Ext = '.yaml') or (Ext = '.yml') then
  begin
    OpenFileInNotepad(SelPath);
    PageControl1.ActivePage := tabNotepad;
  end
  else
  begin
    OpenDocument(SelPath);
  end;
end;

procedure TfrmMain.ShellListViewExplorerSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  SelPath: string;
begin
  if not Selected or (Item = nil) then Exit;
  SelPath := ShellListViewExplorer.GetPathFromItem(Item);
  if (cbExpPreviewAlways.Checked or (Assigned(frmPreview) and frmPreview.Visible)) and FileExists(SelPath) then
    PreviewExplorerFile(SelPath);
end;

procedure TfrmMain.ShellListViewExplorerKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
    begin
      Key := 0;
      ShellListViewExplorerDblClick(Sender);
    end;
    VK_F2:
    begin
      Key := 0;
      miExpRenameClick(Sender);
    end;
    VK_DELETE:
    begin
      Key := 0;
      miExpDeleteClick(Sender);
    end;
    VK_BACK:
    begin
      Key := 0;
      btnExpUpClick(Sender);
    end;
  end;
end;

procedure TfrmMain.popExplorerPopup(Sender: TObject);
var
  HasSel: Boolean;
begin
  HasSel := (ShellListViewExplorer.Selected <> nil);
  miExpOpen.Enabled := HasSel;
  miExpOpenAssociated.Enabled := HasSel;
  miExpNotepad.Enabled := HasSel;
  miExpPreview.Enabled := HasSel or cbExpPreviewAlways.Checked or (Assigned(frmPreview) and frmPreview.Visible);
  miExpPreview.Checked := cbExpPreviewAlways.Checked;
  miExpReveal.Enabled := True;
  miExpCopyPath.Enabled := HasSel;
  miExpCopyName.Enabled := HasSel;
  miExpRename.Enabled := HasSel;
  miExpDelete.Enabled := HasSel;
end;

procedure TfrmMain.miExpOpenClick(Sender: TObject);
begin
  ShellListViewExplorerDblClick(Sender);
end;

procedure TfrmMain.miExpOpenAssociatedClick(Sender: TObject);
var
  SelPath: string;
begin
  SelPath := GetExplorerSelectedPath;
  if SelPath = '' then Exit;

  {$IFDEF WINDOWS}
  ShellExecute(0, 'open', PChar(SelPath), nil, nil, SW_SHOWNORMAL);
  {$ELSE}
  OpenDocument(SelPath);
  {$ENDIF}
end;

procedure TfrmMain.miExpNotepadClick(Sender: TObject);
var
  SelPath: string;
begin
  SelPath := GetExplorerSelectedPath;
  if (SelPath <> '') and FileExists(SelPath) then
  begin
    OpenFileInNotepad(SelPath);
    PageControl1.ActivePage := tabNotepad;
  end;
end;

procedure TfrmMain.miExpRevealClick(Sender: TObject);
var
  SelPath: string;
begin
  SelPath := GetExplorerSelectedPath;
  if SelPath = '' then
    SelPath := ShellListViewExplorer.Root;
  {$IFDEF WINDOWS}
  if FileExists(SelPath) then
    ShellExecute(Handle, 'open', 'explorer.exe', PChar('/select,"' + SelPath + '"'), nil, SW_SHOWNORMAL)
  else
    ShellExecute(Handle, 'open', PChar(SelPath), nil, nil, SW_SHOWNORMAL);
  {$ELSE}
  OpenDocument(ExtractFileDir(SelPath));
  {$ENDIF}
end;

procedure TfrmMain.miExpCopyPathClick(Sender: TObject);
var
  SelPath: string;
begin
  SelPath := GetExplorerSelectedPath;
  if SelPath <> '' then
    Clipboard.AsText := SelPath;
end;

procedure TfrmMain.miExpCopyNameClick(Sender: TObject);
var
  SelPath: string;
begin
  SelPath := GetExplorerSelectedPath;
  if SelPath <> '' then
    Clipboard.AsText := ExtractFileName(SelPath);
end;

procedure TfrmMain.miExpRenameClick(Sender: TObject);
var
  SelPath, OldName, NewName, NewPath, Dir: string;
begin
  SelPath := GetExplorerSelectedPath;
  if SelPath = '' then Exit;

  OldName := ExtractFileName(SelPath);
  NewName := OldName;
  if InputQuery('Rename', 'Enter new name for "' + OldName + '":', NewName) then
  begin
    if (NewName <> '') and (NewName <> OldName) then
    begin
      Dir := ExtractFileDir(SelPath);
      NewPath := IncludeTrailingPathDelimiter(Dir) + NewName;
      if RenameFile(SelPath, NewPath) then
      begin
        ShellListViewExplorer.UpdateView;
        SetStatus(' Renamed to: ' + NewPath);
      end
      else
        MessageDlg('Error', 'Could not rename to: ' + NewPath, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmMain.miExpDeleteClick(Sender: TObject);
var
  SelPath: string;
  Res: Integer;
  {$IFDEF WINDOWS}
  ShOp: TSHFileOpStruct;
  FromBuf: array of Char;
  {$ENDIF}
begin
  SelPath := GetExplorerSelectedPath;
  if SelPath = '' then Exit;

  Res := MessageDlg('Confirm Delete', 'Are you sure you want to send this item to the Recycle Bin?'#13#10 + SelPath,
    mtConfirmation, [mbYes, mbNo], 0);
  if Res <> mrYes then Exit;

  {$IFDEF WINDOWS}
  SetLength(FromBuf, Length(SelPath) + 2);
  Move(SelPath[1], FromBuf[0], Length(SelPath));
  FromBuf[Length(SelPath)] := #0;
  FromBuf[Length(SelPath) + 1] := #0;

  FillChar(ShOp, SizeOf(ShOp), 0);
  ShOp.Wnd := Handle;
  ShOp.wFunc := FO_DELETE;
  ShOp.pFrom := @FromBuf[0];
  ShOp.fFlags := FOF_ALLOWUNDO or FOF_SILENT or FOF_NOCONFIRMATION;
  SHFileOperation(ShOp);
  {$ELSE}
  if DirectoryExists(SelPath) then
    RemoveDir(SelPath)
  else
    DeleteFile(SelPath);
  {$ENDIF}
  ShellListViewExplorer.UpdateView;
end;

procedure TfrmMain.ShellListViewExplorerFileAdded(Sender: TObject; Item: TListItem);
var
  ItemPath: string;
  FTime: LongInt;
  {$IFDEF WINDOWS}
  SFI: TSHFileInfoW;
  Res: DWORD_PTR;
  {$ENDIF}
begin
  if Item = nil then Exit;
  ItemPath := ShellListViewExplorer.GetPathFromItem(Item);
  if Item is TShellListItem then
    FTime := TShellListItem(Item).FileInfo.Time
  else
    FTime := FileAge(ItemPath);

  // Modernize Size column (Column 1, SubItems[0]): blank if folder, consistent KB/MB/GB format
  if Item.SubItems.Count > 0 then
  begin
    if (Item is TShellListItem) and TShellListItem(Item).isFolder then
      Item.SubItems[0] := ''
    else if (Item is TShellListItem) then
      Item.SubItems[0] := FormatFileSize(TShellListItem(Item).FileInfo.Size, False)
    else if DirectoryExists(ItemPath) then
      Item.SubItems[0] := ''
    else
      Item.SubItems[0] := FormatFileSize(0, False);
  end;

  if FTime <> -1 then
    Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn', SafeFileDateToDateTime(FTime)))
  else
    Item.SubItems.Add('');

  {$IFDEF WINDOWS}
  if ItemPath <> '' then
  begin
    Res := SHGetFileInfoW(PWideChar(UTF8Decode(ItemPath)), 0, SFI, SizeOf(SFI),
      SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
    if Res <> 0 then
      Item.ImageIndex := SFI.iIcon;
  end;
  {$ENDIF}
end;

procedure TfrmMain.ShellListViewExplorerColumnClick(Sender: TObject; Column: TListColumn);
var
  i: Integer;
  BaseCaption: string;
begin
  if Column = nil then Exit;
  if FExpSortColumn = Column.Index then
    FExpSortAscending := not FExpSortAscending
  else
  begin
    FExpSortColumn := Column.Index;
    FExpSortAscending := True;
  end;

  for i := 0 to ShellListViewExplorer.Columns.Count - 1 do
  begin
    BaseCaption := ShellListViewExplorer.Columns[i].Caption;
    BaseCaption := StringReplace(BaseCaption, '  ▲', '', [rfReplaceAll]);
    BaseCaption := StringReplace(BaseCaption, '  ▼', '', [rfReplaceAll]);
    if i = FExpSortColumn then
    begin
      if FExpSortAscending then
        BaseCaption := BaseCaption + '  ▲'
      else
        BaseCaption := BaseCaption + '  ▼';
    end;
    ShellListViewExplorer.Columns[i].Caption := BaseCaption;
  end;

  ShellListViewExplorer.AlphaSort;
  AutoFitListViewColumns(ShellListViewExplorer, ShellListViewExplorer.Columns);
end;

procedure TfrmMain.ShellListViewExplorerCompare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
var
  IsFold1, IsFold2: Boolean;
  Size1, Size2: Int64;
  Time1, Time2: LongInt;
begin
  Compare := 0;
  if (Item1 = nil) or (Item2 = nil) then Exit;

  if (Item1 is TShellListItem) then
    IsFold1 := TShellListItem(Item1).isFolder
  else
    IsFold1 := False;

  if (Item2 is TShellListItem) then
    IsFold2 := TShellListItem(Item2).isFolder
  else
    IsFold2 := False;

  // Folders always grouped first!
  if IsFold1 and (not IsFold2) then
  begin
    Compare := -1;
    Exit;
  end;
  if (not IsFold1) and IsFold2 then
  begin
    Compare := 1;
    Exit;
  end;

  // Compare according to active column
  case FExpSortColumn of
    0: // Name
    begin
      Compare := CompareText(Item1.Caption, Item2.Caption);
    end;
    1: // Size
    begin
      if (Item1 is TShellListItem) and (Item2 is TShellListItem) then
      begin
        Size1 := TShellListItem(Item1).FileInfo.Size;
        Size2 := TShellListItem(Item2).FileInfo.Size;
        if Size1 < Size2 then Compare := -1
        else if Size1 > Size2 then Compare := 1
        else Compare := 0;
      end
      else if (Item1.SubItems.Count > 0) and (Item2.SubItems.Count > 0) then
        Compare := CompareText(Item1.SubItems[0], Item2.SubItems[0])
      else
        Compare := 0;
    end;
    2: // Type
    begin
      if (Item1.SubItems.Count > 1) and (Item2.SubItems.Count > 1) then
        Compare := CompareText(Item1.SubItems[1], Item2.SubItems[1])
      else
        Compare := 0;
      if Compare = 0 then
        Compare := CompareText(Item1.Caption, Item2.Caption);
    end;
    3: // Date Modified
    begin
      if (Item1 is TShellListItem) and (Item2 is TShellListItem) then
      begin
        Time1 := TShellListItem(Item1).FileInfo.Time;
        Time2 := TShellListItem(Item2).FileInfo.Time;
        if Time1 < Time2 then Compare := -1
        else if Time1 > Time2 then Compare := 1
        else Compare := 0;
      end
      else if (Item1.SubItems.Count > 2) and (Item2.SubItems.Count > 2) then
        Compare := CompareText(Item1.SubItems[2], Item2.SubItems[2])
      else
        Compare := 0;
    end
    else
      Compare := CompareText(Item1.Caption, Item2.Caption);
  end;

  if not FExpSortAscending then
    Compare := -Compare;
end;

initialization
  {$I tabicons.lrs}
end.

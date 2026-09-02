unit PreviewForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  SynEdit,
  SynHighlighterPas, SynHighlighterPython, SynHighlighterXML, SynHighlighterCSS,
  SynHighlighterJScript, SynHighlighterSQL, SynHighlighterBat, SynHighlighterIni;

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

    FHighlighterPas: TSynPasSyn;
    FHighlighterPython: TSynPythonSyn;
    FHighlighterXML: TSynXMLSyn;
    FHighlighterCSS: TSynCssSyn;
    FHighlighterJS: TSynJScriptSyn;
    FHighlighterSQL: TSynSQLSyn;
    FHighlighterBat: TSynBatSyn;
    FHighlighterIni: TSynIniSyn;

    procedure AutoDetectHighlighter(const AFileName: string);
    procedure LoadPreviewLines(const AFilePath: string; Lines: TStrings; MaxLines: Integer);
    procedure ShowInfoCard(const AFilePath, AName, ASizeStr, ADateStr, ATypeStr: string; ASizeBytes: Int64);
    procedure SetWindowsTitleBarDark(AForm: TForm; ADark: Boolean);

  public
    procedure ShowFile(const APath: string; const AName, ASizeStr, ADateStr, ATypeStr: string;
      ASizeBytes: Int64; ADarkMode: Boolean);
    procedure ApplyTheme(ADark: Boolean);
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

procedure TfrmPreview.FormCreate(Sender: TObject);
begin
  FCurrentPath := '';
  FDarkMode := True;

  // Highlighters
  FHighlighterPas := TSynPasSyn.Create(Self);
  FHighlighterPython := TSynPythonSyn.Create(Self);
  FHighlighterXML := TSynXMLSyn.Create(Self);
  FHighlighterCSS := TSynCssSyn.Create(Self);
  FHighlighterJS := TSynJScriptSyn.Create(Self);
  FHighlighterSQL := TSynSQLSyn.Create(Self);
  FHighlighterBat := TSynBatSyn.Create(Self);
  FHighlighterIni := TSynIniSyn.Create(Self);

  synPreview.ScrollBars := ssBoth;
end;

procedure TfrmPreview.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
  if Assigned(frmMain) and Assigned(frmMain.cbEnablePreview) then
    frmMain.cbEnablePreview.Checked := False;
end;

procedure TfrmPreview.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPreview.btnOpenInNotepadClick(Sender: TObject);
begin
  if (FCurrentPath <> '') and FileExists(FCurrentPath) then
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

  if ADark then
  begin
    FHighlighterPas.CommentAttri.Foreground := $0068AA68;
    FHighlighterPas.KeyAttri.Foreground := $00E08050;
    FHighlighterPas.StringAttri.Foreground := $0080B0FF;
    FHighlighterPython.CommentAttri.Foreground := $0068AA68;
    FHighlighterPython.KeyAttri.Foreground := $00E08050;
  end;
end;

procedure TfrmPreview.AutoDetectHighlighter(const AFileName: string);
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  if (Ext = '.pas') or (Ext = '.pp') or (Ext = '.lpr') or (Ext = '.lfm') or (Ext = '.inc') then
    synPreview.Highlighter := FHighlighterPas
  else if Ext = '.py' then
    synPreview.Highlighter := FHighlighterPython
  else if (Ext = '.html') or (Ext = '.htm') or (Ext = '.xml') or (Ext = '.svg') then
    synPreview.Highlighter := FHighlighterXML
  else if Ext = '.css' then
    synPreview.Highlighter := FHighlighterCSS
  else if (Ext = '.js') or (Ext = '.json') or (Ext = '.ts') then
    synPreview.Highlighter := FHighlighterJS
  else if Ext = '.sql' then
    synPreview.Highlighter := FHighlighterSQL
  else if (Ext = '.bat') or (Ext = '.cmd') then
    synPreview.Highlighter := FHighlighterBat
  else if (Ext = '.ini') or (Ext = '.cfg') or (Ext = '.md') then
    synPreview.Highlighter := FHighlighterIni
  else
    synPreview.Highlighter := nil;
end;

procedure TfrmPreview.LoadPreviewLines(const AFilePath: string; Lines: TStrings; MaxLines: Integer);
var
  F: TextFile;
  S: string;
  Count: Integer;
begin
  Lines.BeginUpdate;
  try
    Lines.Clear;
    AssignFile(F, AFilePath);
    Reset(F);
    try
      Count := 0;
      while (not Eof(F)) and (Count < MaxLines) do
      begin
        ReadLn(F, S);
        Lines.Add(S);
        Inc(Count);
      end;
    finally
      CloseFile(F);
    end;
  finally
    Lines.EndUpdate;
  end;
end;

procedure TfrmPreview.ShowInfoCard(const AFilePath, AName, ASizeStr, ADateStr, ATypeStr: string; ASizeBytes: Int64);
var
  FS: TFileStream;
  Buf: array[0..255] of Byte;
  ReadBytes, i, j: Integer;
  HexLine, AscLine, HexDump: string;
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

  // Hex Peek
  HexDump := '';
  try
    FS := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
    try
      ReadBytes := FS.Read(Buf, SizeOf(Buf));
      i := 0;
      while i < ReadBytes do
      begin
        HexLine := IntToHex(i, 4) + ': ';
        AscLine := ' ';
        for j := 0 to 15 do
        begin
          if (i + j) < ReadBytes then
          begin
            HexLine := HexLine + IntToHex(Buf[i + j], 2) + ' ';
            if Buf[i + j] in [32..126] then
              AscLine := AscLine + Chr(Buf[i + j])
            else
              AscLine := AscLine + '.';
          end
          else
            HexLine := HexLine + '   ';
        end;
        HexDump := HexDump + HexLine + AscLine + sLineBreak;
        Inc(i, 16);
      end;
    finally
      FS.Free;
    end;
  except
    HexDump := 'Could not read file for preview.';
  end;

  memHex.Text := HexDump;
end;

procedure TfrmPreview.ShowFile(const APath: string; const AName, ASizeStr, ADateStr, ATypeStr: string;
  ASizeBytes: Int64; ADarkMode: Boolean);
var
  Ext: string;
begin
  FCurrentPath := APath;
  ApplyTheme(ADarkMode);

  lblFileName.Caption := AName;
  lblFileMeta.Caption := Format('%s | %s | %s', [ATypeStr, ASizeStr, ADateStr]);
  Caption := 'Preview - ' + AName;

  if not FileExists(APath) then
  begin
    pnlImage.Visible := False;
    synPreview.Visible := False;
    pnlInfo.Visible := True;
    lblInfoName.Caption := AName;
    lblInfoType.Caption := 'Folder or Missing File';
    lblInfoSize.Caption := '';
    lblInfoModified.Caption := '';
    memHex.Text := '';
    Exit;
  end;

  Ext := LowerCase(ExtractFileExt(APath));

  // 1. Image Preview
  if (Ext = '.png') or (Ext = '.jpg') or (Ext = '.jpeg') or (Ext = '.bmp') or
     (Ext = '.ico') or (Ext = '.gif') then
  begin
    try
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
  if (Ext = '.txt') or (Ext = '.md') or (Ext = '.pas') or (Ext = '.pp') or
     (Ext = '.lpr') or (Ext = '.lfm') or (Ext = '.inc') or (Ext = '.py') or
     (Ext = '.html') or (Ext = '.htm') or (Ext = '.xml') or (Ext = '.css') or
     (Ext = '.js') or (Ext = '.json') or (Ext = '.ts') or (Ext = '.sql') or
     (Ext = '.bat') or (Ext = '.cmd') or (Ext = '.ini') or (Ext = '.cfg') or
     (Ext = '.log') or (Ext = '.csv') or (Ext = '.diff') or (Ext = '.c') or
     (Ext = '.cpp') or (Ext = '.h') or (Ext = '.java') then
  begin
    try
      LoadPreviewLines(APath, synPreview.Lines, 300);
      AutoDetectHighlighter(APath);
      pnlImage.Visible := False;
      synPreview.Visible := True;
      pnlInfo.Visible := False;
    except
      ShowInfoCard(APath, AName, ASizeStr, ADateStr, ATypeStr, ASizeBytes);
    end;
    Exit;
  end;

  // 3. Binary / Shell card
  ShowInfoCard(APath, AName, ASizeStr, ADateStr, ATypeStr, ASizeBytes);
end;

end.

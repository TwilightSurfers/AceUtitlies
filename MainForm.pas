unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, ShellCtrls, Menus, LCLType, FileUtil, LazFileUtils;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnSearch: TButton;
    btnStop: TButton;
    btnClear: TButton;
    cbSubfolders: TCheckBox;
    cbCaseSensitive: TCheckBox;
    edtPattern: TEdit;
    lblPattern: TLabel;
    lblStatus: TLabel;
    lblResults: TLabel;
    lvResults: TListView;
    pnlTop: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    pnlSearch: TPanel;
    pnlStatus: TPanel;
    ShellTreeView1: TShellTreeView;
    splMain: TSplitter;
    procedure btnClearClick(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvResultsDblClick(Sender: TObject);
    procedure ShellTreeView1SelectionChanged(Sender: TObject);
  private
    FStopSearch: Boolean;
    FFileCount: Integer;
    FDirCount: Integer;
    FSearching: Boolean;
    FSelectedPath: string;
    procedure DoSearch(const APath, APattern: string; ARecursive, ACaseSensitive: Boolean);
    procedure AddResult(const AFileName, APath: string; ASize: Int64; ADate: TDateTime);
    procedure UpdateStatus(const AMsg: string);
    procedure SetSearching(AValue: Boolean);
    function MatchesPattern(const AFileName, APattern: string; ACaseSensitive: Boolean): Boolean;
    function MatchWildcard(const AStr, APattern: string): Boolean;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

uses
  {$IFDEF WINDOWS}
  Windows, ShellAPI,
  {$ENDIF}
  DateUtils, Math;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FStopSearch := False;
  FSearching := False;
  FSelectedPath := 'C:\';

  // Style the form
  Self.Caption := 'Ace File Search';
  Self.Color := clWhite;
  Self.Width := 1100;
  Self.Height := 700;
  Self.Position := poScreenCenter;
  Self.Font.Name := 'Segoe UI';
  Self.Font.Size := 9;

  // --- Top Panel (Search Controls) ---
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 75;
  pnlTop.BevelOuter := bvNone;
  pnlTop.Color := $00493A28;  // Dark brown/charcoal
  pnlTop.ParentBackground := False;

  lblPattern := TLabel.Create(Self);
  lblPattern.Parent := pnlTop;
  lblPattern.Left := 16;
  lblPattern.Top := 10;
  lblPattern.Caption := 'SEARCH PATTERN';
  lblPattern.Font.Color := clWhite;
  lblPattern.Font.Size := 8;
  lblPattern.Font.Style := [fsBold];

  edtPattern := TEdit.Create(Self);
  edtPattern.Parent := pnlTop;
  edtPattern.Left := 16;
  edtPattern.Top := 30;
  edtPattern.Width := 300;
  edtPattern.Height := 28;
  edtPattern.Text := '*.png';
  edtPattern.Font.Size := 10;

  cbSubfolders := TCheckBox.Create(Self);
  cbSubfolders.Parent := pnlTop;
  cbSubfolders.Left := 340;
  cbSubfolders.Top := 12;
  cbSubfolders.Caption := 'Include Subfolders';
  cbSubfolders.Checked := True;
  cbSubfolders.Font.Color := clWhite;
  cbSubfolders.Font.Size := 9;

  cbCaseSensitive := TCheckBox.Create(Self);
  cbCaseSensitive.Parent := pnlTop;
  cbCaseSensitive.Left := 340;
  cbCaseSensitive.Top := 38;
  cbCaseSensitive.Caption := 'Case Sensitive';
  cbCaseSensitive.Checked := False;
  cbCaseSensitive.Font.Color := clWhite;
  cbCaseSensitive.Font.Size := 9;

  btnSearch := TButton.Create(Self);
  btnSearch.Parent := pnlTop;
  btnSearch.Left := 520;
  btnSearch.Top := 22;
  btnSearch.Width := 110;
  btnSearch.Height := 36;
  btnSearch.Caption := '🔍  Search';
  btnSearch.Font.Size := 10;
  btnSearch.Font.Style := [fsBold];
  btnSearch.OnClick := @btnSearchClick;

  btnStop := TButton.Create(Self);
  btnStop.Parent := pnlTop;
  btnStop.Left := 640;
  btnStop.Top := 22;
  btnStop.Width := 90;
  btnStop.Height := 36;
  btnStop.Caption := '⏹  Stop';
  btnStop.Font.Size := 10;
  btnStop.Enabled := False;
  btnStop.OnClick := @btnStopClick;

  btnClear := TButton.Create(Self);
  btnClear.Parent := pnlTop;
  btnClear.Left := 740;
  btnClear.Top := 22;
  btnClear.Width := 90;
  btnClear.Height := 36;
  btnClear.Caption := '🗑  Clear';
  btnClear.Font.Size := 10;
  btnClear.OnClick := @btnClearClick;

  // --- Left Panel (ShellTreeView) ---
  pnlLeft := TPanel.Create(Self);
  pnlLeft.Parent := Self;
  pnlLeft.Align := alLeft;
  pnlLeft.Width := 280;
  pnlLeft.BevelOuter := bvNone;
  pnlLeft.Color := $00F5F5F0;
  pnlLeft.ParentBackground := False;

  ShellTreeView1 := TShellTreeView.Create(Self);
  ShellTreeView1.Parent := pnlLeft;
  ShellTreeView1.Align := alClient;
  ShellTreeView1.Root := '';
  ShellTreeView1.Font.Size := 9;
  ShellTreeView1.OnSelectionChanged := @ShellTreeView1SelectionChanged;
  ShellTreeView1.BorderStyle := bsNone;

  // --- Splitter ---
  splMain := TSplitter.Create(Self);
  splMain.Parent := Self;
  splMain.Left := pnlLeft.Width;
  splMain.Width := 5;
  splMain.Color := $00D0D0D0;

  // --- Right Panel (Results) ---
  pnlRight := TPanel.Create(Self);
  pnlRight.Parent := Self;
  pnlRight.Align := alClient;
  pnlRight.BevelOuter := bvNone;
  pnlRight.Color := clWhite;
  pnlRight.ParentBackground := False;

  lblResults := TLabel.Create(Self);
  lblResults.Parent := pnlRight;
  lblResults.Align := alTop;
  lblResults.Height := 28;
  lblResults.Caption := '  Results';
  lblResults.Font.Size := 10;
  lblResults.Font.Style := [fsBold];
  lblResults.Font.Color := $00493A28;
  lblResults.Layout := tlCenter;
  lblResults.Color := $00F0EDE8;
  lblResults.ParentColor := False;

  lvResults := TListView.Create(Self);
  lvResults.Parent := pnlRight;
  lvResults.Align := alClient;
  lvResults.ViewStyle := vsReport;
  lvResults.RowSelect := True;
  lvResults.ReadOnly := True;
  lvResults.GridLines := True;
  lvResults.Font.Size := 9;
  lvResults.BorderStyle := bsNone;
  lvResults.OnDblClick := @lvResultsDblClick;

  // Add columns
  with lvResults.Columns.Add do begin
    Caption := 'File Name';
    Width := 280;
  end;
  with lvResults.Columns.Add do begin
    Caption := 'Path';
    Width := 380;
  end;
  with lvResults.Columns.Add do begin
    Caption := 'Size';
    Width := 100;
    Alignment := taRightJustify;
  end;
  with lvResults.Columns.Add do begin
    Caption := 'Modified';
    Width := 160;
  end;

  // --- Status Bar ---
  pnlStatus := TPanel.Create(Self);
  pnlStatus.Parent := Self;
  pnlStatus.Align := alBottom;
  pnlStatus.Height := 28;
  pnlStatus.BevelOuter := bvNone;
  pnlStatus.Color := $00493A28;
  pnlStatus.ParentBackground := False;

  lblStatus := TLabel.Create(Self);
  lblStatus.Parent := pnlStatus;
  lblStatus.Align := alClient;
  lblStatus.Caption := '  Ready — Select a folder and enter a search pattern.';
  lblStatus.Font.Color := clWhite;
  lblStatus.Font.Size := 9;
  lblStatus.Layout := tlCenter;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Cleanup handled by owner
end;

procedure TfrmMain.ShellTreeView1SelectionChanged(Sender: TObject);
begin
  if ShellTreeView1.Selected <> nil then
  begin
    FSelectedPath := ShellTreeView1.GetPathFromNode(ShellTreeView1.Selected);
    UpdateStatus('  Selected: ' + FSelectedPath);
  end;
end;

procedure TfrmMain.btnSearchClick(Sender: TObject);
var
  SearchPath, Pattern: string;
begin
  Pattern := Trim(edtPattern.Text);
  if Pattern = '' then
  begin
    MessageDlg('Please enter a search pattern (e.g. *.png or readme*)', mtWarning, [mbOK], 0);
    Exit;
  end;

  SearchPath := FSelectedPath;
  if SearchPath = '' then
    SearchPath := 'C:\';

  // Ensure trailing path delimiter
  SearchPath := IncludeTrailingPathDelimiter(SearchPath);

  if not DirectoryExists(SearchPath) then
  begin
    MessageDlg('Directory does not exist: ' + SearchPath, mtError, [mbOK], 0);
    Exit;
  end;

  // Prepare search
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

  try
    DoSearch(SearchPath, Pattern, cbSubfolders.Checked, cbCaseSensitive.Checked);
  finally
    SetSearching(False);
    if FStopSearch then
      UpdateStatus(Format('  Search stopped. Found %d files in %d directories.', [FFileCount, FDirCount]))
    else
      UpdateStatus(Format('  Search complete. Found %d files in %d directories.', [FFileCount, FDirCount]));
  end;
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  FStopSearch := True;
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
  UpdateStatus('  Results cleared.');
end;

procedure TfrmMain.lvResultsDblClick(Sender: TObject);
{$IFDEF WINDOWS}
var
  FullPath: string;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  if lvResults.Selected <> nil then
  begin
    FullPath := lvResults.Selected.SubItems[0];
    // Open the containing folder with the file selected
    ShellExecute(0, 'open', 'explorer.exe',
      PChar('/select,"' + FullPath + '"'), nil, SW_SHOWNORMAL);
  end;
  {$ENDIF}
end;

{ --- Core Search Engine ---
  Uses iterative BFS (breadth-first) with a TStringList as a queue
  for directory traversal. This avoids deep recursion stack overflows
  on large directory trees and is very fast.
  Pattern matching uses an optimized wildcard matcher. }

procedure TfrmMain.DoSearch(const APath, APattern: string;
  ARecursive, ACaseSensitive: Boolean);
var
  DirQueue: TStringList;
  SR: TSearchRec;
  CurrentDir: string;
  QueueIndex: Integer;
  BatchCount: Integer;
begin
  DirQueue := TStringList.Create;
  try
    DirQueue.Add(APath);
    QueueIndex := 0;

    while (QueueIndex < DirQueue.Count) and (not FStopSearch) do
    begin
      CurrentDir := IncludeTrailingPathDelimiter(DirQueue[QueueIndex]);
      Inc(QueueIndex);
      Inc(FDirCount);
      BatchCount := 0;

      // Scan current directory
      if FindFirst(CurrentDir + '*', faAnyFile, SR) = 0 then
      begin
        try
          repeat
            if FStopSearch then Break;

            // Skip . and ..
            if (SR.Name = '.') or (SR.Name = '..') then
              Continue;

            // If directory, enqueue for BFS
            if (SR.Attr and faDirectory) <> 0 then
            begin
              if ARecursive then
                DirQueue.Add(CurrentDir + SR.Name);
            end
            else
            begin
              // Check if file matches pattern
              if MatchesPattern(SR.Name, APattern, ACaseSensitive) then
              begin
                AddResult(SR.Name, CurrentDir + SR.Name, SR.Size,
                  FileDateToDateTime(SR.Time));
                Inc(FFileCount);
              end;
            end;

            // Process messages every 100 files to keep UI responsive
            Inc(BatchCount);
            if BatchCount >= 100 then
            begin
              BatchCount := 0;
              UpdateStatus(Format('  Searching: %s  |  Found: %d files  |  Scanned: %d dirs',
                [CurrentDir, FFileCount, FDirCount]));
              Application.ProcessMessages;
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

procedure TfrmMain.AddResult(const AFileName, APath: string;
  ASize: Int64; ADate: TDateTime);
var
  Item: TListItem;
  SizeStr: string;
begin
  // Format size nicely
  if ASize < 1024 then
    SizeStr := Format('%d B', [ASize])
  else if ASize < 1024 * 1024 then
    SizeStr := Format('%.1f KB', [ASize / 1024.0])
  else if ASize < 1024 * 1024 * 1024 then
    SizeStr := Format('%.1f MB', [ASize / (1024.0 * 1024.0)])
  else
    SizeStr := Format('%.2f GB', [ASize / (1024.0 * 1024.0 * 1024.0)]);

  lvResults.Items.BeginUpdate;
  try
    Item := lvResults.Items.Add;
    Item.Caption := AFileName;
    Item.SubItems.Add(APath);
    Item.SubItems.Add(SizeStr);
    Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', ADate));
  finally
    lvResults.Items.EndUpdate;
  end;
end;

procedure TfrmMain.UpdateStatus(const AMsg: string);
begin
  lblStatus.Caption := AMsg;
end;

procedure TfrmMain.SetSearching(AValue: Boolean);
begin
  FSearching := AValue;
  btnSearch.Enabled := not AValue;
  btnStop.Enabled := AValue;
  edtPattern.Enabled := not AValue;
  ShellTreeView1.Enabled := not AValue;
  if AValue then
    Screen.Cursor := crHourGlass
  else
    Screen.Cursor := crDefault;
end;

{ Pattern matching: supports multiple patterns separated by semicolon.
  e.g. "*.png;*.jpg;*.bmp" }
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

      if MatchWildcard(FN, Pat) then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    Patterns.Free;
  end;
end;

{ Optimized wildcard matching using a two-pointer / backtracking algorithm.
  Supports * (any sequence) and ? (any single char).
  Time complexity: O(n*m) worst case, but typically linear.
  This is the same algorithm used in many high-performance file managers. }
function TfrmMain.MatchWildcard(const AStr, APattern: string): Boolean;
var
  SP, PP: Integer;      // String pointer, Pattern pointer
  StarP, MatchP: Integer; // Star position backup, match position backup
begin
  SP := 1;
  PP := 1;
  StarP := 0;
  MatchP := 1;

  while SP <= Length(AStr) do
  begin
    // Advancing both pointers when chars match or ? found
    if (PP <= Length(APattern)) and
       ((APattern[PP] = '?') or (APattern[PP] = AStr[SP])) then
    begin
      Inc(SP);
      Inc(PP);
    end
    // * found: record position and advance pattern pointer
    else if (PP <= Length(APattern)) and (APattern[PP] = '*') then
    begin
      StarP := PP;
      MatchP := SP;
      Inc(PP);
    end
    // Mismatch after a *: backtrack
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

  // Consume remaining * in pattern
  while (PP <= Length(APattern)) and (APattern[PP] = '*') do
    Inc(PP);

  Result := PP > Length(APattern);
end;

end.

unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, ShellCtrls, FileUtil, LazFileUtils;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnSearch: TButton;
    btnStop: TButton;
    btnClear: TButton;
    cbSubfolders: TCheckBox;
    cbCaseSensitive: TCheckBox;
    edtPattern: TEdit;
    edtSearchPath: TEdit;
    lblActivity: TLabel;
    lblPattern: TLabel;
    lblSearchIn: TLabel;
    lblFolders: TLabel;
    lvResults: TListView;
    pnlTop: TPanel;
    pnlProgress: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    ProgressBar1: TProgressBar;
    ShellTreeView1: TShellTreeView;
    splMain: TSplitter;
    StatusBar1: TStatusBar;
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
    procedure AddResult(const AFileName, AFolder: string; ASize: Int64; ADate: TDateTime);
    procedure SetStatus(const AMsg: string);
    procedure SetActivity(const AMsg: string);
    procedure SetCounts;
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
  DateUtils;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FStopSearch := False;
  FSearching := False;
  FSelectedPath := 'C:\';

  // Default status
  ProgressBar1.Style := pbstMarquee;
  ProgressBar1.Visible := False;
  lblActivity.Caption := 'Ready.';
  StatusBar1.Panels[0].Text := ' Select a folder from the tree and enter a search pattern.';
  StatusBar1.Panels[1].Text := '';
  StatusBar1.Panels[2].Text := '';
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
    edtSearchPath.Text := FSelectedPath;
    SetStatus(' Selected: ' + FSelectedPath);
  end;
end;

procedure TfrmMain.btnSearchClick(Sender: TObject);
var
  SearchPath, Pattern: string;
begin
  Pattern := Trim(edtPattern.Text);
  if Pattern = '' then
  begin
    MessageDlg('Please enter a search pattern (e.g. *.png or readme*)',
      mtWarning, [mbOK], 0);
    Exit;
  end;

  // Use the path from the edit box (user may have typed one directly)
  SearchPath := Trim(edtSearchPath.Text);
  if SearchPath = '' then
    SearchPath := FSelectedPath;
  if SearchPath = '' then
    SearchPath := 'C:\';

  // Ensure trailing path delimiter
  SearchPath := IncludeTrailingPathDelimiter(SearchPath);

  if not DirectoryExists(SearchPath) then
  begin
    MessageDlg('Directory does not exist: ' + SearchPath,
      mtError, [mbOK], 0);
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
  SetActivity('Starting search for "' + Pattern + '" in ' + SearchPath + ' ...');
  SetStatus(' Searching...');
  Application.ProcessMessages;  // Force UI to paint immediately

  try
    DoSearch(SearchPath, Pattern, cbSubfolders.Checked, cbCaseSensitive.Checked);
  finally
    SetSearching(False);
    SetCounts;
    if FStopSearch then
    begin
      SetActivity(Format('Search stopped. Found %d file(s) in %d folder(s).', [FFileCount, FDirCount]));
      SetStatus(Format(' Stopped. %d file(s), %d folder(s) scanned.', [FFileCount, FDirCount]));
    end
    else
    begin
      if FFileCount = 0 then
        SetActivity(Format('Search complete. No matches found for "%s" in %d folder(s).', [Pattern, FDirCount]))
      else
        SetActivity(Format('Search complete. Found %d file(s) in %d folder(s).', [FFileCount, FDirCount]));
      SetStatus(Format(' Done. %d file(s), %d folder(s) scanned.', [FFileCount, FDirCount]));
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

procedure TfrmMain.lvResultsDblClick(Sender: TObject);
{$IFDEF WINDOWS}
var
  FullPath: string;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  if lvResults.Selected <> nil then
  begin
    // Build full path from folder + filename
    FullPath := IncludeTrailingPathDelimiter(lvResults.Selected.SubItems[0])
                + lvResults.Selected.Caption;
    // Open Explorer with the file selected
    ShellExecute(0, 'open', 'explorer.exe',
      PChar('/select,"' + FullPath + '"'), nil, SW_SHOWNORMAL);
  end;
  {$ENDIF}
end;

{ --- Core Search Engine ---
  Uses iterative BFS (breadth-first) with a TStringList as a queue
  for directory traversal. This avoids deep recursion stack overflows
  on large directory trees and is very fast.
  Pattern matching uses an optimized wildcard matcher.

  UI is updated every single directory so the user always sees
  what folder is currently being scanned. }

procedure TfrmMain.DoSearch(const APath, APattern: string;
  ARecursive, ACaseSensitive: Boolean);
var
  DirQueue: TStringList;
  SR: TSearchRec;
  CurrentDir: string;
  QueueIndex: Integer;
  TickCount: QWord;
  LastTick: QWord;
begin
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

      // Update UI every ~100ms so it stays responsive without slowing search
      TickCount := GetTickCount64;
      if (TickCount - LastTick) >= 100 then
      begin
        LastTick := TickCount;
        SetActivity('Scanning: ' + CurrentDir);
        SetCounts;
        Application.ProcessMessages;
      end;

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
                AddResult(SR.Name, CurrentDir, SR.Size,
                  FileDateToDateTime(SR.Time));
                Inc(FFileCount);

                // Update immediately when a match is found so user sees results appear
                TickCount := GetTickCount64;
                if (TickCount - LastTick) >= 100 then
                begin
                  LastTick := TickCount;
                  SetActivity('Scanning: ' + CurrentDir + '  (found ' + IntToStr(FFileCount) + ' so far)');
                  SetCounts;
                  Application.ProcessMessages;
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

procedure TfrmMain.AddResult(const AFileName, AFolder: string;
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
    Item.SubItems.Add(ExcludeTrailingPathDelimiter(AFolder));
    Item.SubItems.Add(SizeStr);
    Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', ADate));
  finally
    lvResults.Items.EndUpdate;
  end;
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
  ShellTreeView1.Enabled := not AValue;
  ProgressBar1.Visible := AValue;
  if AValue then
    Screen.Cursor := crHourGlass
  else
    Screen.Cursor := crDefault;
end;

{ Pattern matching: supports multiple patterns separated by semicolons.
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
  Supports * (any sequence of chars) and ? (any single char).
  Time complexity: O(n*m) worst case, typically linear. }
function TfrmMain.MatchWildcard(const AStr, APattern: string): Boolean;
var
  SP, PP: Integer;         // String pointer, Pattern pointer
  StarP, MatchP: Integer;  // Star position backup, match position backup
begin
  SP := 1;
  PP := 1;
  StarP := 0;
  MatchP := 1;

  while SP <= Length(AStr) do
  begin
    // Chars match or ? wildcard
    if (PP <= Length(APattern)) and
       ((APattern[PP] = '?') or (APattern[PP] = AStr[SP])) then
    begin
      Inc(SP);
      Inc(PP);
    end
    // * wildcard: record position and advance pattern pointer
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

  // Consume any remaining * in pattern
  while (PP <= Length(APattern)) and (APattern[PP] = '*') do
    Inc(PP);

  Result := PP > Length(APattern);
end;

end.

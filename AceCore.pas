unit AceCore;

{ ----------------------------------------------------------------------------
  Ace's Utilities - UI-independent core logic.

  Everything in this unit is pure (no LCL, no forms, no Win32 handles) so it
  can be exercised directly by the fpcunit suite in tests/AceTests.lpi.
  TfrmMain delegates to these routines.
  ---------------------------------------------------------------------------- }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

const
  // Explorer list column indices (match ShellListViewExplorer.Columns order)
  EXP_COL_NAME = 0;
  EXP_COL_SIZE = 1;
  EXP_COL_TYPE = 2;
  EXP_COL_DATE = 3;

  MAX_RECENT_FILES = 10;

type
  { Snapshot of the fields the Explorer sort needs from a TShellListItem }
  TExplorerEntry = record
    Name: string;
    IsFolder: Boolean;
    Size: Int64;
    Time: LongInt;   // DOS packed date/time as returned by FindFirst / FileAge
  end;

// Path input normalization: strips any number of leading/trailing quote
// characters (" or ') and surrounding whitespace, e.g. ""C:\x"" -> C:\x
function StripPathQuotes(const APath: string): string;

// Search pattern handling. Patterns are parsed once (trimmed, empties removed
// and lowercased when ACaseSensitive is False) so the per-file match in the
// traversal loop never allocates per pattern.
procedure ParseSearchPatterns(const APattern: string; ACaseSensitive: Boolean; AList: TStrings);
function MatchesSearchPatterns(const AFileName: string; APatterns: TStrings; ACaseSensitive: Boolean): Boolean;
function MatchWildcard(const AStr, APattern: string): Boolean;

function FormatFileSize(ASize: Int64; IsFolder: Boolean = False): string;
function IsPdfFile(const APath: string): Boolean;

// Notepad text helpers
function CleanAITells(const AText: string): string;
function SuggestFileName(ALines: TStrings): string;
function StripListMarker(const S: string): string;
function FormatAsNumberedList(const AText: string; AIsHTML: Boolean): string;
function FormatAsBulletList(const AText: string; AIsHTML: Boolean): string;

// Explorer ordering: folders are always grouped first, regardless of direction.
// Ties on the primary key fall back to an ascending name comparison so the
// order is stable and predictable.
function CompareExplorerEntries(const A, B: TExplorerEntry; AColumn: Integer; AAscending: Boolean): Integer;

// Tab cycling: returns the index ADelta steps away from ACurrent, wrapping
// around and skipping entries whose AVisible flag is False.
function CycleTabIndex(ACurrent, ADelta: Integer; const AVisible: array of Boolean): Integer;

// Most-recently-used list maintenance: moves/inserts AFileName at the top,
// removes duplicates (case-insensitive) and trims the list to AMax entries.
procedure AddRecentFile(AList: TStrings; const AFileName: string; AMax: Integer = MAX_RECENT_FILES);

// Shortens a long path for display by replacing middle folders with '...',
// keeping the root and as many trailing folders as fit, e.g.
// C:\Users\me\very\long\path\Project -> C:\...\path\Project
function ShortenPath(const APath: string; AMaxLen: Integer): string;

implementation

function StripPathQuotes(const APath: string): string;
begin
  Result := Trim(APath);
  while (Length(Result) > 0) and (Result[1] in ['"', '''']) do
    Delete(Result, 1, 1);
  while (Length(Result) > 0) and (Result[Length(Result)] in ['"', '''']) do
    Delete(Result, Length(Result), 1);
  Result := Trim(Result);
end;

procedure ParseSearchPatterns(const APattern: string; ACaseSensitive: Boolean; AList: TStrings);
var
  Raw: TStringList;
  i: Integer;
  Pat: string;
begin
  AList.Clear;
  Raw := TStringList.Create;
  try
    Raw.Delimiter := ';';
    Raw.StrictDelimiter := True;
    Raw.DelimitedText := APattern;
    for i := 0 to Raw.Count - 1 do
    begin
      Pat := Trim(Raw[i]);
      if Pat = '' then Continue;
      if not ACaseSensitive then
        Pat := LowerCase(Pat);
      AList.Add(Pat);
    end;
  finally
    Raw.Free;
  end;
end;

function MatchesSearchPatterns(const AFileName: string; APatterns: TStrings; ACaseSensitive: Boolean): Boolean;
var
  i: Integer;
  FN, Pat: string;
begin
  if (APatterns = nil) or (APatterns.Count = 0) then Exit(True);

  if ACaseSensitive then
    FN := AFileName
  else
    FN := LowerCase(AFileName);

  for i := 0 to APatterns.Count - 1 do
  begin
    Pat := APatterns[i];
    // Smart match: without wildcards (* or ?) a pattern is a "contains" search
    if (Pos('*', Pat) = 0) and (Pos('?', Pat) = 0) then
    begin
      if Pos(Pat, FN) > 0 then Exit(True);
    end
    else if MatchWildcard(FN, Pat) then
      Exit(True);
  end;
  Result := False;
end;

function MatchWildcard(const AStr, APattern: string): Boolean;
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
      Exit(False);
  end;

  while (PP <= Length(APattern)) and (APattern[PP] = '*') do
    Inc(PP);

  Result := PP > Length(APattern);
end;

function FormatFileSize(ASize: Int64; IsFolder: Boolean = False): string;
var
  Val: Double;
begin
  if IsFolder then Exit('');
  if ASize <= 0 then Exit('0 KB');

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

function IsPdfFile(const APath: string): Boolean;
begin
  Result := SameText(ExtractFileExt(APath), '.pdf');
end;

function CleanAITells(const AText: string): string;
begin
  Result := AText;
  if Result = '' then Exit;

  // Em-dash (U+2014), En-dash (U+2013), and Horizontal bar (U+2015) to hyphens (-)
  Result := StringReplace(Result, #$E2#$80#$94, '-', [rfReplaceAll]);
  Result := StringReplace(Result, #$E2#$80#$93, '-', [rfReplaceAll]);
  Result := StringReplace(Result, #$E2#$80#$95, '-', [rfReplaceAll]);

  // Curly double quotes (U+201C, U+201D) and low double quote (U+201E) to straight quotes (")
  Result := StringReplace(Result, #$E2#$80#$9C, '"', [rfReplaceAll]);
  Result := StringReplace(Result, #$E2#$80#$9D, '"', [rfReplaceAll]);
  Result := StringReplace(Result, #$E2#$80#$9E, '"', [rfReplaceAll]);

  // Curly single quotes / apostrophes (U+2018, U+2019), low quote (U+201A),
  // high reversed-9 quote (U+201B), modifier letter apostrophe (U+02BC) to straight apostrophe (')
  Result := StringReplace(Result, #$E2#$80#$98, '''', [rfReplaceAll]);
  Result := StringReplace(Result, #$E2#$80#$99, '''', [rfReplaceAll]);
  Result := StringReplace(Result, #$E2#$80#$9A, '''', [rfReplaceAll]);
  Result := StringReplace(Result, #$E2#$80#$9B, '''', [rfReplaceAll]);
  Result := StringReplace(Result, #$CA#$BC, '''', [rfReplaceAll]);
end;

function SuggestFileName(ALines: TStrings): string;
var
  i, LineIdx: Integer;
  Candidate, RawLine, CleanChars: string;
  C: Char;
const
  IllegalChars: set of Char = ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
begin
  Candidate := '';
  RawLine := '';

  // Scan for the first non-empty line
  if ALines <> nil then
    for LineIdx := 0 to ALines.Count - 1 do
      if Trim(ALines[LineIdx]) <> '' then
      begin
        RawLine := ALines[LineIdx];
        Break;
      end;

  if RawLine <> '' then
  begin
    CleanChars := '';
    for i := 1 to Length(RawLine) do
    begin
      C := RawLine[i];
      if (not (C in IllegalChars)) and (Ord(C) >= 32) then
      begin
        // Skip leading space or period
        if (CleanChars = '') and (C in [' ', '.']) then
          Continue;
        CleanChars := CleanChars + C;
      end;
    end;

    // Take up to 8 characters
    Candidate := Trim(Copy(CleanChars, 1, 8));

    // Remove any trailing periods or spaces
    while (Length(Candidate) > 0) and (Candidate[Length(Candidate)] in ['.', ' ']) do
      Delete(Candidate, Length(Candidate), 1);
  end;

  if Candidate = '' then
    Result := 'Untitled.txt'
  else
    Result := Candidate + '.txt';
end;

function StripListMarker(const S: string): string;
var
  i, len: Integer;
  LowerS: string;
begin
  Result := Trim(S);
  if Result = '' then Exit;

  // Check for HTML <li>...</li>
  LowerS := LowerCase(Result);
  if (Copy(LowerS, 1, 4) = '<li>') and (Copy(LowerS, Length(LowerS) - 4, 5) = '</li>') then
    Result := Trim(Copy(Result, 5, Length(Result) - 9));

  // Check for leading markdown / text bullets: '-', '*', '+', followed by space
  if (Length(Result) >= 2) and (Result[1] in ['-', '*', '+']) and (Result[2] = ' ') then
  begin
    Delete(Result, 1, 2);
    Result := Trim(Result);
    Exit;
  end;

  // UTF-8 Bullet U+2022 is 3 bytes: #$E2#$80#$A2
  if (Length(Result) >= 3) and (Copy(Result, 1, 3) = #$E2#$80#$A2) then
  begin
    Delete(Result, 1, 3);
    Result := Trim(Result);
    Exit;
  end;

  // Check for leading number like '1. ', '1) ', '12. '
  len := Length(Result);
  i := 1;
  while (i <= len) and (Result[i] in ['0'..'9']) do
    Inc(i);
  if (i > 1) and (i <= len) and (Result[i] in ['.', ')', '-']) then
  begin
    Inc(i);
    while (i <= len) and (Result[i] = ' ') do
      Inc(i);
    Result := Copy(Result, i, len - i + 1);
  end;
end;

// Shared list builder. ANumbered selects 1./2./3. (or <ol>) versus bullets (or <ul>).
function FormatAsList(const AText: string; AIsHTML, ANumbered: Boolean): string;
var
  Lines, OutLines: TStringList;
  i, ItemNum: Integer;
  CurLine, LowLine, ListTag: string;
  HasTrailingNL: Boolean;
begin
  if AText = '' then Exit('');

  HasTrailingNL := AText[Length(AText)] in [#10, #13];
  Lines := TStringList.Create;
  OutLines := TStringList.Create;
  try
    Lines.Text := AText;
    ItemNum := 1;

    if AIsHTML then
    begin
      if ANumbered then ListTag := 'ol' else ListTag := 'ul';
      OutLines.Add('<' + ListTag + '>');
      for i := 0 to Lines.Count - 1 do
      begin
        CurLine := Lines[i];
        if Trim(CurLine) = '' then
          Continue;
        LowLine := LowerCase(Trim(CurLine));
        if (LowLine = '<ol>') or (LowLine = '</ol>') or
           (LowLine = '<ul>') or (LowLine = '</ul>') then
          Continue;
        OutLines.Add('  <li>' + StripListMarker(CurLine) + '</li>');
      end;
      OutLines.Add('</' + ListTag + '>');
    end
    else
    begin
      for i := 0 to Lines.Count - 1 do
      begin
        CurLine := Lines[i];
        if Trim(CurLine) = '' then
          OutLines.Add(CurLine)
        else if ANumbered then
        begin
          OutLines.Add(IntToStr(ItemNum) + '. ' + StripListMarker(CurLine));
          Inc(ItemNum);
        end
        else
          OutLines.Add(#$E2#$80#$A2' ' + StripListMarker(CurLine));
      end;
    end;

    Result := OutLines.Text;
    if (not HasTrailingNL) and (Length(Result) >= Length(LineEnding)) and
       (Copy(Result, Length(Result) - Length(LineEnding) + 1, Length(LineEnding)) = LineEnding) then
      SetLength(Result, Length(Result) - Length(LineEnding));
  finally
    Lines.Free;
    OutLines.Free;
  end;
end;

function FormatAsNumberedList(const AText: string; AIsHTML: Boolean): string;
begin
  Result := FormatAsList(AText, AIsHTML, True);
end;

function FormatAsBulletList(const AText: string; AIsHTML: Boolean): string;
begin
  Result := FormatAsList(AText, AIsHTML, False);
end;

function CompareExplorerEntries(const A, B: TExplorerEntry; AColumn: Integer; AAscending: Boolean): Integer;
begin
  // Folders always grouped first
  if A.IsFolder and (not B.IsFolder) then Exit(-1);
  if (not A.IsFolder) and B.IsFolder then Exit(1);

  case AColumn of
    EXP_COL_SIZE:
      if A.Size < B.Size then Result := -1
      else if A.Size > B.Size then Result := 1
      else Result := 0;
    EXP_COL_TYPE:
      Result := CompareText(ExtractFileExt(A.Name), ExtractFileExt(B.Name));
    EXP_COL_DATE:
      // Compare unsigned: DOS timestamps from 2044 on set the sign bit
      if LongWord(A.Time) < LongWord(B.Time) then Result := -1
      else if LongWord(A.Time) > LongWord(B.Time) then Result := 1
      else Result := 0;
    else
      Result := CompareText(A.Name, B.Name);
  end;

  if not AAscending then
    Result := -Result;

  if Result = 0 then
    Result := CompareText(A.Name, B.Name);
end;

function CycleTabIndex(ACurrent, ADelta: Integer; const AVisible: array of Boolean): Integer;
var
  Count, Steps, Idx: Integer;
begin
  Result := ACurrent;
  Count := Length(AVisible);
  if (Count = 0) or (ADelta = 0) then Exit;

  Idx := ACurrent;
  if (Idx < 0) or (Idx >= Count) then Idx := 0;
  for Steps := 1 to Count do
  begin
    Idx := ((Idx + ADelta) mod Count + Count) mod Count;
    if AVisible[Idx] then Exit(Idx);
  end;
end;

procedure AddRecentFile(AList: TStrings; const AFileName: string; AMax: Integer);
var
  i: Integer;
begin
  if (AList = nil) or (Trim(AFileName) = '') then Exit;
  for i := AList.Count - 1 downto 0 do
    if SameText(AList[i], AFileName) then
      AList.Delete(i);
  AList.Insert(0, AFileName);
  while AList.Count > AMax do
    AList.Delete(AList.Count - 1);
end;

function ShortenPath(const APath: string; AMaxLen: Integer): string;
var
  RootLen, P: Integer;
  Root, Tail: string;
begin
  Result := APath;
  if Length(APath) <= AMaxLen then Exit;

  // Root: "C:\" or, for UNC paths, "\\server\share\"
  RootLen := Pos(PathDelim, APath);
  if Copy(APath, 1, 2) = PathDelim + PathDelim then
  begin
    P := PosEx(PathDelim, APath, 3);             // end of server
    if P > 0 then
      P := PosEx(PathDelim, APath, P + 1);       // end of share
    if P > 0 then
      RootLen := P;
  end;
  if RootLen = 0 then
    Exit('...' + Copy(APath, Length(APath) - AMaxLen + 4, MaxInt));
  Root := Copy(APath, 1, RootLen);

  // Keep whole trailing segments while they fit after "<root>...\"
  Tail := Copy(APath, RootLen + 1, MaxInt);
  while (Length(Root) + 4 + Length(Tail) > AMaxLen) and (Pos(PathDelim, Tail) > 0) do
    Tail := Copy(Tail, Pos(PathDelim, Tail) + 1, MaxInt);
  Result := Root + '...' + PathDelim + Tail;
  // A single last segment that is still too long is cut from the left
  if Length(Result) > AMaxLen then
    Result := Root + '...' + Copy(Tail, Length(Tail) - (AMaxLen - Length(Root) - 3) + 1, MaxInt);
end;

end.

unit TestAceCore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, AceCore;

type

  TTestPathQuotes = class(TTestCase)
  published
    procedure TestPlainPathUnchanged;
    procedure TestDoubleQuotes;
    procedure TestDoubledDoubleQuotes;
    procedure TestSingleQuotes;
    procedure TestWhitespaceAroundQuotes;
    procedure TestOnlyQuotes;
  end;

  TTestSearchPatterns = class(TTestCase)
  published
    procedure TestParseTrimsAndDropsEmpties;
    procedure TestParseLowercasesWhenCaseInsensitive;
    procedure TestParseKeepsCaseWhenCaseSensitive;
    procedure TestWildcardStar;
    procedure TestWildcardQuestionMark;
    procedure TestWildcardNoMatch;
    procedure TestSubstringWithoutWildcards;
    procedure TestMultiplePatterns;
    procedure TestCaseSensitiveMatch;
    procedure TestEmptyPatternListMatchesEverything;
  end;

  TTestFileSize = class(TTestCase)
  published
    procedure TestFolderIsBlank;
    procedure TestZero;
    procedure TestBytes;
    procedure TestKilobytes;
    procedure TestMegabytes;
    procedure TestGigabytes;
  end;

  TTestTextHelpers = class(TTestCase)
  published
    procedure TestCleanAITellsDashes;
    procedure TestCleanAITellsQuotes;
    procedure TestCleanAITellsLeavesAsciiAlone;
    procedure TestSuggestFileNameFirstLine;
    procedure TestSuggestFileNameSkipsBlankAndIllegal;
    procedure TestSuggestFileNameEmpty;
    procedure TestStripListMarkers;
    procedure TestNumberedListPlain;
    procedure TestNumberedListRenumbers;
    procedure TestBulletListHTML;
    procedure TestNumberedListPreservesTrailingNewline;
  end;

  TTestExplorerSort = class(TTestCase)
  private
    function Entry(const AName: string; AFolder: Boolean; ASize: Int64; ATime: LongInt): TExplorerEntry;
  published
    procedure TestFoldersAlwaysFirst;
    procedure TestFoldersFirstEvenDescending;
    procedure TestByName;
    procedure TestByTypeGroupsExtensions;
    procedure TestByTypeTieBreaksOnName;
    procedure TestByDateNewestFirst;
    procedure TestByDateUnsignedTimestamps;
    procedure TestBySize;
    procedure TestSortsListDeterministically;
  end;

  TTestTabsAndRecent = class(TTestCase)
  published
    procedure TestCycleForwardWraps;
    procedure TestCycleBackwardWraps;
    procedure TestCycleSkipsHidden;
    procedure TestCycleAllHiddenReturnsCurrent;
    procedure TestRecentInsertsAtTop;
    procedure TestRecentMovesDuplicateToTop;
    procedure TestRecentTrimsToMax;
    procedure TestRecentIgnoresBlank;
    procedure TestIsPdfFile;
    procedure TestShortenPathShortUnchanged;
    procedure TestShortenPathKeepsRootAndTail;
    procedure TestShortenPathRespectsMax;
  end;

implementation

{ TTestPathQuotes }

procedure TTestPathQuotes.TestPlainPathUnchanged;
begin
  AssertEquals('C:\Users\Test', StripPathQuotes('C:\Users\Test'));
end;

procedure TTestPathQuotes.TestDoubleQuotes;
begin
  AssertEquals('C:\Users\Test\file.md', StripPathQuotes('"C:\Users\Test\file.md"'));
end;

procedure TTestPathQuotes.TestDoubledDoubleQuotes;
begin
  AssertEquals('C:\path', StripPathQuotes('""C:\path""'));
end;

procedure TTestPathQuotes.TestSingleQuotes;
begin
  AssertEquals('C:\path', StripPathQuotes('''C:\path'''));
end;

procedure TTestPathQuotes.TestWhitespaceAroundQuotes;
begin
  AssertEquals('C:\path with space', StripPathQuotes('  " C:\path with space "  '));
end;

procedure TTestPathQuotes.TestOnlyQuotes;
begin
  AssertEquals('', StripPathQuotes('""'''''));
end;

{ TTestSearchPatterns }

procedure TTestSearchPatterns.TestParseTrimsAndDropsEmpties;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    ParseSearchPatterns(' *.pas ; ;*.md;; ', True, L);
    AssertEquals(2, L.Count);
    AssertEquals('*.pas', L[0]);
    AssertEquals('*.md', L[1]);
  finally
    L.Free;
  end;
end;

procedure TTestSearchPatterns.TestParseLowercasesWhenCaseInsensitive;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    ParseSearchPatterns('*.PAS;ReadMe', False, L);
    AssertEquals('*.pas', L[0]);
    AssertEquals('readme', L[1]);
  finally
    L.Free;
  end;
end;

procedure TTestSearchPatterns.TestParseKeepsCaseWhenCaseSensitive;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    ParseSearchPatterns('ReadMe', True, L);
    AssertEquals('ReadMe', L[0]);
  finally
    L.Free;
  end;
end;

procedure TTestSearchPatterns.TestWildcardStar;
begin
  AssertTrue(MatchWildcard('mainform.pas', '*.pas'));
  AssertTrue(MatchWildcard('mainform.pas', 'main*'));
  AssertTrue(MatchWildcard('mainform.pas', '*form*'));
  AssertTrue(MatchWildcard('a.b.c', '*.c'));
end;

procedure TTestSearchPatterns.TestWildcardQuestionMark;
begin
  AssertTrue(MatchWildcard('file1.txt', 'file?.txt'));
  AssertFalse(MatchWildcard('file12.txt', 'file?.txt'));
end;

procedure TTestSearchPatterns.TestWildcardNoMatch;
begin
  AssertFalse(MatchWildcard('mainform.lfm', '*.pas'));
  AssertFalse(MatchWildcard('', '?'));
  AssertTrue(MatchWildcard('', '*'));
end;

procedure TTestSearchPatterns.TestSubstringWithoutWildcards;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    ParseSearchPatterns('Form', False, L);
    AssertTrue(MatchesSearchPatterns('MainForm.pas', L, False));
    AssertFalse(MatchesSearchPatterns('AceUtils.lpr', L, False));
  finally
    L.Free;
  end;
end;

procedure TTestSearchPatterns.TestMultiplePatterns;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    ParseSearchPatterns('*.pas;*.lpr;*.md', False, L);
    AssertTrue(MatchesSearchPatterns('README.md', L, False));
    AssertTrue(MatchesSearchPatterns('AceUtils.LPR', L, False));
    AssertFalse(MatchesSearchPatterns('AceUtils.exe', L, False));
  finally
    L.Free;
  end;
end;

procedure TTestSearchPatterns.TestCaseSensitiveMatch;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    ParseSearchPatterns('*.PAS', True, L);
    AssertTrue(MatchesSearchPatterns('X.PAS', L, True));
    AssertFalse(MatchesSearchPatterns('x.pas', L, True));
  finally
    L.Free;
  end;
end;

procedure TTestSearchPatterns.TestEmptyPatternListMatchesEverything;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    ParseSearchPatterns(' ; ', False, L);
    AssertEquals(0, L.Count);
    AssertTrue(MatchesSearchPatterns('anything.bin', L, False));
  finally
    L.Free;
  end;
end;

{ TTestFileSize }

procedure TTestFileSize.TestFolderIsBlank;
begin
  AssertEquals('', FormatFileSize(12345, True));
end;

procedure TTestFileSize.TestZero;
begin
  AssertEquals('0 KB', FormatFileSize(0));
  AssertEquals('0 KB', FormatFileSize(-5));
end;

procedure TTestFileSize.TestBytes;
begin
  AssertEquals(Format('%.2f KB', [512 / 1024.0]), FormatFileSize(512));
end;

procedure TTestFileSize.TestKilobytes;
begin
  AssertEquals(Format('%.2f KB', [2.0]), FormatFileSize(2048));
  AssertEquals(Format('%.1f KB', [50.0]), FormatFileSize(50 * 1024));
end;

procedure TTestFileSize.TestMegabytes;
begin
  AssertEquals(Format('%.2f MB', [10.0]), FormatFileSize(10 * 1024 * 1024));
end;

procedure TTestFileSize.TestGigabytes;
begin
  AssertEquals(Format('%.2f GB', [3.0]), FormatFileSize(Int64(3) * 1024 * 1024 * 1024));
end;

{ TTestTextHelpers }

procedure TTestTextHelpers.TestCleanAITellsDashes;
begin
  AssertEquals('a - b - c - d', CleanAITells('a '#$E2#$80#$94' b '#$E2#$80#$93' c '#$E2#$80#$95' d'));
end;

procedure TTestTextHelpers.TestCleanAITellsQuotes;
begin
  AssertEquals('"hi" it''s ''x''',
    CleanAITells(#$E2#$80#$9C'hi'#$E2#$80#$9D' it'#$E2#$80#$99's '#$E2#$80#$98'x'#$E2#$80#$99));
end;

procedure TTestTextHelpers.TestCleanAITellsLeavesAsciiAlone;
begin
  AssertEquals('plain "ascii" - text''s', CleanAITells('plain "ascii" - text''s'));
  AssertEquals('', CleanAITells(''));
end;

procedure TTestTextHelpers.TestSuggestFileNameFirstLine;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add('Shopping list for Monday');
    AssertEquals('Shopping.txt', SuggestFileName(L));
  finally
    L.Free;
  end;
end;

procedure TTestTextHelpers.TestSuggestFileNameSkipsBlankAndIllegal;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add('');
    L.Add('   ');
    L.Add('  ..a:b/c*d?e');
    AssertEquals('abcde.txt', SuggestFileName(L));
  finally
    L.Free;
  end;
end;

procedure TTestTextHelpers.TestSuggestFileNameEmpty;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    AssertEquals('Untitled.txt', SuggestFileName(L));
    L.Add('???');
    AssertEquals('Untitled.txt', SuggestFileName(L));
    AssertEquals('Untitled.txt', SuggestFileName(nil));
  finally
    L.Free;
  end;
end;

procedure TTestTextHelpers.TestStripListMarkers;
begin
  AssertEquals('item', StripListMarker('- item'));
  AssertEquals('item', StripListMarker('* item'));
  AssertEquals('item', StripListMarker('12. item'));
  AssertEquals('item', StripListMarker('3) item'));
  AssertEquals('item', StripListMarker('<li>item</li>'));
  AssertEquals('item', StripListMarker(#$E2#$80#$A2' item'));
  AssertEquals('-no space', StripListMarker('-no space'));
end;

procedure TTestTextHelpers.TestNumberedListPlain;
begin
  AssertEquals('1. a' + LineEnding + LineEnding + '2. b',
    FormatAsNumberedList('a' + LineEnding + LineEnding + 'b', False));
end;

procedure TTestTextHelpers.TestNumberedListRenumbers;
begin
  AssertEquals('1. a' + LineEnding + '2. b',
    FormatAsNumberedList('5. a' + LineEnding + '- b', False));
end;

procedure TTestTextHelpers.TestBulletListHTML;
begin
  AssertEquals('<ul>' + LineEnding + '  <li>a</li>' + LineEnding + '  <li>b</li>' + LineEnding + '</ul>',
    FormatAsBulletList('<ol>' + LineEnding + '1. a' + LineEnding + LineEnding + 'b' + LineEnding + '</ol>', True));
end;

procedure TTestTextHelpers.TestNumberedListPreservesTrailingNewline;
begin
  AssertEquals('1. a' + LineEnding, FormatAsNumberedList('a' + LineEnding, False));
  AssertEquals('', FormatAsNumberedList('', False));
end;

{ TTestExplorerSort }

function TTestExplorerSort.Entry(const AName: string; AFolder: Boolean; ASize: Int64; ATime: LongInt): TExplorerEntry;
begin
  Result.Name := AName;
  Result.IsFolder := AFolder;
  Result.Size := ASize;
  Result.Time := ATime;
end;

procedure TTestExplorerSort.TestFoldersAlwaysFirst;
begin
  AssertTrue(CompareExplorerEntries(Entry('zzz', True, 0, 0), Entry('aaa.txt', False, 0, 0), EXP_COL_NAME, True) < 0);
  AssertTrue(CompareExplorerEntries(Entry('aaa.txt', False, 0, 0), Entry('zzz', True, 0, 0), EXP_COL_NAME, True) > 0);
end;

procedure TTestExplorerSort.TestFoldersFirstEvenDescending;
begin
  AssertTrue(CompareExplorerEntries(Entry('a', True, 0, 0), Entry('z.txt', False, 0, 99), EXP_COL_DATE, False) < 0);
end;

procedure TTestExplorerSort.TestByName;
begin
  AssertTrue(CompareExplorerEntries(Entry('Alpha.txt', False, 0, 0), Entry('beta.txt', False, 0, 0), EXP_COL_NAME, True) < 0);
  AssertTrue(CompareExplorerEntries(Entry('Alpha.txt', False, 0, 0), Entry('beta.txt', False, 0, 0), EXP_COL_NAME, False) > 0);
end;

procedure TTestExplorerSort.TestByTypeGroupsExtensions;
begin
  AssertTrue(CompareExplorerEntries(Entry('z.md', False, 0, 0), Entry('a.txt', False, 0, 0), EXP_COL_TYPE, True) < 0);
  AssertTrue(CompareExplorerEntries(Entry('noext', False, 0, 0), Entry('a.txt', False, 0, 0), EXP_COL_TYPE, True) < 0);
end;

procedure TTestExplorerSort.TestByTypeTieBreaksOnName;
begin
  AssertTrue(CompareExplorerEntries(Entry('a.TXT', False, 0, 0), Entry('b.txt', False, 0, 0), EXP_COL_TYPE, True) < 0);
  // Tie-break stays ascending by name even when the type sort is descending
  AssertTrue(CompareExplorerEntries(Entry('a.txt', False, 0, 0), Entry('b.txt', False, 0, 0), EXP_COL_TYPE, False) < 0);
end;

procedure TTestExplorerSort.TestByDateNewestFirst;
begin
  AssertTrue(CompareExplorerEntries(Entry('new', False, 0, 2000), Entry('old', False, 0, 1000), EXP_COL_DATE, False) < 0);
  AssertTrue(CompareExplorerEntries(Entry('new', False, 0, 2000), Entry('old', False, 0, 1000), EXP_COL_DATE, True) > 0);
end;

procedure TTestExplorerSort.TestByDateUnsignedTimestamps;
begin
  // A DOS timestamp with the high bit set (year >= 2044) is newer than one without
  AssertTrue(CompareExplorerEntries(Entry('future', False, 0, Low(LongInt)), Entry('now', False, 0, $5A000000),
    EXP_COL_DATE, True) > 0);
end;

procedure TTestExplorerSort.TestBySize;
begin
  AssertTrue(CompareExplorerEntries(Entry('small', False, 10, 0), Entry('big', False, 10 * 1024 * 1024, 0), EXP_COL_SIZE, True) < 0);
end;

procedure TTestExplorerSort.TestSortsListDeterministically;
var
  E: array[0..4] of TExplorerEntry;
  i, j: Integer;
  T: TExplorerEntry;
begin
  E[0] := Entry('report.pdf', False, 1, 300);
  E[1] := Entry('Projects', True, 0, 100);
  E[2] := Entry('notes.txt', False, 1, 500);
  E[3] := Entry('Archive', True, 0, 900);
  E[4] := Entry('photo.png', False, 1, 400);
  // Simple insertion sort by date, newest first
  for i := 1 to High(E) do
  begin
    T := E[i];
    j := i - 1;
    while (j >= 0) and (CompareExplorerEntries(E[j], T, EXP_COL_DATE, False) > 0) do
    begin
      E[j + 1] := E[j];
      Dec(j);
    end;
    E[j + 1] := T;
  end;
  AssertEquals('Archive', E[0].Name);
  AssertEquals('Projects', E[1].Name);
  AssertEquals('notes.txt', E[2].Name);
  AssertEquals('photo.png', E[3].Name);
  AssertEquals('report.pdf', E[4].Name);
end;

{ TTestTabsAndRecent }

procedure TTestTabsAndRecent.TestCycleForwardWraps;
begin
  AssertEquals(1, CycleTabIndex(0, 1, [True, True, True]));
  AssertEquals(0, CycleTabIndex(2, 1, [True, True, True]));
end;

procedure TTestTabsAndRecent.TestCycleBackwardWraps;
begin
  AssertEquals(2, CycleTabIndex(0, -1, [True, True, True]));
  AssertEquals(0, CycleTabIndex(1, -1, [True, True, True]));
end;

procedure TTestTabsAndRecent.TestCycleSkipsHidden;
begin
  AssertEquals(2, CycleTabIndex(0, 1, [True, False, True]));
  AssertEquals(0, CycleTabIndex(2, 1, [True, False, True]));
  AssertEquals(0, CycleTabIndex(2, -1, [True, False, True]));
end;

procedure TTestTabsAndRecent.TestCycleAllHiddenReturnsCurrent;
begin
  AssertEquals(1, CycleTabIndex(1, 1, [False, False, False]));
  AssertEquals(-1, CycleTabIndex(-1, 1, []));
end;

procedure TTestTabsAndRecent.TestRecentInsertsAtTop;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    AddRecentFile(L, 'C:\a.txt');
    AddRecentFile(L, 'C:\b.txt');
    AssertEquals(2, L.Count);
    AssertEquals('C:\b.txt', L[0]);
  finally
    L.Free;
  end;
end;

procedure TTestTabsAndRecent.TestRecentMovesDuplicateToTop;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    AddRecentFile(L, 'C:\a.txt');
    AddRecentFile(L, 'C:\b.txt');
    AddRecentFile(L, 'c:\A.TXT');
    AssertEquals(2, L.Count);
    AssertEquals('c:\A.TXT', L[0]);
    AssertEquals('C:\b.txt', L[1]);
  finally
    L.Free;
  end;
end;

procedure TTestTabsAndRecent.TestRecentTrimsToMax;
var
  L: TStringList;
  i: Integer;
begin
  L := TStringList.Create;
  try
    for i := 1 to 15 do
      AddRecentFile(L, Format('C:\f%d.txt', [i]), 10);
    AssertEquals(10, L.Count);
    AssertEquals('C:\f15.txt', L[0]);
    AssertEquals('C:\f6.txt', L[9]);
  finally
    L.Free;
  end;
end;

procedure TTestTabsAndRecent.TestRecentIgnoresBlank;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    AddRecentFile(L, '   ');
    AssertEquals(0, L.Count);
  finally
    L.Free;
  end;
end;

procedure TTestTabsAndRecent.TestIsPdfFile;
begin
  AssertTrue(IsPdfFile('C:\docs\Report.PDF'));
  AssertTrue(IsPdfFile('a.pdf'));
  AssertFalse(IsPdfFile('a.pdf.txt'));
  AssertFalse(IsPdfFile('pdf'));
end;

// Test paths are written Windows-style; convert for the platform under test
function P(const S: string): string;
begin
  Result := StringReplace(S, '\', PathDelim, [rfReplaceAll]);
end;

procedure TTestTabsAndRecent.TestShortenPathShortUnchanged;
begin
  AssertEquals(P('C:\Users\me'), ShortenPath(P('C:\Users\me'), 40));
end;

procedure TTestTabsAndRecent.TestShortenPathKeepsRootAndTail;
begin
  AssertEquals(P('C:\...\path\Project'),
    ShortenPath(P('C:\Users\me\very\long\path\Project'), 20));
  AssertEquals(P('\\server\share\...\deep\dir'),
    ShortenPath(P('\\server\share\a\b\c\deep\dir'), 27));
end;

procedure TTestTabsAndRecent.TestShortenPathRespectsMax;
var
  S: string;
begin
  S := ShortenPath(P('C:\Users\me\') + StringOfChar('x', 80), 30);
  AssertTrue('length ' + IntToStr(Length(S)), Length(S) <= 30);
  AssertEquals(P('C:\...'), Copy(S, 1, 6));
  S := ShortenPath(P('C:\a\b\c\d\e\f\g\h\i\j\k\l\m\n\o\p\q\r\s\t\u\v'), 16);
  AssertTrue('length ' + IntToStr(Length(S)), Length(S) <= 16);
end;

initialization
  RegisterTest(TTestPathQuotes);
  RegisterTest(TTestSearchPatterns);
  RegisterTest(TTestFileSize);
  RegisterTest(TTestTextHelpers);
  RegisterTest(TTestExplorerSort);
  RegisterTest(TTestTabsAndRecent);
end.

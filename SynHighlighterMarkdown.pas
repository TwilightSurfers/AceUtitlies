unit SynHighlighterMarkdown;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics,
  SynEditTypes, SynEditHighlighter;

type
  TtkTokenKind = (
    tkNull,
    tkSpace,
    tkText,
    tkHeader,
    tkCodeBlock,
    tkInlineCode,
    tkBlockQuote,
    tkList,
    tkBold,
    tkItalic,
    tkLinkText,
    tkLinkUrl,
    tkRule,
    tkTag,
    tkComment
  );

  TRangeState = (rsUnknown, rsCodeBlock, rsComment);

  { TSynMarkdownSyn }

  TSynMarkdownSyn = class(TSynCustomHighlighter)
  private
    fRange: TRangeState;
    fLine: PChar;
    fLineNumber: Integer;
    Run: LongInt;
    fTokenPos: Integer;
    FTokenID: TtkTokenKind;

    fHeaderAttri: TSynHighlighterAttributes;
    fCodeBlockAttri: TSynHighlighterAttributes;
    fInlineCodeAttri: TSynHighlighterAttributes;
    fBlockQuoteAttri: TSynHighlighterAttributes;
    fListAttri: TSynHighlighterAttributes;
    fBoldAttri: TSynHighlighterAttributes;
    fItalicAttri: TSynHighlighterAttributes;
    fLinkTextAttri: TSynHighlighterAttributes;
    fLinkUrlAttri: TSynHighlighterAttributes;
    fRuleAttri: TSynHighlighterAttributes;
    fTagAttri: TSynHighlighterAttributes;
    fCommentAttri: TSynHighlighterAttributes;
    fTextAttri: TSynHighlighterAttributes;
    fSpaceAttri: TSynHighlighterAttributes;

    function IsLineStart(APos: Integer): Boolean;
    function IsHorizontalRule: Boolean;
    procedure ScanWhitespace;
    procedure ScanHeader;
    procedure ScanInlineCode;
    procedure ScanBlockQuote;
    procedure ScanList;
    procedure ScanBoldOrItalic;
    procedure ScanLink;
    procedure ScanTagOrComment;
    procedure ScanText;
  protected
    function GetIdentChars: TSynIdentChars; override;
    function GetSampleSource: string; override;
  public
    class function GetLanguageName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes; override;
    function GetEol: Boolean; override;
    function GetRange: Pointer; override;
    procedure SetRange(Value: Pointer); override;
    procedure ResetRange; override;
    function GetToken: string; override;
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: integer); override;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: integer; override;
    function GetTokenPos: Integer; override;
    function GetTokenID: TtkTokenKind;
    procedure SetLine(const NewValue: string; LineNumber: Integer); override;
    procedure Next; override;
  published
    property HeaderAttri: TSynHighlighterAttributes read fHeaderAttri write fHeaderAttri;
    property CodeBlockAttri: TSynHighlighterAttributes read fCodeBlockAttri write fCodeBlockAttri;
    property InlineCodeAttri: TSynHighlighterAttributes read fInlineCodeAttri write fInlineCodeAttri;
    property BlockQuoteAttri: TSynHighlighterAttributes read fBlockQuoteAttri write fBlockQuoteAttri;
    property ListAttri: TSynHighlighterAttributes read fListAttri write fListAttri;
    property BoldAttri: TSynHighlighterAttributes read fBoldAttri write fBoldAttri;
    property ItalicAttri: TSynHighlighterAttributes read fItalicAttri write fItalicAttri;
    property LinkTextAttri: TSynHighlighterAttributes read fLinkTextAttri write fLinkTextAttri;
    property LinkUrlAttri: TSynHighlighterAttributes read fLinkUrlAttri write fLinkUrlAttri;
    property RuleAttri: TSynHighlighterAttributes read fRuleAttri write fRuleAttri;
    property TagAttri: TSynHighlighterAttributes read fTagAttri write fTagAttri;
    property CommentAttri: TSynHighlighterAttributes read fCommentAttri write fCommentAttri;
    property TextAttri: TSynHighlighterAttributes read fTextAttri write fTextAttri;
    property SpaceAttri: TSynHighlighterAttributes read fSpaceAttri write fSpaceAttri;
  end;

implementation

{ TSynMarkdownSyn }

constructor TSynMarkdownSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  fHeaderAttri := TSynHighlighterAttributes.Create('Header');
  fHeaderAttri.Style := [fsBold];
  fHeaderAttri.Foreground := $00569CD6;
  AddAttribute(fHeaderAttri);

  fCodeBlockAttri := TSynHighlighterAttributes.Create('CodeBlock');
  fCodeBlockAttri.Foreground := $00CE9178;
  AddAttribute(fCodeBlockAttri);

  fInlineCodeAttri := TSynHighlighterAttributes.Create('InlineCode');
  fInlineCodeAttri.Foreground := $00CE9178;
  AddAttribute(fInlineCodeAttri);

  fBlockQuoteAttri := TSynHighlighterAttributes.Create('BlockQuote');
  fBlockQuoteAttri.Style := [fsItalic];
  fBlockQuoteAttri.Foreground := $00A0A0A0;
  AddAttribute(fBlockQuoteAttri);

  fListAttri := TSynHighlighterAttributes.Create('List');
  fListAttri.Style := [fsBold];
  fListAttri.Foreground := $0050D0FF;
  AddAttribute(fListAttri);

  fBoldAttri := TSynHighlighterAttributes.Create('Bold');
  fBoldAttri.Style := [fsBold];
  fBoldAttri.Foreground := $00FFFFFF;
  AddAttribute(fBoldAttri);

  fItalicAttri := TSynHighlighterAttributes.Create('Italic');
  fItalicAttri.Style := [fsItalic];
  fItalicAttri.Foreground := $00E0E0E0;
  AddAttribute(fItalicAttri);

  fLinkTextAttri := TSynHighlighterAttributes.Create('LinkText');
  fLinkTextAttri.Style := [fsUnderline];
  fLinkTextAttri.Foreground := $004EC9B0;
  AddAttribute(fLinkTextAttri);

  fLinkUrlAttri := TSynHighlighterAttributes.Create('LinkUrl');
  fLinkUrlAttri.Foreground := $00808080;
  AddAttribute(fLinkUrlAttri);

  fRuleAttri := TSynHighlighterAttributes.Create('Rule');
  fRuleAttri.Foreground := $0068AA68;
  AddAttribute(fRuleAttri);

  fTagAttri := TSynHighlighterAttributes.Create('Tag');
  fTagAttri.Foreground := $00569CD6;
  AddAttribute(fTagAttri);

  fCommentAttri := TSynHighlighterAttributes.Create('Comment');
  fCommentAttri.Style := [fsItalic];
  fCommentAttri.Foreground := $0068AA68;
  AddAttribute(fCommentAttri);

  fTextAttri := TSynHighlighterAttributes.Create('Text');
  fTextAttri.Foreground := $00D4D4D4;
  AddAttribute(fTextAttri);

  fSpaceAttri := TSynHighlighterAttributes.Create('Space');
  AddAttribute(fSpaceAttri);

  SetAttributesOnChange(@DefHighlightChange);
  fDefaultFilter := 'Markdown Files (*.md;*.markdown)|*.md;*.markdown';
  fRange := rsUnknown;
end;

destructor TSynMarkdownSyn.Destroy;
begin
  inherited Destroy;
end;

class function TSynMarkdownSyn.GetLanguageName: string;
begin
  Result := 'Markdown';
end;

function TSynMarkdownSyn.GetIdentChars: TSynIdentChars;
begin
  Result := ['a'..'z', 'A'..'Z', '0'..'9', '_'];
end;

function TSynMarkdownSyn.GetSampleSource: string;
begin
  Result := '# Markdown Document' + sLineBreak +
            '> A blockquote example' + sLineBreak +
            '- List item 1' + sLineBreak +
            '- **Bold** and *Italic*' + sLineBreak +
            '`inline code`' + sLineBreak +
            '```' + sLineBreak +
            'Code block' + sLineBreak +
            '```' + sLineBreak +
            '[Ace Utils](https://github.com/TwilightSurfers/AceUtitlies)';
end;

function TSynMarkdownSyn.GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_KEYWORD: Result := fHeaderAttri;
    SYN_ATTR_STRING: Result := fInlineCodeAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    else Result := fTextAttri;
  end;
end;

function TSynMarkdownSyn.GetEol: Boolean;
begin
  Result := (fLine = nil) or (fLine[Run] = #0);
end;

function TSynMarkdownSyn.GetRange: Pointer;
begin
  Result := Pointer(PtrInt(fRange));
end;

procedure TSynMarkdownSyn.SetRange(Value: Pointer);
begin
  fRange := TRangeState(PtrUInt(Value));
end;

procedure TSynMarkdownSyn.ResetRange;
begin
  fRange := rsUnknown;
end;

function TSynMarkdownSyn.GetToken: string;
var
  Len: LongInt;
begin
  Len := Run - fTokenPos;
  if (fLine <> nil) and (Len > 0) then
    SetString(Result, (fLine + fTokenPos), Len)
  else
    Result := '';
end;

procedure TSynMarkdownSyn.GetTokenEx(out TokenStart: PChar; out TokenLength: integer);
begin
  TokenLength := Run - fTokenPos;
  TokenStart := fLine + fTokenPos;
end;

function TSynMarkdownSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case FTokenID of
    tkHeader: Result := fHeaderAttri;
    tkCodeBlock: Result := fCodeBlockAttri;
    tkInlineCode: Result := fInlineCodeAttri;
    tkBlockQuote: Result := fBlockQuoteAttri;
    tkList: Result := fListAttri;
    tkBold: Result := fBoldAttri;
    tkItalic: Result := fItalicAttri;
    tkLinkText: Result := fLinkTextAttri;
    tkLinkUrl: Result := fLinkUrlAttri;
    tkRule: Result := fRuleAttri;
    tkTag: Result := fTagAttri;
    tkComment: Result := fCommentAttri;
    tkSpace: Result := fSpaceAttri;
    else Result := fTextAttri;
  end;
end;

function TSynMarkdownSyn.GetTokenKind: integer;
begin
  Result := Ord(FTokenID);
end;

function TSynMarkdownSyn.GetTokenPos: Integer;
begin
  Result := fTokenPos;
end;

function TSynMarkdownSyn.GetTokenID: TtkTokenKind;
begin
  Result := FTokenID;
end;

procedure TSynMarkdownSyn.SetLine(const NewValue: string; LineNumber: Integer);
begin
  inherited;
  fLine := PChar(NewValue);
  Run := 0;
  fLineNumber := LineNumber;
  Next;
end;

function TSynMarkdownSyn.IsLineStart(APos: Integer): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to APos - 1 do
    if not (fLine[i] in [' ', #9]) then
      Exit(False);
end;

function TSynMarkdownSyn.IsHorizontalRule: Boolean;
var
  i, Count: Integer;
  Ch: Char;
begin
  Result := False;
  Ch := fLine[Run];
  if not (Ch in ['-', '*', '_']) then Exit;
  Count := 0;
  i := Run;
  while not (fLine[i] in [#0, #10, #13]) do
  begin
    if fLine[i] = Ch then
      Inc(Count)
    else if not (fLine[i] in [' ', #9]) then
      Exit(False);
    Inc(i);
  end;
  Result := (Count >= 3);
end;

procedure TSynMarkdownSyn.ScanWhitespace;
begin
  while fLine[Run] in [#1..#32] do
    Inc(Run);
  FTokenID := tkSpace;
end;

procedure TSynMarkdownSyn.ScanHeader;
var
  Count: Integer;
begin
  Count := 0;
  while (fLine[Run + Count] = '#') and (Count < 6) do
    Inc(Count);

  if (fLine[Run + Count] in [' ', #9, #0, #10, #13]) then
  begin
    while not (fLine[Run] in [#0, #10, #13]) do Inc(Run);
    FTokenID := tkHeader;
  end
  else
    ScanText;
end;

procedure TSynMarkdownSyn.ScanBlockQuote;
begin
  Inc(Run);
  while not (fLine[Run] in [#0, #10, #13]) do Inc(Run);
  FTokenID := tkBlockQuote;
end;

procedure TSynMarkdownSyn.ScanList;
begin
  if fLine[Run] in ['-', '*', '+'] then
  begin
    Inc(Run);
    if fLine[Run] in [' ', #9] then Inc(Run);
  end
  else
  begin
    while fLine[Run] in ['0'..'9'] do Inc(Run);
    if fLine[Run] in ['.', ')'] then Inc(Run);
    if fLine[Run] in [' ', #9] then Inc(Run);
  end;
  FTokenID := tkList;
end;

procedure TSynMarkdownSyn.ScanInlineCode;
begin
  Inc(Run);
  while not (fLine[Run] in [#0, '`', #10, #13]) do Inc(Run);
  if fLine[Run] = '`' then Inc(Run);
  FTokenID := tkInlineCode;
end;

procedure TSynMarkdownSyn.ScanBoldOrItalic;
var
  Ch: Char;
begin
  Ch := fLine[Run];
  if (fLine[Run + 1] = Ch) then
  begin
    // Bold: **...** or __...__
    Inc(Run, 2);
    while (fLine[Run] <> #0) and not (fLine[Run] in [#10, #13]) do
    begin
      if (fLine[Run] = Ch) and (fLine[Run + 1] = Ch) then
      begin
        Inc(Run, 2);
        Break;
      end;
      Inc(Run);
    end;
    FTokenID := tkBold;
  end
  else
  begin
    // Italic: *...* or _..._
    Inc(Run);
    while (fLine[Run] <> #0) and not (fLine[Run] in [#10, #13]) do
    begin
      if (fLine[Run] = Ch) then
      begin
        Inc(Run);
        Break;
      end;
      Inc(Run);
    end;
    FTokenID := tkItalic;
  end;
end;

procedure TSynMarkdownSyn.ScanLink;
begin
  if fLine[Run] = '!' then Inc(Run);
  if fLine[Run] = '[' then Inc(Run);
  while not (fLine[Run] in [#0, ']', #10, #13]) do Inc(Run);
  if fLine[Run] = ']' then Inc(Run);
  FTokenID := tkLinkText;
end;

procedure TSynMarkdownSyn.ScanTagOrComment;
begin
  Inc(Run);
  while not (fLine[Run] in [#0, '>', #10, #13]) do Inc(Run);
  if fLine[Run] = '>' then Inc(Run);
  FTokenID := tkTag;
end;

procedure TSynMarkdownSyn.ScanText;
begin
  while not (fLine[Run] in [#0..#32, '`', '*', '_', '[', '!', '<', '>', '#', '-', '+', '~']) do
    Inc(Run);
  FTokenID := tkText;
end;

procedure TSynMarkdownSyn.Next;
begin
  fTokenPos := Run;
  if (fLine = nil) or (fLine[Run] = #0) then
  begin
    FTokenID := tkNull;
    Exit;
  end;

  // 1. Inside multi-line code block?
  if fRange = rsCodeBlock then
  begin
    if (fLine[Run] = '`') and (fLine[Run+1] = '`') and (fLine[Run+2] = '`') then
    begin
      while not (fLine[Run] in [#0, #10, #13]) do Inc(Run);
      fRange := rsUnknown;
      FTokenID := tkCodeBlock;
      Exit;
    end
    else if (fLine[Run] = '~') and (fLine[Run+1] = '~') and (fLine[Run+2] = '~') then
    begin
      while not (fLine[Run] in [#0, #10, #13]) do Inc(Run);
      fRange := rsUnknown;
      FTokenID := tkCodeBlock;
      Exit;
    end
    else
    begin
      while not (fLine[Run] in [#0, #10, #13]) do Inc(Run);
      FTokenID := tkCodeBlock;
      Exit;
    end;
  end;

  // 2. Inside multi-line HTML comment?
  if fRange = rsComment then
  begin
    while (fLine[Run] <> #0) do
    begin
      if (fLine[Run] = '-') and (fLine[Run+1] = '-') and (fLine[Run+2] = '>') then
      begin
        Inc(Run, 3);
        fRange := rsUnknown;
        Break;
      end;
      Inc(Run);
    end;
    FTokenID := tkComment;
    Exit;
  end;

  // 3. Whitespace
  if fLine[Run] in [#1..#32] then
  begin
    ScanWhitespace;
    Exit;
  end;

  // 4. Opening fenced code block
  if IsLineStart(Run) and (((fLine[Run] = '`') and (fLine[Run+1] = '`') and (fLine[Run+2] = '`')) or
                           ((fLine[Run] = '~') and (fLine[Run+1] = '~') and (fLine[Run+2] = '~'))) then
  begin
    while not (fLine[Run] in [#0, #10, #13]) do Inc(Run);
    fRange := rsCodeBlock;
    FTokenID := tkCodeBlock;
    Exit;
  end;

  // 5. HTML comment start <!--
  if (fLine[Run] = '<') and (fLine[Run+1] = '!') and (fLine[Run+2] = '-') and (fLine[Run+3] = '-') then
  begin
    Inc(Run, 4);
    while (fLine[Run] <> #0) do
    begin
      if (fLine[Run] = '-') and (fLine[Run+1] = '-') and (fLine[Run+2] = '>') then
      begin
        Inc(Run, 3);
        fRange := rsUnknown;
        Break;
      end;
      Inc(Run);
    end;
    if fLine[Run] = #0 then
      fRange := rsComment;
    FTokenID := tkComment;
    Exit;
  end;

  // 6. Header # at start of line
  if IsLineStart(Run) and (fLine[Run] = '#') then
  begin
    ScanHeader;
    Exit;
  end;

  // 7. Horizontal rule: ---, ***, ___
  if IsLineStart(Run) and IsHorizontalRule then
  begin
    while not (fLine[Run] in [#0, #10, #13]) do Inc(Run);
    FTokenID := tkRule;
    Exit;
  end;

  // 8. Blockquote > at start of line
  if IsLineStart(Run) and (fLine[Run] = '>') then
  begin
    ScanBlockQuote;
    Exit;
  end;

  // 9. Lists (- , * , + , 1. ) at start of line
  if IsLineStart(Run) and (((fLine[Run] in ['-', '*', '+']) and (fLine[Run+1] = ' ')) or
                           ((fLine[Run] in ['0'..'9']) and (fLine[Run+1] in ['.', ')']) and (fLine[Run+2] = ' '))) then
  begin
    ScanList;
    Exit;
  end;

  // 10. Inline code `code`
  if fLine[Run] = '`' then
  begin
    ScanInlineCode;
    Exit;
  end;

  // 11. Bold (** or __) or Italic (* or _)
  if (fLine[Run] in ['*', '_']) then
  begin
    ScanBoldOrItalic;
    Exit;
  end;

  // 12. Links: [text](url) or ![alt](url)
  if (fLine[Run] = '[') or ((fLine[Run] = '!') and (fLine[Run+1] = '[')) then
  begin
    ScanLink;
    Exit;
  end;

  // Link URL following [text]
  if (fLine[Run] = '(') and (fTokenPos > 0) and (fLine[fTokenPos - 1] = ']') then
  begin
    Inc(Run);
    while not (fLine[Run] in [#0, ')', #10, #13]) do Inc(Run);
    if fLine[Run] = ')' then Inc(Run);
    FTokenID := tkLinkUrl;
    Exit;
  end;

  // 13. HTML tags <tag ...>
  if (fLine[Run] = '<') and (fLine[Run+1] in ['a'..'z', 'A'..'Z', '/']) then
  begin
    ScanTagOrComment;
    Exit;
  end;

  // 14. Regular text
  ScanText;
end;

end.

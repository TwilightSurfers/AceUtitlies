unit TestAcePdf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, fpcunit, testregistry, AcePdf;

type

  TTestPdfFit = class(TTestCase)
  published
    procedure TestFitLandscape;
    procedure TestFitPortrait;
    procedure TestFitDegenerate;
  end;

  TTestPdfium = class(TTestCase)
  private
    FPdfPath: string;
    procedure RequireLibrary;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestLibraryLoads;
    procedure TestPageCountAndSize;
    procedure TestRenderLandscapePage;
    procedure TestRenderPortraitPage;
    procedure TestOutOfRangePageRaises;
    procedure TestInvalidFileRaisesFormatError;
    procedure TestMissingFileRaisesFileError;
    procedure TestOpenDocumentDoesNotLockFile;
  end;

// Builds a valid two-page PDF: page 1 is 200x100pt with a blue box in the
// middle, page 2 is 100x200pt filled solid red.
function BuildTestPdf: string;

implementation

function BuildTestPdf: string;
var
  Objs: array[1..6] of string;
  Offsets: array[1..6] of Integer;
  Content1, Content2, Body, XRef: string;
  i: Integer;
begin
  Content1 := '0 0 1 rg 50 25 100 50 re f';
  Content2 := '1 0 0 rg 0 0 100 200 re f';
  Objs[1] := '<< /Type /Catalog /Pages 2 0 R >>';
  Objs[2] := '<< /Type /Pages /Kids [3 0 R 5 0 R] /Count 2 >>';
  Objs[3] := '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 100] /Contents 4 0 R /Resources << >> >>';
  Objs[4] := Format('<< /Length %d >>'#10'stream'#10'%s'#10'endstream', [Length(Content1), Content1]);
  Objs[5] := '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 100 200] /Contents 6 0 R /Resources << >> >>';
  Objs[6] := Format('<< /Length %d >>'#10'stream'#10'%s'#10'endstream', [Length(Content2), Content2]);

  Body := '%PDF-1.4'#10;
  for i := 1 to 6 do
  begin
    Offsets[i] := Length(Body);
    Body := Body + Format('%d 0 obj'#10'%s'#10'endobj'#10, [i, Objs[i]]);
  end;

  XRef := 'xref'#10'0 7'#10'0000000000 65535 f '#10;
  for i := 1 to 6 do
    XRef := XRef + Format('%.10d 00000 n '#10, [Offsets[i]]);

  Result := Body + XRef +
    'trailer'#10'<< /Size 7 /Root 1 0 R >>'#10 +
    'startxref'#10 + IntToStr(Length(Body)) + #10'%%EOF'#10;
end;

procedure WriteFile(const APath, AData: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(APath, fmCreate);
  try
    if AData <> '' then
      FS.WriteBuffer(AData[1], Length(AData));
  finally
    FS.Free;
  end;
end;

function IsBlue(C: TColor): Boolean;
begin
  C := ColorToRGB(C);
  Result := (Blue(C) > 200) and (Red(C) < 60) and (Green(C) < 60);
end;

function IsRed(C: TColor): Boolean;
begin
  C := ColorToRGB(C);
  Result := (Red(C) > 200) and (Blue(C) < 60) and (Green(C) < 60);
end;

function IsWhite(C: TColor): Boolean;
begin
  C := ColorToRGB(C);
  Result := (Red(C) > 240) and (Green(C) > 240) and (Blue(C) > 240);
end;

{ TTestPdfFit }

procedure TTestPdfFit.TestFitLandscape;
var
  W, H: Integer;
begin
  FitPageToBox(200, 100, 400, 400, W, H);
  AssertEquals(400, W);
  AssertEquals(200, H);
end;

procedure TTestPdfFit.TestFitPortrait;
var
  W, H: Integer;
begin
  FitPageToBox(612, 792, 500, 500, W, H);
  AssertEquals(386, W);
  AssertEquals(500, H);
end;

procedure TTestPdfFit.TestFitDegenerate;
var
  W, H: Integer;
begin
  FitPageToBox(0, 100, 300, 200, W, H);
  AssertEquals(300, W);
  AssertEquals(200, H);
  FitPageToBox(100, 100, 0, -5, W, H);
  AssertEquals(1, W);
  AssertEquals(1, H);
end;

{ TTestPdfium }

procedure TTestPdfium.RequireLibrary;
begin
  if not PdfiumAvailable then
    Fail(PdfiumLibraryName + ' could not be loaded. Run tests\run-tests.ps1 (it copies the library next to the test executable).');
end;

procedure TTestPdfium.SetUp;
begin
  FPdfPath := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    Format('ace_pdf_test_%d_%d.pdf', [GetProcessID, Random(MaxInt)]);
  WriteFile(FPdfPath, BuildTestPdf);
end;

procedure TTestPdfium.TearDown;
begin
  if FileExists(FPdfPath) then
    DeleteFile(FPdfPath);
end;

procedure TTestPdfium.TestLibraryLoads;
begin
  RequireLibrary;
  AssertTrue(PdfiumAvailable);
end;

procedure TTestPdfium.TestPageCountAndSize;
var
  Doc: TPdfDocument;
  W, H: Double;
begin
  RequireLibrary;
  Doc := TPdfDocument.Create(FPdfPath);
  try
    AssertEquals(2, Doc.PageCount);
    Doc.GetPageSize(0, W, H);
    AssertEquals(200.0, W, 0.01);
    AssertEquals(100.0, H, 0.01);
    Doc.GetPageSize(1, W, H);
    AssertEquals(100.0, W, 0.01);
    AssertEquals(200.0, H, 0.01);
  finally
    Doc.Free;
  end;
end;

procedure TTestPdfium.TestRenderLandscapePage;
var
  Doc: TPdfDocument;
  Bmp: TBitmap;
begin
  RequireLibrary;
  Doc := TPdfDocument.Create(FPdfPath);
  Bmp := TBitmap.Create;
  try
    Doc.RenderPage(0, Bmp, 400, 400);
    AssertEquals('width', 400, Bmp.Width);
    AssertEquals('height', 200, Bmp.Height);
    AssertTrue('centre should be blue', IsBlue(Bmp.Canvas.Pixels[200, 100]));
    AssertTrue('corner should be white', IsWhite(Bmp.Canvas.Pixels[5, 5]));
    AssertTrue('right edge should be white', IsWhite(Bmp.Canvas.Pixels[395, 100]));
  finally
    Bmp.Free;
    Doc.Free;
  end;
end;

procedure TTestPdfium.TestRenderPortraitPage;
var
  Doc: TPdfDocument;
  Bmp: TBitmap;
begin
  RequireLibrary;
  Doc := TPdfDocument.Create(FPdfPath);
  Bmp := TBitmap.Create;
  try
    Doc.RenderPage(1, Bmp, 400, 400);
    AssertEquals('width', 200, Bmp.Width);
    AssertEquals('height', 400, Bmp.Height);
    AssertTrue('page should be red', IsRed(Bmp.Canvas.Pixels[100, 200]));
    AssertTrue('page corner should be red', IsRed(Bmp.Canvas.Pixels[2, 2]));
  finally
    Bmp.Free;
    Doc.Free;
  end;
end;

procedure TTestPdfium.TestOutOfRangePageRaises;
var
  Doc: TPdfDocument;
  Bmp: TBitmap;
  Raised: Boolean;
begin
  RequireLibrary;
  Doc := TPdfDocument.Create(FPdfPath);
  Bmp := TBitmap.Create;
  try
    Raised := False;
    try
      Doc.RenderPage(5, Bmp, 100, 100);
    except
      on E: EPdfError do
      begin
        Raised := True;
        AssertEquals(PDF_ERR_PAGE, E.ErrorCode);
      end;
    end;
    AssertTrue('EPdfError expected', Raised);
  finally
    Bmp.Free;
    Doc.Free;
  end;
end;

procedure TTestPdfium.TestInvalidFileRaisesFormatError;
var
  BadPath: string;
  Raised: Boolean;
begin
  RequireLibrary;
  BadPath := ChangeFileExt(FPdfPath, '.bad.pdf');
  WriteFile(BadPath, 'this is definitely not a pdf document');
  try
    Raised := False;
    try
      TPdfDocument.Create(BadPath).Free;
    except
      on E: EPdfError do
      begin
        Raised := True;
        AssertEquals(PDF_ERR_FORMAT, E.ErrorCode);
      end;
    end;
    AssertTrue('EPdfError expected', Raised);
  finally
    DeleteFile(BadPath);
  end;
end;

procedure TTestPdfium.TestMissingFileRaisesFileError;
var
  Raised: Boolean;
begin
  RequireLibrary;
  Raised := False;
  try
    TPdfDocument.Create(FPdfPath + '.missing').Free;
  except
    on E: EPdfError do
    begin
      Raised := True;
      AssertEquals(PDF_ERR_FILE, E.ErrorCode);
    end;
  end;
  AssertTrue('EPdfError expected', Raised);
end;

procedure TTestPdfium.TestOpenDocumentDoesNotLockFile;
var
  Doc: TPdfDocument;
  Bmp: TBitmap;
begin
  RequireLibrary;
  Doc := TPdfDocument.Create(FPdfPath);
  Bmp := TBitmap.Create;
  try
    // The Explorer must be able to delete / rename a file that is being previewed
    AssertTrue('file should be deletable while the document is open', DeleteFile(FPdfPath));
    Doc.RenderPage(0, Bmp, 100, 100);
    AssertEquals(100, Bmp.Width);
  finally
    Bmp.Free;
    Doc.Free;
  end;
end;

initialization
  Randomize;
  RegisterTest(TTestPdfFit);
  RegisterTest(TTestPdfium);
end.

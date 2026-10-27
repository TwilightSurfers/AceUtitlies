unit AcePdf;

{ ----------------------------------------------------------------------------
  Ace's Utilities - PDF page rendering.

  Primary engine: PDFium (BSD-licensed, the engine used by Chrome), loaded
  dynamically from pdfium.dll (Windows) / libpdfium.so (Linux) next to the
  executable. Nothing is linked statically, so the program still starts and
  works when the library is missing; PdfiumAvailable simply returns False and
  callers fall back to LoadShellThumbnail (Windows) or the file info card.

  Documents are read fully into memory and opened with FPDF_LoadMemDocument,
  so PDFium never holds an OS file handle: previewed files can still be
  renamed, edited, or sent to the Recycle Bin from The Real Explorer.
  ---------------------------------------------------------------------------- }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

const
  PDF_ERR_SUCCESS  = 0;
  PDF_ERR_UNKNOWN  = 1;
  PDF_ERR_FILE     = 2;
  PDF_ERR_FORMAT   = 3;
  PDF_ERR_PASSWORD = 4;
  PDF_ERR_SECURITY = 5;
  PDF_ERR_PAGE     = 6;

  // Refuse to load absurdly large files into memory for a preview
  PDF_MAX_PREVIEW_BYTES = 512 * 1024 * 1024;

type
  EPdfError = class(Exception)
  private
    FErrorCode: Integer;
  public
    constructor CreateCode(ACode: Integer; const AMsg: string);
    property ErrorCode: Integer read FErrorCode;
  end;

  { TPdfDocument }

  TPdfDocument = class
  private
    FHandle: Pointer;
    FData: TMemoryStream;
    FPageCount: Integer;
    FFileName: string;
  public
    // Raises EPdfError if PDFium is unavailable or the document cannot be opened
    constructor Create(const AFileName: string; const APassword: string = '');
    destructor Destroy; override;

    // Page size in PDF points (1/72 inch)
    procedure GetPageSize(AIndex: Integer; out AWidth, AHeight: Double);

    // Renders page AIndex scaled to fit inside AMaxWidth x AMaxHeight pixels
    // (aspect ratio preserved) onto a white background.
    procedure RenderPage(AIndex: Integer; ABitmap: TBitmap; AMaxWidth, AMaxHeight: Integer);

    property PageCount: Integer read FPageCount;
    property FileName: string read FFileName;
  end;

function PdfiumAvailable: Boolean;
function PdfiumLibraryName: string;
function PdfErrorMessage(ACode: Integer): string;

// Fits a AWidth x AHeight page into AMaxWidth x AMaxHeight, preserving aspect.
procedure FitPageToBox(AWidth, AHeight: Double; AMaxWidth, AMaxHeight: Integer;
  out APixelWidth, APixelHeight: Integer);

{$IFDEF WINDOWS}
// Windows Shell thumbnail (first page) via IShellItemImageFactory. Only
// succeeds when a thumbnail provider for the file type is installed.
function LoadShellThumbnail(const APath: string; ASize: Integer; ABitmap: Graphics.TBitmap): Boolean;
{$ENDIF}

implementation

uses
  dynlibs, Math, GraphType, IntfGraphics
  {$IFDEF WINDOWS}, Windows, ActiveX{$ENDIF};

const
  {$IFDEF WINDOWS}
  PDFIUM_LIB = 'pdfium.dll';
  {$ELSE}
  {$IFDEF DARWIN}
  PDFIUM_LIB = 'libpdfium.dylib';
  {$ELSE}
  PDFIUM_LIB = 'libpdfium.so';
  {$ENDIF}
  {$ENDIF}

  FPDF_ANNOT    = $01;
  FPDF_LCD_TEXT = $02;

type
  // Calling convention: fpdfview.h only uses __stdcall when FPDFSDK_EXPORTS is
  // defined, which the pdfium-binaries builds do not do; their x86 DLL exports
  // undecorated cdecl symbols. Declaring these stdcall corrupts the stack.
  FS_SIZEF = record
    width: Single;
    height: Single;
  end;

  TFPDF_InitLibrary = procedure; cdecl;
  TFPDF_DestroyLibrary = procedure; cdecl;
  TFPDF_LoadMemDocument = function(data_buf: Pointer; size: Integer; password: PAnsiChar): Pointer; cdecl;
  TFPDF_CloseDocument = procedure(document: Pointer); cdecl;
  TFPDF_GetLastError = function: LongWord; cdecl;
  TFPDF_GetPageCount = function(document: Pointer): Integer; cdecl;
  TFPDF_GetPageSizeByIndexF = function(document: Pointer; page_index: Integer; var size: FS_SIZEF): Integer; cdecl;
  TFPDF_LoadPage = function(document: Pointer; page_index: Integer): Pointer; cdecl;
  TFPDF_ClosePage = procedure(page: Pointer); cdecl;
  TFPDF_RenderPageBitmap = procedure(bitmap, page: Pointer; start_x, start_y, size_x, size_y, rotate, flags: Integer); cdecl;
  TFPDFBitmap_Create = function(width, height, alpha: Integer): Pointer; cdecl;
  TFPDFBitmap_FillRect = function(bitmap: Pointer; left, top, width, height: Integer; color: LongWord): Integer; cdecl;
  TFPDFBitmap_GetBuffer = function(bitmap: Pointer): Pointer; cdecl;
  TFPDFBitmap_GetStride = function(bitmap: Pointer): Integer; cdecl;
  TFPDFBitmap_Destroy = procedure(bitmap: Pointer); cdecl;

var
  LibHandle: TLibHandle = NilHandle;
  LibTried: Boolean = False;
  LibReady: Boolean = False;

  FPDF_InitLibrary: TFPDF_InitLibrary;
  FPDF_DestroyLibrary: TFPDF_DestroyLibrary;
  FPDF_LoadMemDocument: TFPDF_LoadMemDocument;
  FPDF_CloseDocument: TFPDF_CloseDocument;
  FPDF_GetLastError: TFPDF_GetLastError;
  FPDF_GetPageCount: TFPDF_GetPageCount;
  FPDF_GetPageSizeByIndexF: TFPDF_GetPageSizeByIndexF;
  FPDF_LoadPage: TFPDF_LoadPage;
  FPDF_ClosePage: TFPDF_ClosePage;
  FPDF_RenderPageBitmap: TFPDF_RenderPageBitmap;
  FPDFBitmap_Create: TFPDFBitmap_Create;
  FPDFBitmap_FillRect: TFPDFBitmap_FillRect;
  FPDFBitmap_GetBuffer: TFPDFBitmap_GetBuffer;
  FPDFBitmap_GetStride: TFPDFBitmap_GetStride;
  FPDFBitmap_Destroy: TFPDFBitmap_Destroy;

function PdfiumLibraryName: string;
begin
  Result := PDFIUM_LIB;
end;

// FPC unmasks FPU exceptions by default, but C/C++ libraries such as PDFium
// rely on IEEE masked behaviour (NaN/Inf instead of traps). Every call into
// native code is bracketed by these two helpers, otherwise the process dies
// with STATUS_FLOAT_MULTIPLE_TRAPS. Pending flags are cleared before the
// Pascal mask is restored so they cannot fire later in unrelated code.
function EnterNativeCall: TFPUExceptionMask;
begin
  Result := SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
    exOverflow, exUnderflow, exPrecision]);
end;

procedure LeaveNativeCall(const ASaved: TFPUExceptionMask);
begin
  ClearExceptions(False);
  SetExceptionMask(ASaved);
end;

function PdfiumAvailable: Boolean;

  function Bind(const AName: string): Pointer;
  begin
    Result := GetProcedureAddress(LibHandle, AName);
    if Result = nil then
      raise Exception.Create('missing export ' + AName);
  end;

var
  Saved: TFPUExceptionMask;
begin
  if not LibTried then
  begin
    LibTried := True;
    Saved := EnterNativeCall;
    try
      // Prefer the copy shipped next to the executable, then the system search path
      LibHandle := dynlibs.LoadLibrary(ExtractFilePath(ParamStr(0)) + PDFIUM_LIB);
      if LibHandle = NilHandle then
        LibHandle := dynlibs.LoadLibrary(PDFIUM_LIB);
      if LibHandle <> NilHandle then
      begin
        try
          Pointer(FPDF_InitLibrary) := Bind('FPDF_InitLibrary');
          Pointer(FPDF_DestroyLibrary) := Bind('FPDF_DestroyLibrary');
          Pointer(FPDF_LoadMemDocument) := Bind('FPDF_LoadMemDocument');
          Pointer(FPDF_CloseDocument) := Bind('FPDF_CloseDocument');
          Pointer(FPDF_GetLastError) := Bind('FPDF_GetLastError');
          Pointer(FPDF_GetPageCount) := Bind('FPDF_GetPageCount');
          Pointer(FPDF_GetPageSizeByIndexF) := Bind('FPDF_GetPageSizeByIndexF');
          Pointer(FPDF_LoadPage) := Bind('FPDF_LoadPage');
          Pointer(FPDF_ClosePage) := Bind('FPDF_ClosePage');
          Pointer(FPDF_RenderPageBitmap) := Bind('FPDF_RenderPageBitmap');
          Pointer(FPDFBitmap_Create) := Bind('FPDFBitmap_Create');
          Pointer(FPDFBitmap_FillRect) := Bind('FPDFBitmap_FillRect');
          Pointer(FPDFBitmap_GetBuffer) := Bind('FPDFBitmap_GetBuffer');
          Pointer(FPDFBitmap_GetStride) := Bind('FPDFBitmap_GetStride');
          Pointer(FPDFBitmap_Destroy) := Bind('FPDFBitmap_Destroy');
          FPDF_InitLibrary();
          LibReady := True;
        except
          UnloadLibrary(LibHandle);
          LibHandle := NilHandle;
          LibReady := False;
        end;
      end;
    finally
      LeaveNativeCall(Saved);
    end;
  end;
  Result := LibReady;
end;

function PdfErrorMessage(ACode: Integer): string;
begin
  case ACode of
    PDF_ERR_SUCCESS:  Result := 'No error.';
    PDF_ERR_FILE:     Result := 'The file could not be opened or read.';
    PDF_ERR_FORMAT:   Result := 'The file is not a valid PDF document or is corrupted.';
    PDF_ERR_PASSWORD: Result := 'This PDF is password protected.';
    PDF_ERR_SECURITY: Result := 'This PDF uses an unsupported security scheme.';
    PDF_ERR_PAGE:     Result := 'The page could not be found or has a content error.';
    else              Result := 'Unknown PDF error.';
  end;
end;

procedure FitPageToBox(AWidth, AHeight: Double; AMaxWidth, AMaxHeight: Integer;
  out APixelWidth, APixelHeight: Integer);
var
  Scale: Double;
begin
  if (AWidth <= 0) or (AHeight <= 0) or (AMaxWidth <= 0) or (AMaxHeight <= 0) then
  begin
    APixelWidth := Math.Max(AMaxWidth, 1);
    APixelHeight := Math.Max(AMaxHeight, 1);
    Exit;
  end;
  Scale := Math.Min(AMaxWidth / AWidth, AMaxHeight / AHeight);
  APixelWidth := Math.Max(1, Round(AWidth * Scale));
  APixelHeight := Math.Max(1, Round(AHeight * Scale));
end;

{ EPdfError }

constructor EPdfError.CreateCode(ACode: Integer; const AMsg: string);
begin
  inherited Create(AMsg);
  FErrorCode := ACode;
end;

{ TPdfDocument }

constructor TPdfDocument.Create(const AFileName: string; const APassword: string);
var
  FS: TFileStream;
  Code: Integer;
  Saved: TFPUExceptionMask;
begin
  inherited Create;
  FFileName := AFileName;
  if not PdfiumAvailable then
    raise EPdfError.CreateCode(PDF_ERR_UNKNOWN, PdfiumLibraryName + ' is not available.');

  FData := TMemoryStream.Create;
  try
    FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      if FS.Size > PDF_MAX_PREVIEW_BYTES then
        raise EPdfError.CreateCode(PDF_ERR_FILE, 'The PDF is too large to preview.');
      FData.CopyFrom(FS, 0);
    finally
      FS.Free;
    end;
  except
    on E: EPdfError do raise;
    on E: Exception do
      raise EPdfError.CreateCode(PDF_ERR_FILE, PdfErrorMessage(PDF_ERR_FILE) + ' ' + E.Message);
  end;

  Saved := EnterNativeCall;
  try
    FHandle := FPDF_LoadMemDocument(FData.Memory, Integer(FData.Size), PAnsiChar(AnsiString(APassword)));
    if FHandle = nil then
      Code := Integer(FPDF_GetLastError())
    else
      FPageCount := FPDF_GetPageCount(FHandle);
  finally
    LeaveNativeCall(Saved);
  end;
  if FHandle = nil then
    raise EPdfError.CreateCode(Code, PdfErrorMessage(Code));
end;

destructor TPdfDocument.Destroy;
var
  Saved: TFPUExceptionMask;
begin
  if (FHandle <> nil) and LibReady then
  begin
    Saved := EnterNativeCall;
    try
      FPDF_CloseDocument(FHandle);
    finally
      LeaveNativeCall(Saved);
    end;
  end;
  FHandle := nil;
  // The memory buffer must outlive the document handle
  FreeAndNil(FData);
  inherited Destroy;
end;

procedure TPdfDocument.GetPageSize(AIndex: Integer; out AWidth, AHeight: Double);
var
  Sz: FS_SIZEF;
  Ok: Integer;
  Saved: TFPUExceptionMask;
begin
  AWidth := 0;
  AHeight := 0;
  if (AIndex < 0) or (AIndex >= FPageCount) then
    raise EPdfError.CreateCode(PDF_ERR_PAGE, PdfErrorMessage(PDF_ERR_PAGE));
  Sz.width := 0;
  Sz.height := 0;
  Saved := EnterNativeCall;
  try
    Ok := FPDF_GetPageSizeByIndexF(FHandle, AIndex, Sz);
  finally
    LeaveNativeCall(Saved);
  end;
  if Ok = 0 then
    raise EPdfError.CreateCode(PDF_ERR_PAGE, PdfErrorMessage(PDF_ERR_PAGE));
  AWidth := Sz.width;
  AHeight := Sz.height;
end;

procedure TPdfDocument.RenderPage(AIndex: Integer; ABitmap: Graphics.TBitmap; AMaxWidth, AMaxHeight: Integer);
var
  PageW, PageH: Double;
  PixW, PixH, Stride, Y: Integer;
  Page, Bmp: Pointer;
  Src: PByte;
  Img: TLazIntfImage;
  Desc: TRawImageDescription;
  Saved: TFPUExceptionMask;
begin
  GetPageSize(AIndex, PageW, PageH);
  FitPageToBox(PageW, PageH, AMaxWidth, AMaxHeight, PixW, PixH);

  // DataDescription is a record property (returned by value): build it locally
  Desc.Init_BPP32_B8G8R8_BIO_TTB(PixW, PixH);
  Img := TLazIntfImage.Create(0, 0);
  try
    Img.DataDescription := Desc;
    Img.CreateData;

    Saved := EnterNativeCall;
    try
      Page := FPDF_LoadPage(FHandle, AIndex);
      if Page = nil then
        raise EPdfError.CreateCode(PDF_ERR_PAGE, PdfErrorMessage(PDF_ERR_PAGE));
      try
        Bmp := FPDFBitmap_Create(PixW, PixH, 0); // BGRx, 4 bytes per pixel
        if Bmp = nil then
          raise EPdfError.CreateCode(PDF_ERR_UNKNOWN, 'Could not allocate a page bitmap.');
        try
          FPDFBitmap_FillRect(Bmp, 0, 0, PixW, PixH, $FFFFFFFF);
          FPDF_RenderPageBitmap(Bmp, Page, 0, 0, PixW, PixH, 0, FPDF_ANNOT or FPDF_LCD_TEXT);
          Src := FPDFBitmap_GetBuffer(Bmp);
          Stride := FPDFBitmap_GetStride(Bmp);
          // Copy through TLazIntfImage so the byte order is correct on every widgetset
          for Y := 0 to PixH - 1 do
            Move(Src[Y * Stride], Img.GetDataLineStart(Y)^, PixW * 4);
        finally
          FPDFBitmap_Destroy(Bmp);
        end;
      finally
        FPDF_ClosePage(Page);
      end;
    finally
      LeaveNativeCall(Saved);
    end;

    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

{$IFDEF WINDOWS}
type
  IShellItemImageFactory = interface(IUnknown)
    ['{BCC18B79-BA16-442F-80C4-8A59C30C463B}']
    function GetImage(size: TSize; flags: DWORD; out phbm: HBITMAP): HRESULT; stdcall;
  end;

const
  SIIGBF_RESIZETOFIT    = $00;
  SIIGBF_THUMBNAILONLY  = $08;

function SHCreateItemFromParsingName(pszPath: PWideChar; pbc: Pointer;
  const riid: TGUID; out ppv): HRESULT; stdcall; external 'shell32.dll';

function LoadShellThumbnail(const APath: string; ASize: Integer; ABitmap: Graphics.TBitmap): Boolean;
var
  Factory: IShellItemImageFactory;
  Sz: TSize;
  HBmp: HBITMAP;
  WPath: UnicodeString;
  InitRes: HRESULT;
  Saved: TFPUExceptionMask;
begin
  Result := False;
  if (APath = '') or (ABitmap = nil) then Exit;
  Saved := EnterNativeCall;
  InitRes := CoInitialize(nil);
  try
    WPath := UTF8Decode(APath);
    if Failed(SHCreateItemFromParsingName(PWideChar(WPath), nil, IShellItemImageFactory, Factory)) then
      Exit;
    Sz.cx := ASize;
    Sz.cy := ASize;
    HBmp := 0;
    if Succeeded(Factory.GetImage(Sz, SIIGBF_RESIZETOFIT or SIIGBF_THUMBNAILONLY, HBmp)) and (HBmp <> 0) then
    begin
      ABitmap.Handle := HBmp; // TBitmap takes ownership of the GDI handle
      Result := True;
    end;
    Factory := nil;
  finally
    if Succeeded(InitRes) then
      CoUninitialize;
    LeaveNativeCall(Saved);
  end;
end;
{$ENDIF}

finalization
  if LibReady then
  begin
    EnterNativeCall;
    FPDF_DestroyLibrary();
  end;
  if LibHandle <> NilHandle then
    UnloadLibrary(LibHandle);
end.

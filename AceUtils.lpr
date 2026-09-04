program AceUtils;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, MainForm, PreviewForm;

{$R *.res}

{$IFDEF WINDOWS}
const
  ASFW_ANY = DWORD(-1);
function AllowSetForegroundWindow(dwProcessId: DWORD): BOOL; stdcall; external 'user32.dll';

var
  hMutex: THandle;
  hPrevWnd: HWND;
  WMRestore: UINT;
{$ENDIF}

begin
{$IFDEF WINDOWS}
  // Single Instance Guard: Allow only one instance of Ace's Utilities to run
  hMutex := CreateMutex(nil, True, 'AceUtils_SingleInstance_Mutex');
  if (hMutex = 0) or (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    if hMutex <> 0 then
      CloseHandle(hMutex);

    AllowSetForegroundWindow(ASFW_ANY);
    WMRestore := RegisterWindowMessage('AceUtils_Restore_SingleInstance');
    hPrevWnd := FindWindow(nil, 'Ace''s Utilities');
    if hPrevWnd <> 0 then
    begin
      // Send restore message to wake up and unhide from system tray
      PostMessage(hPrevWnd, WMRestore, 0, 0);
      ShowWindow(hPrevWnd, SW_RESTORE);
      SetForegroundWindow(hPrevWnd);
      BringWindowToTop(hPrevWnd);
    end;
    // Broadcast to ensure all top-level windows of the instance receive the restore signal
    PostMessage(HWND_BROADCAST, WMRestore, 0, 0);

    // Terminate the duplicate instance immediately
    Exit;
  end;
{$ENDIF}

  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmPreview, frmPreview);
  Application.Run;

{$IFDEF WINDOWS}
  if hMutex <> 0 then
    CloseHandle(hMutex);
{$ENDIF}
end.

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
var
  hMutex: THandle;
  hPrevWnd: HWND;
  WMRestore: UINT;
  FWI: FLASHWINFO;
{$ENDIF}

begin
{$IFDEF WINDOWS}
  // Single Instance Guard: Allow only one instance of Ace's Utilities to run
  hMutex := CreateMutex(nil, True, 'AceUtils_SingleInstance_Mutex');
  if (hMutex = 0) or (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    if hMutex <> 0 then
      CloseHandle(hMutex);

    WMRestore := RegisterWindowMessage('AceUtils_Restore_SingleInstance');
    hPrevWnd := FindWindow(nil, 'Ace''s Utilities');
    if hPrevWnd <> 0 then
    begin
      // Send restore message to wake up and unhide from system tray
      PostMessage(hPrevWnd, WMRestore, 0, 0);
      ShowWindow(hPrevWnd, SW_RESTORE);
      SetForegroundWindow(hPrevWnd);

      // Flash window title bar to alert user
      FillChar(FWI, SizeOf(FWI), 0);
      FWI.cbSize := SizeOf(FWI);
      FWI.hwnd := hPrevWnd;
      FWI.dwFlags := FLASHW_ALL or FLASHW_TIMERNOFG;
      FWI.uCount := 4;
      FlashWindowEx(@FWI);
    end
    else
    begin
      // Broadcast if handle not resolved by exact caption
      PostMessage(HWND_BROADCAST, WMRestore, 0, 0);
    end;

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

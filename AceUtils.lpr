program AceUtils;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  SysUtils, Interfaces, Forms, MainForm, PreviewForm;

{$R *.res}

{$IFDEF WINDOWS}
const
  ASFW_ANY = DWORD(-1);
  ACE_IPC_MAGIC = $41434531; // 'ACE1'
  ACE_WINDOW_PROP = 'AceUtils_MainWindow';

function AllowSetForegroundWindow(dwProcessId: DWORD): BOOL; stdcall; external 'user32.dll';

type
  PFindWindowRec = ^TFindWindowRec;
  TFindWindowRec = record
    FoundWnd: HWND;
    CurrentPid: DWORD;
  end;

function EnumFindAceWindowProc(hWnd: HWND; lParam: LPARAM): BOOL; stdcall;
var
  P: PFindWindowRec;
  WndPid: DWORD;
  Buf: array[0..255] of Char;
begin
  P := PFindWindowRec(lParam);
  WndPid := 0;
  GetWindowThreadProcessId(hWnd, @WndPid);
  if (P^.CurrentPid <> 0) and (WndPid = P^.CurrentPid) then
  begin
    Result := True;
    Exit;
  end;

  // Primary check: unique window property set on frmMain
  if GetProp(hWnd, PChar(ACE_WINDOW_PROP)) <> 0 then
  begin
    P^.FoundWnd := hWnd;
    Result := False; // Found target; stop enumerating
    Exit;
  end;

  // Secondary fallback: window text matches and has children (filters out Application.Handle)
  if GetWindowText(hWnd, Buf, Length(Buf)) > 0 then
  begin
    if ((StrComp(Buf, 'Ace''s Utilities') = 0) or (StrLComp(Buf, 'Ace''s Utilities', 15) = 0)) and
       (GetWindow(hWnd, GW_CHILD) <> 0) then
    begin
      P^.FoundWnd := hWnd;
      Result := False; // Found target; stop enumerating
      Exit;
    end;
  end;

  Result := True;
end;

function FindAceMainWindow: HWND;
var
  Rec: TFindWindowRec;
begin
  Rec.FoundWnd := 0;
  Rec.CurrentPid := GetCurrentProcessId;
  EnumWindows(@EnumFindAceWindowProc, LPARAM(@Rec));
  if Rec.FoundWnd = 0 then
    Rec.FoundWnd := FindWindow(nil, 'Ace''s Utilities');
  Result := Rec.FoundWnd;
end;

var
  hMutex: THandle;
  hPrevWnd: HWND;
  WMRestore: UINT;
  i: Integer;
  CleanArg: string;
  CDS: TCopyDataStruct;
  SendRes: DWORD_PTR;
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
    hPrevWnd := FindAceMainWindow;

    if hPrevWnd <> 0 then
    begin
      // Transfer command-line parameters (files or switches) to the running instance via WM_COPYDATA
      if ParamCount >= 1 then
      begin
        for i := 1 to ParamCount do
        begin
          CleanArg := Trim(ParamStr(i));
          while (Length(CleanArg) > 0) and (CleanArg[1] in ['"', '''']) do
            Delete(CleanArg, 1, 1);
          while (Length(CleanArg) > 0) and (CleanArg[Length(CleanArg)] in ['"', '''']) do
            Delete(CleanArg, Length(CleanArg), 1);
          CleanArg := Trim(CleanArg);

          if CleanArg <> '' then
          begin
            if (CleanArg[1] <> '/') and (CleanArg[1] <> '-') then
              CleanArg := ExpandFileName(CleanArg);

            FillChar(CDS, SizeOf(CDS), 0);
            CDS.dwData := ACE_IPC_MAGIC;
            CDS.cbData := (Length(CleanArg) + 1) * SizeOf(Char);
            CDS.lpData := PChar(CleanArg);
            SendRes := 0;
            SendMessageTimeout(hPrevWnd, WM_COPYDATA, 0, LPARAM(@CDS),
              SMTO_ABORTIFHUNG or SMTO_NORMAL, 5000, @SendRes);
          end;
        end;
      end
      else
      begin
        // No parameters: wake up and restore the window
        PostMessage(hPrevWnd, WMRestore, 0, 0);
      end;

      ShowWindow(hPrevWnd, SW_RESTORE);
      SetForegroundWindow(hPrevWnd);
      BringWindowToTop(hPrevWnd);
    end
    else
    begin
      // Broadcast fallback
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

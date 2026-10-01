# AGENTS.md - Developer & Agent Guide: Preventing UI Hangs in Ace's Utilities

This document records the architectural constraints, critical bug patterns, and hard-earned lessons learned while maintaining and developing **Ace's Utilities** (Free Pascal / Lazarus LCL). 

Any AI agent or developer working on this codebase **must read and follow these rules** to prevent UI freezes, thread lockups, and event recursion.

---

## 1. Custom SynEdit Highlighters (`SynHighlighterMarkdown.pas`, etc.)

### The `GetEol` Contract (CRITICAL)
In Lazarus SynEdit, custom highlighters have an exact contract that MUST NOT be violated:
```pascal
function TSynCustomHighlighter.GetEol: Boolean;
begin
  Result := (FTokenID = tkNull);
end;
```
- **Never** implement `GetEol` as `(fLine = nil) or (fLine[Run] = #0)`.
- **Why this causes a 100% CPU freeze**:
  When scanning the final token of a line (e.g. `@LBuckingham` or `end;`), the highlighter's internal `Run` index reaches `#0` (the line null terminator), but `FTokenID` is still set to the valid token kind (e.g. `tkText` or `tkIdentifier`).
  If `GetEol` checks `fLine[Run] = #0`, it prematurely reports `True` before SynEdit consumes the token.
  When `TLazSynEditLineWrapPlugin` or SynEdit line layout runs during window painting (`Application.ProcessMessages` / `WM_PAINT`), the wrap engine's token consumption loop fails its termination invariant and enters an **infinite loop**, locking the UI thread at 100% of a core.

### Absolute Token Advancement Invariant
A highlighter's `Next` method must strictly advance `Run` on every step until the end of the line:
1. Separate parsing logic into `NextInternal`.
2. Wrap `Next` with an absolute safety guard:
```pascal
procedure TSynMarkdownSyn.Next;
begin
  fTokenPos := Run;
  if (fLine = nil) or (fLine[Run] = #0) then
  begin
    FTokenID := tkNull;
    Exit;
  end;

  NextInternal;

  // ABSOLUTE SAFETY GUARANTEE:
  // Run MUST advance past fTokenPos on every call unless at end-of-line (#0).
  if (Run <= fTokenPos) and (fLine <> nil) and (fLine[Run] <> #0) then
  begin
    Inc(Run);
    FTokenID := tkText;
  end;
end;
```
This guarantees mathematical termination regardless of unexpected characters, hyphens, Unicode sequences, or unclosed inline markup.

---

## 2. Keystroke Routing & Menu Shortcuts (`MainForm.lfm`)

### Do Not Assign Global Shortcuts to Context Menu Items
- **The Issue**: In Lazarus LCL, popup menu (`TPopupMenu`) items with assigned `ShortCut` properties (e.g. `ShortCut = 16470` for `Ctrl+V`, `ShortCut = 16451` for `Ctrl+C`) register as **form-global shortcuts** by default.
- **The Symptom**: When a user clicks an edit box like `edtExpPath` (Explorer address bar) or `edtSearchPath` and presses `Ctrl+V`, the LCL form-level shortcut handler intercepts the key and routes it to `popNotepad.miPasteClick`, pasting text into `SynEdit1` in the background and leaving the active edit control frozen or untouched.
- **The Rule**: Keep standard clipboard shortcuts (`Ctrl+C`, `Ctrl+V`, `Ctrl+X`) unassigned on popup menus. Both native edit controls (`TEdit`, `TMemo`) and `TSynEdit` handle standard clipboard shortcuts internally through their own window procedures.

---

## 3. Path Input Normalization & Smart Detection (`MainForm.pas`)

### Loop-Based Quote Stripping
Users frequently paste paths copied via Windows Explorer ("Copy as path"), from terminals, or accidentally double-paste (`""C:\path""` or `'C:\path'`).
Always use loop-based trimming rather than a single `Copy(..., 2, Length - 2)` check:
```pascal
CleanPath := Trim(APath);
while (Length(CleanPath) > 0) and (CleanPath[1] in ['"', '''']) do
  Delete(CleanPath, 1, 1);
while (Length(CleanPath) > 0) and (CleanPath[Length(CleanPath)] in ['"', '''']) do
  Delete(CleanPath, Length(CleanPath), 1);
CleanPath := Trim(CleanPath);
```

### File vs. Folder Smart Resolution
When an address bar or folder picker receives a file path:
1. Check `FileExists(CleanPath) and (not DirectoryExists(CleanPath))`.
2. Extract the parent folder with `ExtractFileDir(CleanPath)`.
3. Set the directory view root to the parent folder.
4. Locate the item in the list view, select it, and trigger live preview.
5. Protect against recursive events using a navigation lock flag (`FExpNavigating := True; try ... finally FExpNavigating := False; end;`).

---

## 4. Search Traversal & Instant Cancellation Engine

### Non-Blocking Cancellation Rules
Long file searches must never block the Windows message pump:
- **Periodic Message Pumping**: Call `Application.ProcessMessages` every 50ms or every 32 examined filesystem items. Do not tie message pumping solely to search matches.
- **Immediate Flag & UI State**: When "Stop" is clicked:
  1. Set `FStopSearch := True;` immediately.
  2. Disable `btnStop` immediately to block repeated clicks.
  3. Drain pending mouse/keyboard messages (`while PeekMessage(..., PM_REMOVE) do;`) upon completion to prevent phantom clicks.
- **Zero Allocations in Traversal Loops**: Pre-parse semicolon-delimited search patterns (`*.pas;*.md;*.txt`) once into a `TStringList` prior to entering BFS/DFS traversal. Never allocate or destroy `TStringList` instances inside file enumeration loops.

---

## 5. Lazarus / Free Pascal Build Hygiene

### Stale Root Unit Files (`.ppu` / `.o`)
When building with `lazbuild` or `fpc`:
- The compiler checks the current directory (`.`) before the target unit output directory (`lib/$(TargetCPU)-$(TargetOS)`).
- If stale `.ppu` or `.o` files exist in the project root, FPC will link against the old object code even after source `.pas` files are edited.
- **Rule**: Always clean up root artifacts:
  ```powershell
  Remove-Item -Force .\*.ppu, .\*.o -ErrorAction SilentlyContinue
  ```
- Always build with `-B` (`lazbuild -B AceUtils.lpi`) for clean compilation.

### Executable Synchronization
- Both `AceUtils.exe` and `AceFileSearch.exe` must be kept identical:
  ```powershell
  Copy-Item -Force AceUtils.exe AceFileSearch.exe
  ```

---

## 6. Verification Checklist Before Marking Work Done

Before considering any fix complete:
1. **Pumping Window Messages**: Verify that GUI code paths execute through `Application.ProcessMessages` so that `WM_PAINT`, layout calculation, and line wrapping actually execute.
2. **CPU Verification**: Ensure CPU usage returns to 0% after actions (no runaway thread spinning on a core).
3. **Quoted & Edge-Case Inputs**: Test paths with quotes (`"C:\..."`), double quotes (`""C:\...""`), single quotes, and trailing delimiters.
4. **Git Tree Cleanliness**: Ensure no temporary test executables (`test_*.exe`), crash dumps (`*.dmp`), or stray `.o`/`.ppu` files remain untracked.

---

## 7. Single Instance Enforcement, IPC File Launching & System Tray Wake-up

To prevent duplicate processes, resource contention, and facilitate seamless external file opening (e.g., Windows Explorer "Open with Ace's Utilities" or file associations), Ace's Utilities strictly allows only one instance to run:

### 1. Named Mutex & Process Termination
- **Named Mutex**: `CreateMutex(nil, True, 'AceUtils_SingleInstance_Mutex')` in `AceUtils.lpr` checks for an existing instance before initializing LCL forms.
- **Secondary Instance Handshake**: If `GetLastError = ERROR_ALREADY_EXISTS`, the second process transfers any command-line parameters (files or switches) to the running instance via `WM_COPYDATA`, restores and elevates the primary window, and terminates immediately.

### 2. Window Identification & The `Application.Handle` Trap (CRITICAL)
- **The Issue**: In Free Pascal / Lazarus LCL on Windows, `TApplication` creates an invisible top-level helper window (`Application.Handle`) with window class `'Window'` and title `'Ace''s Utilities'` (matching `Application.Title`). `TfrmMain` creates the actual visible form window also with class `'Window'` and title `'Ace''s Utilities'`.
- **The Symptom**: Calling standard `FindWindow(nil, 'Ace''s Utilities')` frequently returns `Application.Handle` instead of `frmMain.Handle`. Because `Application.Handle` has 0 child controls and does not run form message handlers, any messages sent to it (`WM_COPYDATA` or `WM_ACEUTILS_RESTORE`) are ignored, causing secondary launches to do nothing.
- **The Rule**:
  1. Set a unique window property on `frmMain` in `FormCreate`:
     ```pascal
     SetProp(Handle, PChar(ACE_WINDOW_PROP), 1);
     ```
     and clean it up in `FormDestroy`:
     ```pascal
     RemoveProp(Handle, PChar(ACE_WINDOW_PROP));
     ```
  2. In `AceUtils.lpr`, use `EnumWindows` (`FindAceMainWindow`) to locate the window whose `GetProp(hWnd, 'AceUtils_MainWindow') <> 0`. Fall back to checking title and verifying child windows (`GetWindow(hWnd, GW_CHILD) <> 0`) to guarantee `frmMain` is accurately targeted.

### 3. Lazarus LCL Win32 `WM_COPYDATA` Dropping Trap & Subclassing (CRITICAL)
- **The Issue**: In Lazarus LCL's Win32 interface (`win32callback.inc` inside `RealWindowProc`), incoming Win32 messages are mapped to LCL messages (`LM_*`) using a `case Msg of` block. Because `WM_COPYDATA` is **not** present in `case Msg of`, the LCL message structure retains `LMessage.Msg = LM_NULL` (`0`). At line 2620, LCL executes `if Assigned(lWinControl) and (PLMsg^.Msg <> LM_NULL) then DeliverMessage(...)`. Consequently, standard `TForm.WndProc` **never receives `WM_COPYDATA`**—LCL drops it before it ever reaches form code.
- **The Rule**:
  1. Subclass `frmMain.Handle` directly using `SetWindowSubclass` (`comctl32.dll`) in `FormCreate`:
     ```pascal
     SetWindowSubclass(Handle, @MainFormSubclassProc, SUBCLASS_ID_MAINFORM, DWORD_PTR(Self));
     ```
  2. Intercept `WM_COPYDATA` and `WM_ACEUTILS_RESTORE` in `MainFormSubclassProc` directly from Windows, completely bypassing LCL message filtering.
  3. Clean up with `RemoveWindowSubclass(Handle, @MainFormSubclassProc, SUBCLASS_ID_MAINFORM)` in `FormDestroy`.

### 4. Asynchronous Document Dispatch & Re-Entrancy Prevention
- When `MainFormSubclassProc` receives `WM_COPYDATA`:
  1. Immediately copy string data from `PCopyDataStruct(lParam)^.lpData`.
  2. Queue the file open using `Application.QueueAsyncCall(@ProcessPendingOpenFiles, 0)`.
  3. Return `1` immediately so the secondary process's `SendMessageTimeout` finishes and the process exits in <1ms without delay.
  4. Dispatching asynchronously ensures that if the currently open file has unsaved changes, `OpenFileInNotepad` -> `PromptSaveIfModified` modal dialogs execute safely in standard message pump context without re-entrancy or IPC deadlocks.

### 5. Window Elevation & System Tray Restoration
- **Elevation Filtering**: To allow non-elevated Explorer processes to communicate with an elevated Ace's Utilities instance without UIPI blocks, call `ChangeWindowMessageFilterEx(Handle, WM_COPYDATA, MSGFLT_ALLOW, nil)` and for `WM_ACEUTILS_RESTORE`.
- **System Tray Restoration & Window Flashing**: Call `AllowSetForegroundWindow(ASFW_ANY)` before IPC. When messages arrive, `ShowWindow(Handle, SW_RESTORE)`, `Show`, and `WindowState := wsNormal` ensure the form cleanly unhides from the system tray and gains foreground focus. `FlashWindowEx` alerts the user if the application was minimized.

---

## 8. Runtime TabControl / PageControl Style Switching (`MainForm.pas`)

### The Win32 Widgetset Limitation
In Free Pascal / Lazarus LCL's Win32 widgetset (`customnotebook.inc` and `win32pagecontrol.inc`):
- `TCustomTabControl.SetStyle` (e.g., `PageControl.Style := tsButtons` / `tsFlatButtons` / `tsTabs`) only assigns an internal property `FStyle`.
- It does **not** update or recreate the native Win32 window (`SysTabControl32`). The underlying Win32 window style flags (`TCS_BUTTONS`, `TCS_FLATBUTTONS`, `TCS_TABS`) are only evaluated in `CreateHandle` when `CreateWindowEx` is invoked.
- Consequently, simply changing `PageControl1.Style := tsButtons` at runtime appears to do nothing on screen; the tabs retain their original visual style until the program restarts.

### The Rule for Runtime Tab Style Switching
Whenever modifying `PageControl.Style` dynamically at runtime:
1. Check `if PageControl.HandleAllocated then`.
2. Save the active tab index: `SavedIndex := PageControl.ActivePageIndex;`.
3. Call `RecreateWnd(PageControl);` from the `Controls` unit to tear down and recreate the native window with the updated `Style` flags.
4. Restore the active tab index: `if (SavedIndex >= 0) and (SavedIndex < PageControl.PageCount) then PageControl.ActivePageIndex := SavedIndex;`.
5. Realign and trigger immediate invalidation and repainting:
   ```pascal
   PageControl.Realign;
   PageControl.Invalidate;
   PageControl.Repaint;
   Self.Invalidate;
   Self.Repaint;
   Application.ProcessMessages;
   ```
6. Similarly, when toggling `TabHeight` or custom caption indicators (like active dot markers), ensure `Invalidate` and `Repaint` are explicitly called so changes reflect immediately without user interaction delays.

---

## 9. Lazarus LCL `TStatusBar` Multi-Panel Initialization (`MainForm.pas` / `MainForm.lfm`)

### The `SimplePanel` Trap (CRITICAL)
In Delphi VCL, `TStatusBar.SimplePanel` defaults to `False`. In Lazarus LCL, however, `TStatusBar.FSimplePanel` is initialized to `True` by default (`statusbar.inc`).
- **The Symptom**: If an LFM defines items under `Panels = < item ... item ... >` but omits `SimplePanel = False`, the control remains in `SimplePanel = True` mode. The native Win32 `SysStatus32` control receives `SB_SIMPLE = 1` and renders a single monolithic text bar. Furthermore, `TStatusBar.UpdateHandleObject` explicitly drops all updates to `PanelIndex > 0` when `SimplePanel` is `True`, causing all secondary panels (such as CAPS, NUM, INS, file/directory counts, and system clock) to be completely invisible and unresponsive.
- **The Rule**:
  1. Always explicitly specify `SimplePanel = False` and `Align = alBottom` in the `.lfm`.
  2. Always enforce `StatusBar.SimplePanel := False;` in `FormCreate`.
  3. Auto-fit Panel 0 dynamically on `FormResize`:
     ```pascal
     procedure TfrmMain.FormResize(Sender: TObject);
     const
       RightPanelsWidth = 90 + 90 + 50 + 50 + 50 + 130 + 24;
     begin
       if (StatusBar1 <> nil) and (StatusBar1.Panels.Count > 0) then
         StatusBar1.Panels[0].Width := Max(200, StatusBar1.ClientWidth - RightPanelsWidth);
     end;
     ```
     This keeps the right-aligned status panels (Files, Dirs, CAPS, NUM, INS, Clock) cleanly docked to the right edge across all monitor resolutions and window sizes.

### Native Win32 `SysStatus32` Text Color Limitation & `psOwnerDraw` (CRITICAL)
- **The Issue**: On Windows, the underlying `SysStatus32` common control draws panel text using the GDI system color `COLOR_BTNTEXT` (hardcoded black). Standard `TStatusBar.Font.Color` assignments are completely ignored by `SysStatus32` when non-owner-drawn. When the status bar background is set to a dark color (e.g., `HeaderBg`), the text renders black on dark gray, making it unreadable.
- **The Rule**:
  1. Set `Style = psOwnerDraw` on each panel in both `.lfm` and `FormCreate`.
  2. Implement an `OnDrawPanel` event handler (`StatusBar1DrawPanel`) to paint the panel background (`StatusBar.Canvas.Brush.Color := StatusBar.Color; StatusBar.Canvas.FillRect(Rect);`) and draw the text using `StatusBar.Canvas.Font` with explicit high-contrast colors (`$00F0F0F0` for general text, counts, and clock in dark mode; `$0050D0FF` for active lock indicators).
  3. Use `StatusBar.Canvas.Brush.Style := bsClear;` and `StatusBar.Canvas.TextRect(...)` with alignment calculations to render clean, vertically centered, and clipped text across all resolutions.


---

## 10. SynEdit Keystroke Invariants & Form KeyPreview Guarding (`MainForm.pas`)

### The `csLoading` Keystroke Invariant (CRITICAL)
In Lazarus SynEdit (`synedit.pp` line 2454):
```pascal
if assigned(Owner) and not (csLoading in Owner.ComponentState) then
  SetDefaultKeystrokes;
```
- **The Symptom**: When `TSynEdit` is loaded from a `.lfm` stream, `Owner.ComponentState` contains `csLoading`. SynEdit's constructor skips `SetDefaultKeystrokes`. Furthermore, `TCustomSynEdit.Loaded` only updates the caret and does **not** call `SetDefaultKeystrokes`. If the `.lfm` does not contain a serialized `<Keystrokes>` collection, `SynEdit.Keystrokes.Count` remains **`0`**.
- **The Impact**: With 0 keystrokes registered, `VK_BACK` is never dispatched to `ecDeleteLastChar`, `ord('A')` with `ssCtrl` is never dispatched to `ecSelectAll`, and all editor navigation keys (Delete, Home, End, Ctrl+Arrows) fail silently, appearing as if the control is "swallowing" keys.
- **The Rule**:
  Always explicitly call `SynEdit.Keystrokes.ResetDefaults;` in `FormCreate`:
  ```pascal
  SynEdit1.Keystrokes.ResetDefaults;
  ```

### Form `KeyPreview` Scope & Classic Delphi Typing Guard
When `KeyPreview = True` is enabled on the main form:
1. **Scope Restriction**: Secondary forms (like `TfrmPreview`) must keep `KeyPreview = False` to prevent phantom interception outside the main window.
2. **The Non-Interference Guard**: When the user is typing into an active text editor (`SynEdit1`, `TCustomEdit`, `TCustomMemo`), `FormKeyDown` must **never** swallow or process normal typing or editing keys (`VK_BACK`, `VK_DELETE`, `VK_RETURN`, arrow keys).
3. **Explicit `Ctrl+A` Routing**: Because LCL Win32 only delivers `EM_SETSEL` to native `EditClsName` controls, custom controls like `TSynEdit` require form-level shortcut routing:
   ```pascal
   if (ssCtrl in Shift) and not (ssAlt in Shift) and ((Key = VK_A) or (Key = ord('A'))) then
   begin
     if (ActiveControl = SynEdit1) or ((PageControl1 <> nil) and (PageControl1.ActivePage = tabNotepad) and (SynEdit1 <> nil)) then
     begin
       SynEdit1.SelectAll;
       Key := 0;
       Exit;
     end
     else if ActiveControl is TCustomEdit then
     begin
       TCustomEdit(ActiveControl).SelectAll;
       Key := 0;
       Exit;
     end
     else if ActiveControl is TCustomMemo then
     begin
       TCustomMemo(ActiveControl).SelectAll;
       Key := 0;
       Exit;
     end;
   end;

   // Delphi tip: Never let Form-level KeyPreview interfere with typing in active editor/edit controls!
   if (ActiveControl = SynEdit1) or (ActiveControl is TCustomEdit) or (ActiveControl is TCustomMemo) then
     Exit;
   ```
4. **Focus Assurance**: Ensure `SynEdit1.SetFocus` is called on tab switches (`PageControl1Change`), `OpenFileInNotepad`, and `btnNewFileClick` so keyboard input is never directed into inactive containers.

---

## 11. SynEdit Gutter Theming & Dark Mode Invariants (`MainForm.pas` / `PreviewForm.pas`)

### The `TSynGutterPartBase` Default Color Trap (CRITICAL)
In Lazarus SynEdit (`syngutterbase.pp`), all gutter parts (`TSynGutterLineNumber`, `TSynGutterMarks`, `TSynGutterChanges`, `TSynGutterSeparator`, `TSynGutterCodeFolding`) inherit from `TSynGutterPartBase`:
```pascal
constructor TSynGutterPartBase.Create(AOwner: TComponent);
begin
  FMarkupInfo := TSynSelectedColor.Create;
  FMarkupInfo.Background := clBtnFace;
  FMarkupInfo.Foreground := clNone;
  ...
```
- **The Symptom**: When switching to Dark Mode, assigning `SynEdit.Gutter.Color := GutterBg;` only tints the underlying gutter container canvas. When individual gutter parts paint (`TSynGutterLineNumber.Paint` and `TSynGutterPartBase.PaintBackground`), they explicitly draw opaque rectangles using `MarkupInfo.Background`. Because `MarkupInfo.Background` was initialized to `clBtnFace` (and is NOT `clNone`), the gutter parts remain bright button-face grey (`$00F0F0F0`), so the gutter never goes dark.
- **The Invisible Line Numbers Issue**: Because `MarkupInfo.Foreground` is `clNone` by default, `TSynGutterLineNumber` falls back to `SynEdit.Font.Color`. In dark mode, `Font.Color` is set to light grey/white (`$00F0F0F0`). Consequently, white/light text was drawn on top of an un-darkened `clBtnFace` (`$00F0F0F0`) background—rendering line numbers completely invisible.
- **The Rule**:
  Always update all gutter parts and explicitly configure line number foreground and current line colors via a dedicated helper `ApplySynEditGutterTheme`:
  ```pascal
  procedure ApplySynEditGutterTheme(ASynEdit: TSynEdit; ADark: Boolean; AGutterBg: TColor);
  var
    i: Integer;
    LineNumCol, ActiveLineNumCol: TColor;
    LinePart: TSynGutterLineNumber;
    SepPart: TSynGutterSeparator;
    FoldPart: TSynGutterCodeFolding;
  begin
    if ASynEdit = nil then Exit;

    if ADark then
    begin
      LineNumCol := $00858585;        // Clean readable muted slate-gray for line numbers (VS Code style)
      ActiveLineNumCol := $00FFFFFF;  // Bright crisp white for active line number
    end
    else
    begin
      LineNumCol := $00707070;        // Readable neutral gray for line numbers
      ActiveLineNumCol := $00000000;  // Solid black for active line number
    end;

    ASynEdit.Gutter.Color := AGutterBg;

    // Update background of all gutter parts
    for i := 0 to ASynEdit.Gutter.Parts.Count - 1 do
      if ASynEdit.Gutter.Parts[i] <> nil then
        ASynEdit.Gutter.Parts[i].MarkupInfo.Background := AGutterBg;

    // Explicitly configure line numbers
    LinePart := ASynEdit.Gutter.LineNumberPart;
    if LinePart <> nil then
    begin
      LinePart.MarkupInfo.Background := AGutterBg;
      LinePart.MarkupInfo.Foreground := LineNumCol;
      LinePart.MarkupInfoCurrentLine.Background := AGutterBg;
      LinePart.MarkupInfoCurrentLine.Foreground := ActiveLineNumCol;
    end;

    // Synchronize separator line and code folding markers
    SepPart := ASynEdit.Gutter.SeparatorPart;
    if SepPart <> nil then
    begin
      SepPart.MarkupInfo.Background := AGutterBg;
      if ADark then SepPart.MarkupInfo.Foreground := $003C3834
      else SepPart.MarkupInfo.Foreground := clBtnShadow;
    end;

    FoldPart := ASynEdit.Gutter.CodeFoldPart;
    if FoldPart <> nil then
    begin
      FoldPart.MarkupInfo.Background := AGutterBg;
      if ADark then FoldPart.MarkupInfo.Foreground := $00858585
      else FoldPart.MarkupInfo.Foreground := clGrayText;
    end;

    ASynEdit.RightGutter.Color := AGutterBg;
    for i := 0 to ASynEdit.RightGutter.Parts.Count - 1 do
      if ASynEdit.RightGutter.Parts[i] <> nil then
        ASynEdit.RightGutter.Parts[i].MarkupInfo.Background := AGutterBg;

    ASynEdit.InvalidateGutter;
    ASynEdit.Repaint;
  end;
  ```
  Ensure this is invoked for every `TSynEdit` control (`SynEdit1` in `MainForm` and `synPreview` in `PreviewForm`) in `ApplyTheme`.


---

## 12. Win32 Common Controls Dark Mode Invariants (`SysHeader32`, `SysListView32`, `SysTreeView32`)

### 1. The Win32 `SysHeader32` Dark Mode Limitation & Subclassing (CRITICAL)
- **The Issue**: On Windows, the native `SysHeader32` common control (the column titles in `TListView` report mode) does not natively support dark mode even when `AllowDarkModeForWindow` and `SetWindowTheme(hHdr, 'DarkMode_ItemsView', nil)` are called. Windows common controls draw header text in hardcoded black GDI system colors.
- **The Solution**: Subclass the parent `TListView` window using `SetWindowSubclass`:
  ```pascal
  SetWindowSubclass(ALV.Handle, @ListViewHeaderSubclassProc, ASubclassId, DWORD_PTR(Self));
  ```
  In `ListViewHeaderSubclassProc`:
  - Intercept `WM_NOTIFY` where `pnmh^.hwndFrom = ListView_GetHeader(hWnd)` and `Integer(pnmh^.code) = -12` (`NM_CUSTOMDRAW`).
  - On `CDDS_PREPAINT`: Fill the entire header bounding rect with dark charcoal (`$0024211E`) to paint any empty space beyond the rightmost column, draw the bottom border line (`$003C3834`), and return `CDRF_NOTIFYITEMDRAW`.
  - On `CDDS_ITEMPREPAINT`: Paint column background (`$0025211E`, or `$00322E2A` on hover, `$001B1816` on press), draw right separator line (`$003C3834`), query the column's Unicode title using `Windows.SendMessageW(hHdr, $120B {HDM_GETITEM_W}, PtrUInt(lpcd^.dwItemSpec), PtrInt(@HdItem))`, draw text in crisp light silver (`$00F0F0F0`) via `DrawTextW` with alignment flags, and return `CDRF_SKIPDEFAULT`.
  - Clean up with `RemoveWindowSubclass(ALV.Handle, @ListViewHeaderSubclassProc, ASubclassId)` in `FormDestroy`.

### 2. The `TCustomTreeView` `tvoThemedDraw` Black Font Trap (CRITICAL)
- **The Issue**: In Lazarus LCL (`treeview.inc`), when `tvoThemedDraw in Options` is `True`, the treeview delegates node painting to Windows UxTheme `DrawThemeText(..., TVP_TREEITEM, ...)`. Under Win32 UxTheme, this call completely ignores `Font.Color` and draws black text onto dark backgrounds.
- **The Rule**: In dark mode, always remove `tvoThemedDraw` from treeview options:
  ```pascal
  ShellTreeView.Options := ShellTreeView.Options - [tvoThemedDraw];
  ShellTreeView.SelectionColor := $006B4D2B;
  ShellTreeView.SelectionFontColor := clWhite;
  ```
  In light mode, restore `Options := Options + [tvoThemedDraw]`.
  Implement `OnCustomDrawItem` to ensure node brush and font colors remain high-contrast in all selection and focus states.

### 3. ListView Item & SubItem Custom Draw & Cracker Classes
- **The Issue**: Without `OnCustomDrawItem` and `OnCustomDrawSubItem`, LCL Win32 `win32wscustomlistview.inc` skips `clrText` assignment, causing subitem text (size, type, date modified) to fall back to black system text.
- **The Rule**:
  1. Implement unified `ListViewCustomDrawItem` and `ListViewCustomDrawSubItem` setting `$00F0F0F0` for items and `$00D8D8D8` for subitems in dark mode.
  2. For `TShellListView`, because `OnCustomDrawItem` and `OnCustomDrawSubItem` are protected in `TCustomListView` and not published in `TShellListView`, define a cracker class:
     ```pascal
     type
       TShellListViewCracker = class(TShellListView);
     ```
     Cast and assign the custom draw handlers in `FormCreate`:
     ```pascal
     TShellListViewCracker(ShellListViewExplorer).OnCustomDrawItem := @ListViewCustomDrawItem;
     TShellListViewCracker(ShellListViewExplorer).OnCustomDrawSubItem := @ListViewCustomDrawSubItem;
     ```
  3. Re-apply themes and subclasses upon tab switching in `PageControl1Change` to account for controls whose Win32 window handles were lazily allocated.

### 4. Runtime Dark/Light Mode Switching Invariants (CRITICAL)
- **The Issue**: When toggling between Dark Mode and Light Mode at runtime:
  1. If `OnCustomDrawItem` / `OnCustomDrawSubItem` remain attached in Light Mode, LCL's `win32wscustomlistview.inc` unconditionally assigns `DrawInfo^.clrTextBk := ColorToRGB(ALV.Canvas.Brush.Color)`, which overrides Windows native Explorer selection and hover effects, causing opaque white/blue text blocks or stuck dark rectangles.
  2. If custom draw handlers check `cdsFocused in State`, items retain dark selection styling even after losing selection or when focus moves.
  3. `SysListView32` and `SysHeader32` cache internal `HTHEME` handles. Merely calling `SetWindowTheme` does not flush the cache, causing column headers or list items to stay dark or render with stale themes.
  4. Non-transparent text backgrounds (`LVM_SETTEXTBKCOLOR`) draw solid rectangular boxes over selection highlights.
- **The Rule**:
  1. **Dynamic Wiring / Unwiring**: In `ApplyTheme`, assign custom draw handlers when `ADark = True`, and unhook them (`:= nil`) when `ADark = False` (except special status items like stale context menu verbs). In `ListViewCustomDrawItem`, guard immediately with `if not FDarkMode then begin DefaultDraw := True; Exit; end;`.
  2. **Strict Selection Check**: Check `if cdsSelected in State then` strictly. Never include `cdsFocused in State` in selection styling.
  3. **Transparent Text Background**: Always send `Windows.SendMessage(ALV.Handle, $1026 {LVM_SETTEXTBKCOLOR}, 0, $FFFFFFFF {CLR_NONE});` in both themes.
  4. **Force Theme Cache Flush**: Always call `SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED)` and send `WM_THEMECHANGED` (`$031A`) to both the control and its header (`ListView_GetHeader`).
  5. **Header Theme Reset**: In Light Mode, set header theme back to `'ItemsView'` (not non-existent `'Explorer'`), and list view theme to `'Explorer'`.
  6. **Explorer List Refresh**: For `ShellListViewExplorer`, call `ShellListViewExplorer.UpdateView;` and `EnsureExplorerSystemImageList;` upon theme change to cleanly re-populate items and system shell icon caches.


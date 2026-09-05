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

## 7. Single Instance Enforcement & System Tray Wake-up

To prevent duplicate processes and resource contention, Ace's Utilities strictly allows only one instance to run:
- **Named Mutex**: `CreateMutex(nil, True, 'AceUtils_SingleInstance_Mutex')` in `AceUtils.lpr` checks for an existing instance before initializing LCL forms.
- **Secondary Instance Termination**: If `GetLastError = ERROR_ALREADY_EXISTS`, the second process signals the running instance and exits immediately.
- **System Tray Restoration & Window Flashing**: The second process posts a registered message (`RegisterWindowMessage('AceUtils_Restore_SingleInstance')`) and calls `ShowWindow(..., SW_RESTORE)` / `SetForegroundWindow`. When `TfrmMain.WndProc` receives this message, it calls `Show`, sets `WindowState := wsNormal`, brings the form to the front (unhiding it if minimized to the system tray), and calls `FlashWindowEx` to flash the window title bar and taskbar.

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

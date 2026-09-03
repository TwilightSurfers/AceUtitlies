# Ace's Utilities (AceUtils)

> *"A Windows application that actually search Windows for files! What an idea? Also a Windows 11 Notepad replacement and a few other miscellaneous utilites."*

[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-blue)](https://github.com/TwilightSurfers/AceUtitlies)
[![Framework](https://img.shields.io/badge/built%20with-Lazarus%20%2F%20Free%20Pascal-orange)](https://www.lazarus-ide.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**Ace's Utilities** (`AceUtils`) is a high-performance, lightweight desktop application written in Object Pascal using the Free Pascal Compiler (FPC) and Lazarus LCL. While tailored for modern Windows workflows, the entire codebase is written using portable LCL components and clean conditional directives, allowing it to be **compiled and run on Linux very easily**.

---

## ✨ Features

### 🔍 1. Real Windows File Search (That Actually Works)
Tired of Windows Search indexing freezes, search loops, or failing to find files that are right in front of you?
- **Fast Traversal Engine**: Safe Breadth-First Search (BFS) directory walker.
- **Junction Point & Symlink Protection**: Automatically skips NTFS reparse points (`FILE_ATTRIBUTE_REPARSE_POINT` `$400`), avoiding endless recursion loops common in Windows 11 user directories (e.g. `Application Data`).
- **Flexible Pattern Matching**: Type `*.pas` or simply `MainForm`—terms without explicit wildcards automatically perform substring searches.
- **Content Search**: Optional full-text scan inside files with configurable case sensitivity.
- **Interactive Multi-Column Header Sorting**: Click any column (**File Name**, **Folder**, **Size**, **Modified Date**, **Type**) to sort Ascending (`▲`) or Descending (`▼`). File sizes sort by true numeric byte count (so 10 MB correctly sorts higher than 2 KB).
- **Directory Tree & Quick Buttons**: Includes a full `TShellTreeView`, directory browse dialog, and one-click quick jump buttons for `C:\`, User Home, and Desktop.
- **Rich Results Context Menu**: Right-click any search result to Open in Notepad, Reveal in Explorer, Open / Run File, **Copy Filename Only**, **Copy File Path Only**, or **Copy File Path and Name** (with multi-item selection support).

### 👁️ 2. Floating Live File Preview Window
Preview files dynamically on a single click without blocking the main search window:
- **Modeless Floating Window**: Stays open side-by-side with your search list; click any result and the preview updates instantaneously.
- **Image Previews**: Seamless native rendering for `.png`, `.jpg`, `.jpeg`, `.bmp`, `.ico`, and `.gif` with proportional scaling, dimension readouts (`Width x Height`), and file size.
- **Syntax-Highlighted Code & Text Previews**: Read-only `TSynEdit` preview displaying the first 300 lines with line numbers and auto-detected syntax coloring for Pascal, Python, HTML/XML, CSS, JavaScript, JSON, SQL, Batch, INI, and Markdown.
- **Binary & Document File Cards**: Displays the high-resolution Windows Shell icon (`SHGetFileInfo`), file metadata, and a 16-column Hex + ASCII byte peek of the file header.
- **"Open in Editor" Quick Action**: One click jumps straight into the built-in Notepad editor tab.
- **Enable / Disable Toggle**: Easily toggle live preview on or off with the search option checkbox.

### 📝 3. Windows 11 Notepad Replacement
A complete, tabbed text and code editor powered by `TSynEdit`:
- **File Management**: New, Open, Save, and Save As with dirty-tracking prompts so you never lose unsaved changes.
- **Multi-Language Syntax Highlighting**: Includes syntax highlighters for Pascal (`.pas`, `.pp`, `.lpr`), Python (`.py`), HTML/XML (`.html`, `.xml`), CSS (`.css`), JavaScript/JSON (`.js`, `.json`), SQL (`.sql`), Batch (`.bat`, `.cmd`), INI/Config (`.ini`, `.cfg`), and a **dedicated custom Markdown syntax highlighter** (`.md`, `.markdown`) with header, code block, list, blockquote, link, and formatting styles for both dark and light modes.
- **Find & Replace Bar**: Sleek slide-down search bar with Find Next, Replace, Replace All, Case Sensitivity, and Whole Word matching.
- **Word Wrap & Formatting**: Toggle Word Wrap on and off on the fly.
- **Status Bar**: Live line number, column number, character position, and modified state tracker.

### 🌙 4. Native Windows 11 Dark Mode
- **Native DWM Titlebar**: Integrates directly with Windows 11 Desktop Window Manager (`DwmSetWindowAttribute` via `dwmapi.dll`) for a true dark window frame.
- **Automatic System Detection**: Detects your Windows theme preference (`AppsUseLightTheme`) on startup.
- **One-Click Toggle**: Switch between Dark and Light mode anytime via the header toggle button.

### 📥 5. System Tray Integration
- **Run in System Tray**: Check the "Run in System Tray" option to keep Ace's Utilities running quietly in your Windows notification area.
- **Minimize & Close to Tray**: Minimizing or closing the window cleanly hides it to the tray.
- **Tray Context Menu**: Right-click the tray icon for quick actions:
  - *Open Ace's Utilities*
  - *Open Notepad*
  - *Exit*
- **One-Click Restore**: Left-clicking the tray icon restores the window to normal view immediately.
- **Persistent Setting**: Preferences are saved across restarts in `AceUtils.ini`.

### 📂 6. Windows Explorer Shell Integration & Windows 11 Notepad Override
- **Full File Associations**: Complete one-click registration associates `.txt`, `.md`, and `.markdown` files with Ace's Utilities.
- **Windows 11 Notepad Override**: Cleans up Windows 11 `UserChoice` / `UserChoiceLatest` registry hijacking for `.md` and `.txt`, so files double-clicked or opened in Explorer launch directly in Ace's Utilities instead of the modern UWP Notepad.
- **Context Menu Integration**: Adds "Open with Ace's Utilities" directly to Windows Explorer right-click context menus for instant access.
- **Zero Admin Privileges Required**: Writes cleanly to per-user `HKCU\Software\Classes` without needing Administrator privileges or modifying system files.
- **Command-Line Registration**: Supports `/register` and `/unregister` flags for headless setup or automation.
- **Easy Toggle**: Add or remove all associations and context menu items at any time directly from the header button.

---

## 🛠️ Visual Form Designer & Lazarus IDE Compatibility

Both forms are standard Lazarus Component Library (LCL) visual forms:
- `MainForm.lfm` / `MainForm.pas`
- `PreviewForm.lfm` / `PreviewForm.pas`

Every component, panel, gutter, and event handler is declared with standard published properties. **You can open, visually modify, and save both forms directly in the Lazarus IDE Form Designer without errors.**

## 🐧 Linux Compilation & Cross-Platform Support

Ace's Utilities is designed from the ground up to be **compiled and run on Linux very easily**:

- **Conditional Code Separation**: All Windows-specific operations (such as Windows DWM dark titlebar composition via `dwmapi.dll`, Windows Shell file icons via `SHGetFileInfo`, and Explorer context menu registry integration) are strictly isolated with `{$IFDEF WINDOWS}` compiler directives.
- **Pure LCL & FPC**: The file search engine, breadth-first directory walker, text encoding conversion (`LazUTF8` / `LConvEncoding`), syntax highlighters, and GUI interfaces rely exclusively on the cross-platform Lazarus Component Library (LCL).
- **Multiple Linux Widgetsets**: Compiles cleanly against **GTK2**, **GTK3**, **Qt5**, or **Qt6** without requiring changes to source code.

### Compiling on Linux in 3 Easy Steps

1. **Install Lazarus and FPC**:
   ```bash
   # Debian / Ubuntu / Linux Mint
   sudo apt update && sudo apt install lazarus fpc

   # Fedora / RHEL
   sudo dnf install lazarus fpc

   # Arch Linux / Manjaro
   sudo pacman -S lazarus fpc
   ```

2. **Compile with `lazbuild`**:
   ```bash
   lazbuild AceUtils.lpi
   ```

3. **Run**:
   ```bash
   ./AceUtils
   ```

You can also open `AceUtils.lpi` in the Lazarus IDE on Linux and press **F9** to compile and run immediately.

---

## 🚀 Building from Source

### Prerequisites
1. **Lazarus IDE** (version 2.2+ or 3.0+ / 4.0+) with **Free Pascal Compiler (FPC 3.2.2+)**.
2. **SynEdit Package**: Standard package bundled with Lazarus (located in `lazarus/components/synedit`).

### Compile via Command Line

**Windows (PowerShell / Command Prompt):**
```powershell
lazbuild AceUtils.lpi
```

**Linux (Bash / Zsh):**
```bash
lazbuild AceUtils.lpi
```

### Compile via Lazarus IDE (Windows or Linux)
1. Open Lazarus.
2. Select **Project** -> **Open Project...** and choose `AceUtils.lpi`.
3. Press **F9** (or select **Run** -> **Build**).
4. The compiled executable (`AceUtils.exe` on Windows, `AceUtils` on Linux) will be generated in the project root.

---

## 📄 License
MIT License. Created by [TwilightSurfers](https://github.com/TwilightSurfers).

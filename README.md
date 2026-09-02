# Ace's Utilities (AceUtils)

> *"A Windows application that actually search Windows for files! What an idea? Also a Windows 11 Notepad replacement and a few other miscellaneous utilites."*

[![Platform](https://img.shields.io/badge/platform-Windows%2011%20%7C%2010-blue)](https://github.com/TwilightSurfers/AceUtitlies)
[![Framework](https://img.shields.io/badge/built%20with-Lazarus%20%2F%20Free%20Pascal-orange)](https://www.lazarus-ide.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**Ace's Utilities** (`AceUtils.exe`) is a high-performance, lightweight Windows desktop application written in Object Pascal using the Free Pascal Compiler (FPC) and Lazarus LCL. It replaces bloated, unresponsive system tools with lightning-fast, native utilities designed specifically for modern Windows 11 workflows.

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
- **Multi-Language Syntax Highlighting**: Includes syntax highlighters for Pascal (`.pas`, `.pp`, `.lpr`), Python (`.py`), HTML/XML (`.html`, `.xml`), CSS (`.css`), JavaScript/JSON (`.js`, `.json`), SQL (`.sql`), Batch (`.bat`, `.cmd`), and INI/Markdown (`.ini`, `.md`).
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

### 📂 6. Windows Explorer Shell Integration
- **"Open with Ace's Utilities"**: Optional one-click registration adds a fast context menu item in Windows Explorer for `.txt` and `.md` files.
- **Zero Registry Bloat**: Writes to per-user `HKCU\Software\Classes\SystemFileAssociations` without requiring Administrator privileges or disrupting system default associations.
- **Easy Toggle**: Add or remove the context menu integration at any time directly from the header bar.

---

## 🛠️ Visual Form Designer & Lazarus IDE Compatibility

Both forms are standard Lazarus Component Library (LCL) visual forms:
- `MainForm.lfm` / `MainForm.pas`
- `PreviewForm.lfm` / `PreviewForm.pas`

Every component, panel, gutter, and event handler is declared with standard published properties. **You can open, visually modify, and save both forms directly in the Lazarus IDE Form Designer without errors.**

---

## 🚀 Building from Source

### Prerequisites
1. **Lazarus IDE** (version 2.2+ or 3.0+ / 4.0+) with **Free Pascal Compiler (FPC 3.2.2+)**.
2. **SynEdit Package**: Standard package bundled with Lazarus (located in `lazarus/components/synedit`).

### Compile via Command Line
Run `lazbuild` from the project directory:
```powershell
lazbuild AceUtils.lpi
```

### Compile via Lazarus IDE
1. Open Lazarus.
2. Select **Project** -> **Open Project...** and choose `AceUtils.lpi`.
3. Press **F9** (or select **Run** -> **Build**).
4. The compiled executable `AceUtils.exe` will be generated in the project root.

---

## 📄 License
MIT License. Created by [TwilightSurfers](https://github.com/TwilightSurfers).

# Ace File Search

A fast, lightweight file search utility built with Lazarus/Free Pascal.

## Features

- **Directory Browser** — Integrated `TShellTreeView` for navigating your file system
- **Wildcard Search** — Supports `*` and `?` patterns (e.g. `*.png`, `readme*`)
- **Multi-Pattern** — Search for multiple types at once: `*.png;*.jpg;*.bmp`
- **Recursive Search** — Optionally includes all subfolders
- **Case Sensitivity** — Toggle case-sensitive matching
- **BFS Algorithm** — Uses breadth-first search for fast, stack-safe directory traversal
- **Open in Explorer** — Double-click a result to reveal the file in Windows Explorer
- **Live Status** — Real-time progress showing directories scanned and files found

## Building

Requires [Lazarus IDE](https://www.lazarus-ide.org/) with Free Pascal Compiler.

```bash
lazbuild AceFileSearch.lpi
```

## Usage

1. Select a starting directory from the tree on the left (defaults to `C:\`)
2. Enter a search pattern (e.g. `*.png`)
3. Click **Search**
4. Double-click any result to open its location in Explorer

## License

MIT

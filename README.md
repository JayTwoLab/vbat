# vbat

> [Korean](README.ko.md)

Enhanced wrapper for `bat` that adds wildcard support and flexible
encoding handling for viewing text files across platforms.

Supported entrypoints
- `vbat.cmd` — Windows (CMD) launcher
- `vbat.sh`  — POSIX shell script (Linux/macOS)

Requirements
- `bat` (shorthand pager) must be installed and available on `PATH`.
   - A cat(1) clone with wings. https://github.com/sharkdp/bat

Quick usage
- Windows (CMD):
	- `vbat.bat myfile.txt`
- Bash (Linux/macOS):
	- `./vbat.sh myfile.txt`

Options
- `--encoding=VALUE` or `-e VALUE` — override encoding for files (e.g. `UTF-8`, `CP949`, `EUC-KR`).
- `-h` or `--help` — show usage help.

`.encoding` sidecar files
Each target text file may have a sidecar file named `<filename>.encoding` that contains a line like:
```
encoding=UTF8
```

The scripts will prefer an explicit `--encoding` argument, then a `.encoding` sidecar, and finally fall back to a sensible default (PowerShell/CMD variants default to CP949; the shell script defaults to UTF-8).

Examples
- View all `.txt` files with default behavior:
	- `vbat.ps1 *.txt`
- Force UTF-8 for a single file:
	- `vbat.sh myfile.txt --encoding=UTF-8`
- Use short flag:
	- `vbat.cmd myfile.txt -e CP949`

Notes
- The Windows `vbat.cmd` is a tiny launcher that invokes PowerShell with the same logic as `vbat.ps1`.
- The shell script uses `iconv` to convert encodings before piping into `bat`.
- If you see an "unsupported encoding" error, either install the required encoding support (platform-specific) or use a different encoding value.

Troubleshooting
- Ensure `bat` is on your `PATH` and callable as `bat`.
- On Windows, run PowerShell scripts according to your execution policy, or use `vbat.cmd` to avoid changing policies.

See the individual scripts for full implementation details.

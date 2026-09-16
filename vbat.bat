<# :
@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create([System.IO.File]::ReadAllText('%~f0'))) @args" -- %*
endlocal
goto :eof
#>

# --- Set bat.exe executable path ---
$batCmd = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\sharkdp.bat_Microsoft.Winget.Source_8wekyb3d8bbwe\bat-v0.26.1-x86_64-pc-windows-msvc\bat.exe"
if (-not (Test-Path $batCmd)) { 
    $batCmd = 'bat' 
}

# --- Automatic encoding detection function (UTF-8 vs CP949) ---
function Get-FileEncodingHelper([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    if ($bytes.Length -eq 0) { return [System.Text.Encoding]::UTF8 }

    # 1. Check for UTF-8 BOM (EF BB BF)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return (New-Object System.Text.UTF8Encoding($true))
    }

    # 2. Check for UTF-16 LE BOM (FF FE)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return [System.Text.Encoding]::Unicode
    }

    # 3. Strict UTF-8 validation without BOM
    $utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        [void]$utf8Strict.GetString($bytes)
        return (New-Object System.Text.UTF8Encoding($false))
    } catch {
        # Fallback to CP949 if invalid UTF-8 byte sequences are found
        return [System.Text.Encoding]::GetEncoding(949)
    }
}

# --- Parse arguments ---
$filePattern = ''
$encOverride = $null

for ($i = 0; $i -lt $args.Length; $i++) {
    $t = "$($args[$i])".Trim()
    if ($t -eq '') { continue }
    
    if ($t -eq '--help' -or $t -eq '-h') {
        Write-Host 'Usage:'
        Write-Host '  vbat [filename/pattern] [--encoding=value] [-e value]'
        exit
    }
    
    if ($t -like '--encoding=*') {
        $encOverride = $t.Substring(11)
    } elseif ($t -eq '--encoding' -or $t -eq '-e') {
        $encOverride = "$($args[++$i])".Trim()
    } else {
        $filePattern = $t
    }
}

if (-not $filePattern) {
    Write-Host 'Error: Missing filename or pattern. Type `vbat -h` for help.'
    exit
}

$OutputEncoding = [System.Text.Encoding]::UTF8
$files = Get-ChildItem -Path $filePattern -ErrorAction SilentlyContinue

if (-not $files) {
    Write-Host "File(s) not found: $filePattern"
    exit
}

# --- Process encoding per file and execute bat ---
foreach ($f in $files) {
    $filePath = $f.FullName
    $encodingObj = $null

    # 1) Check for override options or adjacent .encoding file
    $metaEnc = $null
    if ($encOverride) {
        $metaEnc = $encOverride
    } else {
        $metaPath = $filePath + '.encoding'
        if (Test-Path $metaPath) {
            $metaContent = Get-Content $metaPath -ErrorAction SilentlyContinue
            foreach ($line in $metaContent) {
                if ($line -match '^\s*encoding\s*=\s*(.+)$') {
                    $metaEnc = $Matches[1].Trim()
                    break
                }
            }
        }
    }

    if ($metaEnc) {
        if ($metaEnc -ieq 'CP949') { $metaEnc = 949 }
        if ($metaEnc -match '^\d+$') { $metaEnc = [int]$metaEnc }

        if ($metaEnc -ieq 'Default') {
            $encodingObj = [System.Text.Encoding]::Default
        } elseif ($metaEnc -ieq 'UTF-8' -or $metaEnc -ieq 'UTF8') {
            $encodingObj = New-Object System.Text.UTF8Encoding($false)
        } else {
            try {
                $encodingObj = [System.Text.Encoding]::GetEncoding($metaEnc)
            } catch {
                Write-Host "Error: Unsupported encoding '$metaEnc' for file $($f.Name)"
                continue
            }
        }
    } else {
        # 2) Fallback to auto-detection if not specified
        $encodingObj = Get-FileEncodingHelper -path $filePath
    }

    [System.IO.File]::ReadAllText($filePath, $encodingObj) | & $batCmd --file-name $f.Name
}

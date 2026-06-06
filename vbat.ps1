<#
.SYNOPSIS
    Enhanced bat wrapper supporting wildcards, custom encodings, and .encoding sidecar files.
    Default encoding is strictly set to CP949 (949).
.EXAMPLE
    .\vbat.ps1 *.txt
    .\vbat.ps1 utf8.txt --encoding=UTF-8
#>

$file_pattern = $null
$enc_override = $null

# 1. Parse Arguments Safely
for ($i = 0; $i -lt $args.Length; $i++) {
    $t = $args[$i].Trim()
    if ($t -eq '') { continue }
    
    if ($t -eq '--help' -or $t -eq '-h') {
        Write-Host 'Usage:'
        Write-Host '  .\vbat.ps1 [filename/pattern] [--encoding=value] [-e value]'
        Write-Host ''
        Write-Host 'Options:'
        Write-Host '  -h, --help           Show this help message'
        Write-Host '  -e, --encoding=      Specify file encoding (e.g., UTF-8, CP949, EUC-KR)'
        Write-Host '                       (Defaults to CP949 if omitted)'
        exit
    }
    
    if ($t -like '--encoding=*') {
        $enc_override = $t.Substring(11)
    } elseif ($t -eq '--encoding' -or $t -eq '-e') {
        $enc_override = $args[++$i].Trim()
    } else {
        $file_pattern = $t
    }
}

# 2. Validation: Check Missing Path
if (-not $file_pattern) {
    Write-Host 'Error: Missing filename or pattern. Type `.\vbat.ps1 -h` for help.'
    exit
}

# 3. Enforce UTF-8 Output for pipeline to 'bat'
$OutputEncoding = [System.Text.Encoding]::UTF8

# 4. Process Files (Resolving Wildcards)
$files = Get-ChildItem -Path $file_pattern -ErrorAction SilentlyContinue
if (-not $files) {
    Write-Host "File(s) not found: $file_pattern"
    exit
}

foreach ($f in $files) {
    $filePath = $f.FullName
    $current_enc = 949  # Default Fallback
    
    if ($enc_override) {
        $current_enc = $enc_override
    } else {
        $metaPath = $filePath + ".encoding"
        if (Test-Path $metaPath) {
            $metaContent = Get-Content $metaPath -ErrorAction SilentlyContinue
            foreach ($line in $metaContent) {
                if ($line -match '^\s*encoding\s*=\s*(.+)$') {
                    $current_enc = $Matches[1].Trim()
                    break
                }
            }
        }
    }
    
    # Normalize Encoding Names
    if ($current_enc -ieq 'CP949') { $current_enc = 949 }
    if ($current_enc -match '^\d+$') { $current_enc = [int]$current_enc }
    
    # Validate Encoding
    if ($current_enc -ne 'Default' -and $current_enc -ne 'UTF-8' -and $current_enc -ne 'UTF8') {
        try {
            [void][System.Text.Encoding]::GetEncoding($current_enc)
        } catch {
            Write-Host "Error: Unsupported encoding '$current_enc' for file $($f.Name)"
            continue
        }
    }
    
    # 5. Read and Print File via bat
    if ($current_enc -ieq 'Default') {
        [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::Default) | bat --file-name $f.Name
    } elseif ($current_enc -ieq 'UTF-8' -or $current_enc -ieq 'UTF8') {
        [System.IO.File]::ReadAllText($filePath, (New-Object System.Text.UTF8Encoding($false))) | bat --file-name $f.Name
    } else {
        [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::GetEncoding($current_enc)) | bat --file-name $f.Name
    }
}
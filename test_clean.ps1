$file = 'd:\FYP\urbanpulse_flutter_final\urbanpulse\lib\screens\create_report_screen.dart'
$lines = Get-Content $file -Raw
$linesArray = $lines -split "
|
"

$newLines = @()
foreach ($line in $linesArray) {
    $stripped = $line.Trim()
    
    if ($stripped.StartsWith("//")) {
        $lowerLine = $stripped.ToLower()
        $keep = $false
        
        if ($stripped -match "──") {
            $keep = $true
        } elseif ($lowerLine -match "ignore:") {
            $keep = $true
        } elseif ($stripped -match "TODO") {
            $keep = $true
        } else {
            $words = $stripped.Substring(2).Trim().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
            if ($words.Count -le 8) {
                $keywords = @("widget", "container", "button", "section", "header", "step", "row", "column", "card", "list", "text", "icon", "image", "appbar", "body", "fab", "floating", "dialog", "bottom", "stats", "tabs")
                foreach ($kw in $keywords) {
                    if ($lowerLine -match $kw) {
                        $keep = $true
                        break
                    }
                }
            }
        }
        
        if ($keep) {
            $newLines += $line
        }
    } else {
        $newLines += $line
    }
}

$finalLines = @()
$blankCount = 0
foreach ($line in $newLines) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        $blankCount++
        if ($blankCount -gt 1) {
            continue
        }
    } else {
        $blankCount = 0
    }
    $finalLines += $line
}

[IO.File]::WriteAllText($file, ($finalLines -join "
"))

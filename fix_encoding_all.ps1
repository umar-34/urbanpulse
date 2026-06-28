$files = Get-ChildItem -Path d:\FYP\urbanpulse_flutter_final\urbanpulse\lib -Recurse -Filter *.dart

foreach ($file in $files) {
    $content = [IO.File]::ReadAllText($file.FullName)
    $content = $content.Replace('â”€', '─')
    [IO.File]::WriteAllText($file.FullName, $content)
}

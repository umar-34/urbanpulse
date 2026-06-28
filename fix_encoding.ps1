$file = 'd:\FYP\urbanpulse_flutter_final\urbanpulse\lib\screens\create_report_screen.dart'
$content = [IO.File]::ReadAllText($file)
$content = $content.Replace('â”€', '─')
[IO.File]::WriteAllText($file, $content)

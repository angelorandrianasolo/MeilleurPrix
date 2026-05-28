param(
    [switch]$watch
)

$src = "C:\meilleur-prix-project\frontend-web"
$dst = "C:\Tomcat\apache-tomcat-9.0.117\webapps\meilleur_prix"

if (-not $watch) {
    Write-Host "Deploying frontend-web -> $dst"
    robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP
    Write-Host "Done"
    return
}

Write-Host "Watching $src for changes..."
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $src
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

Register-ObjectEvent $watcher "Changed" -Action {
    robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP | Out-Null
} | Out-Null

Write-Host "Watching. Press Ctrl+C to stop."
while ($true) { Start-Sleep -Seconds 1 }

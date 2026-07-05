# Run Echo Labyrinth on Chrome — uses E: drive for temp (C: often full)
$tempDir = "E:\flutter_temp"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
$env:TEMP = $tempDir
$env:TMP = $tempDir

Set-Location $PSScriptRoot
flutter pub get
flutter run -d chrome

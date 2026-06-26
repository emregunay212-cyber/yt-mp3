# yt-mp3 otomatik baslatici.
# Gorevi: uygulamayi (Flask) ayakta tutmak.
# Internete acma isini Tailscale Funnel kendi servisiyle yapar (sabit adres):
#     https://retmen.tailaff0cd.ts.net
$ErrorActionPreference = 'SilentlyContinue'

$proj  = 'C:\Users\emreg\Downloads\yt-mp3\yt-mp3'
$py    = 'C:\Users\emreg\AppData\Local\Programs\Python\Python312\python.exe'
$ffbin = 'C:\Users\emreg\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin'

# yt-dlp'nin ffmpeg'i bulabilmesi icin PATH'e ekle (giris yapilmadan da gecerli olsun).
if (Test-Path $ffbin) { $env:PATH = "$ffbin;$env:PATH" }

function Test-Flask {
    try { (Invoke-WebRequest -Uri 'http://127.0.0.1:5000/' -UseBasicParsing -TimeoutSec 3).StatusCode -eq 200 }
    catch { $false }
}

# Flask ayakta degilse baslat; surekli kontrol ederek ayakta tut.
while ($true) {
    if (-not (Test-Flask)) {
        Start-Process -FilePath $py -ArgumentList 'app.py' -WorkingDirectory $proj -WindowStyle Hidden
        Start-Sleep -Seconds 5
    }
    Start-Sleep -Seconds 20
}

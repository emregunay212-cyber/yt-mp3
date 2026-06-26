# yt-mp3 YONETICI KURULUMU (bu dosya yonetici olarak calistirilir)
# 1) Girissiz acilis: SYSTEM gorevi -> bilgisayar acilir acilmaz (giris yapmadan) uygulamayi baslatir
# 2) Otomatik giris (auto-login): acilista sifre sormadan masaustune dusurur
# 3) Eski oturum-acilisi baslaticisini (vbs) siler (cift calismasin)
# 4) Tailscale kurar (sabit adres icin; girisi sonra elle yapilacak)
# 5) SYSTEM gorevini test eder

$ErrorActionPreference = 'SilentlyContinue'
$proj    = 'C:\Users\emreg\Downloads\yt-mp3\yt-mp3'
$ps1     = Join-Path $proj 'baslangic.ps1'
$urlfile = Join-Path $proj 'guncel-adres.txt'
$log     = Join-Path $proj 'admin-kurulum-log.txt'
$vbs     = Join-Path ([Environment]::GetFolderPath('Startup')) 'yt-mp3-otomatik.vbs'

function Yaz($m) { Add-Content -Path $log -Value $m -Encoding UTF8 }
Set-Content -Path $log -Value "=== yt-mp3 yonetici kurulum basl/log ===" -Encoding UTF8

# --- 1) SYSTEM gorevi: acilista (girissiz) baslangic.ps1 calissin ---
try {
    $action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ps1`""
    $trigger   = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -TaskName 'yt-mp3-sistem' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Yaz "1) SYSTEM gorevi 'yt-mp3-sistem' olusturuldu: TAMAM"
} catch { Yaz "1) SYSTEM gorevi HATA: $($_.Exception.Message)" }

# --- 2) Otomatik giris (auto-login) ---
try {
    $wl = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    Set-ItemProperty -Path $wl -Name 'AutoAdminLogon'   -Value '1'              -Type String
    Set-ItemProperty -Path $wl -Name 'DefaultUserName'  -Value $env:USERNAME    -Type String
    Set-ItemProperty -Path $wl -Name 'DefaultDomainName' -Value $env:COMPUTERNAME -Type String
    Set-ItemProperty -Path $wl -Name 'DefaultPassword'  -Value '8516'           -Type String
    Yaz "2) Otomatik giris ayarlandi (kullanici=$env:USERNAME, alan=$env:COMPUTERNAME): TAMAM"
} catch { Yaz "2) Otomatik giris HATA: $($_.Exception.Message)" }

# --- 3) Eski oturum-acilisi vbs'sini sil (SYSTEM gorevi ile cakismasin) ---
try {
    if (Test-Path $vbs) { Remove-Item $vbs -Force; Yaz "3) Eski Startup vbs silindi: TAMAM" }
    else { Yaz "3) Eski Startup vbs zaten yok: TAMAM" }
} catch { Yaz "3) vbs silme HATA: $($_.Exception.Message)" }

# --- 4) Tailscale kur (giris sonra elle yapilacak) ---
try {
    $tsExe = 'C:\Program Files\Tailscale\tailscale.exe'
    if (Test-Path $tsExe) {
        Yaz "4) Tailscale zaten kurulu: TAMAM"
    } else {
        Yaz "4) Tailscale kuruluyor (winget)..."
        winget install --id Tailscale.Tailscale -e --accept-source-agreements --accept-package-agreements --disable-interactivity 2>&1 | Out-Null
        if (Test-Path $tsExe) { Yaz "4) Tailscale kuruldu: TAMAM" } else { Yaz "4) Tailscale kurulamadi (winget basarisiz olabilir)" }
    }
} catch { Yaz "4) Tailscale HATA: $($_.Exception.Message)" }

# --- 5) SYSTEM gorevini temiz test et ---
try {
    Yaz "5) Test: eski surecler kapatiliyor..."
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like '*baslangic.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Get-Process cloudflared, python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    $before = (Get-Item $urlfile -ErrorAction SilentlyContinue).LastWriteTime
    Start-ScheduledTask -TaskName 'yt-mp3-sistem'
    $deadline = (Get-Date).AddSeconds(70); $url = $null
    while ((Get-Date) -lt $deadline -and -not $url) {
        Start-Sleep -Seconds 3
        $item = Get-Item $urlfile -ErrorAction SilentlyContinue
        if ($item -and (-not $before -or $item.LastWriteTime -gt $before)) {
            $m = [regex]::Match((Get-Content $urlfile -Raw), 'https://[a-z0-9-]+\.trycloudflare\.com')
            if ($m.Success) { $url = $m.Value }
        }
    }
    if ($url) {
        try { $code = (Invoke-WebRequest -Uri "$url/" -UseBasicParsing -TimeoutSec 20).StatusCode } catch { $code = "HATA" }
        Yaz "5) SYSTEM gorevi calisti. Adres: $url  (disaridan test: HTTP $code)"
    } else {
        Yaz "5) SYSTEM gorevi test: adres olusmadi. cloudflared.log son satirlar:"
        Get-Content (Join-Path $proj 'cloudflared.log') -Tail 12 -ErrorAction SilentlyContinue | ForEach-Object { Yaz "    $_" }
    }
} catch { Yaz "5) Test HATA: $($_.Exception.Message)" }

Yaz "===DONE==="

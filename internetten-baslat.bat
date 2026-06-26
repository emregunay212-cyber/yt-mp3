@echo off
chcp 65001 >nul
cd /d "%~dp0"
title yt-mp3 internet erisimi

echo ============================================================
echo   YouTube -^> MP3  ^|  Internet uzerinden erisim
echo ============================================================
echo.
echo   [1/2] Uygulama baslatiliyor (arka pencere)...
start "yt-mp3 sunucu" /min python app.py

echo   Sunucunun acilmasi icin birkac saniye bekleniyor...
timeout /t 4 /nobreak >nul

echo.
echo   [2/2] Internet adresi olusturuluyor...
echo.
echo   Birazdan asagida su sekilde bir adres cikacak:
echo       https://....trycloudflare.com
echo   O adresi telefondan veya baska aglardan acabilirsin.
echo.
echo   *** BU PENCEREYI KAPATMA ***  Kapatirsan baglanti kesilir.
echo   Bilgisayar da acik ve uyumamis olmali.
echo ============================================================
echo.

"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel --url http://localhost:5000

echo.
echo   Baglanti kapandi. Cikmak icin bir tusa bas...
pause >nul

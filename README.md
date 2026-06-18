# Liste.mp3 — YouTube'dan toplu MP3 indirici

Bir liste yazıyorsun (her satıra bir şarkı: `dudu dudu`, `kuzu kuzu` …),
uygulama her satırı YouTube'da arayıp en uygun sonucu buluyor ve MP3 olarak
indiriyor. Tamamen **senin bilgisayarında** çalışan yerel bir araç.

## Gereksinimler

1. **Python 3.9+**
2. **ffmpeg** (MP3'e çevirmek için şart)
   - Windows: <https://www.gyan.dev/ffmpeg/builds/> adresinden indir, `bin`
     klasörünü PATH'e ekle. (Veya `winget install ffmpeg`)
   - macOS: `brew install ffmpeg`
   - Linux: `sudo apt install ffmpeg`

`ffmpeg -version` komutu çalışıyorsa kurulum tamamdır.

## Kurulum

```bash
cd yt-mp3
pip install -r requirements.txt
```

## Çalıştırma

```bash
python app.py
```

Sonra tarayıcıdan aç: **http://127.0.0.1:5000**

Listeyi yapıştır, **İndir**'e bas. Her parça bulunduğunda yanında bir indirme
bağlantısı çıkar; istersen en altta **Tümünü ZIP indir** ile hepsini tek
dosyada alabilirsin.

İndirilen dosyalar `yt-mp3/indirilenler/` klasöründe birikir.

## İpuçları

- Arama isabetini artırmak için sanatçı adını da yaz: `tarkan kuzu kuzu`.
- Yanlış sonuç gelirse satırı daha açık yaz (şarkı + sanatçı + "official").
- Bir şarkı bulunamazsa o satır "hata" olarak işaretlenir, diğerleri devam eder.

## Yasal not

YouTube'dan indirme, YouTube kullanım şartlarına aykırıdır ve telifli müziği
izinsiz indirmek çoğu ülkede telif ihlalidir. Bu aracı kendi içeriğin,
telifsiz / Creative Commons parçalar veya indirme hakkına sahip olduğun
müzikler için kullan.

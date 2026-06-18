FROM python:3.12-slim

# ffmpeg: yt-dlp'nin sesi MP3'e cevirebilmesi icin sart.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Railway $PORT degiskenini verir. SSE akisi (indirme ilerlemesi) uzun
# surebildigi icin worker timeout'u yuksek tutuyoruz; thread'ler ayni anda
# birden fazla indirme oturumuna izin verir.
CMD gunicorn app:app --bind 0.0.0.0:${PORT:-8000} --workers 1 --threads 8 --timeout 600

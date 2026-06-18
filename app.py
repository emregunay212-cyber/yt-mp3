"""
YouTube -> MP3 toplu indirici (yerel sunucu).

Kullanici basit isimlerden olusan bir liste verir ("dudu dudu", "kuzu kuzu" ...),
uygulama her satiri YouTube'da arar, en uygun sonucu bulur ve MP3 olarak indirir.

Calistirmadan once sistemde ffmpeg kurulu olmalidir.
"""

import os
import io
import re
import json
import uuid
import zipfile
from urllib.parse import quote

from flask import (
    Flask, request, Response, render_template,
    send_from_directory, send_file
)
import yt_dlp

app = Flask(__name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DOWNLOAD_DIR = os.path.join(BASE_DIR, "indirilenler")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

# Oturum kimligi: uuid4().hex -> 32 hane onaltilik. Zip ucundaki yol guvenligi
# icin tam bu kaliba uyan degerleri kabul ediyoruz.
SESSION_RE = re.compile(r"^[0-9a-f]{32}$")


def sse(event_type, **data):
    """Tek bir Server-Sent Event satiri uretir."""
    payload = {"type": event_type, **data}
    return f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"


def download_one(query, out_dir):
    """Verilen aramayi YouTube'da bulur ve MP3 olarak out_dir icine indirir.

    (gosterilecek_baslik, dosya_adi) doner.
    """
    ydl_opts = {
        "format": "bestaudio/best",
        "outtmpl": os.path.join(out_dir, "%(title)s.%(ext)s"),
        "postprocessors": [{
            "key": "FFmpegExtractAudio",
            "preferredcodec": "mp3",
            "preferredquality": "192",
        }],
        "noplaylist": True,
        "quiet": True,
        "no_warnings": True,
        "default_search": "ytsearch",
        # Ayni dosya tekrar indirilirse uzerine yazmasin diye:
        "overwrites": False,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        # ytsearch1: -> ilk (en alakali) sonucu al
        info = ydl.extract_info(f"ytsearch1:{query}", download=True)
        entry = info["entries"][0] if "entries" in info else info
        base_name = ydl.prepare_filename(entry)
        mp3_name = os.path.splitext(base_name)[0] + ".mp3"
        return entry.get("title", query), os.path.basename(mp3_name)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/indir")
def indir():
    """Listeyi alir, sira sira indirir ve ilerlemeyi SSE ile yayinlar."""
    raw = request.args.get("liste", "")
    songs = [s.strip() for s in raw.splitlines() if s.strip()]

    # Her indirme istegi kendi oturum klasorune iner; ZIP de sadece onu paketler.
    session = uuid.uuid4().hex
    out_dir = os.path.join(DOWNLOAD_DIR, session)
    os.makedirs(out_dir, exist_ok=True)

    def generate():
        yield sse("start", total=len(songs), session=session)
        for i, song in enumerate(songs):
            yield sse("searching", index=i, query=song)
            try:
                title, filename = download_one(song, out_dir)
                yield sse(
                    "done", index=i, query=song, title=title,
                    url=f"/indirilenler/{session}/" + quote(filename),
                )
            except Exception as exc:  # noqa: BLE001
                yield sse("error", index=i, query=song, message=str(exc))
        yield sse("finished")

    return Response(
        generate(),
        mimetype="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",  # nginx arkasinda da takilmasin
        },
    )


@app.route("/indirilenler/<path:filename>")
def serve_file(filename):
    return send_from_directory(DOWNLOAD_DIR, filename, as_attachment=True)


@app.route("/api/zip")
def zip_all():
    """Tek bir oturumda indirilen MP3'leri tek ZIP olarak verir."""
    session = request.args.get("session", "")
    if not SESSION_RE.match(session):
        return "Gecersiz oturum", 400

    session_dir = os.path.join(DOWNLOAD_DIR, session)
    if not os.path.isdir(session_dir):
        return "Oturum bulunamadi", 404

    mem = io.BytesIO()
    with zipfile.ZipFile(mem, "w", zipfile.ZIP_DEFLATED) as zf:
        for fn in sorted(os.listdir(session_dir)):
            if fn.lower().endswith(".mp3"):
                zf.write(os.path.join(session_dir, fn), fn)
    mem.seek(0)
    return send_file(
        mem, mimetype="application/zip",
        as_attachment=True, download_name="muzikler.zip",
    )


if __name__ == "__main__":
    print("\n  Tarayicidan ac:  http://127.0.0.1:5000\n")
    app.run(host="127.0.0.1", port=5000, debug=False, threaded=True)

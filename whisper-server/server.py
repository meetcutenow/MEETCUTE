import os
import tempfile
import whisper
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Dopušta Flutter app na localhostu

# Whisper model — "base" je brz i točan za HR/EN
# Za bolji HR/EN: promijenite u "small" ili "medium"
# Za najveću točnost: "large-v3" (sporiji, treba više RAM-a)
MODEL_SIZE = os.environ.get("WHISPER_MODEL", "small")



print(f"[MeetCute Whisper] Učitavam model '{MODEL_SIZE}'...")
model = whisper.load_model(MODEL_SIZE)
print(f"[MeetCute Whisper] Model spreman! Server pokrenut na http://localhost:5050")


@app.route("/transcribe", methods=["POST"])
def transcribe():
    """
    Prima audio file (m4a/wav/mp3/webm) i vraća transkript.
    Flutter šalje: multipart/form-data s poljem 'audio'
    """
    if "audio" not in request.files:
        return jsonify({"success": False, "error": "Nedostaje audio datoteka"}), 400

    audio_file = request.files["audio"]

    # Spremi privremeno
    suffix = "." + (audio_file.filename.rsplit(".", 1)[-1] if "." in audio_file.filename else "m4a")
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        audio_file.save(tmp.name)
        tmp_path = tmp.name

    try:
        # Whisper transcripcija — automatski detektira jezik (HR ili EN)
        result = model.transcribe(
            tmp_path,
            language="hr",
            task="transcribe",
            fp16=False,
            verbose=False,
        )
        text = result["text"].strip()
        detected_lang = result.get("language", "unknown")

        return jsonify({
            "success": True,
            "text": text,
            "language": detected_lang,
        })
    except Exception as e:
            import traceback
            traceback.print_exc()
            return jsonify({"success": False, "error": str(e)}), 500
    finally:
        os.unlink(tmp_path)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "model": MODEL_SIZE})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050, debug=True)
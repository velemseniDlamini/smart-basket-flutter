import base64
import binascii
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


MAX_IMAGE_BYTES = 8 * 1024 * 1024
GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "gemini-flash-latest:generateContent"
)


def parse_image_request(payload):
    encoded_image = payload.get("image_base64")
    mime_type = payload.get("mime_type")
    if not isinstance(encoded_image, str) or not isinstance(mime_type, str):
        raise ValueError("image_base64 and mime_type are required")
    if mime_type not in {"image/jpeg", "image/png", "image/webp"}:
        raise ValueError("unsupported image type")

    try:
        image_bytes = base64.b64decode(encoded_image, validate=True)
    except (binascii.Error, ValueError) as error:
        raise ValueError("image_base64 must be valid base64") from error

    if not image_bytes or len(image_bytes) > MAX_IMAGE_BYTES:
        raise ValueError("image must be between 1 byte and 8 MB")
    return image_bytes, mime_type


def analyze_image(image_bytes, mime_type, api_key):
    prompt = (
        "Read the visible retail price label or receipt in this image as OCR. "
        "Return only JSON with this shape: "
        '{"products":[{"name":"string","price":number|null,'
        '"confidence":number}],"recognized_text":"string",'
        '"receipt_text":"string"}. '
        "List each distinct product whose name and price can be read. Use a numeric "
        "price in South African rand, without a currency symbol. Set price to null "
        "when it is not clearly printed, and never infer or guess a value. Keep "
        "recognized_text as a faithful transcription of all legible text, preserving "
        "the original wording. Format receipt_text as a compact receipt using these "
        "lines where visible: STORE, DATE, ITEM | QTY | UNIT PRICE | LINE TOTAL, "
        "then SUBTOTAL, DISCOUNT, TAX, and TOTAL. Omit fields that are not visible; "
        "do not invent quantities, totals, store names, or receipt details. For a "
        "single shelf label, format its receipt_text as one item row with the exact "
        "visible product name and price. Use R for displayed South African rand "
        "amounts in receipt_text."
    )
    body = json.dumps(
        {
            "contents": [
                {
                    "parts": [
                        {"text": prompt},
                        {
                            "inline_data": {
                                "mime_type": mime_type,
                                "data": base64.b64encode(image_bytes).decode("ascii"),
                            }
                        },
                    ]
                }
            ],
            "generationConfig": {"responseMimeType": "application/json"},
        }
    ).encode("utf-8")
    request = Request(
        GEMINI_URL,
        data=body,
        headers={
            "Content-Type": "application/json",
            "X-goog-api-key": api_key,
        },
        method="POST",
    )

    try:
        with urlopen(request, timeout=45) as response:
            gemini_response = json.loads(response.read().decode("utf-8"))
    except (HTTPError, URLError, TimeoutError) as error:
        raise RuntimeError("Gemini request failed") from error

    parts = gemini_response["candidates"][0]["content"]["parts"]
    result = json.loads(parts[0]["text"])
    if not isinstance(result.get("products"), list):
        raise RuntimeError("Gemini returned an invalid product list")
    if not isinstance(result.get("recognized_text"), str):
        result["recognized_text"] = ""
    if not isinstance(result.get("receipt_text"), str):
        result["receipt_text"] = result["recognized_text"]
    return result


class GeminiProxyHandler(BaseHTTPRequestHandler):
    def _send_json(self, status, payload):
        response = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(response)

    def do_OPTIONS(self):
        self._send_json(204, {})

    def do_POST(self):
        if self.path != "/analyze":
            self._send_json(404, {"error": "not found"})
            return

        try:
            content_length = int(self.headers.get("Content-Length", "0"))
            if content_length <= 0 or content_length > MAX_IMAGE_BYTES * 2:
                raise ValueError("request body is missing or too large")
            payload = json.loads(self.rfile.read(content_length).decode("utf-8"))
            image_bytes, mime_type = parse_image_request(payload)
        except (ValueError, UnicodeDecodeError, json.JSONDecodeError) as error:
            self._send_json(400, {"error": str(error)})
            return

        api_key = os.environ.get("GEMINI_API_KEY")
        if not api_key:
            self._send_json(503, {"error": "Gemini server key is not configured"})
            return

        try:
            result = analyze_image(image_bytes, mime_type, api_key)
        except (RuntimeError, KeyError, IndexError, json.JSONDecodeError):
            self._send_json(502, {"error": "Gemini could not analyze this image"})
            return
        self._send_json(200, result)

    def log_message(self, format_string, *args):
        if self.path != "/analyze":
            super().log_message(format_string, *args)


def main():
    port = int(os.environ.get("PORT", "8000"))
    host = os.environ.get("HOST", "127.0.0.1")
    server = ThreadingHTTPServer((host, port), GeminiProxyHandler)
    print("Gemini image proxy listening on http://{}:{}/analyze".format(host, port))
    server.serve_forever()


if __name__ == "__main__":
    main()
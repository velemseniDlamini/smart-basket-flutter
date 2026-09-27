import base64
import io
import json
import unittest
from unittest.mock import patch

from main import analyze_image, parse_image_request


class ParseImageRequestTests(unittest.TestCase):
    def test_accepts_jpeg_base64(self):
        image_bytes = b"jpeg-data"
        parsed_bytes, mime_type = parse_image_request(
            {
                "image_base64": base64.b64encode(image_bytes).decode("ascii"),
                "mime_type": "image/jpeg",
            }
        )
        self.assertEqual(parsed_bytes, image_bytes)
        self.assertEqual(mime_type, "image/jpeg")

    def test_rejects_unsupported_mime_type(self):
        with self.assertRaisesRegex(ValueError, "unsupported image type"):
            parse_image_request({"image_base64": "eA==", "mime_type": "image/gif"})

    def test_rejects_invalid_base64(self):
        with self.assertRaisesRegex(ValueError, "valid base64"):
            parse_image_request({"image_base64": "not base64!", "mime_type": "image/jpeg"})

    def test_rejects_empty_image(self):
        with self.assertRaisesRegex(ValueError, "between 1 byte"):
            parse_image_request({"image_base64": "", "mime_type": "image/jpeg"})


class AnalyzeImageTests(unittest.TestCase):
    @patch("main.urlopen")
    def test_sends_image_and_parses_gemini_response(self, urlopen):
        gemini_payload = {
            "candidates": [
                {
                    "content": {
                        "parts": [
                            {
                                "text": json.dumps(
                                    {
                                        "products": [
                                            {"name": "Milk", "price": 18.5, "confidence": 0.9}
                                        ],
                                        "recognized_text": "Milk R18.50",
                                    }
                                )
                            }
                        ]
                    }
                }
            ]
        }
        urlopen.return_value = io.BytesIO(json.dumps(gemini_payload).encode("utf-8"))

        result = analyze_image(b"jpeg-data", "image/jpeg", "test-key")

        request = urlopen.call_args.args[0]
        request_payload = json.loads(request.data)
        self.assertEqual(request.get_header("X-goog-api-key"), "test-key")
        self.assertEqual(
            request_payload["contents"][0]["parts"][1]["inline_data"]["data"],
            base64.b64encode(b"jpeg-data").decode("ascii"),
        )
        self.assertEqual(result["products"][0]["name"], "Milk")


if __name__ == "__main__":
    unittest.main()
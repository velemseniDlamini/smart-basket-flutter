# Shoprite Image Review Data

The source photos are in `lib/training data/`. Generate first-pass OCR drafts on macOS with:

```sh
swift training/draft_ocr.swift
```

This writes `training/ocr_drafts.csv` with one row per image, recognized text,
an average Vision OCR confidence, and any decoding error. OCR is only a draft:
review each row against its image, especially promotional prices, loyalty-card
prices, unit prices, and photos without a readable ticket. Do not treat the OCR
output as verified labels or use it as ground truth without correction.

The app currently uses Gemini's hosted image-generation endpoint for inference;
it does not expose a local fine-tuning workflow. A verified image-to-output
dataset and a model provider that supports vision fine-tuning are still needed
to train model weights. Keep original images and corrected labels together so
the dataset can later be split into training and held-out evaluation examples.
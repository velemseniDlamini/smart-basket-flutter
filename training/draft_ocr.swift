import Foundation
import ImageIO
import Vision

let workspace = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let imageDirectory = workspace.appendingPathComponent("lib/training data", isDirectory: true)
let outputURL = workspace.appendingPathComponent("training/ocr_drafts.csv")
let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp"]

func csvField(_ value: String) -> String {
    "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
}

let enumerator = FileManager.default.enumerator(
    at: imageDirectory,
    includingPropertiesForKeys: [.isRegularFileKey],
    options: [.skipsHiddenFiles]
)

let imageURLs = (enumerator?.allObjects as? [URL] ?? [])
    .filter { imageExtensions.contains($0.pathExtension.lowercased()) }
    .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

guard !imageURLs.isEmpty else {
    fputs("No image files found in \(imageDirectory.path)\n", stderr)
    exit(1)
}

var rows = ["image_path,recognized_text,mean_confidence,error"]

for (index, imageURL) in imageURLs.enumerated() {
    let relativePath = "lib/training data/\(imageURL.lastPathComponent)"
    guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        rows.append([relativePath, "", "", "Unable to decode image"].map(csvField).joined(separator: ","))
        continue
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    do {
        try VNImageRequestHandler(cgImage: image).perform([request])
        let observations = request.results ?? []
        let ordered = observations.sorted {
            if abs($0.boundingBox.midY - $1.boundingBox.midY) > 0.01 {
                return $0.boundingBox.midY > $1.boundingBox.midY
            }
            return $0.boundingBox.minX < $1.boundingBox.minX
        }
        let text = ordered.compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
        let confidences = ordered.compactMap { $0.topCandidates(1).first?.confidence }
        let meanConfidence = confidences.isEmpty
            ? ""
            : String(format: "%.3f", confidences.reduce(0, +) / Float(confidences.count))

        rows.append([relativePath, text, meanConfidence, ""].map(csvField).joined(separator: ","))
    } catch {
        rows.append([relativePath, "", "", error.localizedDescription].map(csvField).joined(separator: ","))
    }

    if (index + 1) % 10 == 0 || index + 1 == imageURLs.count {
        print("Processed \(index + 1)/\(imageURLs.count) images")
    }
}

try rows.joined(separator: "\n").appending("\n")
    .write(to: outputURL, atomically: true, encoding: .utf8)
print("Wrote OCR drafts to \(outputURL.path)")
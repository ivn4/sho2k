import CoreImage
import Foundation
import Metal
import UIKit

// MARK: - FilterService
// Serviço que carrega LUTs (.cube) e aplica o filtro ativo em imagens.
// Suporta múltiplos presets (ex.: "filtro1", "filtro2") e troca entre eles.
class FilterService {

    // MARK: - Singleton
    static let shared = FilterService()
    private init() {
        if let device = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: device)
        } else {
            context = CIContext(options: nil)
        }
    }

    // MARK: - Propriedades

    // Contexto de renderização (reutilizado).
    private var context: CIContext?

    // Dicionário de filtros carregados: chave = nome do preset.
    private var filters: [String: CIFilter] = [:]

    // Preset ativo (ex.: "filtro1", "filtro2", "original").
    private(set) var activePreset: String = "original"

    // MARK: - Carregamento do LUT

    /// Carrega um arquivo .cube do bundle e armazena o filtro no dicionário.
    func loadLUT(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "CUBE") else {
            print("FilterService: LUT '\(name).CUBE' não encontrado no bundle.")
            return
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("FilterService: não foi possível ler o arquivo.")
            return
        }

        var dimension = 0
        var floats: [Float] = []

        for rawLine in content.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty || line.hasPrefix("#") { continue }

            if line.uppercased().hasPrefix("LUT_3D_SIZE") {
                let parts = line.split(whereSeparator: { $0.isWhitespace })
                if parts.count >= 2, let size = Int(parts[1]) {
                    dimension = size
                }
                continue
            }

            if line.uppercased().hasPrefix("TITLE") ||
                line.uppercased().hasPrefix("DOMAIN") {
                continue
            }

            let values = line.split(whereSeparator: { $0.isWhitespace })
            guard values.count >= 3,
                  let r = Float(values[0]),
                  let g = Float(values[1]),
                  let b = Float(values[2]) else {
                continue
            }

            floats.append(r)
            floats.append(g)
            floats.append(b)
            floats.append(1.0)
        }

        guard dimension > 0 else {
            print("FilterService: dimensão inválida.")
            return
        }
        let expectedCount = dimension * dimension * dimension * 4
        guard floats.count == expectedCount else {
            print("FilterService: dados incorretos. Esperado \(expectedCount), obtido \(floats.count).")
            return
        }

        let data = floats.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }

        guard let filter = CIFilter(name: "CIColorCubeWithColorSpace") else {
            print("FilterService: não foi possível criar o filtro.")
            return
        }
        filter.setValue(dimension, forKey: "inputCubeDimension")
        filter.setValue(data, forKey: "inputCubeData")

        if let colorSpace = CGColorSpace(name: CGColorSpace.displayP3) {
            filter.setValue(colorSpace, forKey: "inputColorSpace")
        }

        // Armazena o filtro no dicionário.
        filters[name] = filter
        print("FilterService: LUT '\(name)' carregado (dimensão \(dimension)).")
    }

    // MARK: - Preset ativo

    /// Troca o filtro ativo.
    func setActivePreset(_ name: String) {
        if name == "original" || filters[name] != nil {
            activePreset = name
        } else {
            print("FilterService: preset '\(name)' não encontrado.")
        }
    }

    /// Indica se há um filtro ativo (diferente de "original").
    var isFilterEnabled: Bool {
        return activePreset != "original"
    }

    // MARK: - Aplicação

    /// Aplica o filtro ativo em um CIImage (usado no preview ao vivo).
    func apply(to ciImage: CIImage) -> CIImage {
        guard activePreset != "original",
              let filter = filters[activePreset] else {
            return ciImage
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        return filter.outputImage ?? ciImage
    }

    /// Aplica o filtro ativo em um UIImage.
    func apply(to image: UIImage) -> UIImage {
        guard isFilterEnabled,
              let filter = filters[activePreset],
              let context = context else {
            return image
        }

        guard let ciImage = CIImage(image: image) else {
            return image
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else {
            return image
        }

        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Renderização

    /// Renderiza um CIImage em UIImage (usado no preview ao vivo).
    func render(_ ciImage: CIImage) -> UIImage? {
        guard let context = context else { return nil }
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

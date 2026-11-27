import Foundation
import UIKit

// MARK: - PhotoItem
// Representa uma foto salva: seu arquivo (URL) e a imagem carregada.
struct PhotoItem {
    let url: URL
    let image: UIImage
}

// MARK: - GalleryViewModel
// Gerencia a lista de fotos, o modo de seleção múltipla e as ações de
// compartilhar/deletar. Notifica a view via `didUpdatePhotos`.
class GalleryViewModel {

    // MARK: - Estado

    private(set) var items: [PhotoItem] = []

    // Conjunto de índices selecionados (usado no modo de seleção).
    private(set) var selectedIndices: Set<Int> = []

    // Indica se o modo de seleção múltipla está ativo.
    private(set) var isSelectionMode: Bool = false

    // MARK: - Callbacks

    var didUpdatePhotos: (() -> Void)?

    // MARK: - Dados derivados

    var numberOfItems: Int { items.count }
    var selectedCount: Int { selectedIndices.count }
    var hasSelection: Bool { !selectedIndices.isEmpty }

    func item(at index: Int) -> PhotoItem? {
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }

    func isSelected(_ index: Int) -> Bool {
        return selectedIndices.contains(index)
    }

    // MARK: - Carregamento

    func fetchPhotos() {
        let loaded = StorageService.shared.loadSavedPhotos()
        items = loaded.map { PhotoItem(url: $0.0, image: $0.1) }
        // Sai do modo de seleção ao recarregar (estado limpo).
        selectedIndices.removeAll()
        isSelectionMode = false
        didUpdatePhotos?()
    }

    // MARK: - Modo de seleção

    func enterSelectionMode() {
        isSelectionMode = true
        selectedIndices.removeAll()
        didUpdatePhotos?()
    }

    func exitSelectionMode() {
        isSelectionMode = false
        selectedIndices.removeAll()
        didUpdatePhotos?()
    }

    func toggleSelectionMode() {
        if isSelectionMode {
            exitSelectionMode()
        } else {
            enterSelectionMode()
        }
    }

    func select(_ index: Int) {
        guard index >= 0 && index < items.count else { return }
        selectedIndices.insert(index)
    }

    func deselect(_ index: Int) {
        selectedIndices.remove(index)
    }

    // MARK: - Ações

    // URLs das fotos selecionadas (para compartilhar via UIActivityViewController).
    func selectedURLs() -> [URL] {
        return selectedIndices.sorted().compactMap { index in
            guard index < items.count else { return nil }
            return items[index].url
        }
    }

    // Exclui as fotos selecionadas do armazenamento e atualiza a lista.
    func deleteSelected() {
        let urls = selectedURLs()
        StorageService.shared.deletePhotos(at: urls)

        let selected = selectedIndices
        items = items.enumerated()
            .filter { !selected.contains($0.offset) }
            .map { $0.element }

        selectedIndices.removeAll()
        isSelectionMode = false
        didUpdatePhotos?()
    }
}
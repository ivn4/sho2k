import UIKit

class StorageService {
    
    // Singleton para acessar o serviço de qualquer lugar do app
    static let shared = StorageService()
    
    private init() {}
    
    // Pega o caminho da pasta "Documents" do aplicativo
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // Salva a imagem na galeria interna
    func savePhotoToAppGallery(image: UIImage) {
        // Converte a imagem do iOS para dados de JPEG
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        
        // Cria um nome de arquivo único baseado na data e hora
        let fileName = UUID().uuidString + ".jpg"
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            // Grava o arquivo no armazenamento do iPhone
            try data.write(to: filePath)
            print("Foto salva no app com sucesso: \(filePath.path)")
        } catch {
            print("Erro ao salvar foto: \(error)")
        }
    }
    
    // Carrega as fotos salvas na galeria interna (URL + imagem).
    func loadSavedPhotos() -> [(URL, UIImage)] {
        let directory = getDocumentsDirectory()
        let fileManager = FileManager.default

        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let photoURLs = fileURLs.filter { $0.pathExtension.lowercased() == "jpg" }

        // Ordena da mais recente para a mais antiga
        let sortedURLs = photoURLs.sorted { (a, b) -> Bool in
            let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return dateA > dateB
        }

        return sortedURLs.compactMap { url in
            guard let image = UIImage(contentsOfFile: url.path) else { return nil }
            return (url, image)
        }
    }

    // Exclui permanentemente as fotos nos URLs informados.
    func deletePhotos(at urls: [URL]) {
        let fileManager = FileManager.default
        for url in urls {
            try? fileManager.removeItem(at: url)
        }
    }
}

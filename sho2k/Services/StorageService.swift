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
}

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    // MARK: - 1. Elementos de Interface (View Code)
    
    // A view que vai mostrar a imagem da câmera no fundo
    private let previewView = UIView()
    
    // Botão de Capturar (Círculo grande)
    private let captureButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 35 // Metade de 70 para ficar redondo
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Botão de Flash
    private let flashButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Botão de Galeria (Quadrado com ícone de foto)
    private let galleryButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Botões de Filtro (F1 e F2)
    private let f1Button = createFilterButton(title: "F1")
    private let f2Button = createFilterButton(title: "F2")
    
    // MARK: - 2. Variáveis da Câmera (AVFoundation)
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let photoOutput = AVCapturePhotoOutput()
    
    // MARK: - 3. Ciclo de Vida da Tela
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupLayout()
        checkCameraPermissions()
        
        // Quando clicar, chama a função de tirar foto
        captureButton.addTarget(self, action: #selector(captureButtonPressed), for: .touchUpInside)
    }
    
    // Garante que o preview da câmera se ajuste se a tela mudar de tamanho
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = previewLayer {
            previewLayer.frame = previewView.bounds
        }
    }
    
    // MARK: - 4. Configuração do Layout (Auto Layout)
    private func setupLayout() {
        // Adiciona a view da câmera primeiro (para ficar no fundo)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        
        // Adiciona os botões por cima
        view.addSubview(captureButton)
        view.addSubview(flashButton)
        view.addSubview(galleryButton)
        view.addSubview(f1Button)
        view.addSubview(f2Button)
        
        // Ativando as restrições (Constraints)
        NSLayoutConstraint.activate([
            // Preview ocupa a tela toda
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Botão de Captura no centro inferior
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Botão de Galeria à esquerda do botão de captura
            galleryButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            galleryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            galleryButton.widthAnchor.constraint(equalToConstant: 44),
            galleryButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Botão de Flash à direita do botão de captura
            flashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            flashButton.widthAnchor.constraint(equalToConstant: 44),
            flashButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Botão F1 logo acima do botão de galeria
            f1Button.bottomAnchor.constraint(equalTo: galleryButton.topAnchor, constant: -30),
            f1Button.leadingAnchor.constraint(equalTo: galleryButton.leadingAnchor),
            f1Button.widthAnchor.constraint(equalToConstant: 40),
            f1Button.heightAnchor.constraint(equalToConstant: 40),
            
            // Botão F2 ao lado do F1
            f2Button.centerYAnchor.constraint(equalTo: f1Button.centerYAnchor),
            f2Button.leadingAnchor.constraint(equalTo: f1Button.trailingAnchor, constant: 15),
            f2Button.widthAnchor.constraint(equalToConstant: 40),
            f2Button.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // Função auxiliar para criar os botões F1 e F2 com o mesmo estilo
    private static func createFilterButton(title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    // A função que o botão executa
    @objc private func captureButtonPressed() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - 5. Lógica da Câmera
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // O usuário ainda não decidiu, vamos perguntar
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        case .authorized:
            // Já deu permissão antes
            setupCamera()
        default:
            // Negado ou restrito (Avisar usuário para ir nos Ajustes)
            print("Permissão de câmera negada.")
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo // Qualidade para fotos
        
        // Pega a lente traseira
        guard let backCamera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("Não foi possível acessar a câmera traseira.")
            return
        }
        
        // Conecta a lente na sessão
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Conecta o output de foto na sessão
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        // Cria a camada de vídeo ao vivo e encaixa na previewView
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds
        previewView.layer.addSublayer(previewLayer)
        
        // Roda a câmera (em uma thread separada para não travar a tela)
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
}

// MARK: - Extensão para processar a foto capturada
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Erro ao capturar foto: \(error.localizedDescription)")
            return
        }
        
        // Pega os dados brutos da câmera e transforma num objeto UIImage
        guard let imageData = photo.fileDataRepresentation(),
              let capturedImage = UIImage(data: imageData) else {
            return
        }
        
        // Pisca a tela rapidamente para o usuário saber que a foto foi tirada
        DispatchQueue.main.async {
            let flashView = UIView(frame: self.previewView.bounds)
            flashView.backgroundColor = .white
            flashView.alpha = 1
            self.previewView.addSubview(flashView)
            
            UIView.animate(withDuration: 0.15, animations: {
                flashView.alpha = 0
            }) { _ in
                flashView.removeFromSuperview()
            }
        }
        
        // Manda o serviço salvar essa imagem internamente
        StorageService.shared.savePhotoToAppGallery(image: capturedImage)
    }
}

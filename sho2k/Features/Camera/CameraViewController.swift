import UIKit
import AVFoundation
import CoreImage

class CameraViewController: UIViewController {
    
    private let cameraView = CameraView()
    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let photoOutput = AVCapturePhotoOutput()

    // Output de vídeo para processar frames em tempo real (preview filtrado).
    private let videoDataOutput = AVCaptureVideoDataOutput()
    // Fila serial em background para não bloquear a main thread.
    private let videoQueue = DispatchQueue(label: "sho2k.videoQueue", qos: .userInitiated)

    // Estado do flash (ligado/desligado).
    private var isFlashEnabled = false

    // Contador de frames para throttle do preview filtrado.
    private var frameCounter = 0
    
    override func loadView() {
        view = cameraView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermissions()
        cameraView.captureButton.addTarget(self, action: #selector(captureButtonPressed), for: .touchUpInside)
        cameraView.galleryButton.addTarget(self, action: #selector(galleryButtonPressed), for: .touchUpInside)
        cameraView.flashButton.addTarget(self, action: #selector(flashButtonPressed), for: .touchUpInside)
        cameraView.f1Button.addTarget(self, action: #selector(f1ButtonPressed), for: .touchUpInside)
        cameraView.f2Button.addTarget(self, action: #selector(f2ButtonPressed), for: .touchUpInside)
        FilterService.shared.loadLUT(named: "filtro1")
        updateFilterButtonAppearance()
    }
    
    // Garantir que o previewLayer cubra toda a previewView sempre que o layout mudar
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraView.previewView.bounds
    }
    
    @objc private func captureButtonPressed() {
        // Dispara o flash visual (tela branca) apenas quando o flash físico está desligado.
        if !isFlashEnabled {
            triggerFlashAnimation()
        }

        let settings = AVCapturePhotoSettings()

        // Configura o flash conforme o estado do botão.
        if photoOutput.supportedFlashModes.contains(isFlashEnabled ? .on : .off) {
            settings.flashMode = isFlashEnabled ? .on : .off
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func triggerFlashAnimation() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let flashView = UIView(frame: self.cameraView.bounds)
            flashView.backgroundColor = .white
            flashView.alpha = 1
            self.cameraView.addSubview(flashView)
            self.cameraView.bringSubviewToFront(flashView)

            UIView.animate(withDuration: 0.15, animations: {
                flashView.alpha = 0
            }) { _ in
                flashView.removeFromSuperview()
            }
        }
    }

    @objc private func flashButtonPressed() {
        isFlashEnabled.toggle()

        // Atualiza o ícone do botão.
        let iconName = isFlashEnabled ? "bolt.fill" : "bolt.slash.fill"
        cameraView.flashButton.setImage(UIImage(systemName: iconName), for: .normal)
        cameraView.flashButton.tintColor = isFlashEnabled ? .systemYellow : .white
    }

    @objc private func galleryButtonPressed() {
        // Abre a galeria de fotos capturadas em tela cheia.
        let galleryViewController = GalleryViewController()
        let navigationController = UINavigationController(rootViewController: galleryViewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    @objc private func f1ButtonPressed() {
        // Ativa o filtro1.
        FilterService.shared.setActivePreset("filtro1")
        updateFilterButtonAppearance()
    }

    @objc private func f2ButtonPressed() {
        // Ativa o filtro2.
        FilterService.shared.setActivePreset("filtro2")
        updateFilterButtonAppearance()
    }

    private func updateFilterButtonAppearance() {
        let isFiltro1 = FilterService.shared.activePreset == "filtro1"
        cameraView.f1Button.alpha = isFiltro1 ? 1.0 : 0.5
        cameraView.f2Button.alpha = isFiltro1 ? 0.5 : 1.0
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        case .authorized:
            setupCamera()
        default:
            print("Permissão de câmera negada nas configurações do sistema.")
        }
    }
    
    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("Não foi possível acessar a câmera traseira.")
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        // Configura o output de vídeo para o preview filtrado em tempo real.
        videoDataOutput.videoSettings = [
            (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)
        ]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }

        captureSession.commitConfiguration()
        
        // Configura o layer de preview
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = cameraView.previewView.bounds
        cameraView.previewView.layer.addSublayer(previewLayer)
        
        // Inicia a sessão em background para não travar a UI
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        // autoreleasepool evita acúmulo de memória nos frames.
        autoreleasepool {
            // Throttle: processa 1 a cada 2 frames para reduzir carga da GPU.
            frameCounter += 1
            guard frameCounter % 2 == 0 else { return }

            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            // Converte o pixel buffer em CIImage.
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

            // Corrige a orientação (frames chegam em landscape).
            let orientedImage = ciImage.oriented(.right)

            // Aplica o filtro (se ativo).
            let filteredImage = FilterService.shared.apply(to: orientedImage)

            // Renderiza o CIImage em UIImage via FilterService.
            guard let uiImage = FilterService.shared.render(filteredImage) else { return }

            // Publica na main queue para atualizar a UI.
            DispatchQueue.main.async { [weak self] in
                self?.cameraView.filteredPreviewView.image = uiImage
            }
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Erro ao capturar foto: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let capturedImage = UIImage(data: imageData) else {
            return
        }
        
        // >>> TESTE: aplica o filtro na foto capturada
        let imagemFiltrada = FilterService.shared.apply(to: capturedImage)
        print("Filtro aplicado. Tamanho: \(imagemFiltrada.size)")

        // Salva em background para não bloquear a UI.
        DispatchQueue.global(qos: .userInitiated).async {
            StorageService.shared.savePhotoToAppGallery(image: imagemFiltrada)
        }
    }
}

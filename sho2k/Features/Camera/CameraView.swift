//
//  CameraView.swift
//  sho2k
//
//  Created by Iv on 17/11/26.
//

import Foundation
import UIKit

class CameraView: UIView {
    
    // MARK: - Elementos de Interface
    let previewView = UIView()

    // View que exibe os frames filtrados em tempo real (por cima do preview).
    let filteredPreviewView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    let captureButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let flashButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let galleryButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let f1Button = createFilterButton(title: "F1")
    let f2Button = createFilterButton(title: "F2")
    
    // MARK: - Inicialização
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuração de Layout e Constraints
    private func setupLayout() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(previewView)

        // Adiciona a view de preview filtrado por cima do preview original.
        addSubview(filteredPreviewView)

        addSubview(captureButton)
        addSubview(flashButton)
        addSubview(galleryButton)
        addSubview(f1Button)
        addSubview(f2Button)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: topAnchor),
            previewView.bottomAnchor.constraint(equalTo: bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: trailingAnchor),

            filteredPreviewView.topAnchor.constraint(equalTo: topAnchor),
            filteredPreviewView.bottomAnchor.constraint(equalTo: bottomAnchor),
            filteredPreviewView.leadingAnchor.constraint(equalTo: leadingAnchor),
            filteredPreviewView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            captureButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            galleryButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            galleryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            galleryButton.widthAnchor.constraint(equalToConstant: 44),
            galleryButton.heightAnchor.constraint(equalToConstant: 44),
            
            flashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flashButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            flashButton.widthAnchor.constraint(equalToConstant: 44),
            flashButton.heightAnchor.constraint(equalToConstant: 44),
            
            f1Button.bottomAnchor.constraint(equalTo: galleryButton.topAnchor, constant: -30),
            f1Button.leadingAnchor.constraint(equalTo: galleryButton.leadingAnchor),
            f1Button.widthAnchor.constraint(equalToConstant: 40),
            f1Button.heightAnchor.constraint(equalToConstant: 40),
            
            f2Button.centerYAnchor.constraint(equalTo: f1Button.centerYAnchor),
            f2Button.leadingAnchor.constraint(equalTo: f1Button.trailingAnchor, constant: 15),
            f2Button.widthAnchor.constraint(equalToConstant: 40),
            f2Button.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
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
}

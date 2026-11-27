import Foundation
import UIKit

class GalleryCell: UICollectionViewCell {
    static let identifier = "GalleryCell"

    // MARK: - Views

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Indicador circular de seleção (visível apenas no modo de seleção).
    private let selectionIndicator: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "circle")
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        // Sombra para destacar sobre a imagem.
        iv.layer.shadowColor = UIColor.black.cgColor
        iv.layer.shadowOpacity = 0.5
        iv.layer.shadowOffset = CGSize(width: 0, height: 1)
        iv.layer.shadowRadius = 2
        return iv
    }()

    // MARK: - Estado

    var isInSelectionMode: Bool = false {
        didSet {
            selectionIndicator.isHidden = !isInSelectionMode
        }
    }

    var isSelectedItem: Bool = false {
        didSet {
            updateSelectionAppearance()
        }
    }

    // MARK: - Inicialização

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(selectionIndicator)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            selectionIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 22),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuração

    func configure(with image: UIImage) {
        imageView.image = image
    }

    private func updateSelectionAppearance() {
        if isSelectedItem {
            selectionIndicator.image = UIImage(systemName: "checkmark.circle.fill")
            selectionIndicator.tintColor = .systemBlue
        } else {
            selectionIndicator.image = UIImage(systemName: "circle")
            selectionIndicator.tintColor = .white
        }
    }

    // MARK: - Reuso

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        isInSelectionMode = false
        isSelectedItem = false
    }
}
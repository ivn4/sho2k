import UIKit
import QuickLook

// MARK: - PreviewItem
// Wrapper para QLPreviewItem, usado pelo QuickLook.
class PreviewItem: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    var previewItemTitle: String?

    init(previewItemURL: URL?, previewItemTitle: String? = nil) {
        self.previewItemURL = previewItemURL
        self.previewItemTitle = previewItemTitle
    }
}

// MARK: - GalleryViewController
// Tela de galeria em grade com suporte a seleção múltipla, compartilhamento
// e exclusão de fotos. Segue MVVM: dados no GalleryViewModel, UI aqui.
class GalleryViewController: UIViewController {

    // MARK: - Dependências

    private let viewModel: GalleryViewModel

    // MARK: - Views

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.dataSource = self
        cv.delegate = self
        cv.allowsMultipleSelection = true
        cv.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.identifier)
        cv.translatesAutoresizingMaskIntoConstraints = false

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        cv.refreshControl = refreshControl

        return cv
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Nenhuma foto salva ainda.\nTire uma foto na câmera para começar."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    // Barra inferior de ações (compartilhar / deletar), oculta por padrão.
    private lazy var bottomToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.isHidden = true
        return toolbar
    }()

    private lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(handleShare)
        )
        button.isEnabled = false
        return button
    }()

    private lazy var deleteButton: UIBarButtonItem = {
        // Ícone padrão de lixeira da Apple (redondo).
        let button = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(handleDelete)
        )
        button.tintColor = .systemRed
        button.isEnabled = false
        return button
    }()

    // MARK: - Inicialização

    init(viewModel: GalleryViewModel = GalleryViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Galeria"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(handleClose)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Selecionar",
            style: .plain,
            target: self,
            action: #selector(handleToggleSelection)
        )

        setupLayout()
        setupToolbar()
        bindViewModel()
        viewModel.fetchPhotos()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchPhotos()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
        view.addSubview(bottomToolbar)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomToolbar.topAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupToolbar() {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        bottomToolbar.items = [shareButton, flexibleSpace, deleteButton]
    }

    // MARK: - Data binding

    private func bindViewModel() {
        viewModel.didUpdatePhotos = { [weak self] in
            guard let self = self else { return }
            self.collectionView.reloadData()
            self.collectionView.refreshControl?.endRefreshing()
            self.updateEmptyState()
            self.updateToolbarState()
            self.updateSelectionButton()
        }
    }

    private func updateEmptyState() {
        let isEmpty = viewModel.numberOfItems == 0
        emptyLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }

    private func updateToolbarState() {
        let hasSelection = viewModel.hasSelection
        shareButton.isEnabled = hasSelection
        deleteButton.isEnabled = hasSelection

        if viewModel.isSelectionMode {
            deleteButton.accessibilityLabel = hasSelection
                ? "Deletar \(viewModel.selectedCount) foto(s)"
                : "Deletar"
            // Exibe o contador no título enquanto seleciona.
            title = hasSelection
                ? "\(viewModel.selectedCount) selecionada(s)"
                : "Selecionar fotos"
            bottomToolbar.isHidden = false
        } else {
            title = "Galeria"
            bottomToolbar.isHidden = true
        }
    }

    private func updateSelectionButton() {
        if viewModel.isSelectionMode {
            navigationItem.rightBarButtonItem?.title = "Cancelar"
        } else {
            navigationItem.rightBarButtonItem?.title = "Selecionar"
        }
    }

    // MARK: - Ações

    @objc private func handleClose() {
        dismiss(animated: true)
    }

    @objc private func handleRefresh() {
        viewModel.fetchPhotos()
    }

    @objc private func handleToggleSelection() {
        viewModel.toggleSelectionMode()
    }

    @objc private func handleShare() {
        let urls = viewModel.selectedURLs()
        guard !urls.isEmpty else { return }

        let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        // Evita crash em iPad (popover).
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = shareButton
        }
        present(activityVC, animated: true)
    }

    @objc private func handleDelete() {
        guard viewModel.hasSelection else { return }

        let alert = UIAlertController(
            title: "Excluir fotos",
            message: "Deseja excluir permanentemente \(viewModel.selectedCount) foto(s)?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Excluir", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteSelected()
        })
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension GalleryViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GalleryCell.identifier,
            for: indexPath
        ) as? GalleryCell else {
            return UICollectionViewCell()
        }

        if let item = viewModel.item(at: indexPath.item) {
            cell.configure(with: item.image)
        }

        // Sincroniza o estado de seleção da célula com o ViewModel.
        cell.isInSelectionMode = viewModel.isSelectionMode
        cell.isSelectedItem = viewModel.isSelected(indexPath.item)

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension GalleryViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let spacing: CGFloat = 2
        let insets: CGFloat = 2
        let columns: CGFloat = 3

        let totalSpacing = (columns - 1) * spacing + insets * 2
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / columns)

        return CGSize(width: itemWidth, height: itemWidth)
    }
}

// MARK: - QLPreviewControllerDataSource

extension GalleryViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return viewModel.numberOfItems
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let url = viewModel.item(at: index)?.url
        return PreviewItem(previewItemURL: url, previewItemTitle: "Foto")
    }
}

// MARK: - UICollectionViewDelegate

extension GalleryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard viewModel.isSelectionMode else {
            // Abre a foto em tela cheia via QuickLook (zoom, compartilhar, etc.).
            let previewController = QLPreviewController()
            previewController.dataSource = self
            previewController.currentPreviewItemIndex = indexPath.item
            present(previewController, animated: true)
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }

        viewModel.select(indexPath.item)
        if let cell = collectionView.cellForItem(at: indexPath) as? GalleryCell {
            cell.isSelectedItem = true
        }
        updateToolbarState()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard viewModel.isSelectionMode else { return }

        viewModel.deselect(indexPath.item)
        if let cell = collectionView.cellForItem(at: indexPath) as? GalleryCell {
            cell.isSelectedItem = false
        }
        updateToolbarState()
    }
}
import UIKit
#if canImport(PrefsHelper)
import PrefsHelper
#endif

/// При первом запуске просит ввести никнейм и сохраняет его в Keychain,
/// при следующих — показывает сохранённый никнейм.
final class ViewController: UIViewController {

    private let nicknameKey = "Nickname"

    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите ваш никнейм"
        textField.borderStyle = .roundedRect
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        return textField
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сохранить", for: .normal)
        button.addTarget(self, action: #selector(saveNickname), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI(nickname: KeychainHelper.get(key: nicknameKey))
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        nicknameTextField.delegate = self

        let stack = UIStackView(arrangedSubviews: [greetingLabel, nicknameTextField, saveButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }

    /// Показывает приветствие, если никнейм сохранён, иначе — поле ввода.
    private func updateUI(nickname: String?) {
        greetingLabel.text = nickname.map { "Ваш никнейм: \($0)" } ?? "Как вас зовут?"
        nicknameTextField.isHidden = nickname != nil
        saveButton.isHidden = nickname != nil
    }

    @objc private func saveNickname() {
        let nickname = nicknameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !nickname.isEmpty else {
            showMessage("Пожалуйста, введите никнейм.")
            return
        }
        guard KeychainHelper.set(key: nicknameKey, value: nickname) else {
            showMessage("Ошибка сохранения никнейма.")
            return
        }

        nicknameTextField.resignFirstResponder()
        updateUI(nickname: nickname)
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveNickname()
        return false
    }
}

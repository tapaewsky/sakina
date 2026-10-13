import SwiftUI

/// Квадратная карточка для «Поделиться» (1080×1080): только перевод и источник, внизу знак «س»
struct ShareCard: View {
    let verse: Verse

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Text(verse.text)
                .font(.system(size: 22, design: .serif))
                .lineSpacing(6)
                .minimumScaleFactor(0.5)
            Rectangle()
                .fill(Color.ink.opacity(0.25))
                .frame(width: 28, height: 1)
                .padding(.vertical, 18)
            Text(verse.source)
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundStyle(Color.ink.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            Text("س")
                .font(.custom("Amiri-Regular", size: 20))
                .foregroundStyle(Color.ink.opacity(0.35))
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.ink)
        .padding(.horizontal, 40)
        .padding(.top, 40)
        .padding(.bottom, 18)
        .frame(width: 360, height: 360)
        .background(Color.paper)
        .environment(\.colorScheme, .light)
    }

    @MainActor
    static func image(for verse: Verse) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCard(verse: verse))
        renderer.scale = 3
        return renderer.uiImage
    }
}

/// «Поделиться»: в мессенджеры уходит только текст — перевод и источник.
/// Картинку можно сохранить в «Фото» отдельной кнопкой в том же меню.
enum Share {
    @MainActor
    static func present(_ verse: Verse) {
        let text = "«\(verse.text)»\n\n— \(verse.source)"
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: [SaveCardActivity(verse: verse)])
        // Показываем системное меню напрямую — так оно само закрывается после отправки
        guard var top = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }
        controller.popoverPresentationController?.sourceView = top.view
        top.present(controller, animated: true)
    }
}

final class SaveCardActivity: UIActivity {
    private let verse: Verse

    init(verse: Verse) {
        self.verse = verse
        super.init()
    }

    override class var activityCategory: UIActivity.Category { .action }
    override var activityType: UIActivity.ActivityType? { .init("cam.sakina.saveCard") }
    override var activityTitle: String? { "Сохранить карточку" }
    override var activityImage: UIImage? { UIImage(systemName: "photo.badge.arrow.down") }
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool { true }

    override func perform() {
        MainActor.assumeIsolated {
            if let image = ShareCard.image(for: verse) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        activityDidFinish(true)
    }
}

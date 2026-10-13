import SwiftUI

extension Color {
    /// Тёплая бумага днём, глубокий тёмный — ночью
    static let paper = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.08, green: 0.08, blue: 0.07, alpha: 1)
        : UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1) })
    static let ink = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.93, green: 0.90, blue: 0.84, alpha: 1)
        : UIColor(red: 0.17, green: 0.15, blue: 0.12, alpha: 1) })
}

extension Verse {
    /// Аяты — шрифтом Мусхафа (Amiri Quran), хадисы — классическим насхом (Amiri)
    func arabicFont(_ size: CGFloat) -> Font {
        .custom(isAyah ? "AmiriQuran-Regular" : "Amiri-Regular", size: size)
    }
}

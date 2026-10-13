import SwiftUI

/// Первый запуск: одно предложение о приложении и включение напоминаний
struct OnboardingView: View {
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderCount") private var reminderCount = 3

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("س")
                .font(.custom("Amiri-Regular", size: 110))
            Text("Sakina")
                .font(.system(size: 34, design: .serif))
                .padding(.top, 4)
            Text("Аяты и хадисы, которые поддержат тебя в течение дня")
                .font(.system(.body, design: .serif))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
                .padding(.horizontal, 12)
            Spacer()

            VStack(spacing: 10) {
                Picker("В день", selection: $reminderCount) {
                    ForEach(Reminder.counts, id: \.self) { Text("\($0) в день").tag($0) }
                }
                .pickerStyle(.segmented)
                Text("Сколько напоминаний присылать")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 28)

            Button {
                Task {
                    reminderOn = await Reminder.schedule(count: reminderCount)
                    finish()
                }
            } label: {
                Text("Включить напоминания")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.paper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.ink, in: .capsule)
            }
            Button("Не сейчас") { finish() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 14)
        }
        .foregroundStyle(Color.ink)
        .tint(Color.ink)
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(Color.paper.ignoresSafeArea())
    }

    private func finish() {
        withAnimation(.smooth(duration: 0.7)) { onboarded = true }
    }
}

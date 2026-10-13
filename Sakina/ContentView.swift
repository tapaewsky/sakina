import SwiftUI

struct ContentView: View {
    @State private var verse = Verse.ofDay()
    @State private var mood: Mood?
    @State private var showMoods = false
    @State private var moodSheetHeight: CGFloat = 360
    @State private var reminderSheetHeight: CGFloat = 240
    @State private var showReminder = false

    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderCount") private var reminderCount = 3
    @AppStorage("onboarded") private var onboarded = false
    @ObservedObject private var router = Router.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            main
                .scaleEffect(onboarded ? 1 : 0.96)
                .opacity(onboarded ? 1 : 0)
            if !onboarded {
                // Первый экран плавно растворяется, а главный экран мягко проявляется под ним
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
                    .zIndex(1)
            }
        }
        .background(Color.paper.ignoresSafeArea())
    }

    private var main: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            VerseCard(verse: verse)
                .id(verse.id)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 10)),
                    removal: .opacity.combined(with: .offset(y: -10))
                ))
            Spacer()
            footer
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(Color.paper.ignoresSafeArea())
        .sheet(isPresented: $showMoods) {
            MoodPicker(height: $moodSheetHeight) { picked in
                mood = picked
                show(Verse.random(for: picked, excluding: verse))
            }
            .presentationDetents([.height(moodSheetHeight)])
        }
        .sheet(isPresented: $showReminder) {
            ReminderSheet(isOn: $reminderOn, count: $reminderCount, height: $reminderSheetHeight)
                .presentationDetents([.height(reminderSheetHeight)])
        }
        // Нажатие на уведомление или виджет открывает именно этот текст
        .onReceive(router.$verseID.compactMap { $0 }) { open($0) }
        .onOpenURL { url in
            if url.scheme == "sakina", let id = Int(url.lastPathComponent) { open(id) }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:     Task { await Reminder.refreshFromSettings() }
            case .background: Reminder.requestBackgroundRefresh()
            default:          break
            }
        }
    }

    private var header: some View {
        HStack {
            if let mood {
                Button {
                    self.mood = nil
                    show(Verse.ofDay())
                } label: {
                    Label(mood.title, systemImage: "xmark")
                        .labelStyle(TrailingIconLabel())
                }
            } else {
                Text(Date.now.formatted(.dateTime.day().month(.wide)))
            }
            Spacer()
            Button { showReminder = true } label: {
                Image(systemName: reminderOn ? "bell.fill" : "bell")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var footer: some View {
        HStack {
            Button("Как ты сейчас?") { showMoods = true }
                .font(.body.weight(.medium))
            Spacer()
            Button { Share.present(verse) } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .padding(.trailing, 20)
            Button {
                show(Verse.random(for: mood, excluding: verse))
            } label: {
                Image(systemName: "arrow.forward")
            }
        }
        .foregroundStyle(Color.ink)
        .font(.title3)
    }

    private func show(_ next: Verse) {
        withAnimation(.smooth(duration: 0.5)) { verse = next }
    }

    private func open(_ id: Int) {
        router.verseID = nil
        guard let target = Verse.all.first(where: { $0.id == id }) else { return }
        mood = nil
        show(target)
    }
}

struct VerseCard: View {
    let verse: Verse

    var body: some View {
        VStack(spacing: 28) {
            Text(verse.arabic)
                .font(verse.arabicFont(28))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.layoutDirection, .rightToLeft)
            Rectangle()
                .fill(Color.ink.opacity(0.25))
                .frame(width: 32, height: 1)
            Text(verse.text)
                .font(.system(.title3, design: .serif))
                .lineSpacing(6)
            SourceLink(verse: verse)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.ink)
        .frame(maxWidth: .infinity)
    }
}

/// Источник под текстом: нажатие открывает аят на quran.com или хадис на sunnah.com
struct SourceLink: View {
    let verse: Verse

    var body: some View {
        let label = HStack(spacing: 4) {
            Text(verse.source)
            if verse.link != nil {
                Image(systemName: "arrow.up.right").imageScale(.small)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)

        if let url = verse.link {
            Link(destination: url) { label }
        } else {
            label
        }
    }
}

struct MoodPicker: View {
    @Binding var height: CGFloat
    let onPick: (Mood) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Как ты сейчас?")
                .font(.system(.title2, design: .serif))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Mood.allCases) { mood in
                    Button {
                        onPick(mood)
                        dismiss()
                    } label: {
                        Text(mood.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.ink.opacity(0.06), in: .rect(cornerRadius: 12))
                    }
                }
            }
            .foregroundStyle(Color.ink)
        }
        .padding(.horizontal, 28)
        .padding(.top, 32)
        .padding(.bottom, 12)
        // Сообщаем свою высоту — шторка подстраивается под содержимое, без пустоты снизу
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .background(Color.paper.ignoresSafeArea())
    }
}

struct ReminderSheet: View {
    @Binding var isOn: Bool
    @Binding var count: Int
    @Binding var height: CGFloat
    @State private var denied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Напоминания")
                .font(.system(.title2, design: .serif))
            Toggle("Присылать аяты и хадисы", isOn: $isOn)
            VStack(alignment: .leading, spacing: 8) {
                Picker("В день", selection: $count) {
                    ForEach(Reminder.counts, id: \.self) { Text("\($0) в день").tag($0) }
                }
                .pickerStyle(.segmented)
                Text(Reminder.hours(for: count).map { "\($0):00" }.joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .disabled(!isOn)
            .opacity(isOn ? 1 : 0.4)
            if denied {
                Text("Разрешите уведомления в Настройках")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .tint(Color.ink)
        .padding(.horizontal, 28)
        .padding(.top, 32)
        .padding(.bottom, 12)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .background(Color.paper.ignoresSafeArea())
        .onChange(of: isOn) { _, _ in update() }
        .onChange(of: count) { _, _ in update() }
    }

    private func update() {
        guard isOn else { Reminder.cancel(); return }
        Task {
            let ok = await Reminder.schedule(count: count)
            if !ok { isOn = false; denied = true }
        }
    }
}

struct TrailingIconLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}

#Preview { ContentView() }

import SwiftUI
import Combine
import RealmSwift

/// Shows the selected pet and a Feed button.
/// Image assets: add the exported PNGs to Assets.xcassets as
/// ember_idle_1…4, ember_happy, ember_sad (same for mochi / pip).
/// Idle frames cycle every 0.18s; hungry pets show the sad sprite.
struct PetView: View {
    @StateObject private var petService = PetService.shared
    @ObservedResults(User.self) var users
    @State private var idleFrame = 1
    @State private var showHappy = false
    @State private var feedMessage: String?

    private let idleTimer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()

    private var user: User? { users.first }

    private var mood: PetMood {
        if petService.isHungry { return .sad }
        if showHappy { return .happy }
        return .idle
    }

    private var imageName: String {
        petService.petType.imageName(mood: mood, idleFrame: idleFrame)
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Питомец", selection: Binding(
                get: { petService.petType },
                set: { petService.selectPet($0) }
            )) {
                ForEach(PetType.allCases) { type in
                    Text(type.shortName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            Image(imageName)
                .interpolation(.nearest)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)

            Text(petService.petType.displayName)
                .font(.headline)

            if petService.isHungry {
                Text("Питомец голоден — показывается грустный спрайт")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Сыт ещё \(petService.timeUntilHungryText) • Бонус к XP: +\(PetService.xpBonusPercent)%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                feed()
            } label: {
                Text("Покормить — \(PetService.feedCost) P")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.profile.theme.accent))
            .disabled((user?.pesetas ?? 0) < PetService.feedCost)

            Text("Баланс: \(user?.pesetas ?? 0) P")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let feedMessage {
                Text(feedMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onReceive(idleTimer) { _ in
            if mood == .idle { idleFrame = idleFrame % 4 + 1 }
        }
    }

    private func feed() {
        switch petService.feed() {
        case .success:
            showHappy = true
            feedMessage = "Вкусно! +5% к XP на 24 часа."
            Haptics.success()
            SoundService.coin()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showHappy = false }
        case .notEnoughPesetas:
            feedMessage = "Не хватает песет: нужно \(PetService.feedCost) P."
            Haptics.error()
        case .noUser:
            feedMessage = "Сначала создайте профиль."
            Haptics.error()
        }
    }
}

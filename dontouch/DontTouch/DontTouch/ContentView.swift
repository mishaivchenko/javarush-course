import SwiftUI
#if os(macOS)
import SafariServices
#endif

struct ContentView: View {
    @AppStorage("extensionEnabled") private var extensionEnabled = false
    @State private var safariExtensionEnabled = false
    @State private var showSafariPrefs = false
    @State private var showResetConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            // App header
            VStack(spacing: 8) {
                Image(systemName: "hand.raised.slash.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                    .symbolEffect(.pulse, options: .repeating)

                Text("Don't Touch")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Safari NSFW Content Blocker")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            Divider()

            // Status section with interactive toggle
            Toggle(isOn: $extensionEnabled) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(extensionEnabled ? .green : .secondary)
                    Text("Extension Active")
                        .font(.headline)
                }
            }
            .toggleStyle(.switch)
            .padding(.horizontal, 4)

            if safariExtensionEnabled {
                if extensionEnabled {
                    Text("Don't Touch is blocking NSFW content on all websites.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Toggle the switch above to activate content blocking.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Enable the extension in Safari Settings first (use the button below).")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                Text("Setup Instructions")
                    .font(.headline)

                InstructionRow(number: 1, text: "Open Safari → Settings → Extensions")
                InstructionRow(number: 2, text: "Enable \"Don't Touch Blocker\"")
                InstructionRow(number: 3, text: "Allow extension on all websites")
                InstructionRow(number: 4, text: "Visit any page to test — look for the 🚫 DT badge")
            }
            .padding()
            #if os(macOS)
            .background(Color(.controlBackgroundColor))
            #else
            .background(Color(.systemGray6))
            #endif
            .cornerRadius(10)

            // Buttons
            Button(action: openSafariPreferences) {
                Label("Open Safari Extension Preferences", systemImage: "safari")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)

            Button(action: { showResetConfirmation = true }) {
                Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
        }
        .padding(24)
        #if os(macOS)
        .frame(width: 400)
        .fixedSize()
        #endif
        .alert("Reset Onboarding", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
                exit(0)
            }
        } message: {
            Text("This will reset the onboarding screen and quit the app. Reopen to see the welcome screen.")
        }
        .onAppear {
            checkExtensionStatus()
        }
    }

    private func openSafariPreferences() {
        #if os(macOS)
        SFSafariApplication.showPreferencesForExtension(
            withIdentifier: "com.yourname.donttouch.extension"
        )
        #endif
    }

    private func checkExtensionStatus() {
        #if os(macOS)
        SFSafariExtensionManager.getStateOfSafariExtension(
            withIdentifier: "com.yourname.donttouch.extension"
        ) { state, error in
            DispatchQueue.main.async {
                safariExtensionEnabled = state?.isEnabled ?? false
            }
        }
        #endif
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(.body)
        }
    }
}

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.raised.slash.fill")
                .font(.system(size: 72))
                .foregroundColor(.red)
                .symbolEffect(.pulse, options: .repeating)

            Text("Don't Touch")
                .font(.system(size: 36, weight: .bold))

            Text("Your privacy-first Safari extension that detects and blurs NSFW content using on-device AI.\n\n100% private — no data leaves your device.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: onComplete) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)

            Text("You can access Safari Extension settings later from the app.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        #if os(macOS)
        .frame(width: 420, height: 520)
        .fixedSize()
        #endif
    }
}

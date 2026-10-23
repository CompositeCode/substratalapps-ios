import SwiftUI
import SubstratalCore
import SubstratalUI

/// AUTH-01 Sign in. Embedded login is allowed for first-party apps (Trust Model); SSO and passkeys stay
/// hidden behind their flags until the API supports them (OPEN-QUESTIONS #4).
struct SignInView: View {
    @Environment(SessionModel.self) private var session
    @Environment(\.appConfiguration) private var configuration
    @Environment(\.openURL) private var openURL
    @Environment(\.palette) private var palette
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image("Brand/BrandLockup")
                        .resizable().scaledToFit()
                        .frame(maxHeight: 56)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                        .accessibilityLabel("Substratal Apps")
                        .listRowBackground(Color.clear)
                }
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit(signIn)
                } footer: {
                    if let error = session.lastError {
                        Label(error.userMessage, systemImage: "exclamationmark.circle").foregroundStyle(Color.danger)
                    }
                }
                Section {
                    Button(action: signIn) {
                        HStack {
                            Spacer()
                            if session.isWorking { ProgressView() } else { Text("Sign in").bold() }
                            Spacer()
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || session.isWorking)
                    NavigationLink("Forgot password?", value: Route(.auth05))
                    NavigationLink("Create an account", value: Route(.auth03))
                }
                Section {
                    LabeledContent("Server", value: configuration.environment.displayName)
                    Button("Help signing in", systemImage: "questionmark.circle") { openURL(HelpCenter.url(for: .auth01)) }
                } footer: {
                    Text("API \(configuration.baseURL.host() ?? "") · Substratal-Version \(APIConfiguration.apiVersion)")
                        .font(.caption.monospaced())
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background)
            .navigationDestination(for: Route.self) { ScreenPlaceholder($0.screen, params: $0.params) }
        }
    }

    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else { return }
        Task { await session.signIn(email: email, password: password) }
    }
}

/// AUTH-02 Two-factor challenge.
struct TwoFactorView: View {
    @Environment(SessionModel.self) private var session
    @State private var code = ""
    @FocusState private var codeFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("6-digit code", text: $code)
                        .textContentType(.oneTimeCode)
                        .keyboardType(.numberPad)
                        .font(.title2.monospacedDigit())
                        .focused($codeFocused)
                        .onSubmit(verify)
                } header: {
                    Text("Enter the code from your authenticator app")
                } footer: {
                    if let error = session.lastError {
                        Label(error.userMessage, systemImage: "exclamationmark.circle").foregroundStyle(Color.danger)
                    }
                }
                Section {
                    Button("Verify", action: verify).disabled(code.count != 6 || session.isWorking)
                    Button("Use a recovery code instead") {}
                        .disabled(true)
                }
            }
            .navigationTitle("Two-factor")
            .onAppear { codeFocused = true }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { session.cancelMFA() } }
            }
        }
    }

    private func verify() {
        Task { await session.verifyMFA(code: code) }
    }
}

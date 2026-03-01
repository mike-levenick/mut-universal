import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = LoginViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                VStack(spacing: 4) {
                    Text("MUT")
                        .font(.largeTitle.bold())

                    Text("Mass Update Tool for Jamf Pro")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Form {
                    Section {
                        TextField("Jamf Pro URL", text: $viewModel.serverURL)
                            .textContentType(.URL)
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled()

                        TextField("Client ID", text: $viewModel.clientID)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif

                        SecureField("Client Secret", text: $viewModel.clientSecret)
                    }

                    Section {
                        Toggle("Remember me", isOn: $viewModel.rememberMe)
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
                .frame(maxHeight: 260)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        guard let apiClient = appViewModel.apiClient else {
                            viewModel.errorMessage = "API client not configured."
                            return
                        }
                        let success = await viewModel.authenticate(using: apiClient)
                        if success {
                            appViewModel.isAuthenticated = true
                            appViewModel.navigateTo(.csvImport)
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
            }
            .frame(maxWidth: 400)
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.loadSavedCredentials()
        }
    }
}

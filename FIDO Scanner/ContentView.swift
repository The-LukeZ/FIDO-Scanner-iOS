//
//  ContentView.swift
//  FIDO Scanner
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isScanning = false
    @State private var scannedCode: String?
    @State private var showFIDOAlert = false
    @State private var fidoURL: URL?
    @State private var cameraPermissionDenied = false
    @State private var showManualInput = false
    @State private var manualInput = ""
    
    // Check if running in simulator
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if isScanning && !isSimulator {
                    QRScannerView(scannedCode: $scannedCode, isScanning: $isScanning)
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        Button(action: {
                            isScanning = false
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 50)
                    }
                } else {
                    VStack(spacing: 30) {
                        Image(systemName: "qrcode.viewfinder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .foregroundColor(.blue)
                        
                        Text("FIDO Passkey Scanner")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Scan QR codes for cross-device passkey authentication")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            if isSimulator {
                                showManualInput = true
                            } else {
                                checkCameraPermissionAndScan()
                            }
                        }) {
                            Label(isSimulator ? "Enter Test Code" : "Scan QR Code",
                                  systemImage: isSimulator ? "keyboard" : "camera.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        
                        if isSimulator {
                            Text("⚠️ Simulator Mode: Camera not available")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Passkey Auth")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: scannedCode) { _, newValue in
                if let code = newValue {
                    handleScannedCode(code)
                }
            }
            .sheet(isPresented: $showManualInput) {
                ManualInputView(manualInput: $manualInput, onSubmit: { code in
                    handleScannedCode(code)
                    showManualInput = false
                })
            }
            .alert("Open with Password Manager?", isPresented: $showFIDOAlert) {
                Button("Open", role: nil) {
                    if let url = fidoURL {
                        openURL(url)
                    }
                }
                Button("Cancel", role: .cancel) {
                    resetScanner()
                }
            } message: {
                Text("This is a FIDO cross-device authentication request. Open it with your password manager to complete passkey authentication.")
            }
            .alert("Camera Access Required", isPresented: $cameraPermissionDenied) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable camera access in Settings to scan QR codes.")
            }
        }
    }
    
    private func checkCameraPermissionAndScan() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isScanning = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        isScanning = true
                    } else {
                        cameraPermissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            cameraPermissionDenied = true
        @unknown default:
            cameraPermissionDenied = true
        }
    }
    
    private func handleScannedCode(_ code: String) {
        if code.uppercased().hasPrefix("FIDO:/") {
            if let url = URL(string: code) {
                fidoURL = url
                showFIDOAlert = true
            } else {
                resetScanner()
            }
        } else {
            resetScanner()
        }
    }
    
    private func openURL(_ url: URL) {
        UIApplication.shared.open(url) { success in
            DispatchQueue.main.async {
                if !success {
                    print("Failed to open URL: \(url)")
                }
                resetScanner()
            }
        }
    }
    
    private func resetScanner() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            scannedCode = nil
            fidoURL = nil
            manualInput = ""
        }
    }
}

// Manual input view for simulator testing
struct ManualInputView: View {
    @Binding var manualInput: String
    @Environment(\.dismiss) var dismiss
    var onSubmit: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter FIDO URI for testing")
                    .font(.headline)
                    .padding(.top)
                
                TextField("FIDO:/...", text: $manualInput)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                Text("Example:\nFIDO:/1234567890ABCDEF")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    onSubmit(manualInput)
                }) {
                    Text("Submit")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(manualInput.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(manualInput.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Test Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

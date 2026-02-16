//
//  QRScannerView.swift
//  FIDO Scanner
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        var parent: QRScannerView
        
        init(_ parent: QRScannerView) {
            self.parent = parent
        }
        
        func didScanQRCode(_ code: String) {
            parent.scannedCode = code
            parent.isScanning = false
        }
        
        func didFailWithError(_ error: Error) {
            print("Scanning failed: \(error.localizedDescription)")
            parent.isScanning = false
        }
    }
}

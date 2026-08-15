import SwiftUI
import VisionKit
import UIKit

struct CaptureView: View {
    @Binding var isPresented: Bool
    @State private var scannedImages: [UIImage] = []
    @State private var showingConfirm = false
    @State private var draft: ExpenseDraft?

    var body: some View {
        DocumentScanner(images: $scannedImages, onCancel: { isPresented = false })
            .ignoresSafeArea()
            .onChange(of: scannedImages) { _, images in
                guard !images.isEmpty else { return }
                Task {
                    draft = await ReceiptTextRecognizer.draft(from: images)
                    showingConfirm = true
                }
            }
            .fullScreenCover(isPresented: $showingConfirm) {
                if let draft {
                    NavigationStack {
                        ConfirmExpenseView(draft: draft, images: scannedImages) {
                            isPresented = false
                        }
                    }
                }
            }
    }
}

struct DocumentScanner: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner

        init(_ parent: DocumentScanner) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var pages: [UIImage] = []
            for pageIndex in 0..<scan.pageCount {
                pages.append(scan.imageOfPage(at: pageIndex))
            }
            parent.images = pages
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onCancel()
        }
    }
}

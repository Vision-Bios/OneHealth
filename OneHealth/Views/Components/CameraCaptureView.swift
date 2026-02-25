import AVFoundation
import SwiftUI
import Combine

final class CameraCaptureController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isReady = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var lastImage: UIImage?

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()

    func configure() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                guard granted else { return }
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo

                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device) else {
                    self.session.commitConfiguration()
                    return
                }

                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
                if self.session.canAddOutput(self.output) {
                    self.session.addOutput(self.output)
                }

                self.session.commitConfiguration()
                self.isReady = true
            }
        }
    }

    func start() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    func capture() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        output.capturePhoto(with: settings, delegate: self)
    }

    func toggleFlash() {
        flashMode = (flashMode == .off) ? .on : .off
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.lastImage = image
        }
    }
}

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller = CameraCaptureController()
    @Binding var selectedImage: UIImage?

    var body: some View {
        ZStack {
            CameraPreview(session: controller.session)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                    Spacer()
                    Button {
                        controller.toggleFlash()
                    } label: {
                        Image(systemName: controller.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)

                Spacer()

                Button {
                    controller.capture()
                } label: {
                    Circle()
                        .stroke(Color.white, lineWidth: 6)
                        .frame(width: 76, height: 76)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            controller.configure()
        }
        .onChange(of: controller.isReady) { _, ready in
            if ready {
                controller.start()
            }
        }
        .onDisappear {
            controller.stop()
        }
        .onChange(of: controller.lastImage) { _, newImage in
            guard let image = newImage else { return }
            selectedImage = image
            dismiss()
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? PreviewView else { return }
        view.previewLayer.session = session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as? AVCaptureVideoPreviewLayer ?? AVCaptureVideoPreviewLayer()
        }
    }
}

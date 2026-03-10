//
//  Untitled.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/15/25.
//

import AVFoundation
import Foundation
import UIKit

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage? = nil
    @Published var captureSession: AVCaptureSession?
    @Published var photoOutput: AVCapturePhotoOutput?

    func setupAndStartSession(useFrontCamera: Bool) {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: useFrontCamera ? .front : .back) else { return }
        
        captureSession.sessionPreset = .photo
        
        do {
            try videoCaptureDevice.lockForConfiguration()

            if videoCaptureDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoCaptureDevice.focusMode = .continuousAutoFocus
            } else if videoCaptureDevice.isFocusModeSupported(.autoFocus) {
                videoCaptureDevice.focusMode = .autoFocus
            }

            if videoCaptureDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoCaptureDevice.exposureMode = .continuousAutoExposure
            } else if videoCaptureDevice.isExposureModeSupported(.autoExpose) {
                videoCaptureDevice.exposureMode = .autoExpose
            }

            // Optional: smoother changes, if supported
            if videoCaptureDevice.isSmoothAutoFocusSupported {
                videoCaptureDevice.isSmoothAutoFocusEnabled = true
            }

            videoCaptureDevice.unlockForConfiguration()
        } catch {
            print("Could not lock device for configuration: \(error)")
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            print("Error setting up camera input: \(error.localizedDescription)")
            return
        }

        // Add photo output
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        // Start the session on a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }

    func stopSession() {
        captureSession?.stopRunning()
    }

    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        let photoSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    // AVCapturePhotoCaptureDelegate method
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        if let imageData = photo.fileDataRepresentation(), let capturedImage = UIImage(data: imageData) {
            DispatchQueue.main.async {
                self.capturedImage = capturedImage
            }
        }
    }
}

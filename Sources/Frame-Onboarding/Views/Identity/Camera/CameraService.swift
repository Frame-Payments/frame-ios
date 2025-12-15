//
//  Untitled.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 12/15/25.
//

import AVFoundation
import Foundation
import UIKit

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage? = nil
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?

    func setupAndStartSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }

        // Configure session preset
        captureSession.sessionPreset = .photo // or .high

        // Add device input
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
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

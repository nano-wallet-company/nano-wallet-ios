//
//  ScannerViewContoller.swift
//  Raiblocks
//
//  Created by Zack Shapiro on 12/8/17.
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

import AVFoundation
import UIKit

import Cartography
import ReactiveSwift
import Result


class ScannerViewContoller: UIViewController {

    weak var label: UILabel?

    typealias AVCameraScanningCompletionBlock = (_ qrCode: String) -> Void
    var scanningCompletionBlock: AVCameraScanningCompletionBlock?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)

        if captureSession?.isRunning == false {
            self.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }

    override var prefersStatusBarHidden: Bool { return true }

    private func createOverlay(view: UIView, at: CGPoint) {
        let background = UIView(frame: view.frame)
        background.backgroundColor = UIColor.black.withAlphaComponent(0.60)
        view.addSubview(background)

        let width = view.bounds.width * 0.70
        let innerFrame = CGRect(x: ((view.bounds.width - width) / 2), y: ((view.bounds.height - width) / 2), width: width, height: width)
        let cutout = UIBezierPath(roundedRect: innerFrame, cornerRadius: 16)

        let path = UIBezierPath(roundedRect: background.frame, cornerRadius: 0)
        path.append(cutout)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = kCAFillRuleEvenOdd

        let borderLayer = CAShapeLayer()
        borderLayer.path = cutout.cgPath
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 10
        background.layer.addSublayer(borderLayer)

        background.layer.mask = maskLayer

        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissCamera))
        gestureRecognizer.direction = .down
        view.addGestureRecognizer(gestureRecognizer)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        checkDeviceAuthorizationStatus()

        self.captureSession = AVCaptureSession()

        guard
            let videoCaptureDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice)
            else { return }

        let metadataOutput = AVCaptureMetadataOutput()

        guard captureSession.canAddInput(videoInput), captureSession.canAddOutput(metadataOutput) else { return showNoCameraAlert() }

        captureSession.addInput(videoInput)

        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.aztec, .qr]

        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        createOverlay(view: view, at: CGPoint(x: 250, y: 250))

        let dismiss = UIButton()
        dismiss.setImage(UIImage(named: "dismissX"), for: .normal)
        dismiss.setTitleColor(.white, for: .normal)
        dismiss.setBackgroundColor(color: .clear, forState: .normal)
        dismiss.addTarget(self, action: #selector(dismissCamera), for: .touchUpInside)
        view.addSubview(dismiss)
        constrain(dismiss) {
            $0.top == $0.superview!.top + CGFloat(24)
            $0.left == $0.superview!.left + CGFloat(24)
        }

        let label = UILabel()
        label.font = Styleguide.Fonts.nunitoRegular.font(ofSize: 20)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        view.addSubview(label)
        constrain(label) {
            $0.centerX == $0.superview!.centerX
            $0.top == $0.superview!.top + CGFloat(100)
            $0.width == $0.superview!.width * CGFloat(0.7)
        }
        self.label = label
    }

    func startRunning() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func dismissCamera() {
        return dismiss(animated: true, completion: nil)
    }

    func showNoCameraAlert() {
        let ac = UIAlertController(title: "Uh oh!", message: "It looks like your phone is missing a camera. Scanning isn't supported on phones without cameras.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Okay", style: .default))
        present(ac, animated: true)

        captureSession = nil
    }

    func checkDeviceAuthorizationStatus() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                let ac = UIAlertController(title: "Uh oh!", message: "Nano Wallet doesn't have permission to use the camera.\n\nPlease turn on camera settings under Nano Wallet preferences.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Take Me to Settings", style: .default) { _ in
                    UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                })
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

                self.present(ac, animated: true)
            }
        }
    }

    func startScanning(complete: AVCameraScanningCompletionBlock?) {
        self.scanningCompletionBlock = complete
    }

    func qrCodeProducer() -> SignalProducer<String, NoError> {
        return SignalProducer<String, NoError> { [weak self] observer, disposable in
                self?.startScanning { observer.send(value: $0) }
            }
            .skipRepeats()
            .observe(on: UIScheduler())
    }

}


extension ScannerViewContoller: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let qrcode = metadataObjects
            .filter({ $0.type == .qr || $0.type == .aztec }).first
            .flatMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }) {

            scanningCompletionBlock?(qrcode)
        }
    }

}

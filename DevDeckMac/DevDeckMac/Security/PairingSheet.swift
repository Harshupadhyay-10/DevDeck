//
//  PairingSheet.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 29/10/2026.
//

import DevDeckKit
import SwiftUI

struct PairingSheet: View {
    let listener: PairingListener
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Connect to Device")
                .font(.title2.bold())

            switch listener.status {
            case .idle:
                ProgressView()
            case .waiting:
                qrAndPIN
                ProgressView(listener.lastEvent)
            case .paired(let name):
                Label("Paired with \(name)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            case .failed(let message):
                Label(message, systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
            }

            Button(listener.status == .waiting ? "Cancel" : "Done") {
                listener.stop()
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(32)
        .frame(width: 360)
        .onAppear { listener.start() }
    }

    @ViewBuilder
    private var qrAndPIN: some View {
        if let payload = listener.qrPayload,
           let data = try? JSONEncoder().encode(payload),
           let image = QRCodeGenerator.image(for: data) {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .frame(width: 200, height: 200)
        }

        VStack(spacing: 4) {
            Text("Scan with the Dev Deck app, or enter this PIN:")
                .foregroundStyle(.secondary)
            Text(listener.pin)
                .font(.system(.title, design: .monospaced).weight(.semibold))
        }
    }
}

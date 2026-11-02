//
//  PairingView.swift
//  DevDeckIOS
//
//  Created by Harsh Upadhyay on 29/10/2026.
//

import DevDeckKit
import SwiftUI

struct PairingView: View {
    @State private var client: PairingClient
    @State private var showingScanner = false
    @State private var selectedMacServiceName: String?
    @State private var pinEntry = ""
    @Environment(\.dismiss) private var dismiss

    init() {
        let macStore = PairedDeviceStore(service: PhoneIdentity.pairedMacsService)
        _client = State(initialValue: PairingClient(macStore: macStore))
    }

    var body: some View {
        NavigationStack {
            Form {
                statusSection

                Section("Scan") {
                    Button("Scan QR Code") {
                        showingScanner = true
                    }
                }

                Section("Or Enter PIN") {
                    if client.discoveredMacs.isEmpty {
                        HStack {
                            ProgressView()
                            Text("Looking for nearby Macs...")
                        }
                    } else {
                        Picker("Mac", selection: $selectedMacServiceName) {
                            Text("Select a Mac").tag(String?.none)
                            ForEach(client.discoveredMacs, id: \.self) { name in
                                Text(name).tag(String?.some(name))
                            }
                        }
                    }
                    TextField("6-digit PIN", text: $pinEntry)
                        .keyboardType(.numberPad)
                    Button("Pair") {
                        guard let selectedMacServiceName else { return }
                        client.pair(serviceName: selectedMacServiceName, pin: pinEntry)
                    }
                    .disabled(selectedMacServiceName == nil || pinEntry.count != 6)
                }
            }
            .navigationTitle("Pair with Mac")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { client.startBrowsing() }
            .onDisappear { client.stopBrowsing() }
            .fullScreenCover(isPresented: $showingScanner) {
                QRScannerView { scanned in
                    showingScanner = false
                    client.pair(qrString: scanned)
                }
                .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch client.status {
        case .paired(let name):
            Section {
                Label("Paired with \(name)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        case .failed(let message):
            Section {
                Label(message, systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
            }
        case .connecting(let step):
            Section {
                HStack {
                    ProgressView()
                    Text(step)
                }
            }
        case .idle, .browsing:
            EmptyView()
        }
    }
}

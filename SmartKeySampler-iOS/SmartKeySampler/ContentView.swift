//
//  ContentView.swift
//  SmartKeySampler
//
//  Created by yuji on 2023/08/12.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    Text(bleManager.logText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 400, alignment: .leading)
                .background(
                    Color.gray,
                    in: RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 3)
                )

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("接続状態： " + (bleManager.isConnected ? "接続" : "未接続"))
                        Text("施錠状態： " + (bleManager.isKeyLocked ? "施錠" : "開錠"))
                    }
                    HStack(spacing: 40) {
                        Button {
                            bleManager.scan()
                        } label: {
                            Text("接続")
                        }
                        .disabled(bleManager.isConnected)
                        Button {
                            bleManager.disconnectPeripheral()
                        } label: {
                            Text("切断")
                        }
                        .disabled(!bleManager.isConnected)
                        Button {
                            bleManager.writeDataToBLEDevice()
                        } label: {
                            Text("施錠")
                        }
                        .disabled(!bleManager.isConnected)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("SmartKeySampler")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

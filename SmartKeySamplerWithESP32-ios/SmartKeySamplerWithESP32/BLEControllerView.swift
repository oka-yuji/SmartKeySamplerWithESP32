//
//  BLEControllerView.swift
//  SmartKeySamplerWithESP32
//
//  Created by oka yuuji on 2022/10/17.
//

import SwiftUI

struct BLEControllerView: View {
    @StateObject var bleModel = BLEModel()
    var body: some View {
        VStack {
            HStack {
                Text("ESP32 BLE Sampler")
                    .font(.title.bold())
                    .padding(.top)
                Spacer()
            }
            ScrollView {
                VStack {
                    HStack {
                        Text(bleModel.logText)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            .frame(width: 360, height: 400, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 3)
            )
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(bleModel.connectStateLabel)
                        HStack {
                            Text("鍵状態： ")
                            Text(bleModel.isWriteState ? "解錠中" : "施錠中")
                                .foregroundColor(bleModel.isWriteState ? .blue : .red)
                        }
                    }
                    Spacer()
                }
                HStack {
                    Button {
                        bleModel.scan()
                    } label: {
                        Text("接続")
                            .padding(.vertical)
                            .frame(width: 100)
                            .background(
                                Capsule()
                                    .stroke(lineWidth: 3)
                                    .foregroundColor(.gray)
                            )
                    }
                    .disabled(!bleModel.isDisabledConnectButton)
                    Button {
                        bleModel.disconnectPeripheral()
                    } label: {
                        Text("切断")
                            .padding(.vertical)
                            .frame(width: 100)
                            .background(
                                Capsule()
                                    .stroke(lineWidth: 3)
                                    .foregroundColor(.gray)
                            )
                    }
                    .disabled(!bleModel.isDisabledDisConnectButton)
                    Button {
                        bleModel.isWriteState.toggle()
                        let strData : String = bleModel.isWriteState ? "1" : "0"
                        let data : Data = strData.data(using: .utf8)!
                        bleModel.sendData(data: data)
                    } label: {
                        Text("書込")
                            .padding(.vertical)
                            .frame(width: 100)
                            .background(
                                Capsule()
                                    .stroke(lineWidth: 3)
                                    .foregroundColor(.gray)
                            )
                    }
                    .disabled(!bleModel.isDisabledWriteButton)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
struct BLEControllerView_Previews: PreviewProvider {
    static var previews: some View {
        BLEControllerView()
    }
}

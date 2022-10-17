//
//  BLEModel.swift
//  SmartKeySamplerWithESP32
//
//  Created by oka yuuji on 2022/10/17.
//

import SwiftUI
import CoreBluetooth

class BLEModel: NSObject, ObservableObject {
    @Published var logText = ""
    @Published var connectStateLabel = "接続状態：未接続"
    @Published var isDisabledConnectButton = true
    @Published var isDisabledDisConnectButton = false
    @Published var isDisabledWriteButton = false
    @Published var isWriteState = false
    
    private var centralManager: CBCentralManager!
    private var cbPeripheral: CBPeripheral? = nil
    private var writeCharacteristic: CBCharacteristic? = nil
    // 接続する時に使用するName
    let bleLoacalName = "ESP_TEST_DEVICE_LOCAL_NAME"
    // 接続時に用いるServiceUUID
    let bleServiceUUID = CBUUID(string: "3c3996e0-4d2c-11ed-bdc3-0242ac120002")
    // 各Characteristic
    let bleWriteCharacteristicUUID = CBUUID(string:"3C399A64-4D2C-11ED-BDC3-0242AC120002")
    let bleNotifyCharacteristicUUID = CBUUID(string:"3C399C44-4D2C-11ED-BDC3-0242AC120002")
    
    override init() {
        super.init()
        bleInit()
    }
    
    //centralManager初期化
    private func bleInit() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //Peripheralをスキャン
    func scan() {
        //BLEのpermissionがONになってなければ早期リターンさせる
        guard centralManager.state == .poweredOn else { return }
        //ServiceUUIDを指定してスキャンをする
        //指定せずスキャンしたい場合はwithServicesにnilを渡す
        let services: [CBUUID] = [bleServiceUUID]
        centralManager.scanForPeripherals(withServices: services, options: nil)
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    //データの送信
    func sendData(data:Data) {
        //データの書き込み：属性がwrite with responseの場合
        if let peripheral = self.cbPeripheral, let writeCharacteristic = self.writeCharacteristic{
            peripheral.writeValue(data, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    //切断処理
    func disconnectPeripheral() {
        if let peripheral = cbPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}
// CBCentralManagerDelegate
extension BLEModel: CBCentralManagerDelegate {
    //Bluetoothの状態が変化する度に呼ばれるメソッド
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case CBManagerState.poweredOn:
            logText.append("poweredOn\n")
            break
        case CBManagerState.poweredOff:
            logText.append("poweredOff\n")
            break
        case CBManagerState.resetting:
            logText.append("resetting\n")
            break
        case CBManagerState.unauthorized:
            logText.append("unauthorized\n")
            break
        case CBManagerState.unsupported:
            logText.append("unsupported\n")
            break
        case .unknown:
            logText.append("unknown\n")
            break
        default:
            logText.append("other unknown\n")
            break
        }
    }
    //Peripheralが見つかる度に呼ばれるメソッド
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //peripheralの情報を取得する
        //Name -> peripheral.name
        //advertiseの中身 -> advertisementData
        //advertiseになっている各ペリフェラルのRSSI -> RSSI.stringValue
        //bleLoacalNameで定義した名前とペリフェラル側で定義したCOMPLETE_LOCAL_NAMEを照合
        if let peripheralName = advertisementData["kCBAdvDataLocalName"] as? String{
            if peripheralName == bleLoacalName{
                //見つけたペリフェラルを保持
                self.cbPeripheral = peripheral
                central.connect(peripheral, options: nil)
                //スキャン停止
                centralManager.stopScan()
            }
        }
    }
    
    //接続が成功した時に呼ばれるデリゲートメソッド
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logText.append("Connect Peripheral\n")
        isDisabledConnectButton = false
        isDisabledDisConnectButton = true
        connectStateLabel = "接続状態：接続中"
        centralManager.stopScan()
        peripheral.delegate = self
        //接続したペリフェラルのServiceUUIDを探す。　全て探す場合はdiscoverServicesにnilを渡す
        let services: [CBUUID] = [bleServiceUUID]
        peripheral.discoverServices(services)
        logText.append("discoverServices\n")
    }
    
    //接続が失敗した時に呼ばれるデリゲートメソッド
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logText.append("接続失敗\n")
    }
    //切断した時に呼ばれるデリゲートメソッド
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logText.append("切断\n")
        isDisabledConnectButton = true
        isDisabledDisConnectButton = false
        isDisabledWriteButton = false
        connectStateLabel = ("接続状態：未接続")
        logText.removeAll()
    }
}

//  CBPeripheralDelegate
extension BLEModel: CBPeripheralDelegate{
    //接続が成功したときに探したServiceUUIDが見つかると呼ばれるデリゲートメソッド
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logText.append("didDiscoverServices\n")
        //全てのサービスのキャラクタリスティックの検索
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    //Characteristicsが見つかった時に呼ばれるデリゲートメソッド
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics!{
            if characteristic.uuid == bleWriteCharacteristicUUID {
                writeCharacteristic = characteristic
                isDisabledWriteButton = true
                logText.append("Write Characteristicが見つかりました\n\(characteristic.uuid)\n")
            }
            if characteristic.uuid == bleNotifyCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                logText.append("Notify Characteristicが見つかりました\n\(characteristic.uuid)\n")
            }
        }
    }
    
    //write実行時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("書き込みに失敗しました： \(error.localizedDescription)\n")
            return
        }else{
            logText.append("書き込みに成功しました： " + (isWriteState ? "1" : "0") + "\n")
            
        }
    }
    
    //Notify実行時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logText.append("通知の受け取りに失敗しました： \(error.localizedDescription)")
        } else {
            let receivedData = String(bytes: characteristic.value!, encoding: String.Encoding.ascii)
            //今回はnotifyしか使用していないのでswitchは必要ではない
            switch characteristic.properties{
            case .read:
                logText.append("read: ")
            case .indicate:
                logText.append("indicate: ")
            case .notify:
                logText.append("notify: ")
            default:
                logText.append("unknown: ")
            }
            logText.append("\(receivedData ?? "breaked data") \n")
            isWriteState = receivedData == "0" ? false : true
        }
    }
}

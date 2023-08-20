import Foundation
import CoreBluetooth

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logText.append("didDiscoverServices" + "\n")
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics!{
            if characteristic.uuid == writeCharacteristicUUID {
                self.characteristic = characteristic
                logText.append("WriteCharacteristicUUID" + "\n" + "\(characteristic.uuid)" + "\n")
            }
            if characteristic.uuid == notifyCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                logText.append("NotifyCharacteristicUUID" + "\n" + "\(characteristic.uuid)" + "\n")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            logText.append( "error： \(error!.localizedDescription)" + "\n")
            return
        }
        logText.append("didWriteValue" + "\n")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logText.append("通知の受け取りに失敗しました： \(error.localizedDescription)")
        } else {
            let receivedData = String(bytes: characteristic.value!, encoding: String.Encoding.ascii)
            logText.append("\(receivedData ?? "breaked data")" + "\n")
            isKeyLocked = receivedData == "ON" ? true : false
        }
    }
}

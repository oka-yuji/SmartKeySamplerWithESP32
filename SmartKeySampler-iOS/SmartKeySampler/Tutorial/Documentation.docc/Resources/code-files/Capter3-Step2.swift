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
}

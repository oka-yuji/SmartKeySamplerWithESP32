import Foundation
import CoreBluetooth

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logText.append("didDiscoverServices" + "\n")
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
}

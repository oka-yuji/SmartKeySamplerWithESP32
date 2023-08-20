import Foundation
import CoreBluetooth

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            logText.append("unknown" + "\n")
        case .resetting:
            logText.append("resetting" + "\n")
        case .unsupported:
            logText.append("unsupported" + "\n")
        case .unauthorized:
            logText.append("unauthorized" + "\n")
        case .poweredOff:
            logText.append("poweredOff" + "\n")
        case .poweredOn:
            logText.append("poweredOn" + "\n")
        default:
            logText.append("default" + "\n")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let peripheralName = advertisementData["kCBAdvDataLocalName"] as? String
        if peripheralName == self.peripheralName {
            self.peripheral = peripheral
            central.connect(peripheral, options: nil)
            centralManager.stopScan() }
    }
}

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
}

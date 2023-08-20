import Foundation
import CoreBluetooth

final class BLEManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral? = nil
    private var characteristic: CBCharacteristic? = nil
    private let peripheralName: String = "ESP-TEST-DEVICE"
    private let serviceUUID: CBUUID = CBUUID(string: "3c3996e0-4d2c-11ed-bdc3-0242ac120002")
    private let writeCharacteristicUUID: CBUUID = CBUUID(string:"3C399A64-4D2C-11ED-BDC3-0242AC120002")
    private let notifyCharacteristicUUID = CBUUID(string:"3C399C44-4D2C-11ED-BDC3-0242AC120002")
    
    @Published var isKeyLocked = false
    @Published var isConnected = false
    @Published var logText = ""
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scan() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: [serviceUUID])
    }
    
    func writeDataToBLEDevice() {
        isKeyLocked.toggle()
        let writeString = isKeyLocked ? "ON" : "OFF"
        guard let writeData = writeString.data(using: .utf8) else { return }
        if let peripheral = self.peripheral, let writeCharacteristic = self.characteristic{
            peripheral.writeValue(writeData, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func disconnectPeripheral() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}

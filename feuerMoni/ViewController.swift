//
//  ViewController.swift
//  feuerMoni
//
//  Created by Sebastian Stallenberger on 18.02.16.
//  Copyright © 2016 jambit. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    // BLE
    var centralManager : CBCentralManager!
    var sensorTagPeripheral : CBPeripheral!

    // IR Temp UUIDs
    // let IRBatteryServiceUUID = CBUUID(string: "A8EFF82F-C9CC-4D4B-AF74-28B42528CFCF")
    // let IRBatteryDataUUID = CBUUID(string: "04402E31-73AF-49B6-A009-A51856C11711")
    // let IRBatteryConfigUUID = CBUUID(string: "26CB603D-0F79-4E5E-BB9C-B56C84761537")

//    let IRHeartRateServiceUUID = CBUUID(string: "2DF21A31-EBBA-40BB-BFE5-E5AC55A5E956")
//    let IRHeartRateDataUUID = CBUUID(string: "FBDD1135-9121-49DE-BC0D-FC7432486AFB")
//    let IRHeartRateConfigUUID = CBUUID(string: "4149908D-0D64-409C-BDEF-8A3E105E89C8")

    let IRHeartRateServiceUUID = CBUUID(string: "2DF21A31-EBBA-40BB-BFE5-E5AC55A5E956")
    let IRHeartRateDataUUID = CBUUID(string: "FBDD1135-9121-49DE-BC0D-FC7432486AFB")
    let IRHeartRateConfigUUID = CBUUID(string: "4149908D-0D64-409C-BDEF-8A3E105E89C8")
//    let IRHeartRateConfigUUID = CBUUID(string: "984227F3-34FC-4045-A5D0-2C581F81A153")

//    151C0000-4580-4111-9CA1-5056F3454FBC
//    151C1000-4580-4111-9CA1-5056F3454FBC
//    151C2000-4580-4111-9CA1-5056F3454FBC
//    151C3000-4580-4111-9CA1-5056F3454FBC

//    151C0002-4580-4111-9CA1-5056F3454FBC
//    151C0001-4580-4111-9CA1-5056F3454FBC

//    let IRTemperatureDataUUID = CBUUID(string: "F000AA01-0451-4000-B000-000000000000")
//    let IRTemperatureConfigUUID = CBUUID(string: "F000AA02-0451-4000-B000-000000000000")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // Initialize central manager on load
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Check status of BLE hardware
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripheralsWithServices(nil, options: nil)
            print("Searching for BLE Devices")
        }
        else {
            // Can have different conditions for all states if needed - print generic message for now
            print("Bluetooth switched off or not initialized")
        }
    }

    // Check out the discovered peripherals to find Device

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let deviceName = "Pavlok-A795"
        let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as? NSString

        if (nameOfDeviceFound == deviceName) {
            // Update Status Label
            print("Device Found")

            // Stop scanning
            self.centralManager.stopScan()
            // Set as the peripheral to use and establish connection
            self.sensorTagPeripheral = peripheral
            self.sensorTagPeripheral.delegate = self
            self.centralManager.connectPeripheral(peripheral, options: nil)
        }
        else {
            print("Device NOT Found. Found device: \(nameOfDeviceFound)")
        }
    }

    // Discover services of the peripheral
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Discovering peripheral services")
        peripheral.discoverServices(nil)
    }

    // Check if the service discovered is a valid IR Temperature Service
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Looking at peripheral services")
        for service in peripheral.services! {
            let thisService = service as CBService
            if service.UUID == IRHeartRateServiceUUID {
                // Discover characteristics of IR Temperature Service
                peripheral.discoverCharacteristics(nil, forService: thisService)
            }
            // Uncomment to print list of UUIDs
            print("SERVICE: \(thisService.UUID)")
        }
    }

    // Enable notification and sensor for each characteristic of valid service
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {

        // update status label
        print("Enabling sensors")

        // 0x01 data byte to enable sensor
        var enableValue = 1
        let enablyBytes = NSData(bytes: &enableValue, length: sizeof(UInt8))

        // check the uuid of each characteristic to find config and data characteristics
        for charateristic in service.characteristics! {
            let thisCharacteristic = charateristic as CBCharacteristic
            // check for data characteristic
            if thisCharacteristic.UUID == IRHeartRateDataUUID {
                // Enable Sensor Notification
                self.sensorTagPeripheral.setNotifyValue(true, forCharacteristic: thisCharacteristic)
            }
            // check for config characteristic
            if thisCharacteristic.UUID == IRHeartRateConfigUUID {
                // Enable Sensor
                self.sensorTagPeripheral.writeValue(enablyBytes, forCharacteristic: thisCharacteristic, type: CBCharacteristicWriteType.WithResponse)
            }

            // Uncomment to print list of UUIDs
            print("Characteristics: \(thisCharacteristic.UUID)")
        }
    }

    // Get data values when they are updated
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {

        print("Connected")

        if characteristic.UUID == IRHeartRateDataUUID {
            // Convert NSData to array of signed 16 bit values
            let dataBytes = characteristic.value
            let dataLength = dataBytes!.length
            var dataArray = [Int16](count: dataLength, repeatedValue: 0)
            dataBytes!.getBytes(&dataArray, length: dataLength * sizeof(Int16))

            // Element 1 of the array will be ambient temperature raw value
            let ambientTemperature = Double(dataArray[1]) / 128

            // Display on the temp label
            print(NSString(format: "%.2f", ambientTemperature))
        }
    }

    // If disconnected, start searching again
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected")
        central.scanForPeripheralsWithServices(nil, options: nil)
    }
}

//
//  DeviceViewController.swift
//  BLE Test01
//
//  Created by 雅耀 on 2018/1/4.
//  Copyright © 2018年 雅耀. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate{
    

    let UUID_Characteristic: [String] = ["FFF1", "FFF2", "FFF3", "FFF4", "FFF5"]
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addrLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var writeText: UITextField!
    @IBOutlet weak var readText: UILabel!
    @IBOutlet weak var writeButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    
//    var trCharactistic_1: CBCharacteristic!
//    var trCharactistic_2: CBCharacteristic!
//    var trCharactistic_3: CBCharacteristic!
//    var trCharactistic_4: CBCharacteristic!
//    var trCharactistic_5: CBCharacteristic!
    
    var trFlagLastConnectState: Bool! = false
    
    var peripheralToConnect: CBPeripheral!
    var trCBCentralManager: CBCentralManager!
    var trIOService: CBService!
    var trWriteCharacteristic: CBCharacteristic!
    var trReadCharacteristic: CBCharacteristic!
    var trNotifyCharacteristic: CBCharacteristic!
    var trServices: NSMutableArray = NSMutableArray()
    var trArrayCharacteristic: [CBCharacteristic] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.peripheralToConnect.delegate = self
        peripheralStateDetect(currentPeripheral: peripheralToConnect)
        uuidLabel.text = peripheralToConnect.identifier.uuidString
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        trCBCentralManager.cancelPeripheralConnection(peripheralToConnect)
    }
    
    func peripheralStateDetect(currentPeripheral: CBPeripheral) {
        switch currentPeripheral.state {
        case .connected:
            NSLog("已连接")
            if currentPeripheral.name != nil {
                nameLabel.text = peripheralToConnect.name!
            }
            currentPeripheral.discoverServices(nil)
            trFlagLastConnectState = true
        case .disconnected:
            NSLog("未连接")
            if !trFlagLastConnectState {
                NSLog("设备 \(currentPeripheral.name!)已断开连接")
                trFlagLastConnectState = false
            }
        default:
            NSLog("状态错误")
        }
    }
    
    @IBAction func actionWrite(_ sender: Any) {
        if let tx = writeText.text {
            if peripheralToConnect.state == .connected {
                let byteArray = stringToByteArray(stringArray: tx)
                let hexArray = uint8ToHexArray(uint8Array: byteArray!)
                var dataToTrans: Data = Data()
                dataToTrans.append(hexArray, count: hexArray.count)
                if trArrayCharacteristic[2] != nil {
                    peripheralToConnect.writeValue(dataToTrans, for: trArrayCharacteristic[2], type: .withResponse)
                }
            }
        }
    }
    
    @IBAction func actionRead(_ sender: Any) {
        if peripheralToConnect.state == .connected {
            if trArrayCharacteristic[0] != nil {
                peripheralToConnect.readValue(for: trArrayCharacteristic[0])
            } else {
                NSLog("读取失败，未获取到写入属性")
            }
        } else {
            NSLog("读取失败，当前未连接设备")
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Central Manager Delegate Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case CBManagerState.poweredOn:
            NSLog("蓝牙已开启")
        case CBManagerState.unauthorized:
            NSLog("无BLE权限")
        case CBManagerState.poweredOff:
            NSLog("蓝牙未开启")
        default:
            NSLog("状态无变化")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("正在连接")
        self.peripheralToConnect = peripheral
        self.peripheralToConnect.delegate = self
        NSLog("重新连接成功")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("连接\(peripheral.name!)失败，原因\(String(describing: error))")
        trFlagLastConnectState = false
    }

    // MARK: - Peripheral Delegate Methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        NSLog("搜索到\(peripheral.services!.count)个服务")
        if peripheral.services?.count != 0 {
            for service in peripheral.services! {
                if service.uuid.uuidString.contains("FFF0") {
                    NSLog("获取到指定服务 \(service.uuid.uuidString)")
                    trIOService = service
                }
                peripheral.discoverCharacteristics(nil, for: service)
            }
        } else {
            NSLog("无有效服务")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        NSLog("从服务\(service.uuid.uuidString) 搜索到\(service.characteristics!.count)个属性")
        
        if service.characteristics?.count != 0 {
            for characteristic in service.characteristics! {
                if trIOService != nil && trIOService == service {
                    for uuid in UUID_Characteristic {
                        if characteristic.uuid.uuidString.contains(uuid) {
                            NSLog("获取到指定属性\(characteristic.uuid.uuidString)")
                            
                            trArrayCharacteristic.append(characteristic)
                            NSLog("添加到数组 idx = \(trArrayCharacteristic.endIndex)")
                            
                        }
                        if uuid == "FFF4" {
                            peripheralToConnect.setNotifyValue(true, for: characteristic)
                        }
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            NSLog("Notify设置失败，当前状态为\(characteristic.isNotifying)，uuid=\(characteristic.uuid.uuidString)，错误提示为\(error.debugDescription)")
        } else {
            NSLog("Notify设置成功，当前状态为\(characteristic.isNotifying)，uuid=\(characteristic.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            var readValue: [UInt8] = [UInt8]()
            for readData in characteristic.value! {
                readValue += [readData]
            }
            readText.text = "data:<\(readValue)>"
            NSLog("name: \(characteristic.uuid), data:<\(readValue)>")
        }else {
            NSLog("读取错误 \(error.debugDescription)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            NSLog("写入成功响应，data：")
            
        }else {
            NSLog("写入错误\(error.debugDescription)")
        }
    }
    
    // MARK: - User Methods
    
    func stringToByteArray(stringArray: String) -> ([UInt8])! {
        var byteArray = [UInt8]()
        
        for char in stringArray.utf8{
            if (char > 0x2F && char < 0x3A) {
                byteArray += [char - 0x30]
            } else if (char > 0x60 && char < 0x67) {
                byteArray += [(char - 0x60) + 9]
            } else if (char > 0x40 && char < 0x47) {
                byteArray += [(char - 0x40) + 9]
            } else {
                NSLog("输入错误")
            }
        }
        
        return byteArray
    }
    
    func uint8ToHexArray(uint8Array: [UInt8]) -> [UInt8] {
        var hexArray = [UInt8]()
        if (uint8Array.count != 0) {
            var hexData: UInt8 = 0
            var cnt = 0
            for data in uint8Array {
                if cnt % 2 == 0 {
                    hexData = data * 16
                    if cnt == uint8Array.count - 1 {
                        hexArray += [data]
                        NSLog("输出长度为奇数， 最后一个值为\(hexData)")
                    }
                } else {
                    hexData += data
                    hexArray += [hexData]
                }
                cnt += 1
            }
        }
        
        return hexArray
    }
}

//
//  ContentViewController.swift
//  BLE Test01
//
//  Created by 雅耀 on 2018/1/3.
//  Copyright © 2018年 雅耀. All rights reserved.
//

import UIKit
import CoreBluetooth

class MyContentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate {

    @IBOutlet weak var devTable: UITableView!
    @IBOutlet weak var scanButton: UIButton!
    
    
    let alertConnect = UIAlertController(title: "Note", message: "Connecting", preferredStyle: .alert)
    let alertError = UIAlertController(title: "Note", message: "Connect Failed", preferredStyle: .alert)
    let alertTimeOut = UIAlertController(title: "Note", message: "Connect Time out", preferredStyle: .alert)
    
    var flagScan: Bool! = false
    var myCentralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    var myCBError: CBError!
    
    var myPeripheralToMainView: CBPeripheral!
    var myPeripherals: NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let cancelAction = UIAlertAction(title: "Cancel Connect", style: .default, handler: {
            action in
            self.myCentralManager.cancelPeripheralConnection(self.myPeripheralToMainView)
        })
        alertConnect.addAction(cancelAction)
        
        let okAction = UIAlertAction(title: "Done", style: .default, handler: nil)
        alertError.addAction(okAction)
        alertTimeOut.addAction(okAction)
        
        self.myCentralManager = CBCentralManager(delegate: self, queue: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Action Function
    
    @IBAction func actionScan(_ sender: Any) {
        if flagScan {
            NSLog("停止搜索")
            self.myCentralManager.stopScan()
            scanButton.setTitle("Scan", for: UIControlState.normal)
            flagScan = false
        } else {
            NSLog("开始搜索")
            scanButton.setTitle("Stop", for: UIControlState.normal)
            self.myCentralManager = CBCentralManager(delegate: self, queue: nil)
            self.myCentralManager.scanForPeripherals(withServices: nil, options: nil)
            flagScan = true
        }
    }

    @IBAction func actionClear(_ sender: Any) {
        myPeripherals.removeAllObjects()
        devTable.reloadData()
    }
    
    func connectPeripheral(peripheral: CBPeripheral) {
        myCentralManager.connect(peripheral, options: nil)
        var nameToConnect: String!
        if peripheral.name == nil {
            nameToConnect = "Unknow Device"
        } else {
            nameToConnect = peripheral.name!
        }
        alertConnect.message = "\(nameToConnect) is connecting"
        self.present(alertConnect, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Table View Data Source Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myPeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.devTable.dequeueReusableCell(withIdentifier: "myTableViewCell")! as UITableViewCell
        let labelName = cell.viewWithTag(1) as! UILabel
        let labelRSSI = cell.viewWithTag(2) as! UILabel
        let labelUUID = cell.viewWithTag(3) as! UILabel
        
        let s: NSDictionary = myPeripherals[indexPath.row] as! NSDictionary
        let p: CBPeripheral = s.value(forKey: "peripheral") as! CBPeripheral
        let d: NSDictionary = s.value(forKey: "advertisementData") as! NSDictionary
        let rssi: NSNumber = s.value(forKey: "RSSI") as!NSNumber
        
        labelName.text? = "\(p.name!)"
        labelRSSI.text? = "\(rssi)dB"
        labelUUID.text? = "\(p.identifier)"
        
        NSLog("设备名\(p.name!), 状态\(p.state), UUID\(p.identifier), 信号\(rssi)")
        NSLog("广播内容\(d.allValues)")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog("停止搜索")
        self.myCentralManager.stopScan()
        scanButton.setTitle("Scan", for: UIControlState.normal)
        flagScan = false
        
       devTable.deselectRow(at: indexPath, animated: true)
        
        let myPeriDict: NSDictionary = myPeripherals[indexPath.row] as! NSDictionary
        myPeripheralToMainView = myPeriDict.value(forKey: "peripheral") as! CBPeripheral
        NSLog("点击设备， NAME=\(myPeripheralToMainView.name!), UUID=\(myPeripheralToMainView.identifier)")
        connectPeripheral(peripheral: myPeripheralToMainView)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDevice"{
            let myVC = segue.destination as! DeviceViewController
            myVC.peripheralToConnect = myPeripheralToMainView
            myVC.trCBCentralManager = myCentralManager
        }
    }
    
    // MARK: - CBCentral Manager Delegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case CBManagerState.poweredOn:
            NSLog("启动成功，开始搜索")
            myCentralManager.scanForPeripherals(withServices: nil, options: nil)
            scanButton.setTitle("Stop", for: UIControlState.normal)
            flagScan = true
        case CBManagerState.unauthorized:
            NSLog("无BLE权限")
        case CBManagerState.poweredOff:
            NSLog("蓝牙未开启")
        default:
            NSLog("状态无变化")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var nsPeripheral: NSArray
        nsPeripheral = myPeripherals.value(forKey: "peripheral") as! NSArray
        
        if(!nsPeripheral.contains(peripheral)){
            if(peripheral.name?.isEmpty == false) {
                let r: NSMutableDictionary = NSMutableDictionary()
                r.setValue(peripheral, forKey: "peripheral")
                r.setValue(RSSI, forKey: "RSSI")
                r.setValue(advertisementData, forKey: "advertisementData")
                myPeripherals.add(r)
                
                NSLog("搜索到设备， NAME=\(peripheral.name!), UUID=\(peripheral.identifier)")
            }
        }
        self.devTable.reloadData()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("已连接\(peripheral.name!)")
        self.myPeripheralToMainView! = peripheral
        self.alertConnect.dismiss(animated: false, completion: {
            self.performSegue(withIdentifier: "showDevice", sender: nil)
        })
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("连接失败，设备名\(peripheral.name!), 原因\(String(describing: error))")
        alertConnect.dismiss(animated: false, completion: {
            self.present(self.alertError, animated: false, completion: nil)
        })
    }
}

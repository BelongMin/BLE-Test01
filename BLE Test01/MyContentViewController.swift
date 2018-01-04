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
    
    var flagScan: Bool! = false
    var myCentralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    var myCBError: CBError!
    
    var myPeripheralToMainView: CBPeripheral!
    var myPeripherals: NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    
    // MARK: - CBCentral Manager Delegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case CBManagerState.poweredOn:
            NSLog("启动成功，开始搜索")
            myCentralManager.scanForPeripherals(withServices: nil, options: nil)
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
}

import Foundation
import Capacitor
import MetricKit

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(PJAMMBackgroundPlugin)
public class PJAMMBackgroundPlugin: CAPPlugin, MXMetricManagerSubscriber {
    private let implementation = PJAMMBackground()
    private var curBatteryData:BatteryData? = nil
    private var initBatteryData_unplugged:BatteryData? = nil
    private var burnRateData_15mins:[BatteryData] = []

    @objc public override func load() {
        if #available(iOS 14.0, *) {
            let metricManager = MXMetricManager.shared
            metricManager.add(self)
        } else {
            // Fallback on earlier versions
        }
        
        
        // Battery Monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
    }

    @objc func enableBackgroundFetch(_ call: CAPPluginCall) {
    }

    @objc func disableBackgroundFetch(_ call: CAPPluginCall) {
    }

    @objc func sendBackgroundExitData(_ call: CAPPluginCall) {

        var payloads:Array<[String:Any]> = []

        if #available(iOS 14.0, *) {
            let metricManager = MXMetricManager.shared
            
            for payload in metricManager.pastPayloads {
                payloads.append(convertPayloadToJSON(payload: payload))
            }
        }

        call.resolve(["payloads": payloads])
    }
    
    @objc func sendBatteryData(_ call: CAPPluginCall) {
        let batteryData = convertBatteryDataToJSON(data: self.curBatteryData ?? BatteryData())
        
        call.resolve(batteryData)
    }
    
    @available(iOS 13.0, *)
    @objc public func didReceive(_ payloads: [MXMetricPayload]) {
        
        var payloadData:Array<[String:Any]> = []
        
        for payload in payloads {
            payloadData.append(convertPayloadToJSON(payload: payload))
        }
        
        self.notifyListeners("pjammExitData", data: ["payloads": payloadData])
    }
    
    @available(iOS 13.0, *)
    @objc private func convertPayloadToJSON (payload:MXMetricPayload) -> [String:Any] {
        var payloadData:[String:Any] = [:]
        var exitCounts:Array<[String:Any]> = []
        
        if #available(iOS 14.0, *) {
            if let exitData = payload.applicationExitMetrics?.backgroundExitData {
                
                exitCounts.append(["name":"abnormalExit","count":exitData.cumulativeAbnormalExitCount]);
                exitCounts.append(["name":"appWatchdog","count":exitData.cumulativeAppWatchdogExitCount]);
                exitCounts.append(["name":"badAccess","count":exitData.cumulativeBadAccessExitCount]);
                exitCounts.append(["name":"backgroundTaskTimeout","count":exitData.cumulativeBackgroundTaskAssertionTimeoutExitCount]);
                exitCounts.append(["name":"cpuResourceLimit","count":exitData.cumulativeCPUResourceLimitExitCount]);
                exitCounts.append(["name":"illegalInstructions","count":exitData.cumulativeIllegalInstructionExitCount]);
                exitCounts.append(["name":"memoryPressureExit","count":exitData.cumulativeMemoryPressureExitCount]);
                exitCounts.append(["name":"memoryResourceLimit","count":exitData.cumulativeMemoryResourceLimitExitCount]);
                exitCounts.append(["name":"normalExit","count":exitData.cumulativeNormalAppExitCount]);
                exitCounts.append(["name":"suspendedWithLockedFile","count":exitData.cumulativeSuspendedWithLockedFileExitCount]);
            }
        }
        
        payloadData["beginTime"]    = payload.timeStampBegin.timeIntervalSince1970
        payloadData["endTime"]      = payload.timeStampEnd.timeIntervalSince1970
        payloadData["exitCounts"]   = exitCounts
        
        return payloadData
    }
    
    @objc public func batteryLevelDidChange(_ notification: Notification){
        let preBatteryData = self.curBatteryData
        self.curBatteryData = BatteryData()
        
        
        if self.curBatteryData?.state == UIDevice.BatteryState.unplugged {
            
            if self.initBatteryData_unplugged == nil {
                self.initBatteryData_unplugged = self.curBatteryData
                self.burnRateData_15mins = []
            }
            
            self.burnRateData_15mins.insert(self.curBatteryData!, at: 0)
            updateCurBatteryDataBurnRates()
            
            
        } else {
            
            self.initBatteryData_unplugged = nil
            self.curBatteryData?.burnRate_15mins = preBatteryData!.burnRate_15mins
            self.curBatteryData?.burnRate_overall = preBatteryData!.burnRate_overall
            
        }
        
        self.notifyListeners("pjammBatteryData", data: ["data": convertBatteryDataToJSON(data: self.curBatteryData!)])
    }
    
    @objc private func updateCurBatteryDataBurnRates(){
        
        if self.curBatteryData?.state != UIDevice.BatteryState.unplugged {
            return
        }
        
        // Update Overall Burn Rate
        if self.initBatteryData_unplugged != nil {
            self.curBatteryData!.burnRate_overall = (self.initBatteryData_unplugged!.level - self.curBatteryData!.level) / (self.initBatteryData_unplugged!.timestamp - self.curBatteryData!.timestamp)
            
            self.curBatteryData!.burnRate_overall *= 100 // % per sec
            self.curBatteryData!.burnRate_overall *= 3600 // % per hour
        }
        
        //Update 15 min Burn Rate
        if self.burnRateData_15mins.count > 1 {
            let curLevel:Float      = self.burnRateData_15mins[0].level
            var startLevel:Float    = self.burnRateData_15mins[0].level
            var time:Float          = 0;
            
            for i in 1..<self.burnRateData_15mins.count {
                let curData = self.burnRateData_15mins[i - 1]
                let preData = self.burnRateData_15mins[i]
                let duration = curData.timestamp - preData.timestamp
                
                if curData.level > preData.level {
                    self.burnRateData_15mins = Array(self.burnRateData_15mins[0..<i])
                    break;
                }
                
                time += duration
                startLevel = preData.level
                
                if time > 15 * 60 {
                    self.burnRateData_15mins = Array(self.burnRateData_15mins[0...i])
                    break;
                }
            }
            
            if time > 0 {
                self.curBatteryData?.burnRate_15mins = 3600 * 100 * (startLevel - curLevel) / time // % per hour
            }
        }
    }
    
    @objc private func convertBatteryDataToJSON (data:BatteryData) -> [String:Any] {
        var batteryData:[String:Any] = [
            "level":0,
            "burnRate_overall":0,
            "burnRate_15mins":0
        ]
        
        batteryData["level"]            = self.curBatteryData?.level
        batteryData["burnRate_overall"] = self.curBatteryData?.burnRate_overall
        batteryData["burnRate_15mins"]  = self.curBatteryData?.burnRate_15mins
        
        if self.curBatteryData?.state == UIDevice.BatteryState.charging || self.curBatteryData?.state == UIDevice.BatteryState.full {
            batteryData["isCharging"] = true
        } else {
            batteryData["isCharging"] = false
        }
        
        return batteryData
    }
}

@objc public class BatteryData: NSObject {
    var timestamp:Float
    var level:Float
    var state:UIDevice.BatteryState
    
    var burnRate_15mins:Float = 0
    var burnRate_overall:Float = 0
    
    public override init() {
        self.timestamp  = Float(NSDate().timeIntervalSince1970)
        self.level      = UIDevice.current.batteryLevel
        self.state      = UIDevice.current.batteryState
    }
}
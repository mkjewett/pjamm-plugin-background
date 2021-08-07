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
    private var burnRateItem_15mins:BurnRateItem = BurnRateItem(timeTarget: 15*60)
    private var burnRateItem_30mins:BurnRateItem = BurnRateItem(timeTarget: 30*60)
    private var taskIds: [String: UIBackgroundTaskIdentifier] = [:]

    @objc public override func load() {
        if #available(iOS 14.0, *) {
            let metricManager = MXMetricManager.shared
            metricManager.add(self)
        } else {
            // Fallback on earlier versions
        }
        
        // Battery Monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryLevelDidChange(notification:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
    }
    
    @objc public func taskBeforeExit(_ call: CAPPluginCall) {
        
        guard let callbackId = call.callbackId else {
            call.reject("No allbackId was provided.")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return }
            
            var taskId = UIBackgroundTaskIdentifier.invalid
            taskId = UIApplication.shared.beginBackgroundTask {
                // Finish the task if time expires.
                UIApplication.shared.endBackgroundTask(taskId)
                self.taskIds.removeValue(forKey: callbackId)
            }
            self.taskIds[callbackId] = taskId
        }
        
        call.resolve()
    }

    @objc public func taskFinish(_ call: CAPPluginCall) {
        guard let callbackId = call.getString("taskId") else {
            call.reject("No taskId was provided.")
            return
        }

        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return }
            
            guard let taskId = self.taskIds[callbackId] else {
                return
            }
            
            UIApplication.shared.endBackgroundTask(taskId)
            self.taskIds.removeValue(forKey: callbackId)
        }
    }

    @objc public func enableBackgroundFetch(_ call: CAPPluginCall) {
    }

    @objc public func disableBackgroundFetch(_ call: CAPPluginCall) {
    }

    @objc public func sendBackgroundExitData(_ call: CAPPluginCall) {

        var payloads:Array<[String:Any]> = []

        if #available(iOS 14.0, *) {
            let metricManager = MXMetricManager.shared
            
            for payload in metricManager.pastPayloads {
                payloads.append(convertPayloadToJSON(payload: payload))
            }
        }

        call.resolve(["payloads": payloads])
    }
    
    @objc public func sendBatteryData(_ call: CAPPluginCall) {
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
    
    @objc public func batteryLevelDidChange(notification: Notification){
        let preBatteryData = self.curBatteryData
        self.curBatteryData = BatteryData()
        
        self.curBatteryData?.burnRate_15mins    = 0
        self.curBatteryData?.burnRate_30mins    = 0
        self.curBatteryData?.burnRate_overall   = 0
        
        if self.curBatteryData?.state == UIDevice.BatteryState.unplugged {
            
            if self.initBatteryData_unplugged == nil {
                self.initBatteryData_unplugged = self.curBatteryData
                self.burnRateItem_15mins.clearData()
                self.burnRateItem_30mins.clearData()
            }
            
            self.burnRateItem_15mins.addNewDataPoint(data: self.curBatteryData!)
            self.burnRateItem_30mins.addNewDataPoint(data: self.curBatteryData!)
            
            self.curBatteryData?.burnRate_15mins = self.burnRateItem_15mins.burnRate
            self.curBatteryData?.burnRate_30mins = self.burnRateItem_30mins.burnRate
            
            updateCurBatteryDataOverallBurnRate()
            
            
        } else {
            
            self.initBatteryData_unplugged = nil
            self.curBatteryData?.burnRate_15mins = preBatteryData?.burnRate_15mins ?? 0
            self.curBatteryData?.burnRate_30mins = preBatteryData?.burnRate_30mins ?? 0
            self.curBatteryData?.burnRate_overall = preBatteryData?.burnRate_overall ?? 0
            
        }
                
        self.notifyListeners("pjammBatteryData", data: convertBatteryDataToJSON(data: self.curBatteryData))
    }
    
    @objc private func updateCurBatteryDataOverallBurnRate(){
        
        if self.curBatteryData == nil || self.curBatteryData?.state != UIDevice.BatteryState.unplugged {
            return
        }
        
        // Update Overall Burn Rate
        if self.initBatteryData_unplugged != nil && self.curBatteryData?.timestamp != self.initBatteryData_unplugged?.timestamp {
            self.curBatteryData?.burnRate_overall = (self.initBatteryData_unplugged!.level - self.curBatteryData!.level) / Float(self.curBatteryData!.timestamp - self.initBatteryData_unplugged!.timestamp)
            
            self.curBatteryData?.burnRate_overall *= 100 // % per sec
            self.curBatteryData?.burnRate_overall *= 3600 // % per hour
        }
    }
    
    @objc private func convertBatteryDataToJSON (data:BatteryData?) -> [String:Any] {
        
        var batteryData:[String:Any] = [:]
        let time:Double = data?.timestamp ?? 0 * 1000
        
        batteryData["level"] = data?.level ?? 0
        batteryData["timestamp"] = time.rounded()
        batteryData["burnRate_overall"] = data?.burnRate_overall ?? 0
        batteryData["burnRate_15mins"] = data?.burnRate_15mins ?? 0
        batteryData["burnRate_30mins"] = data?.burnRate_30mins ?? 0
        
        if data?.state == UIDevice.BatteryState.charging || data?.state == UIDevice.BatteryState.full {
            batteryData["isCharging"] = true
        } else {
            batteryData["isCharging"] = false
        }
        
        return batteryData
    }
}

@objc public class BatteryData: NSObject {
    var timestamp:Double
    var level:Float
    var state:UIDevice.BatteryState
    
    var burnRate_15mins:Float   = 0
    var burnRate_30mins:Float   = 0
    var burnRate_overall:Float  = 0
    
    public override init() {
        self.timestamp  = NSDate().timeIntervalSince1970
        self.level      = UIDevice.current.batteryLevel
        self.state      = UIDevice.current.batteryState
    }
}

@objc public class BurnRateItem: NSObject {
    var timeTarget:Float            = 0
    var burnRateData:[BatteryData]  = []
    var burnRate:Float              = 0

    init(timeTarget:Float) {
        self.timeTarget = timeTarget
    }
    
    public func addNewDataPoint(data:BatteryData){
        self.burnRateData.insert(data, at: 0)
        self.updateBurnRate()
    }
    
    public func clearData(){
        self.burnRateData = [];
        self.burnRate = 0;
    }
    
    private func updateBurnRate(){
        if self.burnRateData.count <= 1 {
            return
        }
        
        let levelNow:Float      = self.burnRateData[0].level
        var levelStart:Float    = self.burnRateData[0].level
        var time:Float          = 0;
            
        for i in 1..<self.burnRateData.count {
            let curData = self.burnRateData[i - 1]
            let preData = self.burnRateData[i]
            let duration = Float(curData.timestamp - preData.timestamp)
            
            if curData.level > preData.level {
                self.burnRateData = Array(self.burnRateData[0..<i])
                break;
            }
            
            time += duration
            levelStart = preData.level
            
            if time > self.timeTarget {
                let excessTime:Float = self.timeTarget
                
                time = self.timeTarget;
                levelStart = curData.level + (preData.level - curData.level)*(duration - excessTime)/duration
                
                self.burnRateData = Array(self.burnRateData[0...i])
                break;
            }
        }
            
        if time > 0 {
            self.burnRate = 3600 * 100 * (levelStart - levelNow) / time // % per hour
        }
    }
}

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

    @objc public override func load() {
        if #available(iOS 14.0, *) {
            let metricManager = MXMetricManager.shared
            metricManager.add(self)
        } else {
            // Fallback on earlier versions
        }
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
                
                // exitCounts["abnormalExit"]! += exitData.cumulativeAbnormalExitCount
                // exitCounts["appWatchdog"]! += exitData.cumulativeAppWatchdogExitCount
                // exitCounts["badAccess"]! += exitData.cumulativeBadAccessExitCount
                // exitCounts["backgroundTaskTimeout"]! += exitData.cumulativeBackgroundTaskAssertionTimeoutExitCount
                // exitCounts["cpuResourceLimit"]! += exitData.cumulativeCPUResourceLimitExitCount
                // exitCounts["illegalInstructions"]! += exitData.cumulativeIllegalInstructionExitCount
                // exitCounts["memoryPressureExit"]! += exitData.cumulativeMemoryPressureExitCount
                // exitCounts["memoryResourceLimit"]! += exitData.cumulativeMemoryResourceLimitExitCount
                // exitCounts["normalExit"]! += exitData.cumulativeNormalAppExitCount
                // exitCounts["suspendedWithLockedFile"]! += exitData.cumulativeSuspendedWithLockedFileExitCount
                
            }
        }
        
        payloadData["beginTime"]    = payload.timeStampBegin.timeIntervalSince1970
        payloadData["endTime"]      = payload.timeStampEnd.timeIntervalSince1970
        payloadData["exitCounts"]   = exitCounts
        
        return payloadData
    }
}

import Foundation
import Capacitor
import MetricKit

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(PJAMMBackground)
public class PJAMMBackground: CAPPlugin, MXMetricManagerSubscriber {
    
    @objc public override func load() {
        let metricManager = MXMetricManager.shared
        metricManager.add(self)
    }

    @objc func enableBackgroundFetch(_ call: CAPPluginCall) {

    }

    @objc func disableBackgroundFetch(_ call: CAPPluginCall) {

    }

    @objc func sendBackgroundExitData(_ call: CAPPluginCall) {

    }
    
    @objc public func didReceive(_ payloads: [MXMetricPayload]) {
        let exitCounts:[String:Int32] = [
            "abnormalExit": 0,
            "appWatchdog": 0,
            "badAccess": 0,
            "backgroundTaskTimeout": 0,
            "cpuResourceLimit": 0,
            "illegalInstructions": 0,
            "memoryPressureExit": 0,
            "memoryResourceLimit": 0,
            "normalExit": 0,
            "suspendedWithLockedFile": 0
        ]
        
        for payload in payloads {
            if let exitData = payload.applicationExitMetrics?.backgroundExitData {
                exitCounts["abnormalExit"] += exitData.cumulativeAbnormalExitCount
                exitCounts["appWatchdog"] += exitData.cumulativeAppWatchdogExitCount
                exitCounts["badAccess"] += exitData.cumulativeBadAccessExitCount
                exitCounts["backgroundTaskTimeout"] += exitData.cumulativeBackgroundTaskAssertionTimeoutExitCount
                exitCounts["cpuResourceLimit"] += exitData.cumulativeCPUResourceLimitExitCount
                exitCounts["illegalInstructions"] += exitData.cumulativeIllegalInstructionExitCount
                exitCounts["memoryPressureExit"] += exitData.cumulativeMemoryPressureExitCount
                exitCounts["memoryResourceLimit"] += exitData.cumulativeMemoryResourceLimitExitCount
                exitCounts["normalExit"] += exitData.cumulativeNormalAppExitCount
                exitCounts["suspendedWithLockedFile"] += exitData.cumulativeSuspendedWithLockedFileExitCount
            }
        }
        
        self.notifyListeners("pjammExitData", data: exitCounts);
    }
    
}

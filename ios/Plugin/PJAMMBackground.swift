import Foundation

@objc public class PJAMMBackground: NSObject {
    var taskIds: [String: UIBackgroundTaskIdentifier] = [:]

    @objc public func taskBeforeExit(_ callbackId: String) {
        DispatchQueue.global().async { [weak self] in
            
            guard let self = self else { return }
            
            var taskId = UIBackgroundTaskIdentifier.invalid
            taskId = UIApplication.shared.beginBackgroundTask {
                // Finish the task if time expires.
                UIApplication.shared.endBackgroundTask(taskId)
                self.taskIds.removeValue(forKey: callbackId)
            }
            self.taskIds[callbackId] = taskId
        }
    }

    @objc public func taskFinish(_ callbackId: String) {
        DispatchQueue.global().async { [weak self] in
            
            guard let self = self else { return }
            
            guard let taskId = self.taskIds[callbackId] else {
                return
            }
            
            UIApplication.shared.endBackgroundTask(taskId)
            self.taskIds.removeValue(forKey: callbackId)
        }
    }
}

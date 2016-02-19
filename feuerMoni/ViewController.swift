//
//  ViewController.swift
//  feuerMoni
//
//  Copyright © 2016 jambit. All rights reserved.
//

import UIKit
import WatchConnectivity
import CocoaLumberjack

class ViewController: UIViewController, WCSessionDelegate, BackendManagerDelegate {

    @IBOutlet weak var logTextView: UITextView!

    private var internalCount = 0

    private var backendManager: BackendManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        if (WCSession.isSupported()) {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }

        backendManager = BackendManager(delegate: self)
    }

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        if let command = message["command"] as? String {

            switch command {
            case "START":
                dispatch_async(dispatch_get_main_queue()) {
                    self.appendLog("Start monitoring")
                }
                backendManager?.activate({ success in
                    replyHandler(["status": success ? "success" : "error"])
                })
            case "STOP":
                dispatch_async(dispatch_get_main_queue()) {
                    self.appendLog("Stop monitoring")
                }
                backendManager?.deactivate({ success in
                    replyHandler(["status": success ? "success" : "error"])
                })
            case "UPDATE":
                if let heartRateString = message["heartrate"] as? String {
                    if let heartRate = Double(heartRateString) {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.appendLog("Update with heartrate: \(heartRate)")
                        }
                        backendManager?.update(VitalDataType.Heartrate, value: heartRate, completion: { success in
                            replyHandler(["status": success ? "success" : "error"])
                        })
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.appendLog("Update with heartrate: Invalid heartrate")
                    }
                }

            default:
                dispatch_async(dispatch_get_main_queue()) {
                    self.appendLog("Unknown command: \(command)")
                    replyHandler(["status": "error"])
                }
            }
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.appendLog("Error!")
            }
            replyHandler(["status": "error"])
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func appendLog(logText: String) {
        let oldText = logTextView.text
        logTextView.text = "\(logText)\n\(oldText)"
    }
}

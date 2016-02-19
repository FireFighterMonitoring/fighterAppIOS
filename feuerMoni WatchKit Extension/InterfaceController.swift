//
//  InterfaceController.swift
//  feuerMoni WatchKit Extension
//
//  Copyright © 2016 jambit. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import CoreMotion
import WatchConnectivity

class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {

    @IBOutlet var startButton: WKInterfaceButton!
    @IBOutlet var stopButton: WKInterfaceButton!

    let healthStore = HKHealthStore()
    var workoutSession : HKWorkoutSession?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        let typesToShare = Set([HKObjectType.workoutType()])
        let typesToRead = Set([HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!])

        healthStore.requestAuthorizationToShareTypes(typesToShare, readTypes: typesToRead) { (success, error) -> Void in
            print("[Watch] Authorization okay")
        }
    }

    func setButtonsStateActive(active: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            self.startButton.setEnabled(active)
            self.stopButton.setEnabled(!active)
        }
    }

    func setBothButtonsInactive() {
        dispatch_async(dispatch_get_main_queue()) {
            self.startButton.setEnabled(false)
            self.stopButton.setEnabled(false)
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func sendStart() {
        setBothButtonsInactive()

        let session = WCSession.defaultSession()
        let startPayload = ["command": "START"]

        print("[Watch] Send message")
        session.sendMessage(startPayload, replyHandler: { (successPayload) -> Void in
            print("[Watch] Send successful. Payload: \(successPayload)")
            if let status = successPayload["status"] as? String {
                print("[Watch] Response: \(status)")

                switch status {
                case "success":
                    print("Start successful")
                    self.workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.Running, locationType: HKWorkoutSessionLocationType.Outdoor)
                    self.workoutSession?.delegate = self

                    self.healthStore.startWorkoutSession(self.workoutSession!)
                    return
                default:
                    print("Error during start.")
                    self.setButtonsStateActive(false)
                }
            }
        }) { (error) -> Void in
            print("[Watch] Send failed! error: \(error)")
            self.setButtonsStateActive(false)
        }
    }

    func sendStop() {
        setBothButtonsInactive()

        let session = WCSession.defaultSession()
        let stopPayload = ["command": "STOP"]

        print("[Watch] Send message")
        session.sendMessage(stopPayload, replyHandler: { (successPayload) -> Void in
            print("[Watch] Send successful. Payload: \(successPayload)")
            if let status = successPayload["status"] as? String {
                print("[Watch] Response: \(status)")

                switch status {
                case "success":
                    print("Stop successful")
                    self.healthStore.endWorkoutSession(self.workoutSession!)
                default:
                    print("Error during stop.")
                    self.setButtonsStateActive(true)
                }
            }
        }) { (error) -> Void in
            print("[Watch] Send failed! error: \(error)")
            self.setButtonsStateActive(true)
        }
    }

    func sendUpdate(heartrate: Double) {
        let session = WCSession.defaultSession()
        let updatePayload = ["command": "UPDATE", "heartrate": "\(heartrate)"]

        print("[Watch] Send message")
        session.sendMessage(updatePayload, replyHandler: { (successPayload) -> Void in
            print("[Watch] Send successful. Payload: \(successPayload)")
            if let status = successPayload["status"] as? String {
                print("[Watch] Response: \(status)")
            }
        }) { (error) -> Void in
            print("[Watch] Send failed! error: \(error)")
        }
    }

    @IBAction func startButtonPressed() {
        sendStart()
    }

    @IBAction func stopButtonPressed() {
        sendStop()
    }

    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        print("[Watch] session started")

        switch toState {
        case .Running:
            self.workoutDidStart(date)
        case .Ended:
            self.workoutDidEnd(date)
        default:
            print("[Watch] workout: unknown state")
        }
    }

    func createStreamingHeartRateQuery(date: NSDate) -> HKQuery {
        let predicate = HKQuery.predicateForSamplesWithStartDate(date, endDate: nil, options: .None)
        let heartRateType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!

        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit))
        { (query, samples, deletedObjects, anchor, error) -> Void in
        }

        query.updateHandler = { (query, samples, deletedObjects, anchor, error) -> Void in

            guard let samples = samples as? [HKQuantitySample] else {
                print("[Watch] samples missing")
                return
            }
            guard let quantity = samples.last?.quantity else {
                print("[Watch] quantity missing")
                return
            }
            let heartRateUnit = HKUnit(fromString: "count/min")
            let heartRate = quantity.doubleValueForUnit(heartRateUnit)
            print("[Watch] Heartrate: \(heartRate)")
            self.sendUpdate(heartRate)
        }

        return query
    }

    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        print("[Watch] session couldn't be started. Error:\(error)")
    }

    private func workoutDidStart(date: NSDate) {
        print("[Watch] workout did start")
        self.setButtonsStateActive(true)

        let query = self.createStreamingHeartRateQuery(date)
        self.healthStore.executeQuery(query)
    }

    private func workoutDidEnd(date: NSDate) {
        print("[Watch] workout did end")
        self.setButtonsStateActive(false)
    }
}

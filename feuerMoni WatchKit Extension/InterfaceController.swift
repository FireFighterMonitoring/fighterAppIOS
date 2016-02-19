//
//  InterfaceController.swift
//  feuerMoni WatchKit Extension
//
//  Created by Sebastian Stallenberger on 18.02.16.
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

        startButton.setEnabled(true)
        stopButton.setEnabled(false)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func sendStart() {
        let session = WCSession.defaultSession()
        let startPayload = ["command": "START"]

        print("[Watch] Send message")
        session.sendMessage(startPayload, replyHandler: { (successPayload) -> Void in
            print("[Watch] Send successful. Payload: \(successPayload)")
            if let status = successPayload["status"] as? String {
                print("[Watch] Response: \(status)")

                switch status {
                case "success":
                    self.workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.Running, locationType: HKWorkoutSessionLocationType.Outdoor)
                    self.workoutSession?.delegate = self

                    self.healthStore.startWorkoutSession(self.workoutSession!)
                default:
                    print("Error during start.")
                    self.startButton.setEnabled(true)
                    self.stopButton.setEnabled(false)
                }
            }
        }) { (error) -> Void in
            print("[Watch] Send failed! error: \(error)")
        }
    }

    func sendStop() {
        let session = WCSession.defaultSession()
        let stopPayload = ["command": "STOP"]

        print("[Watch] Send message")
        session.sendMessage(stopPayload, replyHandler: { (successPayload) -> Void in
            print("[Watch] Send successful. Payload: \(successPayload)")
            if let status = successPayload["status"] as? String {
                print("[Watch] Response: \(status)")

                switch status {
                case "success":
                    self.healthStore.endWorkoutSession(self.workoutSession!)
                default:
                    print("Error during start.")
                    self.startButton.setEnabled(false)
                    self.stopButton.setEnabled(true)
                }
            }
        }) { (error) -> Void in
            print("[Watch] Send failed! error: \(error)")
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
        startButton.setEnabled(false)

        sendStart()
    }

    @IBAction func stopButtonPressed() {
        stopButton.setEnabled(false)

        sendStop()
    }

    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        print("[Watch] session started")

        switch toState {
        case .Running:
            self.workoutDidStart(date)
            stopButton.setEnabled(true)
        case .Ended:
            self.workoutDidEnd(date)
            startButton.setEnabled(true)
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
        startButton.setEnabled(true)
        stopButton.setEnabled(false)
    }

    private func workoutDidStart(date: NSDate) {
        print("[Watch] workout did start")

        let query = self.createStreamingHeartRateQuery(date)
        self.healthStore.executeQuery(query)
    }

    private func workoutDidEnd(date: NSDate) {
        print("[Watch] workout did end")
    }
}

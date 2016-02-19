//
//  BackendManager.swift
//  feuerMoni
//
//  Copyright © 2016 jambit. All rights reserved.
//

import Foundation
import CocoaLumberjack
import Alamofire

protocol BackendManagerDelegate {
}

enum VitalDataType {
    case Heartrate
}

class BackendManager {

    private let baseUrl = "http://192.168.232.112:8080/api/v1"

    private var isActive = false

    private let delegate: BackendManagerDelegate

    init(delegate: BackendManagerDelegate) {
        self.delegate = delegate
    }

    func activate(completion: (Bool) -> ()) {
        let parameters = [
            "ffId": "[AW]TimCook",
            "status": "CONNECTED"
        ]
        Alamofire.request(.POST, baseUrl + "/data", parameters: parameters, encoding: .JSON, headers: ["Content-Type": "application/json"])
            .responseJSON { response in
                print(response.request) // original URL request
                print(response.response) // URL response
                print(response.data) // server data
                print(response.result) // result of response serialization

                switch response.result {
                case Result.Failure(_):
                    DDLogError("Error while posting")
                    completion(false)
                case Result.Success(_):
                    if let JSON = response.result.value {
                        DDLogDebug("JSON: \(JSON)")
                        completion(true)
                    }
                }
            }

        isActive = true
    }

    func deactivate(completion: (Bool) -> ()) {
        isActive = false

        let parameters = [
            "ffId": "[AW]TimCook",
            "status": "DISCONNECTED"
        ]
        Alamofire.request(.POST, baseUrl + "/data", parameters: parameters, encoding: .JSON, headers: ["Content-Type": "application/json"])
            .responseJSON { response in
                print(response.request) // original URL request
                print(response.response) // URL response
                print(response.data) // server data
                print(response.result) // result of response serialization

                switch response.result {
                case Result.Failure(_):
                    DDLogError("Error while posting")
                    completion(false)
                case Result.Success(_):
                    if let JSON = response.result.value {
                        DDLogDebug("JSON: \(JSON)")
                        completion(true)
                    }
                }
            }
    }

    func update(type: VitalDataType, value: Double, completion: (Bool) -> ()) {
        if !isActive {
            print("Unable to send update to backend. BackendManager inactive.")
            return
        }
        let parameters = [
            "ffId": "[AW]TimCook",
            "status": "OK",
            "vitalSigns": [
                "heartRate": Int(value),
                "stepCount": -1
            ]
        ]
        Alamofire.request(.POST, baseUrl + "/data", parameters: parameters, encoding: .JSON, headers: ["Content-Type": "application/json"])
            .responseJSON { response in
                print(response.request) // original URL request
                print(response.response) // URL response
                print(response.data) // server data
                print(response.result) // result of response serialization

                switch response.result {
                case Result.Failure(_):
                    DDLogError("Error while posting")
                    completion(false)
                case Result.Success(_):
                    if let JSON = response.result.value {
                        DDLogDebug("JSON: \(JSON)")
                        completion(true)
                    }
                }
            }
    }
}
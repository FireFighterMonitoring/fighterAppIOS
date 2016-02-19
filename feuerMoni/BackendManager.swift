//
//  BackendManager.swift
//  feuerMoni
//
//  Created by Sebastian Stallenberger on 19.02.16.
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

    let baseUrl = "http://192.168.234.222:8080/api/v1"

    let delegate: BackendManagerDelegate

    init(delegate: BackendManagerDelegate) {
        self.delegate = delegate
    }

    func activate() {
//        Alamofire.request(.GET, baseUrl + "/data", parameters: ["foo": "bar"])
//            .responseJSON { response in
//                print(response.request) // original URL request
//                print(response.response) // URL response
//                print(response.data) // server data
//                print(response.result) // result of response serialization
//
//                if let JSON = response.result.value {
//                    print("JSON: \(JSON)")
//                }
//            }
    }

    func deactivate() {
    }

    func update(type: VitalDataType, value: Double) {

        let parameters = [
            "ffId": "AppleWatch",
            "status": "OK",
            "vitalSigns": [
                "heartRate": Int(value),
                "stepCount": 0
            ]
        ]
        Alamofire.request(.POST, baseUrl + "/data", parameters: parameters, encoding: .JSON, headers: ["Content-Type": "application/json"])
            .responseJSON { response in
                print(response.request) // original URL request
                print(response.response) // URL response
                print(response.data) // server data
                print(response.result) // result of response serialization

                if let JSON = response.result.value {
                    DDLogDebug("JSON: \(JSON)")
                }
            }
    }
}
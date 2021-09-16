//
//  ApiManager.swift
//  Vehicle and
//
//  Created by Abdurrahman on 12/13/20.
//

import Moya

let ApiProvider = MoyaProvider<ApiManager>()

enum ApiManager {
    case convertCurrency(fromAmount: String, fromCurrency: String, toCurrency: String)
}

// MARK: - TargetType Protocol Implementation
extension ApiManager: TargetType {
    var baseURL: URL {
        return URL(string: Constants.baseURL)!
    }
    
    var path: String {
        switch self {
        case .convertCurrency(let fromAmount, let fromCurrency, let toCurrency):
            return "currency/commercial/exchange/\(fromAmount)-\(fromCurrency)/\(toCurrency)/latest"
        }
    }
    
    var parameters: [String: Any]? {
        let params = [String : Any]()
        switch self {
        case .convertCurrency:
            break
        }
        return params
    }
    
    var parameterEncoding: Moya.ParameterEncoding {
        return JSONEncoding.default
    }
    
    var method: Moya.Method {
        switch self {
        case .convertCurrency:
            return .get
            // this for upcomming request
//        default:
//            return .post
        }
    }
    
    var task: Task {
        switch self {
        case .convertCurrency:
            return .requestParameters(parameters: parameters ?? [:], encoding: URLEncoding.queryString)
        // this for upcomming post request
//        default:
//            return .requestParameters(parameters: parameters ?? [:], encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String: String]? {
        var headers = [String: String]()
        headers["Content-Type"] = "application/json"
        return headers
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var manager: Data {
        return Data()
    }
}

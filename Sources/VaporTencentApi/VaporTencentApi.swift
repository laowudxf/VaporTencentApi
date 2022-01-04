//
//  File.swift
//  
//
//  Created by 钟志远 on 2021/12/18.
//

import Foundation
import Vapor
import SwiftyJSON

public class VaporTencentApi<T: TencentAPiPayload> {
    public var secretId = Environment.get("TencentSecretId") ?? ""
    public var secretKey = Environment.get("TencentSecretKey") ?? ""
    public var region = "ap-shanghai"
    let contentType = "application/json; charset=utf-8"
    
    let version = T.version
    let logger: Logger
    private let algorithm = "TC3-HMAC-SHA256"
    
    public init(logger: Logger) {
        self.logger = logger
    }
   
    public struct ApiRequest {
        var host: String {
            return T.service + ".tencentcloudapi.com"
        }
        
        public var region: String = "ap-shanghai"
        let method = "POST"
        public var payload: T
        public init(payload: T) {
            self.payload = payload
        }
    }
    
    
    public func sendReq(client: Client, apiRequst: ApiRequest) -> EventLoopFuture<ClientResponse> {
        self.region = apiRequst.region
       let authRep = genAuthorization(request: apiRequst)
        // step 5 generate request
        return client.post("https://\(apiRequst.host)") { req in
            try req.content.encode(authRep.payload)
            req.headers.replaceOrAdd(name: "Authorization", value: authRep.auth)
            req.headers.replaceOrAdd(name: "Host", value: apiRequst.host)
            req.headers.replaceOrAdd(name: "X-TC-Action", value: T.action)
            req.headers.replaceOrAdd(name: "X-TC-Timestamp", value: authRep.timestamp)
            req.headers.replaceOrAdd(name: "X-TC-Version", value: T.version)
            req.headers.replaceOrAdd(name: "X-TC-Region", value: region)
            req.headers.replaceOrAdd(name: "Content-Type", value: contentType)
        }
    }
    
    public  func sendReq(client: Client, apiRequst: ApiRequest) async throws -> ClientResponse {
        let authRep = genAuthorization(request: apiRequst)
        // step 5 generate request
       let response = try await client.post("https://\(apiRequst.host)") { req in
            try req.content.encode(authRep.payload)
            req.headers.replaceOrAdd(name: "Authorization", value: authRep.auth)
            req.headers.replaceOrAdd(name: "Host", value: apiRequst.host)
            req.headers.replaceOrAdd(name: "X-TC-Action", value: T.action)
            req.headers.replaceOrAdd(name: "X-TC-Timestamp", value: authRep.timestamp)
            req.headers.replaceOrAdd(name: "X-TC-Version", value: T.version)
            req.headers.replaceOrAdd(name: "X-TC-Region", value: region)
            req.headers.replaceOrAdd(name: "Content-Type", value: contentType)
        }
        let json = try response.content.decode(JSON.self)
        if json["Response"]["Error"].dictionaryObject != nil {
            print(json["Response"]["Error"].rawValue)
            throw Abort(.internalServerError, reason: "内部错误")
        }
        return response
    }

    
    public struct AuthResponse {
        let auth: String
        let timestamp: String
        let payload: String
    }
    
    public func genAuthorization(request: ApiRequest) -> AuthResponse {
        let host = request.host
        
        // step 1: build canonical request string
        let timestamp = Int(Date().timeIntervalSince1970).description
        let httpRequestMethod = request.method
        let canonicalUri = "/"
        let canonicalQueryString = ""
        let canonicalHeaders = "content-type:\(contentType)\nhost:\(host)\n"
        let signedHeaders = "content-type;host"
        
        let payloadData = try! JSONEncoder().encode(request.payload)
        let payload: String = String.init(data: payloadData, encoding: .utf8)!
        let hashedRequestPayload = SHA256.hash(data: payload.data(using: .utf8)!)
        
        logger.debug("payload: \(payload)")
        let canonicalRequest = "\(httpRequestMethod)\n\(canonicalUri)\n\(canonicalQueryString)\n\(canonicalHeaders)\n\(signedHeaders)\n\(hashedRequestPayload.hex)"
        logger.debug("canonicalRequest: \(canonicalRequest)")
        
        // step 2: build string to sign
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: .init())
        let credentialScope = "\(date)/\(T.service)/tc3_request"
        let hashedCanonicalRequest: String = SHA256.hash(data: canonicalRequest.data(using: .utf8)!).hex
        let stringToSign = algorithm + "\n" + timestamp + "\n" + credentialScope + "\n" + hashedCanonicalRequest
        logger.debug("stringToSign: \(stringToSign)")
        
        // step 3: sign string
        let secretDate = HMAC<SHA256>.tencentHash(key: ("TC3" + secretKey).data(using: .utf8)!, data: date.data(using: .utf8)!)
        logger.debug("secretDate: \(secretDate.hex)")
        let secretService = HMAC<SHA256>.tencentHash(key: secretDate, data: T.service.data(using: .utf8)!)
        logger.debug("secretService: \(secretService.hex)")
        let secretSigning = HMAC<SHA256>.tencentHash(key: secretService, data: "tc3_request".data(using: .utf8)!)
        logger.debug("secretSigning: \(secretSigning.hex)")
        let stringToSign_test = algorithm + "\n" + timestamp + "\n" + credentialScope + "\n" + hashedCanonicalRequest
        let signature = HMAC<SHA256>.tencentHash(key: secretSigning, data: stringToSign_test.data(using: .utf8)!).hex
        logger.debug("signature: \(signature)")
        
        
        // step 4: build authorization
        let authorization = algorithm + " Credential=" + secretId + "/" + credentialScope + ", SignedHeaders=content-type;host, Signature=" + signature
        logger.debug(.init(stringLiteral:  authorization))
        return .init(auth: authorization, timestamp: timestamp, payload: payload)
    }
}


public extension HMAC {
    static func tencentHash(key: Data, data: Data) -> Data {
        var hmac = HMAC<SHA256>.init(key: SymmetricKey.init(data: key))
        hmac.update(data: data)
        let secretDate = hmac.finalize()
        return Data.init(secretDate)
    }
}


func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

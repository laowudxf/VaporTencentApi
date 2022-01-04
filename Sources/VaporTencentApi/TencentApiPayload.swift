//
//  File.swift
//  
//
//  Created by 钟志远 on 2021/12/20.
//

import Foundation
import Vapor

public extension TencentAPiPayload {
    func sendReq(req: Request, region: String = "ap-shanghai") async throws -> ClientResponse {
        let api = VaporTencentApi<Self>(logger: req.logger)
        api.region = region
        return try await api.sendReq(client:
                                        req.client, apiRequst:
                                        VaporTencentApi<Self>.ApiRequest.init(payload: self)
        )
    }
}

public protocol TencentAPiPayload: Encodable {
    static var version: String {get}
    static var action: String {get}
    static var service: String {get}
}

public struct CVMPayload: TencentAPiPayload {
    public static let version = "2017-03-12"
    public static let action = "DescribeInstances"
    public static let service = "cvm"
    public struct Filter: Content {
        let Values: [String]
        let Name: String
        public init(Values: [String], Name: String) {
            self.Values = Values
            self.Name = Name
        }
    }
    public let Limit: Int
    public let Filters: [Filter]
    
    public init(Limit: Int, Filters: [Filter]) {
        self.Limit = Limit
        self.Filters = Filters
    }
}

public struct STSPayload: TencentAPiPayload {
    public static let version = "2018-08-13"
    public static let action = "AssumeRole"
    public static let service = "sts"
    
    let RoleArn = Environment.get("TencentRoleArn") ?? ""
    let RoleSessionName = "sts"
    public init(){}
}


public struct MailPayload: TencentAPiPayload {
    public static let version = "2020-10-02"
    public static let action = "SendEmail"
    public static let service = "ses"
    public struct TemplateStruct: Encodable {
        let TemplateID: Int
        let TemplateData: String
        
        public init(TemplateID: Int, TemplateData: String) {
            self.TemplateID = TemplateID
            self.TemplateData = TemplateData
        }
    }
    
    public let FromEmailAddress: String
    public let Destination: [String]
    public let Subject: String
    public let Template: TemplateStruct
    
    public init(FromEmailAddress: String, Destination: [String], Subject: String, Template: TemplateStruct) {
        self.FromEmailAddress = FromEmailAddress
        self.Destination = Destination
        self.Subject = Subject
        self.Template = Template
    }
}

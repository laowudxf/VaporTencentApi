# VaporTencentApi

### Tencent Api for Vapor.


# simple usage:
  ```
    func getSts(req: Request) async throws -> JSON {
        let resp: ClientResponse = try await TencentClouldApi<STSPayload>(logger: req.logger)
            .sendReq(client:
                        req.client, apiRequst:
                        TencentClouldApi<STSPayload>.ApiRequest.init(payload: .init())
            )
        
        return try resp.content.decode(JSON.self)["Response"]
    }
  ```


# There are some simple Api payload is implement: 
  - CVMPayload
  - STSPayload
  - MailPayload

If you need some other ApiPayload, you should implement by yourself reference to [腾讯云api浏览器](https://console.cloud.tencent.com/api/explorer).

# Need some variable in .env

#for stsPayload to get temp sts

TencentRoleArn

TencentSecretId

TencentSecretKey


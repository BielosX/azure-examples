namespace HttpTriggerFunction

open Microsoft.AspNetCore.Mvc
open Microsoft.Azure.WebJobs
open Microsoft.Azure.WebJobs.Extensions.Http
open Microsoft.AspNetCore.Http
open Microsoft.Extensions.Logging

module HttpTriggerFunction =

    [<FunctionName("HttpTriggerFunction")>]
    let run ([<HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)>]req: HttpRequest) (log: ILogger) =
        async {
            log.LogInformation("Hello from HttpTriggerFunction. Processing HTTP request.")
            let resultBody = Map [("Status", "OK"); ("Message", "Hello")]
            let result = JsonResult(resultBody)
            result.StatusCode <- 200
            return result
        } |> Async.StartAsTask
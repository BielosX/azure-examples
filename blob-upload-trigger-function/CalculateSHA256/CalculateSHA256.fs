namespace CalculateSHA256

open System.IO
open Microsoft.Azure.WebJobs
open Microsoft.Extensions.Logging

module CalculateSHA256 =

    [<FunctionName("CalculateSHA256")>]
    let run ([<BlobTrigger("demo-container/{name}", Connection="StorageConnectionString")>] myBlob: Stream, name: string, log: ILogger) =
        let msg = sprintf "F# Blob trigger function Processed blob\nName: %s \n Size: %d Bytes" name myBlob.Length
        log.LogInformation msg

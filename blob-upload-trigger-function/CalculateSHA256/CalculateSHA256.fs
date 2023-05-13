namespace CalculateSHA256

open System
open System.IO
open Microsoft.Azure.WebJobs
open Microsoft.Extensions.Logging
open Azure.Storage.Blobs
open System.Security.Cryptography

module CalculateSHA256 =

    [<FunctionName("CalculateSHA256")>]
    let run ([<BlobTrigger("demo-container/{name}", Connection="StorageConnectionString")>] myBlob: Stream, name: string, log: ILogger) =
        let msg = sprintf "Blob\nName: %s \n Size: %d Bytes" name myBlob.Length
        log.LogInformation msg
        let connString = Environment.GetEnvironmentVariable("StorageConnectionString")
        let blobClient = BlobClient(connString, "demo-container", name)
        let sha256 = SHA256.Create()
        let shaValue = System.Convert.ToHexString(sha256.ComputeHash(myBlob))
        let logSha = sprintf "Calculated SHA256: %s" shaValue
        log.LogInformation logSha
        let blobTags = blobClient.GetTags().Value.Tags
        blobTags.Add("SHA256", shaValue)
        blobClient.SetTags(blobTags) |> ignore

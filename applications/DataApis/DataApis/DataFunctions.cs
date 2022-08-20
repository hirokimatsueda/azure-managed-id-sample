using Azure.Identity;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.IO;
using System.Threading.Tasks;

namespace DataApis
{
    public static class DataFunctions
    {
        private static Lazy<CosmosClient> lazyClient = new Lazy<CosmosClient>(InitializeCosmosClient);
        private static CosmosClient cosmosClient => lazyClient.Value;

        private static CosmosClient InitializeCosmosClient()
        {
            return new CosmosClient(Environment.GetEnvironmentVariable("COSMOS_ENDPOINT", EnvironmentVariableTarget.Process), new DefaultAzureCredential());
        }

        [FunctionName("GetData")]
        public static async Task<IActionResult> Get(
            [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequest req, ILogger log)
        {
            log.LogInformation("Get function processed a request.");

            if (!req.Query.TryGetValue("id", out var id))
            {
                return new BadRequestObjectResult("Parameter 'id' is required");
            }
            if (!req.Query.TryGetValue("category", out var category))
            {
                return new BadRequestObjectResult("Parameter 'category' is required");
            }

            var container = cosmosClient.GetContainer("db", "data");

            try
            {
                var data = await container.ReadItemAsync<dynamic>(id, new PartitionKey(category));
                return new OkObjectResult(data.Resource);
            }
            catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                return new NotFoundResult();
            }
        }

        [FunctionName("PutData")]
        public static async Task<IActionResult> Put([HttpTrigger(AuthorizationLevel.Function, "put")] HttpRequest req, ILogger log)
        {
            log.LogInformation("Put function processed a request.");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);

            if (data.id == null)
            {
                return new BadRequestObjectResult("Element 'id' is required");
            }
            if (data.category == null)
            {
                return new BadRequestObjectResult("Element 'category' is required.");
            }

            var container = cosmosClient.GetContainer("db", "data");
            await container.UpsertItemAsync(data);

            return new OkResult();
        }
    }
}

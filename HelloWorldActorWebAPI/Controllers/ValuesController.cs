using System;
using System.Collections.Generic;
using System.Threading;
using System.Web.Http;
using Microsoft.ServiceFabric.Actors;
using SFTF.HelloWorldActor.Interfaces;
using Microsoft.ServiceFabric.Actors.Client;

namespace HelloWorldActorWebAPI.Controllers
{
    [ServiceRequestActionFilter]
    public class ValuesController : ApiController
    {
        private const string _serviceURI = "fabric:/SFTF/HelloWorldActorService";

        // GET api/values 
        public string Get()
        {
            //return new string[] { "value1", "value2" };
            var actor = ActorProxy.Create<IHelloWorldActor>(new ActorId(0), new Uri(_serviceURI));
            var count = actor.GetCountAsync(default(CancellationToken)).GetAwaiter().GetResult();
            return count.ToString();
        }

        // GET api/values/5 
        public string Get(int id)
        {
            return "value";
        }

        // POST api/values 
        public void Post([FromBody]string value)
        {
        }

        // PUT api/values/5 
        public void Put(int id, [FromBody]string value)
        {
        }

        // DELETE api/values/5 
        public void Delete(int id)
        {
        }
    }
}

using Microsoft.ServiceFabric.Actors;
using Microsoft.ServiceFabric.Actors.Client;
using SFTF.HelloWorldActor.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace SFTF.HelloWorldActor.CLI
{
    class Program
    {
        private const string _serviceURI = "fabric:/SFTF/HelloWorldActorService";

        static void Main(string[] args)
        {
            var actor = ActorProxy.Create<IHelloWorldActor>(new ActorId(0), new Uri(_serviceURI));

            var cts = new CancellationTokenSource();

            var writer = Task.Run(
                () =>
                {
                    var count = actor.GetCountAsync(cts.Token).GetAwaiter().GetResult();
                    while (!cts.IsCancellationRequested)
                    {
                        Task.Delay(1000).Wait();
                        actor.SetCountAsync(count++, cts.Token);
                    }
                }, cts.Token);

            var reader = Task.Run(
                () =>
                {
                    while (!cts.IsCancellationRequested)
                    {
                        var count = actor.GetCountAsync(cts.Token).GetAwaiter().GetResult();
                        Console.WriteLine(count);
                        Task.Delay(500).Wait();
                    }
                }, cts.Token);

            Console.ReadLine();

            cts.Cancel();
            Task.WaitAll(writer, reader);
        }
    }
}

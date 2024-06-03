using System.Net;
using System.Net.Sockets;
using System.Net.WebSockets;
using System.Text;
using MicroParams;
using Newtonsoft.Json;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls("http://localhost:8080");
builder.WebHost.UseUrls($"http://{GetLocalIPAddress()}:8080");
var app = builder.Build();
app.UseWebSockets();

List<double> data = new ();
string message = string.Empty;
var buffer = new byte[1024 * 4];
var index = -1;
var counter = 1;
bool goRight = true;
Params? objParams = null;
CancellationTokenSource? cts = null;

Guid ongoingProcessId = Guid.Empty;

app.Map("/ws", async context => 
{
    if (context.WebSockets.IsWebSocketRequest)
    {
        using var ws = await context.WebSockets.AcceptWebSocketAsync();
        var rand = new Random();

        // receining params
        var microParams = await ws.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
        string name = Encoding.UTF8.GetString(buffer, 0, microParams.Count).Replace('"', '\'');

        objParams = JsonConvert.DeserializeObject<Params>(name);
        cts = new CancellationTokenSource();

        Console.WriteLine($"Params for {objParams!.ProccessId} received");

        var handleClientMessageTask = Task.Run(async () =>
        {
            while (ws.State == WebSocketState.Open)
            {
                var result = await ws.ReceiveAsync(new ArraySegment<byte>(buffer), cts.Token);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    await ws.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed by client", cts.Token);
                    Console.WriteLine($"Process {objParams.ProccessId} closed by client");
                    cts.Cancel();
                }
                else
                {
                    var message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                    Console.WriteLine("Received message from client: " + message);
                }
            }
        });

        var sendTask = Task.Run(async () =>
        {
            var height = 0d;
            var stopMessage = "stop";

            if (objParams.ProccessId != ongoingProcessId)
            {
                ResetParams();
                ongoingProcessId = objParams.ProccessId;
            }

            while (ws.State == WebSocketState.Open)
            {
                if (index < 0)
                {
                    message = stopMessage;
                }
                else
                {
                    height = rand.NextDouble();
                    data.Add(height);
                    message = $"{height}, {index}";

                    if (counter == objParams!.SizeInPxl)
                    {
                        counter = 0;
                        index -= objParams.SizeInPxl;
                        goRight = !goRight;
                    }
                    else if (goRight)
                    {
                        index ++;
                    }
                    else
                    {
                        index --;
                    }
                }

                var messageBytes = Encoding.UTF8.GetBytes(message);

                await ws.SendAsync(new ArraySegment<byte>(messageBytes), WebSocketMessageType.Text, true, cts.Token);
                
                Console.WriteLine($"{counter}. Sent: " + message);
                if (message == stopMessage)
                {
                    break;
                }

                await Task.Delay(objParams!.TimePerPixel);
                counter++;
            }
        });

        await Task.WhenAll(handleClientMessageTask, sendTask);
    }
    else
    {
        context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
    }
});

void ResetParams()
{
    index = -1;
    counter = 1;
    goRight = true;
    index = index == -1 ? objParams!.SizeInPxl * objParams.SizeInPxl - objParams.SizeInPxl : index;
}

static string GetLocalIPAddress()
{
    var host = Dns.GetHostEntry(Dns.GetHostName());
    foreach (var ip in host.AddressList)
    {
        if (ip.AddressFamily == AddressFamily.InterNetwork)
        {
            return ip.ToString();
        }
    }
    throw new Exception("No network adapters with an IPv4 address in the system!");
}


await app.RunAsync();
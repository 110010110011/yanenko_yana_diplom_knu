using Newtonsoft.Json;

namespace MicroParams;

public class Params
{
    [JsonProperty("processId")]
    public Guid ProccessId { get; set; }

    [JsonProperty("timePerPxl")]
    public int TimePerPixel { get; set; }
    
    [JsonProperty("proportionalFeedback")]
    public int ProportionalFeedback { get; set; }

    [JsonProperty("integralFeedback")]
    public int IntegralFeedback { get; set; }

    [JsonProperty("differentialFeedback")]
    public int DifferentialFeedback { get; set; }

    [JsonProperty("sizeInPxl")]
    public int SizeInPxl { get; set; }

    [JsonProperty("sizeInNm")]
    public int SizeInNm { get; set; }

    [JsonProperty("sampleBias")]
    public int SampleBias { get; set; }

    [JsonProperty("tunnelingCurrent")]
    public int TunnelingCurrent { get; set; }

    [JsonProperty("sampleName")]
    public string? SampleName { get; set; }

    [JsonProperty("tipName")]
    public string? TipName { get; set; }
}
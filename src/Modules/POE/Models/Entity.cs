using System;

namespace AFWGSS.POE.Models
{
    public class Entity
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Name { get; set; } = "";
        public EntityType Type { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public double Altitude { get; set; }
        public string Force { get; set; } = "Blue";
    }
    
    public enum EntityType
    {
        Fighter,
        Transport,
        Helicopter,
        SAM,
        Radar,
        Airport
    }
}
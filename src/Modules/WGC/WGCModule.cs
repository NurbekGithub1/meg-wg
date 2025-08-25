using AFWGSS.Shared.Interfaces;
using System.Windows.Controls;

namespace AFWGSS.WGC
{
    public class WGCModule : IModule
    {
        public string Name => "War Game Configuration";
        public UserControl View { get; private set; } = null!;

        public void Initialize()
        {
            View = new WGCView();
        }

        public void Activate() { }
        public void Deactivate() { }
    }
    
    public class WGCView : UserControl
    {
        public WGCView()
        {
            Content = new TextBlock { Text = "WGC Module - System Configuration" };
        }
    }
}
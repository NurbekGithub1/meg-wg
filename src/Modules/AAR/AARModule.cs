using AFWGSS.Shared.Interfaces;
using System.Windows.Controls;

namespace AFWGSS.AAR
{
    public class AARModule : IModule
    {
        public string Name => "After Action Review";
        public UserControl View { get; private set; } = null!;

        public void Initialize()
        {
            View = new AARView();
        }

        public void Activate() { }
        public void Deactivate() { }
    }
    
    public class AARView : UserControl
    {
        public AARView()
        {
            Content = new TextBlock { Text = "AAR Module - Review & Analysis" };
        }
    }
}
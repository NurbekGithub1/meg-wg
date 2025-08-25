using AFWGSS.Shared.Interfaces;
using System.Windows.Controls;

namespace AFWGSS.DAAOE
{
    public class DAAOEModule : IModule
    {
        public string Name => "Direction, Analysis and Animation of Exercises";
        public UserControl View { get; private set; } = null!;

        public void Initialize()
        {
            View = new DAAOEView();
        }

        public void Activate() { }
        public void Deactivate() { }
    }
    
    public class DAAOEView : UserControl
    {
        public DAAOEView()
        {
            Content = new TextBlock { Text = "DAAOE Module - Exercise Control" };
        }
    }
}
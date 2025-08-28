using Prism.Ioc;
using Prism.Modularity;
using System.Windows.Controls;

namespace AFWGSS.WGC
{
    public class WGCModule : IModule
    {
        public void OnInitialized(IContainerProvider containerProvider)
        {
            // Пока ничего не делаем
        }

        public void RegisterTypes(IContainerRegistry containerRegistry)
        {
            // Регистрируем View этого модуля для навигации
            containerRegistry.RegisterForNavigation<WGCView>();
        }
    }
    
    public class WGCView : UserControl
    {
        public WGCView()
        {
            Content = new TextBlock { Text = "WGC Module - System Configuration" };
        }
    }
}
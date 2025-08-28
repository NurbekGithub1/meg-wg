using Prism.Ioc;
using Prism.Modularity;
using System.Windows.Controls;

namespace AFWGSS.AAR
{
    public class AARModule : IModule
    {
        public void OnInitialized(IContainerProvider containerProvider)
        {
            // Пока ничего не делаем
        }

        public void RegisterTypes(IContainerRegistry containerRegistry)
        {
            containerRegistry.RegisterForNavigation<AARView>();
        }
    }
    
    // Этот View тоже нужно зарегистрировать для навигации
    public class AARView : UserControl
    {
        public AARView()
        {
            Content = new TextBlock { Text = "AAR Module - Review & Analysis" };
        }
    }
}
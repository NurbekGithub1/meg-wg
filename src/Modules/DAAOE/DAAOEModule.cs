using Prism.Ioc;
using Prism.Modularity;
using System.Windows.Controls;

namespace AFWGSS.DAAOE
{
    public class DAAOEModule : IModule
    {
        public void OnInitialized(IContainerProvider containerProvider)
        {
            // Пока ничего не делаем
        }

        public void RegisterTypes(IContainerRegistry containerRegistry)
        {
            // Регистрируем View этого модуля для навигации
            containerRegistry.RegisterForNavigation<DAAOEView>();
        }
    }

    public class DAAOEView : UserControl
    {
        public DAAOEView()
        {
            Content = new TextBlock { Text = "DAAOE Module - Exercise Control" };
        }
    }
}
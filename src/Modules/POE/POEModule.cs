using AFWGSS.POE.Views;
using Prism.Ioc;
using Prism.Modularity;

namespace AFWGSS.POE
{
    public class POEModule : IModule
    {
        public void OnInitialized(IContainerProvider containerProvider)
        {
            // Инициализация модуля при необходимости
        }

        public void RegisterTypes(IContainerRegistry containerRegistry)
        {
            containerRegistry.RegisterForNavigation<POEMainView>();
        }
    }
}
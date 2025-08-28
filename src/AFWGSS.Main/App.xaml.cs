using System.Windows;
using Prism.DryIoc;
using Prism.Ioc;
using Prism.Modularity;
using Prism.Navigation.Regions;

namespace AFWGSS.Main
{
    public partial class App : PrismApplication
    {
        protected override Window CreateShell()
        {
            return Container.Resolve<MainWindow>();
        }

        protected override void RegisterTypes(IContainerRegistry containerRegistry)
        {
            // Регистрация представлений для навигации
            containerRegistry.RegisterForNavigation<POE.Views.POEMainView>("POEMainView");
            containerRegistry.RegisterForNavigation<DAAOE.DAAOEView>("DAAOEView");
            containerRegistry.RegisterForNavigation<AAR.AARView>("AARView");
            containerRegistry.RegisterForNavigation<WGC.WGCView>("WGCView");
        }

        protected override void ConfigureModuleCatalog(IModuleCatalog moduleCatalog)
        {
            moduleCatalog.AddModule<POE.POEModule>();
            moduleCatalog.AddModule<DAAOE.DAAOEModule>();
            moduleCatalog.AddModule<AAR.AARModule>();
            moduleCatalog.AddModule<WGC.WGCModule>();
        }

        protected override void OnInitialized()
        {
            base.OnInitialized();

            // Навигация к начальному модулю
            var regionManager = Container.Resolve<IRegionManager>();
            regionManager.RequestNavigate("ContentRegion", "POEMainView");
        }
    }
}

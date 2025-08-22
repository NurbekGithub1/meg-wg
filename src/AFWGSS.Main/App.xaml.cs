
using Prism.Unity;
using Prism.Ioc;
using System.Windows;

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
            // Регистрация сервисов
            containerRegistry.RegisterSingleton<ISimulationCore, SimulationCore>();
            containerRegistry.RegisterSingleton<IDatabaseService, DatabaseService>();

            // Регистрация модулей
            containerRegistry.Register<IPOEModule, POEModule>();
            containerRegistry.Register<IDAAOEModule, DAAOEModule>();
            containerRegistry.Register<IAARModule, AARModule>();
        }

        protected override void ConfigureModuleCatalog(IModuleCatalog moduleCatalog)
        {
            // Модули будут загружаться динамически
        }
    }
}

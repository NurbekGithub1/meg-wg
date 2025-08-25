using Prism.Unity;
using Prism.Ioc;
using Prism.Modularity;
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
            // Пока закомментируем, создадим позже
            // containerRegistry.RegisterSingleton<ISimulationCore, SimulationCore>();
        }

        protected override void ConfigureModuleCatalog(IModuleCatalog moduleCatalog)
        {
            // Модули будут добавлены позже
        }
    }
}
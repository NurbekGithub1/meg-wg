// src/AFWGSS.Main/App.xaml.cs
using System.Windows;
using Prism.DryIoc;
using Prism.Ioc;
using Prism.Modularity;
using Prism.Navigation.Regions;   // ВАЖНО: Prism 9 (не Prism.Regions)
using AFWGSS.Shared;

namespace AFWGSS.Main
{
    public partial class App : PrismApplication
    {
        protected override Window CreateShell()
            => Container.Resolve<MainWindow>();

        protected override void RegisterTypes(IContainerRegistry containerRegistry)
        {
            // Регистрация представлений для навигации с ключами из ViewKeys
            containerRegistry.RegisterForNavigation<POE.Views.POEMainView>(ViewKeys.POEMain);
            containerRegistry.RegisterForNavigation<DAAOE.DAAOEView>(ViewKeys.DAAOE);
            containerRegistry.RegisterForNavigation<AAR.AARView>(ViewKeys.AAR);
            containerRegistry.RegisterForNavigation<WGC.WGCView>(ViewKeys.WGC);

            // Пример: регистрация диалогов Prism (когда будете внедрять диалоги)
             containerRegistry.RegisterDialog<
				AFWGSS.POE.Views.MOE.MOEEditorDialog,           // View (желательно UserControl)
				AFWGSS.POE.ViewModels.MOEEditorDialogViewModel  // ViewModel диалога (IDialogAware)
				>("MOEEditor");
        }

        protected override void ConfigureModuleCatalog(IModuleCatalog moduleCatalog)
        {
            // Подключение модулей (как у вас и было)
            moduleCatalog.AddModule<POE.POEModule>();
            moduleCatalog.AddModule<DAAOE.DAAOEModule>();
            moduleCatalog.AddModule<AAR.AARModule>();
            moduleCatalog.AddModule<WGC.WGCModule>();
        }

        protected override void OnInitialized()
        {
            base.OnInitialized();
            // Стартовая навигация в главный регион
            var regionManager = Container.Resolve<IRegionManager>();
            regionManager.RequestNavigate(RegionNames.ContentRegion, ViewKeys.POEMain);
        }
    }
}

using AFWGSS.POE.Views;
using Prism.Ioc;
using Prism.Modularity;
using Prism.Navigation.Regions;

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
			
			containerRegistry.RegisterDialog<
				AFWGSS.POE.Views.MOE.MOEEditorDialog,
				AFWGSS.POE.ViewModels.MOEEditorDialogViewModel
				>("MOEEditor");
        }
    }
}
// src/AFWGSS.Main/ViewModels/MainWindowViewModel.cs
using Prism.Mvvm;
using Prism.Commands;
using Prism.Navigation.Regions;   // Prism 9
using AFWGSS.Shared;

namespace AFWGSS.Main.ViewModels
{
    public class MainWindowViewModel : BindableBase
    {
        private readonly IRegionManager _regionManager;

        public DelegateCommand<string> NavigateCommand { get; }

        public MainWindowViewModel(IRegionManager regionManager)
        {
            _regionManager = regionManager;
            NavigateCommand = new DelegateCommand<string>(ExecuteNavigate);
        }

        private void ExecuteNavigate(string viewKey)
        {
            if (string.IsNullOrWhiteSpace(viewKey)) return;
            _regionManager.RequestNavigate(RegionNames.ContentRegion, viewKey);
        }
    }
}

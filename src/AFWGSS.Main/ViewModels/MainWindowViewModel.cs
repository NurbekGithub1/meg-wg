// src/AFWGSS.Main/ViewModels/MainWindowViewModel.cs
using Prism.Commands;
using Prism.Mvvm;
using Prism.Navigation.Regions;
using System.Windows; // GridLength

namespace AFWGSS.Main.ViewModels
{
    public class MainWindowViewModel : BindableBase
    {
        private readonly IRegionManager _regionManager;

        public DelegateCommand<string> NavigateCommand { get; }

        // --- размеры панели ---
        private GridLength _sideBarWidth = new GridLength(160);
        public GridLength SideBarWidth
        {
            get => _sideBarWidth;
            private set => SetProperty(ref _sideBarWidth, value);
        }

        private bool _isSidebarCollapsed;
        public bool IsSidebarCollapsed
        {
            get => _isSidebarCollapsed;
            set
            {
                if (SetProperty(ref _isSidebarCollapsed, value))
                    SideBarWidth = value ? new GridLength(56) : new GridLength(160);
            }
        }

        // Для подсветки активного пункта
        private string _currentViewKey = string.Empty;
        public string CurrentViewKey
        {
            get => _currentViewKey;
            set => SetProperty(ref _currentViewKey, value);
        }

        public MainWindowViewModel(IRegionManager regionManager)
        {
            _regionManager = regionManager;

            NavigateCommand = new DelegateCommand<string>(Navigate);

            // начальное состояние панели
            IsSidebarCollapsed = false;                      // раскрыта
            SideBarWidth = new GridLength(160);
        }

        private void Navigate(string viewKey)
        {
            if (string.IsNullOrWhiteSpace(viewKey))
                return;

            _regionManager.RequestNavigate(AFWGSS.Shared.RegionNames.ContentRegion, viewKey);
            CurrentViewKey = viewKey;
        }
    }
}

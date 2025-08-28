using MahApps.Metro.Controls;
using Prism.Navigation.Regions;
using System.Windows;
using System.Windows.Controls;

namespace AFWGSS.Main
{
    public partial class MainWindow : MetroWindow
    {
        private readonly IRegionManager _regionManager;

        public MainWindow(IRegionManager regionManager)
        {
            InitializeComponent();
            _regionManager = regionManager;
        }

        private void ModuleButton_Click(object sender, RoutedEventArgs e)
        {
            if (sender is RadioButton button && button.Tag is string viewName)
            {
                _regionManager.RequestNavigate("ContentRegion", viewName);
            }
        }

        private void MenuItem_Exit_Click(object sender, RoutedEventArgs e)
        {
            Application.Current.Shutdown();
        }
    }
}
using MahApps.Metro.Controls;
using System.Windows;

namespace AFWGSS.Main
{
    public partial class MainWindow : MetroWindow
    {
        // Конструктор теперь пустой! ViewModel все сделает сам.
        public MainWindow()
        {
            InitializeComponent();
        }

        private void MenuItem_Exit_Click(object sender, RoutedEventArgs e)
        {
            Application.Current.Shutdown();
        }
    }
}
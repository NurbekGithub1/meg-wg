using System.Windows;

namespace AFWGSS.POE.Views.Wizard
{
    public partial class ScenarioWizard : Window
    {
        public object? CreatedScenario { get; private set; }

        public ScenarioWizard()
        {
            InitializeComponent();
        }

        private void Cancel_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }
    }
}
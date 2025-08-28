// AFWGSS.POE/ViewModels/POEMainViewModel.cs

using Prism.Mvvm;
using Prism.Commands;
using System.Windows.Input;
// Добавьте using для ваших сервисов и моделей

namespace AFWGSS.POE.ViewModels
{
    public class POEMainViewModel : BindableBase
    {
        // Вместо прямого создания окон мы будем использовать сервис
        // private readonly IDialogService _dialogService;

        public ICommand NewScenarioCommand { get; }
        public ICommand LoadScenarioCommand { get; }
        public ICommand ImportATOCommand { get; }
        public ICommand ImportACOCommand { get; }
        public ICommand AddEntityCommand { get; }
        public ICommand EditEntityCommand { get; }
        public ICommand DeleteEntityCommand { get; }
        // ... и так далее для всех кнопок
        public POEMainViewModel()
        {
            NewScenarioCommand = new DelegateCommand(ExecuteNewScenario);
            LoadScenarioCommand = new DelegateCommand(ExecuteLoadScenario);
            ImportATOCommand = new DelegateCommand(ExecuteImportATO);
            ImportACOCommand = new DelegateCommand(ExecuteImportACO);
            AddEntityCommand = new DelegateCommand(ExecuteAddEntity);
            EditEntityCommand = new DelegateCommand(ExecuteEditEntity);
            DeleteEntityCommand = new DelegateCommand(ExecuteDeleteEntity);
        }
		
		
        private void ExecuteImportATO() => System.Windows.MessageBox.Show("Import ATO");
        private void ExecuteImportACO() => System.Windows.MessageBox.Show("Import ACO");
        private void ExecuteEditEntity() => System.Windows.MessageBox.Show("Edit Entity");
        private void ExecuteDeleteEntity() => System.Windows.MessageBox.Show("Delete Entity");

        private void ExecuteNewScenario()
        {
            // Здесь логика, которая раньше была в NewScenario_Click
            // Вместо создания окна напрямую:
            // var wizard = new ScenarioWizard();
            // wizard.ShowDialog();
            
            // Мы будем использовать сервис (пока закомментировано, реализуем позже)
            // _dialogService.ShowScenarioWizard(); 
            
            // Пока что можно оставить MessageBox для проверки
            System.Windows.MessageBox.Show("New Scenario Command Executed!");
        }

        private void ExecuteLoadScenario()
        {
            // Логика загрузки сценария
        }

        private void ExecuteAddEntity()
        {
            // Логика добавления сущности (открытие MOE Editor через сервис)
            System.Windows.MessageBox.Show("Add Entity Command Executed!");
        }

        private void ExecuteEditBehavior()
        {
             // Логика редактирования поведения (открытие Behavior Editor через сервис)
             System.Windows.MessageBox.Show("Edit Behavior Command Executed!");
        }
        
        // ... Реализация остальных методов для команд
    }
}
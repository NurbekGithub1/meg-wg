// src/Modules/POE/ViewModels/POEMainViewModel.cs
using System.Collections.ObjectModel;
using Prism.Mvvm;
using Prism.Commands;
using Prism.Dialogs;

namespace AFWGSS.POE.ViewModels
{
    public class POEMainViewModel : BindableBase
    {
        private readonly IDialogService _dialogs;

        // Инициализируем сразу — снимает CS8618
        private ObservableCollection<string> _entities = new();
        public ObservableCollection<string> Entities
        {
            get => _entities;
            private set => SetProperty(ref _entities, value);
        }

        // Выбранная сущность может отсутствовать → делаем nullable: string?
        private string? _selectedEntity;
        public string? SelectedEntity
        {
            get => _selectedEntity;
            set
            {
                if (SetProperty(ref _selectedEntity, value))
                {
                    EditEntityCommand.RaiseCanExecuteChanged();
                    DeleteEntityCommand.RaiseCanExecuteChanged();
                }
            }
        }

        public DelegateCommand AddEntityCommand { get; }
        public DelegateCommand EditEntityCommand { get; }
        public DelegateCommand DeleteEntityCommand { get; }

        public POEMainViewModel(IDialogService dialogs /*, IYourDataService data */)
        {
            _dialogs = dialogs;

            // Демоданные
            Entities = new ObservableCollection<string> { "Entity A", "Entity B", "Entity C" };

            AddEntityCommand    = new DelegateCommand(ExecuteAddEntity);
            EditEntityCommand   = new DelegateCommand(ExecuteEditEntity,  CanEditOrDelete);
            DeleteEntityCommand = new DelegateCommand(ExecuteDeleteEntity, CanEditOrDelete);
        }

        private bool CanEditOrDelete() => !string.IsNullOrWhiteSpace(SelectedEntity);

        private void ExecuteAddEntity()
        {
            var p = new DialogParameters
            {
                { "mode", "create" },
                { "title", "Create New Entity" }
            };

            _dialogs.ShowDialog("MOEEditor", p, r =>
            {
                if (r.Result == ButtonResult.OK)
                {
                    // var name = r.Parameters.GetValue<string>("name");
                    // if (!string.IsNullOrWhiteSpace(name)) Entities.Add(name);
                }
            });
        }

        private void ExecuteEditEntity()
        {
            if (SelectedEntity is null) return;

            var p = new DialogParameters
            {
                { "mode", "edit" },
                { "name", SelectedEntity },
                { "title", $"Edit: {SelectedEntity}" }
            };

            _dialogs.ShowDialog("MOEEditor", p, r =>
            {
                if (r.Result == ButtonResult.OK)
                {
                    // var newName = r.Parameters.GetValue<string>("name");
                    // if (!string.IsNullOrWhiteSpace(newName))
                    // {
                    //     var idx = Entities.IndexOf(SelectedEntity);
                    //     if (idx >= 0) Entities[idx] = newName;
                    // }
                }
            });
        }

        private void ExecuteDeleteEntity()
        {
            if (SelectedEntity is null) return;

            // Пример confirm-диалога (если реализован):
            // var p = new DialogParameters { { "message", $"Delete {SelectedEntity}?" }, { "title", "Confirm" } };
            // _dialogs.ShowDialog("ConfirmDialog", p, r =>
            // {
            //     if (r.Result == ButtonResult.OK)
            //     {
            //         Entities.Remove(SelectedEntity);
            //         SelectedEntity = null; // <- теперь допустимо (SelectedEntity — nullable)
            //     }
            // });

            // Упрощённо (без подтверждения):
            Entities.Remove(SelectedEntity);
            SelectedEntity = null; // CS8625 исчезает, т.к. свойство допускает null
        }
    }
}

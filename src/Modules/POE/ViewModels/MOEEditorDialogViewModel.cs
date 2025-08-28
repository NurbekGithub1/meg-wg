using System;
using Prism.Mvvm;
using Prism.Commands;
using Prism.Dialogs;

namespace AFWGSS.POE.ViewModels
{
    public class MOEEditorDialogViewModel : BindableBase, IDialogAware
    {
        private string _title = "Modeling of Entities (MOE)";
        public string Title
        {
            get => _title;
            set => SetProperty(ref _title, value);
        }

        // Prism 9: свойство-слушатель, заполняется DialogService'ом
        public DialogCloseListener RequestClose { get; }

        public DelegateCommand<string> CloseCommand { get; }

        public MOEEditorDialogViewModel()
        {
            CloseCommand = new DelegateCommand<string>(OnClose);
        }

        public bool CanCloseDialog() => true;

        public void OnDialogClosed() { }

        public void OnDialogOpened(IDialogParameters parameters)
        {
            if (parameters is null) return;
            if (parameters.TryGetValue<string>("title", out var t) && !string.IsNullOrWhiteSpace(t))
                Title = t;

            // Пример: var mode = parameters.GetValue<string>("mode");
        }

        private void OnClose(string param)
        {
            var result = string.Equals(param, "OK", StringComparison.OrdinalIgnoreCase)
                ? ButtonResult.OK
                : ButtonResult.Cancel;

            var outParams = new DialogParameters
            {
                // Пример отдачи результата: { "name", EditedName }
            };

            // Prism 9: вызываем .Invoke(...) у DialogCloseListener
            RequestClose.Invoke(outParams, result);
        }
    }
}

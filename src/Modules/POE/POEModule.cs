using AFWGSS.Shared.Interfaces;
using AFWGSS.POE.Views;
using System.Windows.Controls;

namespace AFWGSS.POE
{
    public class POEModule : IModule
    {
        public string Name => "Preparation of Exercise";
        public UserControl View { get; private set; } = null!;

        public void Initialize()
        {
            View = new POEView();
        }

        public void Activate() 
        {
            // Восстановление состояния при активации
        }
        
        public void Deactivate() 
        {
            // Сохранение состояния при деактивации
        }
    }
}
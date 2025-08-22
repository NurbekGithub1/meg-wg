using AFWGSS.Shared.Interfaces;

namespace AFWGSS.POE
{
    public class POEModule : IModule
    {
        public string Name => "Preparation of Exercise";
        public UserControl View { get; private set; }

        public void Initialize()
        {
            View = new POEView();
        }

        public void Activate()
        {
            // Активация модуля
        }

        public void Deactivate()
        {
            // Деактивация без уничтожения
        }
    }
}
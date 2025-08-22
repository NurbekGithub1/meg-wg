namespace AFWGSS.Shared.Interfaces
{
    public interface IModule
    {
        string Name { get; }
        UserControl View { get; }
        void Initialize();
        void Activate();
        void Deactivate();
    }
}

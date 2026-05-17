namespace Data.Interfaces
{
    public interface ICurrentUserContext
    {
        Guid? UserId { get; }
        bool HasUserId { get; }
    }
}

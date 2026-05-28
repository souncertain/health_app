using Data.Interfaces;

namespace HealthApp.UnitTests.TestDoubles;

public sealed class TestCurrentUserContext : ICurrentUserContext
{
    public Guid? UserId { get; set; }

    public bool HasUserId => UserId.HasValue;
}

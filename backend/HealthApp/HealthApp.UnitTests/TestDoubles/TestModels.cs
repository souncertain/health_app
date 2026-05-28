using Data.Interfaces;

namespace HealthApp.UnitTests.TestDoubles;

public sealed class TestEntity : IHasId
{
    public Guid Id { get; set; }

    public string Name { get; set; } = string.Empty;
}

public sealed class TestEntityDto
{
    public string Name { get; set; } = string.Empty;
}

public sealed class TestEntityViewDto
{
    public Guid Id { get; set; }

    public string Name { get; set; } = string.Empty;
}

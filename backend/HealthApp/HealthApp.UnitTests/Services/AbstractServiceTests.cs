using AutoMapper;
using Data.Interfaces;
using FluentAssertions;
using HealthApp.UnitTests.TestDoubles;
using Moq;
using Services.Services;

namespace HealthApp.UnitTests.Services;

public sealed class AbstractServiceTests
{
    [Fact]
    public async Task GetAll_MapsRepositoryEntities()
    {
        var repository = new Mock<IAbstractRepository<TestEntity>>();
        var mapper = new Mock<IMapper>();
        var validationService = new TrackingValidationService();
        var service = new TestService(repository.Object, mapper.Object, validationService);
        var entities = new List<TestEntity> { new() { Id = Guid.NewGuid(), Name = "One" } };
        var mapped = new List<TestEntityViewDto> { new() { Id = entities[0].Id, Name = "One" } };

        repository.Setup(x => x.GetAll(It.IsAny<CancellationToken>())).ReturnsAsync(entities);
        mapper.Setup(x => x.Map<List<TestEntityViewDto>>(entities)).Returns(mapped);

        var result = await service.GetAll(CancellationToken.None);

        result.Should().BeSameAs(mapped);
    }

    [Fact]
    public async Task GetById_MapsEntityFromRepository()
    {
        var repository = new Mock<IAbstractRepository<TestEntity>>();
        var mapper = new Mock<IMapper>();
        var service = new TestService(repository.Object, mapper.Object, new TrackingValidationService());
        var id = Guid.NewGuid();
        var entity = new TestEntity { Id = id, Name = "Entity" };
        var dto = new TestEntityViewDto { Id = id, Name = "Entity" };

        repository.Setup(x => x.GetById(id, It.IsAny<CancellationToken>())).ReturnsAsync(entity);
        mapper.Setup(x => x.Map<TestEntityViewDto>(entity)).Returns(dto);

        var result = await service.GetById(id, CancellationToken.None);

        result.Should().BeSameAs(dto);
    }

    [Fact]
    public async Task Create_ValidatesMapsCreatesAndSaves()
    {
        var repository = new Mock<IAbstractRepository<TestEntity>>();
        var mapper = new Mock<IMapper>();
        var validationService = new TrackingValidationService();
        var service = new TestService(repository.Object, mapper.Object, validationService);
        var sourceDto = new TestEntityDto { Name = "Created" };
        var mappedEntity = new TestEntity { Id = Guid.NewGuid(), Name = "Created" };
        var viewDto = new TestEntityViewDto { Id = mappedEntity.Id, Name = "Created" };

        mapper.Setup(x => x.Map<TestEntity>(sourceDto)).Returns(mappedEntity);
        mapper.Setup(x => x.Map<TestEntityViewDto>(mappedEntity)).Returns(viewDto);

        var result = await service.Create(sourceDto, CancellationToken.None);

        validationService.ValidatedModels.Should().ContainSingle().Which.Should().BeSameAs(sourceDto);
        repository.Verify(x => x.Create(mappedEntity, It.IsAny<CancellationToken>()), Times.Once);
        repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Once);
        result.Should().BeSameAs(viewDto);
    }

    [Fact]
    public async Task Update_OverwritesEntityIdBeforeSaving()
    {
        var repository = new Mock<IAbstractRepository<TestEntity>>();
        var mapper = new Mock<IMapper>();
        var validationService = new TrackingValidationService();
        var service = new TestService(repository.Object, mapper.Object, validationService);
        var id = Guid.NewGuid();
        var sourceDto = new TestEntityDto { Name = "Updated" };
        var mappedEntity = new TestEntity { Id = Guid.Empty, Name = "Updated" };
        var viewDto = new TestEntityViewDto { Id = id, Name = "Updated" };

        mapper.Setup(x => x.Map<TestEntity>(sourceDto)).Returns(mappedEntity);
        mapper.Setup(x => x.Map<TestEntityViewDto>(mappedEntity)).Returns(viewDto);

        var result = await service.Update(id, sourceDto, CancellationToken.None);

        mappedEntity.Id.Should().Be(id);
        repository.Verify(x => x.Update(mappedEntity, It.IsAny<CancellationToken>()), Times.Once);
        repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Once);
        result.Should().BeSameAs(viewDto);
    }

    [Fact]
    public async Task Delete_ReturnsFalse_WhenEntityDoesNotExist()
    {
        var repository = new Mock<IAbstractRepository<TestEntity>>();
        var mapper = new Mock<IMapper>();
        var service = new TestService(repository.Object, mapper.Object, new TrackingValidationService());
        var id = Guid.NewGuid();

        repository.Setup(x => x.GetById(id, It.IsAny<CancellationToken>())).ReturnsAsync((TestEntity?)null);

        var result = await service.Delete(id, CancellationToken.None);

        result.Should().BeFalse();
        repository.Verify(x => x.Delete(It.IsAny<TestEntity>(), It.IsAny<CancellationToken>()), Times.Never);
        repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task Delete_DeletesEntityAndSaves_WhenEntityExists()
    {
        var repository = new Mock<IAbstractRepository<TestEntity>>();
        var mapper = new Mock<IMapper>();
        var service = new TestService(repository.Object, mapper.Object, new TrackingValidationService());
        var entity = new TestEntity { Id = Guid.NewGuid(), Name = "Delete me" };

        repository.Setup(x => x.GetById(entity.Id, It.IsAny<CancellationToken>())).ReturnsAsync(entity);

        var result = await service.Delete(entity.Id, CancellationToken.None);

        result.Should().BeTrue();
        repository.Verify(x => x.Delete(entity, It.IsAny<CancellationToken>()), Times.Once);
        repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Once);
    }

    private sealed class TestService : AbstractService<TestEntity, TestEntityDto, TestEntityViewDto>
    {
        public TestService(
            IAbstractRepository<TestEntity> repository,
            IMapper mapper,
            TrackingValidationService validationService)
            : base(repository, mapper, validationService)
        {
        }
    }
}

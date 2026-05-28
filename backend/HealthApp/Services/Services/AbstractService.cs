using AutoMapper;
using Data.Interfaces;
using Services.Interfaces;
using Services.Validation.Infrastructure;

namespace Services.Services
{
    public class AbstractService<T, TDto, TFrontendDto> : IAbstractService<T, TDto, TFrontendDto> where T : class, IHasId
    {
        protected readonly IAbstractRepository<T> _repository;
        protected readonly IMapper _mapper;
        protected readonly IRequestValidationService _validationService;

        public AbstractService(
            IAbstractRepository<T> repository,
            IMapper mapper,
            IRequestValidationService validationService)
        {
            _repository = repository;
            _mapper = mapper;
            _validationService = validationService;
        }

        public async Task<List<TFrontendDto>> GetAll(CancellationToken ct)
        {
            var entities = await _repository.GetAll(ct);
            return _mapper.Map<List<TFrontendDto>>(entities);
        }

        public async Task<TFrontendDto> GetById(Guid id, CancellationToken ct)
        {
            var entity = await _repository.GetById(id, ct);
            return _mapper.Map<TFrontendDto>(entity);
        }

        public async Task<TFrontendDto> Create(TDto dto, CancellationToken ct)
        {
            await _validationService.ValidateAndThrowAsync(dto, ct);
            var mapped = _mapper.Map<T>(dto);
            await _repository.Create(mapped, ct);
            await _repository.Save(ct);
            return _mapper.Map<TFrontendDto>(mapped);
        }

        public async Task<TFrontendDto> Update(Guid id, TDto dto, CancellationToken ct)
        {
            await _validationService.ValidateAndThrowAsync(dto, ct);
            var mapped = _mapper.Map<T>(dto);
            mapped.Id = id;
            await _repository.Update(mapped, ct);
            await _repository.Save(ct);
            return _mapper.Map<TFrontendDto>(mapped);
        }

        public async Task<bool> Delete(Guid id, CancellationToken ct)
        {
            var toDelete = await _repository.GetById(id, ct);
            if (toDelete is null) return false;
            await _repository.Delete(toDelete, ct);
            await _repository.Save(ct);
            return true;
        }
    }
}

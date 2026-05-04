using AutoMapper;
using Data.Interfaces;
using Services.Interfaces;

namespace Services.Services
{
    public class AbstractService<T, TDto, TFrontendDto> : IAbstractService<T, TDto, TFrontendDto>
    {
        protected readonly IAbstractRepository<T> _repository;
        protected readonly IMapper _mapper;
        public AbstractService(IAbstractRepository<T> repository, IMapper mapper)
        {
            _repository = repository;
            _mapper = mapper;
        }
        public async Task<List<TFrontendDto>> GetAll(CancellationToken ct)
        {
            var entities = await _repository.GetAll(ct);
            return _mapper.Map<List<TFrontendDto>>(entities);
        }
        public async Task<TFrontendDto> Create(TDto dto, CancellationToken ct)
        {
            var mapped = _mapper.Map<T>(dto);
            await _repository.Create(mapped, ct);
            await _repository.Save(ct);
            return _mapper.Map<TFrontendDto>(mapped);
        }
    }
}

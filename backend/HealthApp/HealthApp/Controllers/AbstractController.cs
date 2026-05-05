using Data.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    public class AbstractController <T, TDto, TFrontendDto, IAbstractService>
        where T : class, IHasId
        where IAbstractService : class, IAbstractService<T, TDto, TFrontendDto>
    {
        private readonly IAbstractService _serviceBase;
        public AbstractController(IAbstractService serviceBase) { _serviceBase = serviceBase; }
        [HttpGet]
        public async Task<IEnumerable<TFrontendDto>> GetAll(CancellationToken ct)
        {
            return await _serviceBase.GetAll(ct);
        }
        
        [HttpGet("{id}")]
        public async Task<TFrontendDto> GetById(Guid id, CancellationToken ct)
        {
            return await _serviceBase.GetById(id, ct);
        }
        
        [HttpPost]
        public async Task<TFrontendDto> Create(TDto dto, CancellationToken ct)
        {
            return await _serviceBase.Create(dto, ct);
        }
        
        [HttpPut]
        public async Task<TFrontendDto> Update(Guid id, TDto dto, CancellationToken ct)
        {
            return await _serviceBase.Update(id, dto, ct);
        }
        
        [HttpDelete]
        public async Task<bool> Delete(Guid id, CancellationToken ct)
        {
            return await _serviceBase.Delete(id, ct);
        }
    }
}

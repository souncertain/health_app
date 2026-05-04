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
        [HttpPost]
        public async Task<TFrontendDto> Create(TDto dto, CancellationToken ct)
        {
            return await _serviceBase.Create(dto, ct);
        }
    }
}

using Domain.Dto.Ai;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/doctor-note-scanner")]
    public class DoctorNoteScannerController : ControllerBase
    {
        private readonly IDoctorNoteScannerService _scannerService;

        public DoctorNoteScannerController(IDoctorNoteScannerService scannerService)
        {
            _scannerService = scannerService;
        }

        [HttpPost("analyze")]
        [Consumes("multipart/form-data")]
        [RequestFormLimits(MultipartBodyLengthLimit = 8 * 1024 * 1024)]
        public async Task<DoctorNoteScanResultDto> Analyze(
            [FromForm] IFormFile image,
            CancellationToken ct)
        {
            if (image is null || image.Length == 0)
            {
                throw new Domain.Exceptions.ApiException("Upload an image to analyze.");
            }

            await using var stream = image.OpenReadStream();
            return await _scannerService.AnalyzeAsync(
                stream,
                image.ContentType,
                image.FileName,
                ct);
        }
    }
}

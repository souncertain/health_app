using Domain.Dto.Ai;

namespace Services.Interfaces
{
    public interface IDoctorNoteScannerService
    {
        Task<DoctorNoteScanResultDto> AnalyzeAsync(
            Stream imageStream,
            string? contentType,
            string? fileName,
            CancellationToken ct);
    }
}

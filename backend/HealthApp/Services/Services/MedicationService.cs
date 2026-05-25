using AutoMapper;
using Data.Interfaces;
using Domain.Dto.Medication;
using Domain.Entity;
using Enums;
using Services.Interfaces;

namespace Services.Services
{
    public class MedicationService : AbstractService<Medication, MedicationCreateDto, MedicationDetailsDto>, IMedicationService
    {
        private readonly IMedicationRepository _medicationRepository;

        public MedicationService(IMedicationRepository repository, IMapper mapper)
            : base(repository, mapper)
        {
            _medicationRepository = repository;
        }

        public async Task<IEnumerable<MedicationSoonestNotificationDto>> GetSoonestNotification()
        {
            return await _medicationRepository.GetSoonestNotification();
        }

        public async Task<MedicationStatusesDto> GetMedicationStatuses()
        {
            return await _medicationRepository.GetMedicationStatuses();
        }

        public async Task<MedicationDailyStatusDetailsDto?> SetMedicationDailyStatus(
            Guid medicationId,
            DateOnly date,
            MedicationDayStatus? status,
            CancellationToken ct = default)
        {
            var dailyStatus = await _medicationRepository.SetMedicationDailyStatus(
                medicationId,
                date,
                status,
                ct);

            return dailyStatus is null
                ? null
                : _mapper.Map<MedicationDailyStatusDetailsDto>(dailyStatus);
        }
    }
}

using AutoMapper;
using Data.Interfaces;
using Domain.Dto.Profile;
using Enums;
using Services.Interfaces;
using Services.Validation.Infrastructure;
using ProfileEntity = Domain.Entity.Profile;
using UserEntity = Domain.Entity.User;

namespace Services.Services
{
    public class ProfileService : AbstractService<ProfileEntity, ProfileCreateDto, ProfileDetailsDto>, IProfileService
    {
        private readonly IProfileRepository _profileRepository;

        public ProfileService(
            IProfileRepository repository,
            IMapper mapper,
            IRequestValidationService validationService) : base(repository, mapper, validationService)
        {
            _profileRepository = repository;
        }

        public async Task<ProfilePageDto> GetCurrentProfilePage(CancellationToken ct)
        {
            var user = await _profileRepository.GetCurrentUser(ct);
            var profile = await _profileRepository.GetCurrentProfile(ct);
            var stats = await _profileRepository.GetCurrentProfileStats(ct);

            if (profile is null)
            {
                return new ProfilePageDto
                {
                    Email = user?.Email ?? string.Empty,
                    Phone = user?.Phone,
                    NotificationsEnabled = true,
                    CreatedAt = user?.CreatedAt ?? DateTime.UtcNow,
                    UpdatedAt = user?.LastUpdatedAt ?? DateTime.UtcNow,
                    Stats = stats,
                };
            }

            return MapProfilePage(profile, user, stats);
        }

        public Task<ProfileStatsDto> GetCurrentProfileStats(CancellationToken ct)
        {
            return _profileRepository.GetCurrentProfileStats(ct);
        }

        public async Task<ProfilePageDto> SaveCurrentProfile(ProfilePageUpdateDto dto, CancellationToken ct)
        {
            await _validationService.ValidateAndThrowAsync(dto, ct);

            var user = await _profileRepository.GetCurrentUser(ct);
            if (user is null)
            {
                throw new InvalidOperationException("Unable to resolve current user for profile update.");
            }

            var now = DateTime.UtcNow;
            var profile = user.Profile ?? await _profileRepository.GetCurrentProfile(ct);
            var isNewProfile = profile is null;

            if (profile is null)
            {
                profile = new ProfileEntity
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    CreatedAt = now,
                };
            }

            var (firstName, lastName) = SplitFullName(dto.FullName);
            var (bloodType, resusPhactor) = ParseBloodType(dto.BloodType);
            var normalizedBirthday = NormalizeBirthday(dto.Birthday, dto.Age, now);

            profile.FirstName = firstName;
            profile.LastName = lastName;
            profile.Birthday = normalizedBirthday;
            profile.Sex = ParseSex(dto.Gender);
            profile.Height = dto.HeightCm;
            profile.Weight = dto.WeightKg;
            profile.BloodType = bloodType;
            profile.ResusPhactor = resusPhactor;
            profile.PrimaryDoctor = NormalizeText(dto.PrimaryDoctor);
            profile.EmergencyContactName = NormalizeText(dto.EmergencyContactName);
            profile.EmergencyContactDetails = NormalizeText(dto.EmergencyContactDetails);
            profile.NotificationsEnabled = dto.NotificationsEnabled;
            profile.LastUpdatedAt = now;

            if (!string.IsNullOrWhiteSpace(dto.Email))
            {
                user.Email = dto.Email.Trim();
            }

            user.Phone = NormalizeText(dto.Phone);
            user.LastUpdatedAt = now;

            if (isNewProfile)
            {
                await _profileRepository.Create(profile, ct);
            }
            else
            {
                await _profileRepository.Update(profile, ct);
            }

            await _profileRepository.Save(ct);
            return await GetCurrentProfilePage(ct);
        }

        private static ProfilePageDto MapProfilePage(ProfileEntity profile, UserEntity? user, ProfileStatsDto stats)
        {
            return new ProfilePageDto
            {
                Id = profile.Id,
                FullName = BuildFullName(profile.FirstName, profile.LastName),
                Email = user?.Email ?? profile.User?.Email ?? string.Empty,
                Phone = user?.Phone ?? profile.User?.Phone,
                Gender = MapSex(profile.Sex),
                Birthday = profile.Birthday,
                Age = CalculateAge(profile.Birthday),
                BloodType = FormatBloodType(profile.BloodType, profile.ResusPhactor),
                HeightCm = profile.Height.HasValue ? (int)Math.Round(profile.Height.Value) : null,
                WeightKg = profile.Weight,
                PrimaryDoctor = profile.PrimaryDoctor,
                EmergencyContactName = profile.EmergencyContactName,
                EmergencyContactDetails = profile.EmergencyContactDetails,
                NotificationsEnabled = profile.NotificationsEnabled,
                CreatedAt = profile.CreatedAt,
                UpdatedAt = profile.LastUpdatedAt,
                Stats = stats,
            };
        }

        private static (string FirstName, string LastName) SplitFullName(string? fullName)
        {
            var parts = (fullName ?? string.Empty)
                .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

            if (parts.Length == 0)
            {
                return (string.Empty, string.Empty);
            }

            if (parts.Length == 1)
            {
                return (parts[0], string.Empty);
            }

            return (parts[0], string.Join(' ', parts.Skip(1)));
        }

        private static string BuildFullName(string? firstName, string? lastName)
        {
            return string.Join(' ', new[] { firstName, lastName }.Where(x => !string.IsNullOrWhiteSpace(x)));
        }

        private static string? NormalizeText(string? value)
        {
            var normalized = value?.Trim();
            return string.IsNullOrWhiteSpace(normalized) ? null : normalized;
        }

        private static int? CalculateAge(DateTime? birthday)
        {
            if (!birthday.HasValue)
            {
                return null;
            }

            var today = DateTime.UtcNow.Date;
            var birthDate = birthday.Value.Date;
            var age = today.Year - birthDate.Year;
            if (birthDate > today.AddYears(-age))
            {
                age--;
            }

            return age < 0 ? null : age;
        }

        private static DateTime? NormalizeBirthday(DateTime? birthday, int? age, DateTime now)
        {
            if (birthday.HasValue)
            {
                return DateTime.SpecifyKind(birthday.Value.Date, DateTimeKind.Utc);
            }

            return age.HasValue ? now.Date.AddYears(-age.Value) : null;
        }

        private static Sex? ParseSex(string? gender)
        {
            return gender?.Trim().ToLowerInvariant() switch
            {
                "male" => Sex.Male,
                "female" => Sex.Female,
                _ => null,
            };
        }

        private static string MapSex(Sex? sex)
        {
            return sex switch
            {
                Sex.Male => "male",
                Sex.Female => "female",
                _ => "unspecified",
            };
        }

        private static (BloodType? BloodType, bool? ResusPhactor) ParseBloodType(string? bloodTypeValue)
        {
            if (string.IsNullOrWhiteSpace(bloodTypeValue))
            {
                return (null, null);
            }

            var normalized = bloodTypeValue.Trim().ToUpperInvariant().Replace('0', 'O');
            bool? resusPhactor = null;

            if (normalized.EndsWith("+"))
            {
                resusPhactor = true;
                normalized = normalized[..^1];
            }
            else if (normalized.EndsWith("-"))
            {
                resusPhactor = false;
                normalized = normalized[..^1];
            }

            BloodType? bloodType = normalized switch
            {
                "O" => BloodType._0,
                "A" => BloodType.A,
                "B" => BloodType.B,
                "AB" => BloodType.AB,
                _ => (BloodType?)null,
            };

            return (bloodType, bloodType is null ? null : resusPhactor);
        }

        private static string? FormatBloodType(BloodType? bloodType, bool? resusPhactor)
        {
            if (!bloodType.HasValue)
            {
                return null;
            }

            var label = bloodType.Value switch
            {
                BloodType._0 => "O",
                BloodType.A => "A",
                BloodType.B => "B",
                BloodType.AB => "AB",
                _ => null,
            };

            if (label is null)
            {
                return null;
            }

            return resusPhactor switch
            {
                true => $"{label}+",
                false => $"{label}-",
                _ => label,
            };
        }
    }
}

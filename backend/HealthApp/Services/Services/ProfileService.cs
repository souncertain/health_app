using AutoMapper;
using Data.Interfaces;
using Domain.Dto.Profile;
using Enums;
using Services.Interfaces;
using Services.Validation.Infrastructure;
using ProfileEntity = Domain.Entity.Profile;
using UserEntity = Domain.Entity.User;
using BloodPressureEntity = Domain.Entity.BloodPressure;

namespace Services.Services
{
    public class ProfileService : AbstractService<ProfileEntity, ProfileCreateDto, ProfileDetailsDto>, IProfileService
    {
        private readonly IProfileRepository _profileRepository;
        private readonly IBloodPressureRepository _bloodPressureRepository;

        public ProfileService(
            IProfileRepository repository,
            IBloodPressureRepository bloodPressureRepository,
            IMapper mapper,
            IRequestValidationService validationService) : base(repository, mapper, validationService)
        {
            _profileRepository = repository;
            _bloodPressureRepository = bloodPressureRepository;
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

        public async Task<ProfileHealthInsightsDto> GetCurrentHealthInsights(CancellationToken ct)
        {
            var profile = await _profileRepository.GetCurrentProfile(ct);
            var readings = (await _bloodPressureRepository.GetLastValues(30)).ToList();
            var age = CalculateAge(profile?.Birthday);

            return new ProfileHealthInsightsDto
            {
                BloodPressure = BuildBloodPressureInsight(age, readings),
                BodyMass = BuildBodyMassInsight(profile),
                RiskSignals = BuildRiskSignals(age, profile, readings),
            };
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

        private static BloodPressureInsightDto BuildBloodPressureInsight(
            int? age,
            IReadOnlyList<BloodPressureEntity> readings)
        {
            if (readings.Count == 0)
            {
                return new BloodPressureInsightDto
                {
                    Summary = "Добавьте несколько измерений давления, чтобы увидеть средние значения и тренд."
                };
            }

            var ordered = readings
                .OrderByDescending(x => x.RecordedAt)
                .ToList();
            var now = DateTime.UtcNow;
            var last30Days = ordered
                .Where(x => x.RecordedAt >= now.AddDays(-30))
                .ToList();
            var last7Days = ordered
                .Where(x => x.RecordedAt >= now.AddDays(-7))
                .ToList();
            var previous7Days = ordered
                .Where(x => x.RecordedAt < now.AddDays(-7) && x.RecordedAt >= now.AddDays(-14))
                .ToList();
            var windowForAverages = last7Days.Count > 0 ? last7Days : ordered;
            var variabilityWindow = ordered.Take(10).ToList();
            var latest = ordered[0];

            var trend = ResolveTrend(windowForAverages, previous7Days);
            var variability = ResolveVariability(variabilityWindow);
            var normalRangePercent = last30Days.Count == 0
                ? 0
                : (int)Math.Round(last30Days.Count(x => x.Category == BloodPressureCategory.Normal) * 100.0 / last30Days.Count);
            var requiresPediatricAssessment = age.HasValue && age.Value < 13;
            var latestCategoryKey = requiresPediatricAssessment
                ? "requiresPediatricAssessment"
                : MapCategory(latest.Category);

            return new BloodPressureInsightDto
            {
                HasReadings = true,
                ReadingsCount = ordered.Count,
                MeasuredDaysLast30Days = last30Days
                    .Select(x => x.RecordedAt.Date)
                    .Distinct()
                    .Count(),
                AverageSystolic = (int)Math.Round(windowForAverages.Average(x => x.Systolic)),
                AverageDiastolic = (int)Math.Round(windowForAverages.Average(x => x.Diastolic)),
                AveragePulse = (int)Math.Round(windowForAverages.Average(x => x.Pulse)),
                NormalRangePercent = requiresPediatricAssessment ? null : normalRangePercent,
                LatestCategory = latestCategoryKey,
                Trend = trend,
                Variability = variability,
                Summary = BuildBloodPressureSummary(age, latest.Category, trend, variability),
            };
        }

        private static BodyMassInsightDto BuildBodyMassInsight(ProfileEntity? profile)
        {
            if (profile?.Height is null || profile.Weight is null || profile.Height <= 0 || profile.Weight <= 0)
            {
                return new BodyMassInsightDto
                {
                    Summary = "Укажите рост и вес в профиле, чтобы приложение рассчитало индекс массы тела."
                };
            }

            var heightMeters = profile.Height.Value / 100.0;
            var bmi = profile.Weight.Value / (heightMeters * heightMeters);
            var category = ResolveBmiCategory(bmi);
            var minHealthyWeight = 18.5 * heightMeters * heightMeters;
            var maxHealthyWeight = 24.9 * heightMeters * heightMeters;
            double? weightDelta = null;

            if (bmi < 18.5)
            {
                weightDelta = Math.Round(minHealthyWeight - profile.Weight.Value, 1);
            }
            else if (bmi > 24.9)
            {
                weightDelta = Math.Round(maxHealthyWeight - profile.Weight.Value, 1);
            }

            return new BodyMassInsightDto
            {
                HasBodyMassData = true,
                Bmi = Math.Round(bmi, 1),
                Category = category,
                HealthyWeightMinKg = Math.Round(minHealthyWeight, 1),
                HealthyWeightMaxKg = Math.Round(maxHealthyWeight, 1),
                WeightDeltaKg = weightDelta,
                Summary = BuildBodyMassSummary(category, weightDelta),
            };
        }

        private static string ResolveTrend(
            IReadOnlyList<BloodPressureEntity> recentReadings,
            IReadOnlyList<BloodPressureEntity> previousReadings)
        {
            if (recentReadings.Count < 2 || previousReadings.Count < 2)
            {
                return "insufficientData";
            }

            var recentSystolic = recentReadings.Average(x => x.Systolic);
            var recentDiastolic = recentReadings.Average(x => x.Diastolic);
            var previousSystolic = previousReadings.Average(x => x.Systolic);
            var previousDiastolic = previousReadings.Average(x => x.Diastolic);

            if (recentSystolic <= previousSystolic - 5 && recentDiastolic <= previousDiastolic - 3)
            {
                return "improving";
            }

            if (recentSystolic >= previousSystolic + 5 || recentDiastolic >= previousDiastolic + 3)
            {
                return "rising";
            }

            return "stable";
        }

        private static string ResolveVariability(IReadOnlyList<BloodPressureEntity> readings)
        {
            if (readings.Count < 3)
            {
                return "insufficientData";
            }

            var average = readings.Average(x => x.Systolic);
            var variance = readings.Average(x => Math.Pow(x.Systolic - average, 2));
            var standardDeviation = Math.Sqrt(variance);

            if (standardDeviation < 8)
            {
                return "low";
            }

            if (standardDeviation < 15)
            {
                return "moderate";
            }

            return "high";
        }

        private static string MapCategory(BloodPressureCategory category)
        {
            return category switch
            {
                BloodPressureCategory.Normal => "normal",
                BloodPressureCategory.Elevated => "elevated",
                BloodPressureCategory.HighStage1 => "highStage1",
                BloodPressureCategory.HighStage2 => "highStage2",
                BloodPressureCategory.HypertensiveCrisis => "hypertensiveCrisis",
                _ => "noData",
            };
        }

        private static string BuildBloodPressureSummary(
            int? age,
            BloodPressureCategory category,
            string trend,
            string variability)
        {
            if (age.HasValue && age.Value < 13)
            {
                return "Для детей младше 13 лет корректная оценка давления зависит от возраста, пола и ростового перцентиля. Приложение показывает динамику измерений, но итоговую категорию давления для такого возраста должен подтверждать врач.";
            }

            var categoryMessage = category switch
            {
                BloodPressureCategory.Normal => "Последнее измерение находится в нормальном диапазоне.",
                BloodPressureCategory.Elevated => "Давление выше оптимального уровня и требует наблюдения.",
                BloodPressureCategory.HighStage1 => "Показатели соответствуют гипертензии 1 стадии.",
                BloodPressureCategory.HighStage2 => "Показатели соответствуют гипертензии 2 стадии.",
                BloodPressureCategory.HypertensiveCrisis => "Показатели находятся в критически высоком диапазоне.",
                _ => "Пока недостаточно данных для оценки давления."
            };

            var trendMessage = trend switch
            {
                "improving" => "Средние значения улучшаются по сравнению с предыдущей неделей.",
                "rising" => "Средние значения растут и требуют дополнительного контроля.",
                "stable" => "Динамика за последние недели остаётся стабильной.",
                _ => "Для оценки тренда нужно больше регулярных измерений."
            };

            var variabilityMessage = variability switch
            {
                "low" => "Колебания давления небольшие.",
                "moderate" => "Колебания давления умеренные.",
                "high" => "Колебания давления выражены сильнее обычного.",
                _ => string.Empty
            };

            return string.Join(" ",
                new[] { categoryMessage, trendMessage, variabilityMessage }
                    .Where(x => !string.IsNullOrWhiteSpace(x)));
        }

        private static string ResolveBmiCategory(double bmi)
        {
            if (bmi < 18.5)
            {
                return "underweight";
            }

            if (bmi < 25)
            {
                return "normal";
            }

            if (bmi < 30)
            {
                return "overweight";
            }

            return "obesity";
        }

        private static string BuildBodyMassSummary(string category, double? weightDeltaKg)
        {
            return category switch
            {
                "underweight" => weightDeltaKg.HasValue
                    ? $"Масса тела ниже рекомендуемого диапазона. До нижней границы комфортного диапазона не хватает около {weightDeltaKg.Value:F1} кг."
                    : "Масса тела ниже рекомендуемого диапазона.",
                "normal" => "Масса тела находится в рекомендуемом диапазоне по индексу массы тела.",
                "overweight" => weightDeltaKg.HasValue
                    ? $"Есть избыток массы тела. Для возврата к верхней границе рекомендуемого диапазона нужно снизить примерно {Math.Abs(weightDeltaKg.Value):F1} кг."
                    : "Есть избыток массы тела.",
                "obesity" => weightDeltaKg.HasValue
                    ? $"Индекс массы тела соответствует ожирению. Для возврата к верхней границе рекомендуемого диапазона нужно снизить примерно {Math.Abs(weightDeltaKg.Value):F1} кг."
                    : "Индекс массы тела соответствует ожирению.",
                _ => "Укажите рост и вес в профиле, чтобы приложение рассчитало индекс массы тела."
            };
        }

        private static IReadOnlyList<HealthRiskSignalDto> BuildRiskSignals(
            int? age,
            ProfileEntity? profile,
            IReadOnlyList<BloodPressureEntity> readings)
        {
            var signals = new List<HealthRiskSignalDto>();
            var latestReading = readings
                .OrderByDescending(x => x.RecordedAt)
                .FirstOrDefault();
            var bmi = TryCalculateBmi(profile);
            var hasAdultBloodPressureAssessment = !age.HasValue || age.Value >= 13;
            var averagePulse = readings.Count == 0
                ? (double?)null
                : readings
                    .OrderByDescending(x => x.RecordedAt)
                    .Take(7)
                    .Average(x => x.Pulse);

            if (latestReading is not null && hasAdultBloodPressureAssessment)
            {
                switch (latestReading.Category)
                {
                    case BloodPressureCategory.HighStage2:
                    case BloodPressureCategory.HypertensiveCrisis:
                        signals.Add(new HealthRiskSignalDto
                        {
                            Key = "bloodPressureHighRisk",
                            Level = "high",
                            Title = "Высокий риск осложнений из-за давления",
                            Description = "Последние измерения соответствуют выраженно повышенному давлению. Это увеличивает риск инсульта, болезней сердца и поражения почек."
                        });
                        break;
                    case BloodPressureCategory.HighStage1:
                    case BloodPressureCategory.Elevated:
                        signals.Add(new HealthRiskSignalDto
                        {
                            Key = "bloodPressureAttention",
                            Level = "medium",
                            Title = "Давление требует наблюдения",
                            Description = "Показатели давления выше оптимального диапазона. При повторяющихся значениях стоит продолжать контроль и обсудить ситуацию с врачом."
                        });
                        break;
                }
            }

            if (averagePulse.HasValue)
            {
                if (averagePulse.Value > 100)
                {
                    signals.Add(new HealthRiskSignalDto
                    {
                        Key = "pulseHigh",
                        Level = "medium",
                        Title = "Пульс выше нормы покоя",
                        Description = "Средний пульс по недавним измерениям превышает 100 ударов в минуту. Это повод внимательнее наблюдать за самочувствием и повторными измерениями."
                    });
                }
                else if (averagePulse.Value < 60)
                {
                    signals.Add(new HealthRiskSignalDto
                    {
                        Key = "pulseLow",
                        Level = "low",
                        Title = "Пульс ниже типичного диапазона",
                        Description = "Средний пульс по недавним измерениям ниже 60 ударов в минуту. Для части людей это может быть вариантом нормы, но при симптомах стоит оценить показатель отдельно."
                    });
                }
            }

            if (bmi.HasValue)
            {
                if (bmi.Value >= 30)
                {
                    signals.Add(new HealthRiskSignalDto
                    {
                        Key = "obesityRisk",
                        Level = "high",
                        Title = "Выраженный кардиометаболический риск по массе тела",
                        Description = "Индекс массы тела соответствует ожирению. Это связано с более высоким риском гипертонии, диабета 2 типа и сердечно-сосудистых заболеваний."
                    });
                }
                else if (bmi.Value >= 25)
                {
                    signals.Add(new HealthRiskSignalDto
                    {
                        Key = "overweightRisk",
                        Level = "medium",
                        Title = "Повышенный риск из-за избыточной массы",
                        Description = "Избыточная масса тела повышает вероятность роста давления и метаболических нарушений. Полезно наблюдать за весом в динамике."
                    });
                }
            }

            if (age.HasValue && age.Value >= 45 && bmi.HasValue && bmi.Value >= 25)
            {
                signals.Add(new HealthRiskSignalDto
                {
                    Key = "diabetesRisk",
                    Level = bmi.Value >= 30 ? "high" : "medium",
                    Title = "Сигнал риска предиабета и диабета 2 типа",
                    Description = "Возраст старше 45 лет в сочетании с избыточной массой тела считается важным фактором риска нарушений углеводного обмена."
                });
            }

            if (age.HasValue && age.Value >= 45 &&
                bmi.HasValue && bmi.Value >= 25 &&
                latestReading is not null &&
                hasAdultBloodPressureAssessment &&
                latestReading.Category is BloodPressureCategory.Elevated or BloodPressureCategory.HighStage1 or BloodPressureCategory.HighStage2 or BloodPressureCategory.HypertensiveCrisis)
            {
                signals.Add(new HealthRiskSignalDto
                {
                    Key = "cardiometabolicRisk",
                    Level = bmi.Value >= 30 || latestReading.Category >= BloodPressureCategory.HighStage1 ? "high" : "medium",
                    Title = "Кардиометаболический риск повышен",
                    Description = "Сочетание возраста, повышенного давления и избыточной массы тела связано с более высоким риском сердечно-сосудистых и обменных нарушений."
                });
            }

            return signals
                .GroupBy(x => x.Key)
                .Select(x => x.First())
                .ToList();
        }

        private static double? TryCalculateBmi(ProfileEntity? profile)
        {
            if (profile?.Height is null || profile.Weight is null || profile.Height <= 0 || profile.Weight <= 0)
            {
                return null;
            }

            var heightMeters = profile.Height.Value / 100.0;
            return profile.Weight.Value / (heightMeters * heightMeters);
        }
    }
}

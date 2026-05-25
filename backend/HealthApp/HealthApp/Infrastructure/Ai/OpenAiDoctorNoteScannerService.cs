using Domain.Dto.Ai;
using Domain.Exceptions;
using HealthApp.Configuration;
using Microsoft.Extensions.Options;
using Services.Interfaces;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace HealthApp.Infrastructure.Ai
{
    public class OpenAiDoctorNoteScannerService : IDoctorNoteScannerService
    {
        private static readonly JsonSerializerOptions SerializerOptions = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = true
        };

        private readonly HttpClient _httpClient;
        private readonly DoctorNoteScannerOptions _options;
        private readonly ILogger<OpenAiDoctorNoteScannerService> _logger;

        public OpenAiDoctorNoteScannerService(
            HttpClient httpClient,
            IOptions<DoctorNoteScannerOptions> options,
            ILogger<OpenAiDoctorNoteScannerService> logger)
        {
            _httpClient = httpClient;
            _options = options.Value ?? new DoctorNoteScannerOptions();
            _logger = logger;
        }

        public async Task<DoctorNoteScanResultDto> AnalyzeAsync(
            Stream imageStream,
            string? contentType,
            string? fileName,
            CancellationToken ct)
        {
            if (!_options.Enabled)
            {
                throw new ApiException(
                    "Doctor note scanner is disabled. Configure DoctorNoteScanner settings first.",
                    HttpStatusCode.ServiceUnavailable);
            }

            if (!string.Equals(_options.Provider, "OpenAI", StringComparison.OrdinalIgnoreCase))
            {
                throw new ApiException(
                    $"Unsupported AI scanner provider '{_options.Provider}'.",
                    HttpStatusCode.NotImplemented);
            }

            if (string.IsNullOrWhiteSpace(_options.OpenAI.ApiKey))
            {
                throw new ApiException(
                    "OpenAI API key is not configured for doctor note scanning.",
                    HttpStatusCode.ServiceUnavailable);
            }

            var detectedContentType = NormalizeContentType(contentType, fileName);
            var bytes = await ReadImageBytes(imageStream, ct);
            var requestPayload = BuildOpenAiRequest(
                Convert.ToBase64String(bytes),
                detectedContentType);

            using var request = new HttpRequestMessage(
                HttpMethod.Post,
                _options.OpenAI.Endpoint.Trim());
            request.Headers.Authorization = new AuthenticationHeaderValue(
                "Bearer",
                _options.OpenAI.ApiKey.Trim());
            request.Headers.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));
            request.Content = JsonContent.Create(requestPayload, options: SerializerOptions);

            using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(ct);
            timeoutCts.CancelAfter(
                TimeSpan.FromSeconds(Math.Max(5, _options.OpenAI.RequestTimeoutSeconds)));

            using var response = await _httpClient.SendAsync(request, timeoutCts.Token);
            var responseBody = await response.Content.ReadAsStringAsync(timeoutCts.Token);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "OpenAI doctor note scan failed with status {StatusCode}: {Body}",
                    (int)response.StatusCode,
                    responseBody);
                throw new ApiException(
                    "AI scanner is temporarily unavailable. Please try again later.",
                    HttpStatusCode.BadGateway);
            }

            var outputJson = ExtractOutputJson(responseBody);
            try
            {
                var result = JsonSerializer.Deserialize<DoctorNoteScanResultDto>(
                    outputJson,
                    SerializerOptions);
                if (result is null)
                {
                    throw new JsonException("OpenAI returned an empty doctor note analysis.");
                }

                result.Category = NormalizeCategory(result.Category);
                result.RawText = result.RawText?.Trim() ?? string.Empty;
                result.Summary = result.Summary?.Trim() ?? string.Empty;
                result.Warnings = result.Warnings?
                    .Where(x => !string.IsNullOrWhiteSpace(x))
                    .Select(x => x.Trim())
                    .ToList() ?? new List<string>();
                result.Medications ??= new List<DoctorNoteMedicationCandidateDto>();
                result.Visits ??= new List<DoctorNoteVisitCandidateDto>();

                return result;
            }
            catch (JsonException exception)
            {
                _logger.LogError(
                    exception,
                    "Could not parse OpenAI doctor note scan output: {Output}",
                    outputJson);
                throw new ApiException(
                    "AI scanner returned an unreadable response.",
                    HttpStatusCode.BadGateway);
            }
        }

        private static string NormalizeCategory(string? category)
        {
            return category?.Trim().ToLowerInvariant() switch
            {
                "medication" => "medication",
                "medical_visit" => "medical_visit",
                "mixed" => "mixed",
                _ => "unknown"
            };
        }

        private async Task<byte[]> ReadImageBytes(Stream imageStream, CancellationToken ct)
        {
            await using var buffer = new MemoryStream();
            await imageStream.CopyToAsync(buffer, ct);
            var bytes = buffer.ToArray();

            if (bytes.Length == 0)
            {
                throw new ApiException("Image file is empty.");
            }

            if (bytes.Length > Math.Max(1024, _options.MaxImageBytes))
            {
                throw new ApiException(
                    $"Image is too large. Maximum allowed size is {_options.MaxImageBytes / (1024 * 1024)} MB.");
            }

            return bytes;
        }

        private static string NormalizeContentType(string? contentType, string? fileName)
        {
            var normalized = contentType?.Trim().ToLowerInvariant();
            if (normalized is "image/jpeg" or "image/png" or "image/webp" or "image/heic" or "image/heif")
            {
                return normalized;
            }

            var extension = Path.GetExtension(fileName ?? string.Empty).Trim().ToLowerInvariant();
            return extension switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".webp" => "image/webp",
                ".heic" => "image/heic",
                ".heif" => "image/heif",
                _ => throw new ApiException("Only JPG, PNG, WEBP, HEIC and HEIF images are supported.")
            };
        }

        private object BuildOpenAiRequest(string base64Image, string contentType)
        {
            return new
            {
                model = _options.OpenAI.Model.Trim(),
                input = new object[]
                {
                    new
                    {
                        role = "system",
                        content = new object[]
                        {
                            new
                            {
                                type = "input_text",
                                text = SystemPrompt
                            }
                        }
                    },
                    new
                    {
                        role = "user",
                        content = new object[]
                        {
                            new
                            {
                                type = "input_text",
                                text = UserPrompt
                            },
                            new
                            {
                                type = "input_image",
                                image_url = $"data:{contentType};base64,{base64Image}"
                            }
                        }
                    }
                },
                text = new
                {
                    format = new
                    {
                        type = "json_schema",
                        name = "doctor_note_scan",
                        strict = true,
                        schema = ResponseSchema
                    }
                }
            };
        }

        private static string ExtractOutputJson(string responseBody)
        {
            using var document = JsonDocument.Parse(responseBody);
            var root = document.RootElement;

            if (root.TryGetProperty("output_text", out var outputTextElement) &&
                outputTextElement.ValueKind == JsonValueKind.String)
            {
                var outputText = outputTextElement.GetString();
                if (!string.IsNullOrWhiteSpace(outputText))
                {
                    return outputText;
                }
            }

            if (root.TryGetProperty("output", out var outputElement) &&
                outputElement.ValueKind == JsonValueKind.Array)
            {
                foreach (var outputItem in outputElement.EnumerateArray())
                {
                    if (!outputItem.TryGetProperty("content", out var contentElement) ||
                        contentElement.ValueKind != JsonValueKind.Array)
                    {
                        continue;
                    }

                    foreach (var contentItem in contentElement.EnumerateArray())
                    {
                        if (contentItem.TryGetProperty("text", out var textElement) &&
                            textElement.ValueKind == JsonValueKind.String)
                        {
                            var outputText = textElement.GetString();
                            if (!string.IsNullOrWhiteSpace(outputText))
                            {
                                return outputText;
                            }
                        }

                        if (contentItem.TryGetProperty("refusal", out var refusalElement) &&
                            refusalElement.ValueKind == JsonValueKind.String)
                        {
                            var refusal = refusalElement.GetString();
                            if (!string.IsNullOrWhiteSpace(refusal))
                            {
                                throw new ApiException(
                                    "AI scanner refused to process the image. Please try a clearer photo.");
                            }
                        }
                    }
                }
            }

            throw new ApiException(
                "AI scanner returned an empty response.",
                HttpStatusCode.BadGateway);
        }

        private static readonly object ResponseSchema = new
        {
            type = "object",
            properties = new
            {
                category = new
                {
                    type = "string",
                    @enum = new[] { "unknown", "medication", "medical_visit", "mixed" }
                },
                rawText = new
                {
                    type = "string",
                    description = "Best-effort transcription of the visible text. Keep uncertain fragments if needed."
                },
                summary = new
                {
                    type = "string",
                    description = "Short explanation of what the note most likely means."
                },
                warnings = new
                {
                    type = "array",
                    items = new { type = "string" },
                    description = "Potential ambiguities, unreadable fragments, or important uncertainties."
                },
                medications = new
                {
                    type = "array",
                    items = new
                    {
                        type = "object",
                        properties = new
                        {
                            name = new { type = "string" },
                            dosageText = new { type = "string" },
                            frequencyText = new { type = "string" },
                            instructions = new { type = "string" },
                            note = new { type = "string" }
                        },
                        required = new[] { "name", "dosageText", "frequencyText", "instructions", "note" },
                        additionalProperties = false
                    }
                },
                visits = new
                {
                    type = "array",
                    items = new
                    {
                        type = "object",
                        properties = new
                        {
                            doctorName = new { type = "string" },
                            specialty = new { type = "string" },
                            dateText = new { type = "string" },
                            timeText = new { type = "string" },
                            location = new { type = "string" },
                            note = new { type = "string" }
                        },
                        required = new[] { "doctorName", "specialty", "dateText", "timeText", "location", "note" },
                        additionalProperties = false
                    }
                }
            },
            required = new[] { "category", "rawText", "summary", "warnings", "medications", "visits" },
            additionalProperties = false
        };

        private const string SystemPrompt =
            """
            You analyze one photo of a doctor's handwritten or printed note.
            Your job is to transcribe only what is actually visible and classify the content.
            Possible categories:
            - medication: the note mainly prescribes a medication or treatment
            - medical_visit: the note mainly contains an appointment, referral, doctor, specialty, date, time, or place
            - mixed: both medication and visit information are clearly present
            - unknown: the image is too unclear or does not fit the categories

            Important rules:
            - Do not invent words, medication names, doctors, dates, or dosages
            - If something is unclear, keep it in rawText only if it is plausible and add a warning
            - Use the medications and visits arrays only for information you can reasonably infer from the image
            - Empty arrays are allowed
            - Prefer Russian wording in the extracted text and summary if the note is in Russian
            """;

        private const string UserPrompt =
            """
            Analyze this doctor's note image.
            Return a strict JSON object with:
            - category
            - rawText
            - summary
            - warnings
            - medications
            - visits

            The result is only a draft for user confirmation in a medical app.
            """;
    }
}

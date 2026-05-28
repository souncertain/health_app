namespace Localization.Validation
{
    public static class ValidationMessages
    {
        public static string RequestValidationFailed =>
            ValidationResourceAccessor.Get("Validation_RequestValidationFailed");

        public static string Required(string fieldName) =>
            ValidationResourceAccessor.Format("Validation_Required_Format", fieldName);

        public static string InvalidEmail() =>
            ValidationResourceAccessor.Get("Validation_InvalidEmail");

        public static string MinLength(string fieldName, int minLength) =>
            ValidationResourceAccessor.Format("Validation_MinLength_Format", fieldName, minLength);

        public static string MaxLength(string fieldName, int maxLength) =>
            ValidationResourceAccessor.Format("Validation_MaxLength_Format", fieldName, maxLength);

        public static string Range(string fieldName, object min, object max) =>
            ValidationResourceAccessor.Format("Validation_Range_Format", fieldName, min, max);

        public static string InvalidPhone() =>
            ValidationResourceAccessor.Get("Validation_InvalidPhone");

        public static string InvalidGuid(string fieldName) =>
            ValidationResourceAccessor.Format("Validation_InvalidGuid_Format", fieldName);

        public static string InvalidEnum(string fieldName) =>
            ValidationResourceAccessor.Format("Validation_InvalidEnum_Format", fieldName);

        public static string InvalidDate(string fieldName) =>
            ValidationResourceAccessor.Format("Validation_InvalidDate_Format", fieldName);

        public static string CollectionRequired(string fieldName) =>
            ValidationResourceAccessor.Format("Validation_CollectionRequired_Format", fieldName);

        public static string CollectionDistinct(string fieldName) =>
            ValidationResourceAccessor.Format("Validation_CollectionDistinct_Format", fieldName);

        public static string MedicationTimesMustMatchFrequency() =>
            ValidationResourceAccessor.Get("Validation_MedicationTimesMustMatchFrequency");

        public static string WeeklyMedicationRequiresSingleWeekday() =>
            ValidationResourceAccessor.Get("Validation_WeeklyMedicationRequiresSingleWeekday");

        public static string InvalidWeekdayValues() =>
            ValidationResourceAccessor.Get("Validation_InvalidWeekdayValues");

        public static string InvalidTimeOfDay() =>
            ValidationResourceAccessor.Get("Validation_InvalidTimeOfDay");

        public static string MetricTargetRangeInvalid() =>
            ValidationResourceAccessor.Get("Validation_MetricTargetRangeInvalid");

        public static string PasswordResetCodeLength(int length) =>
            ValidationResourceAccessor.Format("Validation_PasswordResetCodeLength_Format", length);

        public static string InvalidBloodType() =>
            ValidationResourceAccessor.Get("Validation_InvalidBloodType");

        public static string InvalidGender() =>
            ValidationResourceAccessor.Get("Validation_InvalidGender");

        public static string InvalidUrl(string fieldName) =>
            ValidationResourceAccessor.Format("Validation_InvalidUrl_Format", fieldName);

        public static string DateCannotBeInFuture(string fieldName) =>
            ValidationResourceAccessor.Format("Validation_DateCannotBeInFuture_Format", fieldName);
    }
}

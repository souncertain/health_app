namespace Services.Interfaces
{
    public interface IOneTimeCodeFactory
    {
        string CreateNumericCode(int length);
        string HashCode(string code);
    }
}

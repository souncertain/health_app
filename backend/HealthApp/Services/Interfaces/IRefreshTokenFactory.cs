namespace Services.Interfaces
{
    public interface IRefreshTokenFactory
    {
        string CreateToken();
        string HashToken(string token);
    }
}

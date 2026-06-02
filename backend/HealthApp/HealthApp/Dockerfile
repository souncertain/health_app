FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["HealthApp/HealthApp.csproj", "HealthApp/"]
COPY ["Data/Data.csproj", "Data/"]
COPY ["Domain/Domain.csproj", "Domain/"]
COPY ["Enums/Enums.csproj", "Enums/"]
COPY ["Localization/Localization.csproj", "Localization/"]
COPY ["Services/Services.csproj", "Services/"]

RUN dotnet restore "HealthApp/HealthApp.csproj"

COPY . .
WORKDIR /src/HealthApp
RUN dotnet publish "HealthApp.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "HealthApp.dll"]

/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT *
  --FROM [Portfolio Project]..CovidDeaths
  --ORDER BY 3,4

 -- SELECT *
  --FROM [Portfolio Project]..CovidVaccinations
  --ORDER BY 3,4

  --Select Data that we are going to be using

  SELECT Location, date, total_cases, new_cases, total_deaths, population
  FROM [Portfolio Project]..CovidDeaths
  ORDER BY 1,2

  -- Looking at Total Cases vs Total Deaths
  --Shows the likelihoood of dying if you contract Covid in your country

  SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPecentage
  FROM [Portfolio Project]..CovidDeaths
  WHERE location LIKE '%states%'
  ORDER BY 1,2

  --Looking at the Total Cases vs Population
  --Shows was percentage of population got Covid

  SELECT Location, date, total_cases, Population, (total_cases/Population)*100 AS InfectedPecentage
  FROM [Portfolio Project]..CovidDeaths
  WHERE location LIKE '%states%'
  ORDER BY 1,2

  --Looking at Countries with Highest Infection Rate compared to Population
  
  SELECT Location,Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))*100 AS InfectedPecentage
  FROM [Portfolio Project]..CovidDeaths
  --WHERE location LIKE '%states%'
  GROUP BY Location,Population
  ORDER BY InfectedPecentage DESC

  --Table 4(Same as above but with Date)

  SELECT Location,Population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))*100 AS InfectedPecentage
  FROM [Portfolio Project]..CovidDeaths
  --WHERE location LIKE '%states%'
  GROUP BY Location, Population, date
  ORDER BY InfectedPecentage DESC

  --Show Countries with the Highest Death Count per population
 

  SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
  FROM [Portfolio Project]..CovidDeaths
  --WHERE location LIKE '%states%'
  WHERE continent IS NOT NULL
  GROUP BY Location
  ORDER BY TotalDeathCount DESC

  --Let's break things down by Continent. Only included US deaths, data issue. 
  --Showing the continents with highest death count

  SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
  FROM [Portfolio Project]..CovidDeaths
  --WHERE location LIKE '%states%'
  WHERE continent IS NOT NULL
  GROUP BY continent
  ORDER BY TotalDeathCount DESC

  --Global Numbers
  SELECT SUM(new_cases) AS TotalNewCases, SUM(CAST(new_deaths AS INT)) AS TotalNewDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPecentage
  FROM [Portfolio Project]..CovidDeaths
   WHERE continent IS NOT NULL
   --GROUP BY date
  ORDER BY 1,2


  --Table 2
  SELECT Location, SUM(CAST(new_deaths as int)) as TotalDeathCount
  FROM [Portfolio Project]..CovidDeaths
  WHERE continent IS NULL
  AND Location NOT IN ('World', 'European Union', 'International', 'Low Income', 'Lower middle income',
		'Upper middle income', 'High Income')
  GROUP BY Location
  ORDER BY TotalDeathCount


  --Looking at Total Population vs Vaccinations


  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
  FROM [Portfolio Project]..CovidDeaths dea
  JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2, 3

--USE CTE
With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingTotalVaccinations)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
	--(RollingTotalVaccination/population)
  FROM [Portfolio Project]..CovidDeaths dea
  JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2, 3
  )

  SELECT *, (RollingTotalVaccinations/population)*100
  FROM PopvsVac


  --TEMP TABLE
  DROP Table if exists #PercentPopulationVaccinated
  Create Table #PercentPopulationVaccinated
  (
  Continent nvarchar(255),
   Location nvarchar(255),
   Date datetime,
   Population numeric,
   New_vaccinations numeric,
   RollingTotalVaccinations numeric
   )

   Insert into #PercentPopulationVaccinated
   SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
	--(RollingTotalVaccination/population)
  FROM [Portfolio Project]..CovidDeaths dea
  JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	--WHERE dea.continent IS NOT NULL
	--ORDER BY 2, 3
  
  SELECT *, (RollingTotalVaccinations/population)*100
  FROM #PercentPopulationVaccinated

  --Creating View to store data for later visualizations
  CREATE VIEW PercentPopulationVaccinated AS
   SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
	--(RollingTotalVaccination/population)
  FROM [Portfolio Project]..CovidDeaths dea
  JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated
	
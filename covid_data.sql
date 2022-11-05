--COVID 19 DATA EXPLORATION


select *
from CovidDB..CovidDeaths
where continent is not null
order by 3,4

--select *
--from CovidDB..CovidVax
--order by 3,4


--SELECTING DATA NEEDED

select location, date, total_cases, new_cases, total_deaths, population
from CovidDB..CovidDeaths
order by 1,2


-- TOTAL CASES VS DEATHS
--likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDB..CovidDeaths
where location like '%Kingdom%'
--where continent is not null
order by 1,2

-- TOTAL CASES VS POPULATION
--percentage of population that contracted Covid
select location, date, population, total_cases, (total_cases/population)*100 as InfectedPercentage
from CovidDB..CovidDeaths
where location='United Kingdom'
order by 1,2  


--Countries with highest infection rates compared to population
select location, population, MAX(total_cases) as HighestInfectionCount , MAX((total_cases/population))*100 as InfectedPopPercentage
from CovidDB..CovidDeaths
--where location='United Kingdom'
where continent is not null
group by location, population
order by InfectedPopPercentage desc


--highest death count per population in country
select location, MAX(cast(total_deaths as int)) as TotalDeathCount 
from CovidDB..CovidDeaths
--where location='United Kingdom'
where continent is not null 
group by location
order by TotalDeathCount desc


--CONTINENTS WITH HIGHEST DEATH COUNT per population
select continent, MAX(cast(total_deaths as int)) as TotalDeathCount 
from CovidDB..CovidDeaths
--where location='United Kingdom'
where continent is not null 
group by continent
order by TotalDeathCount desc--incorrect numbers for some reason

--OR

select location, MAX(cast(total_deaths as int)) as TotalDeathCount 
from CovidDB..CovidDeaths
--where location='United Kingdom'
where continent is null 
group by location
order by TotalDeathCount desc --correct numbers


--GLOBAL NUMBERS
select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_detaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from CovidDB..CovidDeaths
--where location='United Kingdom'
where continent is not null
group by date
order by 1,2


--TOTAL POPULATION VS VACCINATIONS
--percentage of population that received at least one vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST( vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,
	dea.date) as CumulativeVaccinated
--,	(CumulativeVaccinated/dea.population)*100
from CovidDB..CovidDeaths dea
join CovidDB..CovidVax vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--USE CTE to perofrm calculation on PARTITION BY in previous query

with PopvsVac (continent, location, date, population, new_vaccinations, CumulativeVaccinated)
as
(
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST( vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,
		dea.date) as CumulativeVaccinated
	--,	(CumulativeVaccinated/dea.population)*100
	from CovidDB..CovidDeaths dea
	join CovidDB..CovidVax vac
		on dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null
	--order by 2,3
)

select *, (CumulativeVaccinated/population)*100
from PopVsVac


--TEMP TABLE to perofrm calculation on PARTITION BY in previous query
 
 drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
	continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	CumulativeVaccinated numeric
)

  insert into #PercentPopulationVaccinated

		select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		, SUM(CAST( vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,
			dea.date) as CumulativeVaccinated
		--,	(CumulativeVaccinated/dea.population)*100
		from CovidDB..CovidDeaths dea
		join CovidDB..CovidVax vac
			on dea.location = vac.location
			and dea.date = vac.date
		where dea.continent is not null
		order by 2,3

select *, (CumulativeVaccinated/population)*100
from #PercentPopulationVaccinated


-- create view to store data for fututre visualisations

create view PercentPopulationVaccinated as

		select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		, SUM(CAST( vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,
			dea.date) as CumulativeVaccinated
		--,	(CumulativeVaccinated/dea.population)*100
		from CovidDB..CovidDeaths dea
		join CovidDB..CovidVax vac
			on dea.location = vac.location
			and dea.date = vac.date
		where dea.continent is not null
		--order by 2,3

select *
from PercentPopulationVaccinated
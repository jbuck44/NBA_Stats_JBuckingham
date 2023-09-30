using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Microsoft.EntityFrameworkCore;
using SBS_Dev_Test.Data;
using SBS_Dev_Test.Models;
using System.Reflection.Metadata;
using System.Data.SqlClient;
using System.Data;

namespace SBS_Dev_Test.Services
{
    public class CalculateTeamStatsService
    {
        private IDbContextFactory<NbaContext> _dbContextFactory;

        public CalculateTeamStatsService(IDbContextFactory<NbaContext> dbContextFactory)
        {
            _dbContextFactory = dbContextFactory;
        }
        public async Task<List<TeamStats>> Get()
        {
            using (var context = _dbContextFactory.CreateDbContext())
            {
                List<TeamStats> teamStats = await context.TeamStats.FromSqlRaw("EXEC CalculateTeamStats").ToListAsync();
                return teamStats;
            }
        }
    }
}

using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations.Schema;

namespace SBS_Dev_Test.Models
{
    [Keyless]
    public class TeamStats
    {
        public string? Name { get; set; }
        public string? Stadium { get; set; } 
        public string? Logo { get; set; }
        public string? MVP { get; set; }
        public int? TotalGames { get; set; }
        public int? Won { get; set; }
        public int? Lost { get; set; }
        public int? PlayedHome { get; set; }
        public int? PlayedAway { get; set; }
        public string? BiggestWin { get; set; }
        public string? BiggestLoss { get; set; }
        public string? LastGameStadium { get; set; }
        public DateTime? LastGameDate { get; set; }

        public string? URL { get; set; }
    }
}

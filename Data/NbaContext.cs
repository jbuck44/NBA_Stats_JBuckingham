using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using SBS_Dev_Test.Models;

namespace SBS_Dev_Test.Data;

public partial class NbaContext : DbContext
{
    public NbaContext()
    {
    }

    public NbaContext(DbContextOptions<NbaContext> options)
        : base(options)
    {
    } 

    public virtual DbSet<TeamStats> TeamStats { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseSqlServer("Name=ConnectionStrings:DefaultConnection"); 
    
     
}

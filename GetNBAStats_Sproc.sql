USE [NBA]
GO

/****** Object:  StoredProcedure [dbo].[CalculateTeamStats]    Script Date: 30/09/2023 14:53:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CalculateTeamStats]
AS
BEGIN
    SET nocount ON;

    /* Get MVPs */

    WITH mvps
    AS (SELECT G.mvpplayerid,
               TP.teamid,
               Count(*) AS CountOfID
        FROM games AS G
            JOIN team_player AS TP
                ON G.mvpplayerid = TP.playerid
        GROUP BY G.mvpplayerid,
                 TP.teamid
       ),

         /* Rank all MVPS */

         rankedmvps
    AS (SELECT P.NAME AS MVP,
               T.NAME AS NAME,
               T.stadium AS Stadium,
               M.teamid,
               M.countofid,
               Row_number() OVER (partition BY M.teamid ORDER BY M.countofid DESC) AS Rank
        FROM mvps AS M
            JOIN players AS P
                ON M.mvpplayerid = P.playerid
            JOIN teams AS T
                ON M.teamid = T.teamid
       ),

         /* Get list of home games played per team */

         homegamesplayed
    AS (SELECT G.hometeamid AS TeamID,
               Count(*) AS HomeGames
        FROM games AS G
        GROUP BY G.hometeamid
       ),

         /* Get list of away games played per team */

         awaygamesplayed
    AS (SELECT G.awayteamid AS TeamID,
               Count(*) AS AwayGames
        FROM games AS G
        GROUP BY G.awayteamid
       ),

         /* Get list of won games and the team id that won*/

         wins
    AS (SELECT CASE
                   WHEN G.homescore > G.awayscore THEN
                       G.hometeamid
                   WHEN G.awayscore > G.homescore THEN
                       G.awayteamid
                   ELSE
                       NULL
               END AS WinningTeamID
        FROM games AS G
       ),

         /* Sort won games by team*/

         teamwins
    AS (SELECT winningteamid AS TeamID,
               Count(*) AS Won
        FROM wins
        WHERE winningteamid IS NOT NULL
        GROUP BY winningteamid
       ),

         /* Get list of lost games and the team id that lost*/

         losses
    AS (SELECT CASE
                   WHEN G.homescore < G.awayscore THEN
                       G.hometeamid
                   WHEN G.awayscore < G.homescore THEN
                       G.awayteamid
                   ELSE
                       NULL
               END AS LosingTeamID
        FROM games AS G
       ),

         /* Sort lost games by team*/

         teamlosses
    AS (SELECT losingteamid AS TeamID,
               Count(*) AS Lost
        FROM losses
        WHERE losingteamid IS NOT NULL
        GROUP BY losingteamid
       ),

         /* Get each game result*/

         results
    AS (SELECT G.gameid,
               CASE
                   WHEN G.homescore > G.awayscore THEN
                       G.homescore - G.awayscore
                   WHEN G.awayscore > G.homescore THEN
                       G.awayscore - G.homescore
               END AS ScoreDifference,
               G.homescore,
               G.awayscore,
               G.hometeamid,
               G.awayteamid,
               CASE
                   WHEN G.homescore > G.awayscore THEN
                       G.hometeamid
                   WHEN G.awayscore > G.homescore THEN
                       G.awayteamid
                   ELSE
                       NULL
               END AS WinningTeamID,
               CASE
                   WHEN G.homescore < G.awayscore THEN
                       G.hometeamid
                   WHEN G.awayscore < G.homescore THEN
                       G.awayteamid
                   ELSE
                       NULL
               END AS LosingTeamID
        FROM games AS G
       ),

         /* Get biggest wins by team*/

         biggestwins
    AS (SELECT gameid,
               scoredifference,
               winningteamid,
               losingteamid,
               CASE
                   WHEN winningteamid = hometeamid THEN
                       homescore
                   WHEN winningteamid = awayteamid THEN
                       awayscore
               END AS WinningScore,
               CASE
                   WHEN losingteamid = hometeamid THEN
                       homescore
                   WHEN losingteamid = awayteamid THEN
                       awayscore
               END AS LosingScore,
               Row_number() OVER (partition BY winningteamid ORDER BY scoredifference DESC) AS RowNum
        FROM results
       ),

         /* Get biggest losses by team */

         biggestlosses
    AS (SELECT gameid,
               scoredifference,
               winningteamid,
               losingteamid,
               CASE
                   WHEN winningteamid = hometeamid THEN
                       homescore
                   WHEN winningteamid = awayteamid THEN
                       awayscore
               END AS WinningScore,
               CASE
                   WHEN losingteamid = hometeamid THEN
                       homescore
                   WHEN losingteamid = awayteamid THEN
                       awayscore
               END AS LosingScore,
               Row_number() OVER (partition BY losingteamid ORDER BY scoredifference DESC) AS RowNum
        FROM results
       ),

         /* Rank games by date */

         rankedgamesbydate
    AS (SELECT T.teamid,
               G.gameid,
               G.gamedatetime,
               G.hometeamid,
               Row_number() OVER (partition BY T.teamid ORDER BY G.gamedatetime DESC) AS RowNum
        FROM teams T
            JOIN games G
                ON T.teamid = G.hometeamid
                   OR T.teamid = G.awayteamid
       )

    SELECT R.NAME,
           R.stadium,
           T.logo,
           R.mvp,
           H.homegames + A.awaygames AS TotalGames,
           TW.won,
           TL.lost,
           H.homegames AS PlayedHome,
           A.awaygames AS PlayedAway,
           Concat(BW.winningscore, '-', BW.losingscore) AS BiggestWin,
           Concat(BL.losingscore, '-', BL.winningscore) AS BiggestLoss,
           RMVP.stadium AS LastGameStadium,
           RG.gamedatetime AS LastGameDate,
           T.url
    FROM rankedmvps AS R
        JOIN rankedgamesbydate AS RG
            ON R.teamid = RG.teamid
        JOIN teams AS T
            ON R.teamid = T.teamid
        JOIN rankedmvps AS RMVP
            ON RG.hometeamid = RMVP.teamid
        JOIN teamwins AS TW
            ON R.teamid = TW.teamid
        JOIN teamlosses AS TL
            ON R.teamid = TL.teamid
        JOIN homegamesplayed AS H
            ON R.teamid = H.teamid
        JOIN awaygamesplayed AS A
            ON R.teamid = A.teamid
        JOIN biggestwins AS BW
            ON R.teamid = BW.winningteamid
        JOIN biggestlosses AS BL
            ON R.teamid = BL.losingteamid
    WHERE R.rank = 1
          AND BW.rownum = 1
          AND BL.rownum = 1
          AND RG.rownum = 1
          AND RMVP.rank = 1
END;
GO



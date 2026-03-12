// ============================================================================
// NBA NETWORK SCHEMA
// ============================================================================

// 1. CONSTRAINTS
CREATE CONSTRAINT FOR (p:Player) REQUIRE p.name IS UNIQUE;
CREATE CONSTRAINT FOR (t:Team) REQUIRE t.name IS UNIQUE;
CREATE CONSTRAINT FOR (g:Game) REQUIRE g.game_id IS UNIQUE;

// ----------------------------------------------------------------------------

// 2. LOAD RAW DATA
LOAD CSV WITH HEADERS FROM 'file:///nba_graph_data.csv' AS row
MERGE (p:Player {name: row.Player})
MERGE (t:Team {name: row.Team})
MERGE (g:Game {game_id: row.Date + "_" + 
    (CASE WHEN row.Team < row.Opp 
          THEN row.Team + "_" + row.Opp 
          ELSE row.Opp + "_" + row.Team 
     END)
})
SET g.date = date(row.Date),
    g.teams_played = [row.Team, row.Opp]
MERGE (p)-[:IN_TEAM]->(t)
MERGE (p)-[stats:PLAYED_IN]->(g)
SET stats.team = row.Team,
    stats.position = row.Pos,
    stats.points = toInteger(row.PTS),
    stats.game_score = toFloat(row.GmSc),
    stats.box_plus_minus = toFloat(row.BPM),
    stats.plus_minus = toFloat(row['+/-']),
    stats.minutes_played = toInteger(row.MP),
    stats.location = CASE WHEN row.Home CONTAINS '@' THEN 'Away' ELSE 'Home' END,
    stats.result = row.Result;

// ----------------------------------------------------------------------------

// 3. UPDATE STATS
MATCH (p:Player)-[stats:PLAYED_IN]->()
WITH p,
    head(collect(stats.team)) AS currentTeam,
    head(collect(distinct stats.position)) AS pos,
    avg(stats.points) AS aPTS, 
    avg(stats.game_score) AS aGS, 
    avg(stats.box_plus_minus) AS aBPM, 
    avg(stats.plus_minus) AS aPM,
    avg(stats.minutes_played) AS aMP,
    count(stats) AS total_games,
    sum(CASE WHEN stats.result STARTS WITH 'W' THEN 1 ELSE 0 END) AS total_wins
SET p.current_team = currentTeam,
    p.position = pos,
    p.avg_points = aPTS,
    p.avg_game_score = aGS,
    p.avg_bpm = aBPM,
    p.avg_plus_minus = aPM,
    p.avg_plus_minus = aMP,
    p.num_games = total_games,
    p.win_rate = toFloat(total_wins)/total_games;

MATCH (p:Player)-[stats:PLAYED_IN]->(g:Game)
MATCH (p)-[r:IN_TEAM]->(t:Team)
WHERE g.game_id CONTAINS t.name 
WITH p, t, r, 
    min(g.date) AS earliest_date,
    max(g.date) AS latest_date,
    count(g) AS total_games,
    avg(stats.points) AS aPTS, 
    avg(stats.game_score) AS aGS, 
    avg(stats.box_plus_minus) AS aBPM, 
    avg(stats.plus_minus) AS aPM,
    avg(stats.minutes_played) AS aMP
SET r.first_played = earliest_date,
    r.last_played = latest_date,
    r.num_games = total_games,
    r.avg_points = aPTS,
    r.avg_game_score = aGS,
    r.avg_bpm = aBPM,
    r.avg_plus_minus = aPM,
    r.avg_minutes_played = aMP

// ----------------------------------------------------------------------------

// 4. CONNECT TEAMMATES
MATCH (p1:Player)-[r1:PLAYED_IN]->(g:Game)<-[r2:PLAYED_IN]-(p2:Player)
WHERE r1.team = r2.team AND elementId(p1) < elementId(p2)
WITH p1, p2, g,
     CASE 
        WHEN g.date.month >= 10 
        THEN toString(g.date.year) + "-" + toString(g.date.year + 1)
        ELSE toString(g.date.year - 1) + "-" + toString(g.date.year)
     END AS season_period
WITH p1, p2, 
     count(g) as games_together, 
     collect(distinct season_period) as seasons
MERGE (p1)-[r:TEAMMATE_WITH]-(p2)
SET r.games_played = games_together,
    r.seasons_played = seasons;

// ----------------------------------------------------------------------------

// 5. CONNECT OPPONENTS
MATCH (p1:Player)-[r1:PLAYED_IN]->(g:Game)<-[r2:PLAYED_IN]-(p2:Player)
WHERE r1.team <> r2.team AND elementId(p1) < elementId(p2)
WITH p1, p2, g,
     CASE 
        WHEN g.date.month >= 10 
        THEN toString(g.date.year) + "-" + toString(g.date.year + 1)
        ELSE toString(g.date.year - 1) + "-" + toString(g.date.year)
     END AS season_period
WITH p1, p2, 
     count(g) as games_against, 
     collect(distinct season_period) as seasons
MERGE (p1)-[r:OPPONENT_OF]-(p2)
SET r.games_played = games_against,
    r.seasons_played = seasons;

// ----------------------------------------------------------------------------

// 6. POSITIONS AS CENTRAL NODES
MATCH (p:Player)
MERGE (pos:Position {type: p.position})
MERGE (p)-[:PLAYS_POSITION]->(pos);

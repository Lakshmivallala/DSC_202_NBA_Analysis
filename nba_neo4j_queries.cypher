// ============================================================================
// GENERAL QUERIES
// ============================================================================

// general schema
CALL db.schema.visualization();

// get all players in specific position
MATCH (pos:Position {type: "G"})-[r:PLAYS_POSITION]-(p:Player)
RETURN pos, r, p;

// specific player relationships
MATCH (p:Player{name: "LeBron James"})-[r:TEAMMATE_WITH|OPPONENT_OF]-(other:Player)
RETURN p, r, other;

// players played multiple teams
MATCH (p:Player)-[r:IN_TEAM]->(t:Team)
WITH p, count(t) AS team_count
WHERE team_count > 1
MATCH (p)-[r:IN_TEAM]->(teams:Team)
RETURN p, r, teams;

// high frequency of games played together
MATCH (p1:Player)-[r:TEAMMATE_WITH]-(p2:Player)
WHERE r.games_played > 170
RETURN p1, r, p2
ORDER BY r.games_played DESC;

// high frequency of games played against
MATCH (p1:Player)-[r:OPPONENT_OF]-(p2:Player)
WHERE r.games_played > 18
RETURN p1, r, p2
ORDER BY r.games_played DESC;

// ============================================================================
// PLAYER SPECIFIC QUERIES
// ============================================================================

// general profile
MATCH (p:Player{name: "Jaren Jackson Jr."})
OPTIONAL MATCH (p)-[r_t:IN_TEAM]->(t:Team)
OPTIONAL MATCH (p)-[r_tm:TEAMMATE_WITH]-(tm:Player)
OPTIONAL MATCH (p)-[r_pos:PLAYS_POSITION]->(pos:Position)
RETURN p, r_t, t, r_tm, tm, r_pos, pos;

// played both with and against
MATCH (p:Player {name: "Jaren Jackson Jr."})-[r1:TEAMMATE_WITH]-(other:Player)
MATCH (p)-[r2:OPPONENT_OF]-(other)
RETURN p, r1, r2, other;

// top 5 teammates/opponents played the most games with (shared most time with)
MATCH (p:Player {name: "Jaren Jackson Jr."})-[r:TEAMMATE_WITH]-(teammate:Player)
WITH p, r, teammate
ORDER BY r.games_played DESC
LIMIT 10
RETURN p, r, teammate;

MATCH (p:Player {name: "Jaren Jackson Jr."})-[r:OPPONENT_OF]-(opponent:Player)
WITH p, r, opponent
ORDER BY r.games_played DESC
LIMIT 10
RETURN p, r, opponent;

// teammates/opponents played with where his performance was higher than average
MATCH (p:Player {name: "Jaren Jackson Jr."})-[r:TEAMMATE_WITH]-(teammate:Player)
MATCH (p)-[stats:PLAYED_IN]->(g:Game)<-[:PLAYED_IN]-(teammate)
WITH p, teammate, r, avg(stats.game_score) AS avg_with_tm
ORDER BY avg_with_tm DESC
LIMIT 5
RETURN p, r, teammate;

MATCH (p:Player {name: "Jaren Jackson Jr."})-[r:OPPONENT_OF]-(opponent:Player)
MATCH (p)-[stats:PLAYED_IN]->(g:Game)<-[:PLAYED_IN]-(opponent)
WITH p, opponent, r, avg(stats.game_score) AS avg_with_op
ORDER BY avg_with_op DESC
LIMIT 5
RETURN p, r, opponent;

// teammates/opponents played with where his performance was lower than average
MATCH (p:Player {name: "Jaren Jackson Jr."})-[r:TEAMMATE_WITH]-(teammate:Player)
MATCH (p)-[stats:PLAYED_IN]->(g:Game)<-[:PLAYED_IN]-(teammate)
WITH p, teammate, r, avg(stats.game_score) AS avg_with_tm
ORDER BY avg_with_tm
LIMIT 5
RETURN p, r, teammate;

MATCH (p:Player {name: "Jaren Jackson Jr."})-[r:OPPONENT_OF]-(opponent:Player)
MATCH (p)-[stats:PLAYED_IN]->(g:Game)<-[:PLAYED_IN]-(opponent)
WITH p, opponent, r, avg(stats.game_score) AS avg_with_op
ORDER BY avg_with_op
LIMIT 5
RETURN p, r, opponent;

// best teammates played with to assess synergy (weighted by log of frequency of games and game score average improvement)
MATCH (p:Player {name: "Jaren Jackson Jr."})-[r:TEAMMATE_WITH]-(teammate:Player)
MATCH (p)-[stats:PLAYED_IN]->(g:Game)<-[:PLAYED_IN]-(teammate)
WITH p, teammate, r,
count(g) AS shared_games,
avg(stats.game_score) AS avg_score
WHERE shared_games >= 60
WITH p, teammate, r, shared_games, avg_score,
(avg_score * 0.8) + (log(shared_games + 1) * 0.2) AS synergy_score
ORDER BY synergy_score DESC
LIMIT 5
RETURN p, r, teammate, synergy_score;

// his top 10 games shared with most frequent teammate (check on stats)
MATCH (p1:Player {name: "Jaren Jackson Jr."})-[r1:PLAYED_IN]->(g:Game)<-[r2:PLAYED_IN]-(p2:Player {name: "Jake LaRavia"})
WITH p1, r1, r2, g, p2, r1.game_score AS jjj_performance
ORDER BY jjj_performance DESC
LIMIT 10
RETURN p1, r1, r2, g, p2, jjj_performance;
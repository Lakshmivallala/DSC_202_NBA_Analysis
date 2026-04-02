
Data:
[[Player game by game statistics.]([url](https://www.basketball-reference.com/players/))
](https://www.basketball-reference.com/players/) 

We have used 12 players' data stored in individual csv files with their names.

MongoDB Player Analytics – My Pipeline Breakdown
What This Does

The aim is to calculate advanced basketball stats directly in MongoDB. Metrics like consistency, efficiency, defensive impact, and momentum can helpo scout players faster.

No messy CSV crunching in Python, no slow joins, just clean, server-side analytics.

Main Features
Reliability / Consistency
- Filters out games where players didn’t play or have weird totals (DNP, Season Total).
- Calculates Consistency Index using population standard deviation.
- Ranks players from most reliable to most volatile.
- Example: Jaren Jackson Jr. comes out as a balanced, predictable performer.
  
Two-Way Impact
- Combines offense (Avg_Points, Peak_Game, Avg_Efficiency) and defense (Blocks + Steals) in one pipeline.
- Shows why some players are defensive anchors vs. offensive engines.

Efficiency Metrics
- Calculates Points per Minute (PPM) and Total Impact (PTS + AST) on the database side.
- No extra Python calculations—MongoDB does it while it aggregates.

Momentum / Rolling Averages
- Uses $setWindowFields for 5-game rolling averages.
- Tracks hot streaks and cooling periods, e.g., how Jaren Jackson Jr.’s scoring ramps up or dips across games.

Defensive Specialization
- Isolates block stats to quantify rim protection.
- Shows why a player like JJJ is valuable even if his scoring isn’t Luka-level.

Recruitment Matrix
- Plots Consistency Index vs. Average Points.
- Highlights High Consistency Zone (reliable floor) and offensive outliers.
- JJJ fits perfectly in the balanced, low-risk/high-defense quadrant.

How the Pipelines Work:
- $match – Only valid games (PTS > 0 and < 100), removes DNPs and totals.
- $project / $convert – Turns string stats into numbers; handles errors gracefully (onError: 0).
- $group – Aggregates by player: averages, sums, standard deviations, rolling metrics.
- $sort – Orders players by whatever metric you care about (consistency, scoring, etc.).
- $setWindowFields – Rolling averages and momentum trends.
- $addFields / $divide – Points per minute, total impact, other virtual stats.

Example: Consistency Pipeline
pipeline = [
    {"$project": {
        "Player": 1,
        "Date": 1,
        "pts_numeric": {"$convert": {"input": "$PTS", "to": "double", "onError": 0}}
    }},
    {"$match": {
        "pts_numeric": {"$gt": 0, "$lt": 100},
        "Date": {"$regex": "-"}
    }},
    {"$group": {
        "_id": "$Player",
        "avg_pts": {"$avg": "$pts_numeric"},
        "consistency_index": {"$stdDevPop": "$pts_numeric"},
        "game_count": {"$sum": 1}
    }},
    {"$sort": {"consistency_index": 1}}
]
results = list(collection.aggregate(pipeline))

Output: player-level consistency, average points, and game counts.
Use: find reliable recruits with a predictable nightly floor.

Visualizations
- Bar charts for consistency (JJJ highlighted).
- Scatter plots for scoring vs. volatility.
- Rolling average lines for hot streaks and momentum.

Why MongoDB?

- No client-side crunching → faster, less memory.
- Can handle messy data (DNP, missing stats).
- Real-time analytics as new games are added.
- Window functions let us calculate rolling averages efficiently without complex SQL joins.

Requirements
MongoDB 5.0+ (for $setWindowFields)
Python 3.x
pymongo + matplotlib (for plots)

JJJ is our target recruit: balanced risk, consistent, strong on defense.
Players like Luka/Giannis? High scoring but high volatility.
This pipeline lets us see reliability, momentum, and two-way impact clearly in one place.

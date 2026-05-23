import marimo

__generated_with = "0.23.8"
app = marimo.App()


@app.cell
def _():
    import marimo as mo
    import duckdb
    import polars as pl

    con = duckdb.connect("nba.duckdb", read_only=True)
    return con, mo, pl


@app.cell
def _(con, mo):
    # --- Filter controls ---

    teams_df = con.execute(
        "SELECT distinct team_abbreviation FROM mart.mart__play_by_play WHERE team_abbreviation IS NOT NULL ORDER BY team_abbreviation"
    ).pl()

    seasons_df = con.execute(
        "SELECT distinct SEASON FROM mart.mart__player_season_stats ORDER BY SEASON"
    ).pl()

    team_options = teams_df["team_abbreviation"].to_list()
    season_options = seasons_df["SEASON"].to_list()

    team_filter = mo.ui.multiselect(options=team_options, label="Team(s)")
    season_filter = mo.ui.multiselect(options=season_options, label="Season(s)")
    player_search = mo.ui.text(placeholder="Search player name...", label="Player")
    shot_result_filter = mo.ui.multiselect(
        options=["Made", "Missed"], label="Shot result"
    )
    period_filter = mo.ui.multiselect(
        options=["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"],
        label="Period",
    )

    mo.md(
        f"""
        ## NBA Play-by-Play Explorer

        Filter the play-by-play data using the controls below.

        {team_filter} {season_filter} {player_search} {shot_result_filter} {period_filter}
        """
    )
    return (
        team_filter,
        season_filter,
        player_search,
        shot_result_filter,
        period_filter,
    )


@app.cell
def _(con, team_filter, player_search, shot_result_filter, period_filter, mo, pl):
    # --- Play-by-Play ---

    pbp_clauses = []
    if team_filter.value:
        ph = ", ".join(f"'{v}'" for v in team_filter.value)
        pbp_clauses.append(f"team_abbreviation IN ({ph})")
    if player_search.value.strip():
        pbp_clauses.append(f"player_name ILIKE '%{player_search.value.strip()}%'")
    if shot_result_filter.value:
        ph2 = ", ".join(f"'{v}'" for v in shot_result_filter.value)
        pbp_clauses.append(f"SHOT_RESULT IN ({ph2})")
    if period_filter.value:
        ph3 = ", ".join(v for v in period_filter.value)
        pbp_clauses.append(f"PERIOD IN ({ph3})")

    pbp_where = " AND ".join(pbp_clauses)
    pbp_where_sql = f"WHERE {pbp_where}" if pbp_where else ""

    pbp = con.execute(
        f"""
        SELECT
            GAME_ID,
            team_abbreviation,
            player_name,
            PERIOD as period,
            clock_minutes,
            clock_seconds_decimal,
            action_sequence,
            SHOT_RESULT,
            SHOT_DISTANCE,
            SHOT_VALUE,
            is_field_goal,
            SCORE_HOME,
            SCORE_AWAY,
            pts_margin,
            is_close_game,
            is_blowout_game
        FROM mart.mart__play_by_play
        {pbp_where_sql}
        ORDER BY GAME_ID, PERIOD, clock_minutes DESC, clock_seconds_decimal DESC
        LIMIT 5000
        """
    ).pl()

    mo.md(f"### Play-by-Play — **{len(pbp)} rows** (capped at 5,000)")
    return (pbp,)


@app.cell
def _(pbp, mo):
    mo.ui.table(pbp, pagination=True, page_size=25)


@app.cell
def _(con, team_filter, season_filter, mo, pl):
    # --- Team Standings ---

    st_clauses = []
    if team_filter.value:
        ph4 = ", ".join(f"'{v}'" for v in team_filter.value)
        st_clauses.append(f"TEAM_ABBREVIATION IN ({ph4})")
    if season_filter.value:
        ph5 = ", ".join(f"'{v}'" for v in season_filter.value)
        st_clauses.append(f"SEASON IN ({ph5})")

    st_where = " AND ".join(st_clauses)
    st_where_sql = f"WHERE {st_where}" if st_where else ""

    standings = con.execute(
        f"""
        SELECT *
        FROM mart.mart__team_standings
        {st_where_sql}
        ORDER BY win_pct DESC
        """
    ).pl()

    mo.md("### Team Standings")
    return (standings,)


@app.cell
def _(standings, mo):
    mo.ui.table(standings, pagination=True, page_size=30)


@app.cell
def _(con, player_search, season_filter, mo, pl):
    # --- Player Season Stats ---

    ps_clauses = []
    if player_search.value.strip():
        ps_clauses.append(f"PLAYER_NAME ILIKE '%{player_search.value.strip()}%'")
    if season_filter.value:
        ph6 = ", ".join(f"'{v}'" for v in season_filter.value)
        ps_clauses.append(f"SEASON IN ({ph6})")

    ps_where = " AND ".join(ps_clauses)
    ps_where_sql = f"WHERE {ps_where}" if ps_where else ""

    players = con.execute(
        f"""
        SELECT
            PLAYER_NAME,
            SEASON,
            games_played,
            ppg,
            rpg,
            apg,
            spg,
            bpg,
            topg,
            fg_pct,
            fg3_pct,
            ft_pct,
            avg_min,
            avg_plus_minus
        FROM mart.mart__player_season_stats
        {ps_where_sql}
        ORDER BY ppg DESC
        LIMIT 200
        """
    ).pl()

    mo.md("### Player Season Stats")
    return (players,)


@app.cell
def _(players, mo):
    mo.ui.table(players, pagination=True, page_size=25)


@app.cell
def _(con, season_filter, mo, pl):
    # --- Game Summaries ---

    gs_clauses = []
    if season_filter.value:
        ph7 = ", ".join(f"'{v}'" for v in season_filter.value)
        gs_clauses.append(f"SEASON IN ({ph7})")

    gs_where = " AND ".join(gs_clauses)
    gs_where_sql = f"WHERE {gs_where}" if gs_where else ""

    games = con.execute(
        f"""
        SELECT *
        FROM mart.mart__game_summaries
        {gs_where_sql}
        ORDER BY game_date DESC
        """
    ).pl()

    mo.md("### Game Summaries")
    return (games,)


@app.cell
def _(games, mo):
    mo.ui.table(games, pagination=True, page_size=25)


if __name__ == "__main__":
    app.run()
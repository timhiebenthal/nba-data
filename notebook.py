import marimo

__generated_with = "0.23.8"
app = marimo.App()


@app.cell
def _():
    import marimo as mo
    import duckdb
    import pandas as pd
    import altair as alt
    import nba_viz

    nba_viz.setup()
    con = duckdb.connect("nba.duckdb", read_only=True)

    # Inject Roboto from Google Fonts so Altair labels render correctly
    mo.Html(
        '<link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">'
    )

    return alt, con, mo, pd


@app.cell
def _(con, mo, pd):
    # --- Filter controls ---

    teams_df = con.execute(
        "SELECT distinct team_abbreviation FROM mart.mart__play_by_play WHERE team_abbreviation IS NOT NULL ORDER BY team_abbreviation"
    ).df()

    seasons_df = con.execute(
        "SELECT distinct SEASON FROM mart.mart__player_season_stats ORDER BY SEASON"
    ).df()

    team_options = teams_df["team_abbreviation"].tolist()
    season_options = seasons_df["SEASON"].tolist()

    date_range = con.execute(
        "SELECT min(game_date) as min_date, max(game_date) as max_date FROM mart.mart__play_by_play"
    ).df()
    min_date = pd.Timestamp(date_range["min_date"].iloc[0]).date()
    max_date = pd.Timestamp(date_range["max_date"].iloc[0]).date()

    team_filter = mo.ui.multiselect(options=team_options, label="Team(s)")
    date_filter = mo.ui.date_range(start=min_date, stop=max_date, label="Game date range")
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

        {team_filter} {date_filter} {season_filter} {player_search} {shot_result_filter} {period_filter}
        """
    )
    return (
        date_filter,
        period_filter,
        player_search,
        shot_result_filter,
        team_filter,
    )


@app.cell
def _(
    con,
    date_filter,
    mo,
    period_filter,
    player_search,
    shot_result_filter,
    team_filter,
):
    # --- Play-by-Play ---

    pbp_clauses = []
    if team_filter.value:
        ph = ", ".join(f"'{v}'" for v in team_filter.value)
        pbp_clauses.append(f"team_abbreviation IN ({ph})")
    if date_filter.value:
        start, end = date_filter.value
        pbp_clauses.append(f"game_date BETWEEN '{start}' AND '{end}'")
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

    pbp_filtered = con.execute(
        f"""
        SELECT *
        FROM mart.mart__play_by_play
        {pbp_where_sql}
        ORDER BY game_date, PERIOD, action_sequence
        LIMIT 5000
        """
    ).df()

    mo.md(f"### Play-by-Play — **{len(pbp_filtered)} rows** (capped at 5,000)")
    return (pbp_filtered,)


@app.cell
def _(mo, pbp_filtered):
    mo.ui.table(pbp_filtered, pagination=True, page_size=25)
    return


@app.cell
def _(mo):
    mo.md("""
    ### Field Goal % by Team
    """)
    return


@app.cell
def _(con):
    minute_shots_df = con.execute(
        f"""
        with per_game_stats as (
        SELECT
            player_name,
            game_id,
            total_match_minutes,
            is_made_field_goal,
            count(*) as attempts,
        FROM pbp_filtered
        where is_field_goal = True
        GROUP BY all
        ),

        avg_stats_per_minute as (
            select
                player_name,
                total_match_minutes,
                is_made_field_goal,
                avg(attempts) as avg_fg_attempts,
            from per_game_stats
            group by all
            order by 1,2
        )
        select * from avg_stats_per_minute
        """
    ).df()
    return (minute_shots_df,)


@app.cell
def _(alt, minute_shots_df):
    alt.Chart(minute_shots_df).mark_area(opacity=0.7).encode(
        x='total_match_minutes:Q',
        y=alt.Y('avg_fg_attempts').stack(None),
        color='is_made_field_goal',
        row='player_name'
    )
    return


@app.cell
def _():
    return


if __name__ == "__main__":
    app.run()

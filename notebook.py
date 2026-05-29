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

    _players_df = con.execute(
        "SELECT distinct player_name FROM mart.mart__play_by_play WHERE player_name IS NOT NULL ORDER BY player_name"
    ).df()
    _player_options = _players_df["player_name"].tolist()

    team_filter = mo.ui.multiselect(options=team_options, label="Team(s)")
    date_filter = mo.ui.date_range(start=min_date, stop=max_date, label="Game date range")
    season_filter = mo.ui.multiselect(options=season_options, label="Season(s)")
    player_multiselect = mo.ui.multiselect(options=_player_options, label="Player(s)", full_width=True)
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

        {team_filter} {date_filter} {season_filter} {player_multiselect} {shot_result_filter} {period_filter}
        """
    )
    return (
        date_filter,
        period_filter,
        player_multiselect,
        shot_result_filter,
        team_filter,
    )


@app.cell
def _(mo, player_multiselect):
    mo.md(f"""
    #### You have selected the following players:  
    {', '.join(player_multiselect.value)}
    """)
    return


@app.cell
def _(
    con,
    date_filter,
    mo,
    period_filter,
    player_multiselect,
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
    if player_multiselect.value:
        _ph = ", ".join(f"'{v}'" for v in player_multiselect.value)
        pbp_clauses.append(f"player_name IN ({_ph})")
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
def _():
    # (cell removed)
    return


@app.cell
def _(mo):
    shot_type_toggle = mo.ui.dropdown(
        options=["Field Goals", "Free Throws", "Both"],
        value="Both",
        label="Shot type",
    )

    close_game_toggle = mo.ui.dropdown(
        options=["All games", "Close games", "Non-close games"],
        value="All games",
        label="Game type",
    )

    mo.md(f"### Attempts per Game Minute \u2014 {shot_type_toggle}  {close_game_toggle}")
    return close_game_toggle, shot_type_toggle


@app.cell
def _(
    close_game_toggle,
    con,
    pbp_filtered,
    player_multiselect,
    shot_type_toggle,
):
    con.register("pbp_filtered_view", pbp_filtered)
    shot_type = shot_type_toggle.value

    close_game = close_game_toggle.value

    type_filter = ""
    if shot_type == "Field Goals":
        type_filter = "AND shot_type = 'Field Goal'"
    elif shot_type == "Free Throws":
        type_filter = "AND shot_type = 'Free Throw'"

    close_game_filter = ""
    if close_game == "Close games":
        close_game_filter = "AND is_close_game = True"
    elif close_game == "Non-close games":
        close_game_filter = "AND is_close_game = False"

    player_filter = ""
    if player_multiselect.value:
        _ph = ", ".join(f"'{v}'" for v in player_multiselect.value)
        player_filter = f"AND player_name IN ({_ph})"

    minute_shots_df = con.execute(
        f"""
        with per_game_stats as (
            SELECT
                player_name,
                game_id,
                total_match_minutes,
                total_game_minutes,
                shot_type,
                is_made_score as is_made,
                sum(shot_value) as pts_attempted,
                count(*) as attempts,
            FROM pbp_filtered_view
            WHERE is_score_attempt = True {type_filter} {close_game_filter} {player_filter}
            GROUP BY all
        ),

        avg_stats_per_minute as (
            select
                total_match_minutes,
                player_name,
                shot_type,
                is_made,
                max(total_game_minutes) as total_game_minutes,
                avg(pts_attempted) as avg_pts_attempted,
                avg(attempts) as avg_attempts,
                count(1) as sample_size
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
    _max_minute = int(minute_shots_df["total_match_minutes"].max())

    alt.Chart(minute_shots_df).mark_bar(opacity=0.7, size=10).encode(
        x=alt.X(
            "total_match_minutes:Q",
            scale=alt.Scale(domain=[0, _max_minute], nice=False),
            title="Game Minute"
        ),
        y=alt.Y("avg_pts_attempted", title=None, axis=alt.Axis(format="d")).stack(True),
        color="is_made",
        row=alt.Row("player_name:N", spacing=50, header=alt.Header(labelAngle=-90, labelAlign="left", labelPadding=10)),
        tooltip=["total_match_minutes", "shot_type", "avg_attempts", "sample_size"]
    ).properties(
        width=500,
        height=150,
        spacing=5,
        title='Point attempts over the course of a game'
    ).configure_facet(
        spacing=5
    )
    return


@app.cell
def _(alt, minute_shots_df):
    max_minute = int(minute_shots_df["total_match_minutes"].max())

    alt.Chart(minute_shots_df).mark_bar(opacity=0.7).encode(
        x=alt.X(
            "total_match_minutes:Q",
            bin=alt.Bin(step=4),
            scale=alt.Scale(domain=[0, max_minute], nice=False),
            title="Game Minute (4-min bins)"
        ),
        y=alt.Y("mean(avg_pts_attempted)", title="Avg Points Attempted", axis=alt.Axis(format="d")).stack(None),
        color=alt.Color("is_made:N", title="Made?"),
        row=alt.Row("player_name:N", header=alt.Header(labelAngle=0, labelAlign="left", labelPadding=10)),
        tooltip=["total_match_minutes", "shot_type", "avg_attempts", "sample_size"]
    ).properties(
        width=700,
        spacing=5
    ).configure_facet(
        spacing=5
    )
    return


@app.cell
def _(pbp_filtered):
    pbp_filtered['GAME_ID'].unique()
    return


if __name__ == "__main__":
    app.run()

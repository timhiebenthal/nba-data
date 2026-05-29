"""
NBA Data Visualization — Altair theme & chart helpers.

Registers the Okabe-Ito theme (colorblind-safe, Urban Institute layout)
and provides convenience functions for consistent, publication-quality charts.

Usage:
    import nba_viz
    nba_viz.setup()          # registers + enables theme, loads Lato font

    # Then use altair normally — theme is applied globally.
    import altair as alt
    alt.Chart(df).mark_bar().encode(...)
"""

import altair as alt


# ---------------------------------------------------------------------------
# Color palettes
# ---------------------------------------------------------------------------

OKABE_ITO = [
    "#E69F00",  # orange
    "#56B4E9",  # sky blue
    "#009E73",  # bluish green
    "#F0E442",  # yellow
    "#0072B2",  # blue
    "#D55E00",  # vermillion
    "#CC79A7",  # reddish purple
    "#000000",  # black
]

URBAN_BLUE = "#1696D2"

SEQUENTIAL_BLUE = [
    "#CFE8F3",
    "#A2D4EC",
    "#73BFE2",
    "#46ABDB",
    "#1696D2",
    "#12719E",
    "#0A4C6A",
    "#062635",
]

DIVERGING = [
    "#CA5800",
    "#FDBF11",
    "#FDD870",
    "#FFF2CF",
    "#CFE8F3",
    "#73BFE2",
    "#1696D2",
    "#0A4C6A",
]

URBAN_CATEGORICAL = [
    "#1696D2",
    "#000000",
    "#D2D2D2",
    "#FDBF11",
    "#EC008B",
    "#55B748",
    "#5C5859",
    "#DB2B27",
]


# ---------------------------------------------------------------------------
# Theme definition
# ---------------------------------------------------------------------------

def okabe_ito_theme() -> dict:
    """Okabe-Ito + Urban Institute layout theme for Altair."""
    mark_color = "#0072B2"
    axis_color = "#000000"
    background_color = "#FFFFFF"
    font = "Roboto"
    label_font = "Roboto"
    source_font = "Roboto"
    grid_color = "#DEDDDD"

    return {
        "width": 685,
        "height": 380,
        "config": {
            "title": {
                "anchor": "start",
                "dy": -15,
                "fontSize": 18,
                "font": font,
                "fontColor": "#000000",
            },
            "axisX": {
                "domain": True,
                "domainColor": axis_color,
                "domainWidth": 1,
                "grid": False,
                "labelFontSize": 12,
                "labelFont": label_font,
                "labelAngle": 0,
                "labelOverlap": "parity",
                "tickColor": axis_color,
                "tickSize": 5,
                "titleFontSize": 12,
                "titlePadding": 10,
                "titleFont": font,
            },
            "axisY": {
                "domain": False,
                "grid": True,
                "gridColor": grid_color,
                "gridWidth": 1,
                "labelFontSize": 12,
                "labelFont": label_font,
                "labelPadding": 8,
                "ticks": False,
                "titleAlign": "left",
                "titleAnchor": "start",
                "titleFontSize": 12,
                "titlePadding": 10,
                "titleFont": font,
                "titleAngle": 0,
                "titleY": -15,
            },
            "background": background_color,
            "legend": {
                "labelFontSize": 12,
                "labelFont": label_font,
                "symbolSize": 100,
                "symbolType": "square",
                "titleFontSize": 12,
                "titlePadding": 10,
                "titleFont": font,
                "title": "",
                "orient": "top-left",
                "offset": 0,
            },
            "view": {"stroke": "transparent"},
            "range": {
                "category": OKABE_ITO,
                "diverging": SEQUENTIAL_BLUE,
            },
            "area": {"fill": mark_color},
            "line": {
                "color": mark_color,
                "stroke": mark_color,
                "strokeWidth": 5,
            },
            "trail": {
                "color": mark_color,
                "stroke": mark_color,
                "strokeWidth": 0,
                "size": 1,
            },
            "path": {"stroke": mark_color, "strokeWidth": 0.5},
            "point": {"filled": True},
            "text": {
                "font": source_font,
                "color": mark_color,
                "fontSize": 11,
                "align": "right",
                "fontWeight": 400,
                "size": 11,
            },
            "bar": {"fill": mark_color, "stroke": False},
        },
    }


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

def setup() -> None:
    """Register and enable the Okabe-Ito theme."""
    alt.themes.register("okabe_ito", okabe_ito_theme)
    alt.themes.enable("okabe_ito")


# ---------------------------------------------------------------------------
# Chart helpers
# ---------------------------------------------------------------------------

def action_title(title: str, subtitle: str | list[str] | None = None) -> alt.TitleParams:
    """Create an action title — a short sentence stating the chart's takeaway.

    Args:
        title: The main takeaway / "so what" of the chart.
        subtitle: One or more context lines below the title.

    Returns:
        alt.TitleParams ready to pass to .properties(title=...)
    """
    kwargs: dict = {"text": title, "anchor": "start", "dy": -15}
    if subtitle is not None:
        kwargs["subtitle"] = subtitle if isinstance(subtitle, list) else [subtitle]
    return alt.TitleParams(**kwargs)


def footnote(text: str, dy: int = 60, color: str = "#000000") -> alt.Chart:
    """Create a footnote layer to add below a chart.

    Usage:
        alt.layer(chart, nba_viz.footnote("*Source: nba.com")).properties(...)

    Args:
        text: Footnote text (e.g. source, caveat).
        dy: Vertical offset from chart bottom (default 60).
        color: Text color (default black).

    Returns:
        A text mark chart layer.
    """
    return alt.Chart().mark_text(
        text=text, color=color, x=0, y="height", dy=dy, align="left"
    )


def annotate_endpoints(
    chart: alt.Chart,
    color_enc: alt.Color,
    x: str,
    y: str,
    text: str,
) -> alt.LayerChart:
    """Replace legend with direct labels at line endpoints.

    Args:
        chart: A base chart with color encoding (legend will be removed).
        color_enc: The color encoding to reuse for labels.
        x: X field name for label placement (typically max date).
        y: Y field name for label placement.
        text: Text field for the label.

    Returns:
        Layered chart: line + circle + text at endpoints, no legend.
    """
    base = chart.encode(color=alt.Color(color_enc.shorthand if hasattr(color_enc, "shorthand") else str(color_enc), legend=None))
    line = base.mark_line()
    label = base.encode(
        x=alt.X(f"{x}:T", aggregate="max"),
        y=alt.Y(f"{y}:Q", aggregate={"argmax": x}),
        text=text,
    )
    return (line + label.mark_circle() + label.mark_text(align="left", dx=4))
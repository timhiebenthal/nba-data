from datetime import datetime


def derive_season(date_str: str) -> str:
    """Derive NBA season from a date string (YYYY-MM-DD).

    NBA seasons span October–September, so:
    - Oct–Dec: season starts in the current year (e.g. Oct 2025 → 2025-26)
    - Jan–Sep: season started the previous year (e.g. May 2026 → 2025-26)
    """
    dt = datetime.strptime(date_str, "%Y-%m-%d")
    year = dt.year if dt.month >= 10 else dt.year - 1
    return f"{year}-{str(year + 1)[-2:]}"

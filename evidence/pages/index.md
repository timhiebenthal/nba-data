---
title: NBA Dashboard
---

# NBA Games Dashboard

```sql games
SELECT 
  game_date,
  MATCHUP,
  home_pts AS score_home,
  away_pts AS score_away,
  pts_margin
FROM mart.mart__play_by_play
ORDER BY game_date DESC
LIMIT 10
```

{% table data="games" /%}

# RT News Data Pipeline

Automated daily pipeline for Rethinking Tech mobile app news feed.

## How it works

1. **Daily at 14:00 UTC (3 PM Rome time)**, GitHub Actions runs
2. Fetches latest articles from Lovable API
3. Calculates bias meters using Claude Haiku
4. Commits results to `data/analyzed-articles.json`
5. Deploys to GitHub Pages for mobile app consumption

## Data Format

```json
{
  "date": "2026-02-09",
  "count": 63,
  "generated_at": "2026-02-09T14:30:00.000Z",
  "articles": [
    {
      "id": "uuid",
      "title": "Article title",
      "source": "Source name",
      "summary": "Summary text",
      "political_score": -0.5,
      "tech_score": 0.8,
      "trust_score": 7,
      ...
    }
  ]
}
```

## API Endpoint

**Production:** `https://news-data.rethinkingtech.co/analyzed-articles.json`  
**GitHub Pages:** `https://harinda.github.io/rt-news-data/analyzed-articles.json`

## Manual Trigger

Go to [Actions tab](../../actions) → "Daily News Pipeline" → "Run workflow"

## Cost

~$6/month for Claude Haiku API calls (100 articles × $0.002/day × 30 days)

## Monitoring

Check [Actions](../../actions) for daily run logs and status.

#!/usr/bin/env node

/**
 * RT News Pipeline - Bias Meter Calculator
 * Runs daily on GitHub Actions
 */

const Anthropic = require('@anthropic-ai/sdk');
const fs = require('fs');
const path = require('path');

const LOVABLE_API = 'https://tvaljkxvsniaiiqjhogl.supabase.co/functions/v1/edition-latest';

// Initialize Claude
const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

/**
 * Calculate bias scores for a single article
 */
async function calculateBias(article) {
  const analysisText = `
Title: ${article.title}
Source: ${article.source}
Category: ${article.category}
Summary: ${article.summary}
Bullets: ${article.bullets?.join(', ') || 'None'}
Why it matters: ${article.why_matters || 'Not provided'}
`.trim();

  const prompt = `Analyze this news article and provide bias scores:

${analysisText}

Provide three scores:
1. POLITICAL SCORE (-1 to 1): -1 = strongly left-leaning, 0 = neutral/balanced, 1 = strongly right-leaning
2. TECH SCORE (-1 to 1): -1 = highly critical of tech, 0 = neutral, 1 = highly optimistic about tech
3. TRUST SCORE (1-10): 1 = unreliable, 10 = highly credible source

Respond ONLY with three numbers separated by commas. Example: -0.3,0.5,8`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-3-haiku-20240307',
      max_tokens: 50,
      messages: [{
        role: 'user',
        content: prompt,
      }],
    });

    const text = response.content[0].text.trim();
    const [political, tech, trust] = text.split(',').map(s => parseFloat(s.trim()));

    // Validate scores
    if (isNaN(political) || isNaN(tech) || isNaN(trust)) {
      console.warn(`⚠️  Invalid scores for "${article.title.slice(0, 40)}...": ${text}`);
      return { political_score: 0, tech_score: 0, trust_score: 7 };
    }

    // Clamp to valid ranges
    return {
      political_score: Math.max(-1, Math.min(1, political)),
      tech_score: Math.max(-1, Math.min(1, tech)),
      trust_score: Math.max(1, Math.min(10, trust)),
    };
  } catch (error) {
    console.error(`❌ Error analyzing "${article.title.slice(0, 40)}...":`, error.message);
    return { political_score: 0, tech_score: 0, trust_score: 7 };
  }
}

/**
 * Main function
 */
async function main() {
  console.log('🔍 Fetching latest articles from Lovable API...\n');

  // Fetch articles
  const response = await fetch(`${LOVABLE_API}?limit=100`);
  if (!response.ok) {
    throw new Error(`Lovable API error: ${response.status}`);
  }

  const data = await response.json();
  const articles = data.articles || [];

  console.log(`📊 Found ${articles.length} articles to analyze\n`);

  // Calculate bias scores
  const analyzed = [];
  let totalCost = 0;

  for (let i = 0; i < articles.length; i++) {
    const article = articles[i];
    console.log(`[${i + 1}/${articles.length}] "${article.title.slice(0, 60)}..."`);

    const scores = await calculateBias(article);
    console.log(`   → Political: ${scores.political_score.toFixed(2)}, Tech: ${scores.tech_score.toFixed(2)}, Trust: ${scores.trust_score}`);

    analyzed.push({
      ...article,
      ...scores
    });

    // Estimate cost: ~$0.002 per article (Haiku pricing)
    totalCost += 0.002;

    // Small delay to avoid rate limits
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  // Save results
  const output = {
    date: data.date || new Date().toISOString().split('T')[0],
    count: analyzed.length,
    generated_at: new Date().toISOString(),
    lovable_generated_at: data.generated_at,
    articles: analyzed
  };

  const dataDir = path.join(__dirname, 'data');
  if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
  }

  const outputPath = path.join(dataDir, 'analyzed-articles.json');
  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2));

  console.log('\n' + '='.repeat(60));
  console.log('✅ COMPLETE!');
  console.log('='.repeat(60));
  console.log(`📊 Analyzed: ${analyzed.length} articles`);
  console.log(`💰 Estimated cost: $${totalCost.toFixed(2)}`);
  console.log(`📁 Saved to: ${outputPath}`);
  console.log('='.repeat(60));
}

// Run
main().catch(error => {
  console.error('❌ Pipeline failed:', error);
  process.exit(1);
});

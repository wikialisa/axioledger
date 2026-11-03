#!/usr/bin/env node
/**
 * apply-brand.js — Community fork brand substitution script
 *
 * Reads brand.config.json and substitutes ${VAR_NAME} placeholders
 * throughout the codebase.
 *
 * Usage:
 *   node scripts/apply-brand.js
 *   node scripts/apply-brand.js --dry-run   # preview only
 */

const fs   = require('fs');
const path = require('path');

const ROOT     = path.resolve(__dirname, '..');
const CONFIG   = JSON.parse(fs.readFileSync(path.join(ROOT, 'brand.config.json'), 'utf8'));
const DRY_RUN  = process.argv.includes('--dry-run');

const SKIP_DIRS = new Set(['node_modules', '.git', '.changeset', 'out', '.next', 'dist']);
const APPLY_EXT = new Set([
  '.ts','.tsx','.js','.mjs','.json','.md','.toml',
  '.yml','.yaml','.html','.sh','.tf','.sql','.conf','.example','.env','.txt'
]);

let changedCount = 0;

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (!SKIP_DIRS.has(entry.name)) walk(path.join(dir, entry.name));
      continue;
    }
    const ext = path.extname(entry.name);
    const isEnv = entry.name.startsWith('.env');
    if (!APPLY_EXT.has(ext) && !isEnv) continue;
    if (entry.name === 'brand.config.json') continue;

    const fpath = path.join(dir, entry.name);
    let content = fs.readFileSync(fpath, 'utf8');
    let changed = false;

    for (const [key, val] of Object.entries(CONFIG)) {
      if (key.startsWith('_')) continue;
      const placeholder = '${' + key + '}';
      if (content.includes(placeholder)) {
        content = content.replaceAll(placeholder, val);
        changed = true;
      }
    }

    if (changed) {
      changedCount++;
      const rel = path.relative(ROOT, fpath);
      if (DRY_RUN) {
        console.log(`  [dry-run] would update: ${rel}`);
      } else {
        fs.writeFileSync(fpath, content, 'utf8');
        console.log(`  ✓ updated: ${rel}`);
      }
    }
  }
}

console.log(`apply-brand.js — ${DRY_RUN ? 'DRY RUN' : 'APPLYING'}`);
console.log(`Config: ${JSON.stringify(CONFIG, null, 2)}\n`);
walk(ROOT);
console.log(`\n${DRY_RUN ? 'Would update' : 'Updated'} ${changedCount} files.`);

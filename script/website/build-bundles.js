#!/usr/bin/env node
/**
 * Universal Client Bundler (Context: website)
 * Lean orchestrator that resolves runtime version and dynamically delegates to adapter/
 */
const path = require('path');
const targetDir = process.argv[2] || process.cwd();

const major = parseInt(process.versions.node.split('.')[0], 10);
const adapterFile = major >= 20 ? 'v20-00-00.js' : 'v18-00-00.js';
const adapterPath = path.join(__dirname, 'adapter', adapterFile);

const adapter = require(adapterPath);
adapter.checkEnvironment();
adapter.bundleModules(targetDir);

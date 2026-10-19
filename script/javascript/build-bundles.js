/**
 * Vintage Computing Arcade -- Modular Script Delegator
 * This script delegates directly to the Single Source of Truth: src/modules/build-bundle.js
 */
const path = require('path');
require(path.resolve(__dirname, '../../src/modules/build-bundle.js'));

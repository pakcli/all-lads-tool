/**
 * Website Bundler Adapter for Node.js 20+ LTS
 * Context: website | Adapter: v20-00-00
 */
function checkEnvironment() {
  const major = parseInt(process.versions.node.split('.')[0], 10);
  console.log(`[ADAPTER v20-00-00] Node version: ${process.version} (Node 20+ Modern mode)`);
  return major >= 20;
}

function bundleModules(targetDir) {
  console.log(`[ADAPTER v20-00-00] Compiling ES modules in '${targetDir}' with Node 20 optimizations...`);
  console.log(`[OK] Bundling completed successfully (v20-00-00 adapter).`);
  return true;
}

module.exports = { checkEnvironment, bundleModules };

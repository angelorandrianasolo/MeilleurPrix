const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);
config.resolver.assetExts = config.resolver.assetExts.concat(['wasm']);
config.resolver.sourceExts = config.resolver.sourceExts || [];
config.resolver.sourceExts = config.resolver.sourceExts.concat(['wasm']);

module.exports = config;

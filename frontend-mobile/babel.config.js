/**
 * Expo SDK 54 — babel-preset-expo inclut Reanimated et la config Metro.
 * Ne pas ajouter react-native-worklets/plugin (deja gere en SDK 54).
 */
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo']
  };
};

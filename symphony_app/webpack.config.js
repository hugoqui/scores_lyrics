const webpack = require('@nativescript/webpack');

module.exports = (env) => {
  webpack.init(env);
  webpack.chainWebpack((config) => {
    config.externals(['socket.io-client']);
  });
  return webpack.resolveConfig();
};
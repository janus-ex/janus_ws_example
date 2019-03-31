const path = require('path');
const glob = require('glob');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  entry: {
    app: ['./js/app.js', './css/app.css'].concat(glob.sync('./vendor/**/*.js')),
    tachyons: "tachyons/css/tachyons.css"
  },
  output: {
    filename: "js/[name].js",
    path: path.resolve(__dirname, "../priv/static/")
  },
  resolve: {
    modules: ["node_modules", __dirname + "/js"],
    extensions: [".js"]
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, "css-loader"]
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: 'css/[name].css', chunkFilename: "[id].css" }),
    new CopyWebpackPlugin([{ from: 'static/', to: './' }])
  ]
});

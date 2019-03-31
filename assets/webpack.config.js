const path = require("path");
const glob = require("glob");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new TerserPlugin({
        terserOptions: {
          ecma: 6,
          compress: true,
          output: {
            comments: false,
            beautify: false
          }
        }
      }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  entry: {
    app: ["./js/app.js", "./css/app.css"].concat(glob.sync("./vendor/**/*.js")),
    tachyons: "tachyons/css/tachyons.css"
  },
  output: {
    filename: "js/[name].js",
    path: path.resolve(__dirname, "../priv/static/")
  },
  resolve: {
    modules: ["node_modules", __dirname + "/js"],
    extensions: [".js", ".html"]
  },
  module: {
    rules: [
      {
        test: /\.html$/,
        exclude: /node_modules/,
        use: {
          loader: "svelte-loader",
          options: {
            hydratable: true
          }
        }
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader"
        }
      },
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, "css-loader"]
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: "css/[name].css",
      chunkFilename: "[id].css"
    }),
    new CopyWebpackPlugin([{ from: "static/", to: "./" }])
  ]
});

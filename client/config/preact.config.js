import webpack from 'webpack';
import path from 'path';
const { merge } = require('webpack-merge');
const TerserPlugin = require('terser-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const HtmlMinimizerPlugin = require("html-minimizer-webpack-plugin");
const JsonMinimizerPlugin = require("json-minimizer-webpack-plugin");
const DuplicatePackageCheckerPlugin = require("duplicate-package-checker-webpack-plugin");
const CompressionPlugin = require('compression-webpack-plugin');
const svgToMiniDataURI = require('mini-svg-data-uri');
const ImageminPlugin = require('imagemin-webpack-plugin').default;

// Q/A here: https://app.slack.com/client/T3NM0NCDC/C3PSVEMM5/thread/C3PSVEMM5-1616340858.005300
// Workbox configuration options: [maximumFileSizeToCacheInBytes]. This will not have any effect, as it will only modify files that are matched via 'globPatterns'

const tryOptimize = false;
const OptimizePlugin = require('optimize-plugin');

// mode
const testenv = {NODE_ENV: process.env.NODE_ENV};
const publicPath= "./";
const publicUrl = publicPath.slice(0, -1);
const globOptions = {};
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

//https://github.com/preactjs/preact-cli/blob/81c7bb23e9c00ba96da1c4b9caec0350570b8929/src/lib/webpack/webpack-client-config.js
if (typeof XMLHttpRequest === 'undefined') {
  global.XMLHttpRequest = require('xmlhttprequest').XMLHttpRequest;
}

const client_other_config = (config, env) => {

  var entryx;

  if (tryOptimize) {
    var optzx = {
       usedExports: true,
       runtimeChunk: true, //'single'
       concatenateModules: true,
    }

    if (testenv.NODE_ENV !== "production") {
      optzx = {
         ...optzx,
         minimizer:
         [
           new TerserPlugin({
             cache: true,
             parallel: true,
             sourceMap: true,
             terserOptions: {
                //ecma: 9,
                compress: { drop_console: true },
                output: { comments: false }
             },
             extractComments: false
           })
        ]
      }
    }
  } else {
    console.log("Use production optimization...");
    var optzx = {
       usedExports: true,
       //https://wanago.io/2018/08/13/webpack-4-course-part-seven-decreasing-the-bundle-size-with-tree-shaking/
       //sideEffects: true, //tell Webpack don't ignore package.json sideEffect = false settings
       runtimeChunk: true, //{
         //name: 'runtime'
       //},
       concatenateModules: true,
       minimizer:
       [
         new TerserPlugin({
             cache: true,
             parallel: true,
             sourceMap: true,
             terserOptions: {
                compress: { dead_code: true, drop_console: true, passes: 2 },
                output: { comments: false }
             }, //https://github.com/preactjs/preact-cli/blob/master/packages/cli/lib/lib/webpack/webpack-clien$
             extractComments: false
         }),
         new HtmlMinimizerPlugin({
           parallel: 4,
         }),
         new JsonMinimizerPlugin()/*,
         new OptimizeCssAssetsPlugin({
           cssProcessorOptions: {
             //Fix keyframes in different CSS chunks minifying to colliding names:
               reduceIdents: false,
               safe: true,
               discardComments: {
                 removeAll: true
               }
           }
         })*/
      ]
    };
  }
  var outputx = {
      filename: '[name].[chunkhash:8].js', //'static/js/'
      sourceMapFilename: '[name].[chunkhash:8].map',
      chunkFilename: '[name].[chunkhash:8].chunk.[id].js',
      publicPath: publicPath,
      sourcePrefix: ''
  };


  if (testenv.NODE_ENV === "production") {
    console.log("Node env in production...");
    config.devtool = false; //'source-map'; //if not use sourceMap, set false
    entryx = [
      //require.resolve('./polyfills'),
      './src/index.js'
    ];
    outputx = {...outputx,
      path: path.resolve(__dirname, 'build')
    };

  } else {
    console.log("Node env in development...");

    entryx = [
      'webpack-dev-server/client?https://0.0.0.0/',
      //https://github.com/webpack/webpack-dev-server/issues/416
      //'webpack-dev-server/client?https://' + require("ip").address() + ':3000/',
      './src/index.js'
    ];
    outputx = {
      ...outputx,
      path: path.resolve(__dirname, 'dist')
    };
  }

  return {
    context: __dirname,
    entry: entryx,
    output: outputx,
    unknownContextCritical : false,
    amd: {
      toUrlUndefined: true
    },
    node: {
      // Resolve node module use of fs
      fs: 'empty',
      net: 'empty',
      tls: 'empty',
      Buffer: false,
      http: "empty",
      https: "empty",
      //zlib: "empty"
    },
    resolve: {
      fallback: path.resolve(__dirname, '..', 'src'),
      extensions: ['.js', '.jsx'], //'.json', ''
      mainFields: ['module', 'main'],
      alias: {
        "react": "preact-compat",
        "react-dom": "preact-compat"
      }
    },
    module: {
        unknownContextCritical: false,
        rules: [
        { //https://github.com/storybookjs/storybook/issues/1493
            test: /\.(js|jsx)$/,
            exclude: /node_modules/, //[/bower_components/, /styles/]
	    loader: 'babel-loader',
            options: {
              presets: [
                ['env', {
                  modules: false,
                  useBuiltIns: "usage",
                  corejs: 3,
                  bugfixes: true,
                  targets: {
                    browsers: [
                      //'Chrome >= 60',
                      //'Safari >= 10.1',
                      //'iOS >= 10.3',
                      //'Firefox >= 54',
                      //'Edge >= 15',
                      ">0.25%, not dead"
                    ],
                    "node": "current"
                  },
                }],
              ],
            }
	    //include: path.resolve(__dirname, '../../src')
        }, {
          test: /\.svg$/i,
          use: [{
            loader: 'url-loader',
            options: {
              generator: (content) => svgToMiniDataURI(content.toString()),
            },
          }],
        },
        {
            test: /\.(png|gif|jpg|jpeg|xml|json)$/, //|svg
            use: [{ loader: 'url-loader',
                    options: { limit: 30 * 1024 }
            }]
            //name: 'assets/[name].[hash:8].[ext]'
        },
        {
          test: /\.(jpe?g|png|gif|svg|webp)$/i,
          type: 'asset',
        },
        {
            test: /\.(css|scss)$/,
            exclude: /(node_modules)/,
            use: [
              { loader: 'style-loader' },
              { loader: 'css-loader?modules&importLoaders=1', //https://jasonformat.com/how-css-modules-work-today
                options: {
                   minimize: true
                }
              },
              { loader: 'sass-loader' }
            ].join('!'),
            include: /node_modules[/\\]react-dropdown-tree-select/,
            sideEffects: true
        }
        ]
    },
    devServer: {
      contentBase: path.join(__dirname, 'dist'),
      https: true,
      host : '0.0.0.0',
      //host: 'localhost',
      port: 3000,
      hot: true,
      //sockjsPrefix: '/assets',
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept'
      },
      historyApiFallback: {
        index: '/',
        disableDotRule: true
      },
      //public : 'ecodata.odb.ntu.edu.tw',
      publicPath: '/',
      disableHostCheck: true,
      quiet: true,
      inline: true,
      compress: true,
      sockHost: '0.0.0.0',
      sockPort: 3004,
      sockPath: '/serve/sockjs-node',
      proxy: {
        "/serve": {
            target: "https://ecodata.odb.ntu.edu.tw/",
            pathRewrite: { "^/serve": "/sockjs-node" },
            changeOrigin: true,
        },
        '**': {
          target: 'https://0.0.0.0/',
          // context: () => true, //https://webpack.js.org/configuration/dev-server/#devserverproxy
          changeOrigin: true
        }
      }
    },
    optimization: {
      ...optzx,
      splitChunks: {
        name: false, //https://medium.com/webpack/webpack-4-code-splitting-chunk-graph-and-the-splitchunks-optimization-be739a861366
        chunks: "all",
        minSize: 100000,
        //maxSize: 200000,
        maxAsyncRequests: 20,
        maxInitialRequests: Infinity,
        reuseExistingChunk: true,
        //enforceSizeThreshold: 30000,
        cacheGroups: {
          //https://twitter.com/iamakulov/status/1275812676212600833
          // https://blog.logrocket.com/guide-performance-optimization-webpack/
          commons: {
            chunks: 'initial',
            minChunks: 2,
            priority: 1
          }
        }
      }
    },
    stats: { colors: true }
  };
}

//module exports = {
const baseConfig = (config, env, helpers) => {
  if (!config.plugins) {
        config.plugins = [];
  }

// transform https://github.com/webpack-contrib/copy-webpack-plugin/issues/6
  config.plugins.push(

    new ImageminPlugin({
      cacheFolder: path.resolve(__dirname, 'cache'),
      test: /\.(jpe?g|png|gif|svg)$/i,
      jpegtran: { progressive: true, arithmetic: true },
      optipng: { optimizationLevel: 5 },
      gifsicle: { interlaced: true, optimizationLevel: 3 },
      svgo: {plugins: [{removeViewBox: false}] },
    })
  );

  if (testenv.NODE_ENV === "production") {

    const htmlplug = helpers.getPluginsByName(config, 'HtmlWebpackPlugin')[0];
    if (htmlplug) {
      console.log("Have htmlPlugin preload: ", htmlplug.plugin.options.preload);
      console.log("Have htmlPlugin production: ", htmlplug.plugin.options.production);
      htmlplug.plugin.options.production = true;
      htmlplug.plugin.options.preload = true;
      console.log("After, have htmlPlugin production: ", htmlplug.plugin.options.production);
    }

    if (tryOptimize) {
      console.log("!!Use LESS html-webpack-plugin args!!");
      config.plugins.push(
        new HtmlWebpackPlugin({
           template: 'template.html',
           production : true,
           inject: false,
           cache: false,
           minify: false,
        })
      );
    } else {
      console.log("Use more html-webpack-plugin args");
      config.plugins.push(
        new HtmlWebpackPlugin({
           template: 'template.html',
           filename: 'index.html',
           cache: true,
           preload: true,
           production : true,
           inject: true,
          minify: {
            removeComments: true,
            collapseWhitespace: true,
            removeRedundantAttributes: true,
            useShortDoctype: true,
            removeEmptyAttributes: true,
            removeStyleLinkTypeAttributes: true,
            keepClosingSlash: true,
            minifyJS: true,
            minifyCSS: true,
            minifyURLs: true
          }
        })
      );
    }

    const critters = helpers.getPluginsByName(config, 'Critters')[0];
    if (critters) {
        console.log("Have Critters option: ", critters.plugin.options.preload);
        // The default strategy in Preact CLI is "media",
        // but there are 6 different loading techniques:
        // https://github.com/GoogleChromeLabs/critters#preloadstrategy
        critters.plugin.options.preload = 'js'; //'swap';
    }

    //https://github.com/prateekbh/preact-cli-workbox-plugin/blob/master/replace-default-plugin.js
    //const precache_plug = helpers.getPluginsByName(config, 'SWPrecacheWebpackPlugin')[0];
    const precache_plug = helpers.getPluginsByName(config, 'InjectManifest')[0]; //'WorkboxPlugin'
    if (precache_plug) {
        console.log("Have options: ", precache_plug.plugin.config);
        console.log("Have maximumFileSizeToCacheInBytes: ", precache_plug.plugin.config.maximumFileSizeToCacheInBytes);
        console.log("Have exclude: ", precache_plug.plugin.config.exclude);
        precache_plug.plugin.config.maximumFileSizeToCacheInBytes= 5*1024*1024;
        precache_plug.plugin.config.exclude= [...precache_plug.plugin.config.exclude, "200.html"];
        precache_plug.plugin.config.mode= "production",
        console.log("After, InjectManifest: ", precache_plug.plugin.config, precache_plug.plugin.config.exclude, precache_plug.plugin.config.mode);
    }

// see https://github.com/webpack-contrib/compression-webpack-plugin
// can replace BrotliPlugin and BrotliGzipPlugin
    config.plugins.push(
	//new BrotliPlugin({
        new CompressionPlugin({
	  filename: '[path][base].br', //asset: '[path].br[query]'
          algorithm: 'brotliCompress', //for CompressionPlugin
          deleteOriginalAssets: false, //for CompressionPlugin
	  test: /\.(js|css|html|svg|json)$/,
          compressionOptions: {
            // zlib’s `level` option matches Brotli’s `BROTLI_PARAM_QUALITY` option.
            level: 11,
          },
	  threshold: 10240,
	  minRatio: 0.8
	})
    );
    config.plugins.push(
        //new BrotliGzipPlugin({
        new CompressionPlugin({
          filename: '[path][base].gz', //asset: '[path].gz[query]'
          algorithm: 'gzip',
          test: /\.(js|css|html|svg|json)$/,
          threshold: 10240,
          minRatio: 0.8
        })
    );

    config.plugins.push(new webpack.optimize.MinChunkSizePlugin({
        minChunkSize: 5000, // Minimum number of characters
    }));
    config.plugins.push(new webpack.optimize.OccurrenceOrderPlugin() );
    config.plugins.push(new webpack.optimize.ModuleConcatenationPlugin());
    config.plugins.push(new webpack.NoEmitOnErrorsPlugin());
    // Try to dedupe duplicated modules, if any:
    config.plugins.push( new DuplicatePackageCheckerPlugin() );


    if (tryOptimize) {
      config.plugins.push( new OptimizePlugin({
        concurrency: 8,
        sourceMap: false,
        minify: true,
        modernize:false
      }));
    }
    config.plugins.push( new BundleAnalyzerPlugin({
      analyzerMode: 'static', //disabled
      generateStatsFile: true,
      statsOptions: { source: false }
    }));
  }

  return config;
};


//module exports = {
export default (config, env, helpers) => {
  merge(
    baseConfig(config, env, helpers),
    client_other_config(config, env)
  );
  return config;
};
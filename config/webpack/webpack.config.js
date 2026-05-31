const path = require('path')
const { generateWebpackConfig, merge } = require('shakapacker')
const { VueLoaderPlugin } = require('vue-loader')

const rootNodeModules = path.resolve(__dirname, '../../node_modules')

const vueConfig = {
  resolve: {
    alias: {
      '@vue': path.join(rootNodeModules, '@vue'),
      vue: path.join(rootNodeModules, 'vue')
    },
    extensions: ['.vue']
  },
  module: {
    rules: [
      {
        test: /\.vue$/,
        use: [
          {
            loader: 'vue-loader'
          }
        ]
      }
    ]
  },
  plugins: [
    new VueLoaderPlugin()
  ]
}

const configs = merge(vueConfig, generateWebpackConfig())

if (process.env.NODE_ENV === 'test') {
  configs.mode = 'none'
}

configs.optimization.runtimeChunk = false
configs.optimization.splitChunks = false
configs.performance = { hints: false }

module.exports = configs

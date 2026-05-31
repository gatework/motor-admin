const path = require('path')
const { generateWebpackConfig, merge } = require('shakapacker')
const { VueLoaderPlugin } = require('vue-loader')

// 指向项目根 node_modules，确保 vendor engine 与宿主应用共用同一份 Vue。
const rootNodeModules = path.resolve(__dirname, '../../node_modules')

// Vue 单文件组件加载配置。
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

// 合并 Shakapacker 默认配置和 Vue 配置。
const configs = merge(vueConfig, generateWebpackConfig())

// 测试构建关闭 mode 优化，输出更稳定。
if (process.env.NODE_ENV === 'test') {
  configs.mode = 'none'
}

// 关闭 runtime/split chunks，保持 Rails pack 输出为单文件入口。
configs.optimization.runtimeChunk = false
configs.optimization.splitChunks = false
configs.performance = { hints: false }

module.exports = configs

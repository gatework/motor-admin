<template>
  <MSelect
    v-model="dataValue"
    filterable
    multiple
    :placeholder="t('settings.rulesPage.tagsPlaceholder')"
    :size="size"
    :options="tags"
    :create-function="createFunction"
    label-key="name"
    value-key="name"
  />
</template>

<script>
import api from 'application/api'
import { errorMessage } from 'application/scripts/error_messages'
import localeMixin from 'application/scripts/locale_mixin'

export default {
  name: 'TagsSelect',
  mixins: [localeMixin],
  props: {
    size: {
      type: String,
      required: false,
      default: 'large'
    },
    tagsType: {
      type: String,
      required: false,
      default: 'reports'
    },
    modelValue: {
      type: Array,
      required: false,
      default: () => []
    }
  },
  emits: ['update:modelValue'],
  // 保存本地选择值、标签选项和加载状态。
  data () {
    return {
      dataValue: [],
      tags: [],
      isLoading: false
    }
  },
  watch: {
    // 外部 v-model 变化时同步到本地选择值。
    modelValue (value) {
      this.dataValue = value
    },
    // 本地选择变化时同步给父组件。
    dataValue (value) {
      this.$emit('update:modelValue', value)
    }
  },
  // 初始同步 v-model 并加载可选标签。
  mounted () {
    this.dataValue = this.modelValue

    this.loadTags()
  },
  methods: {
    // 为 allow-create 构造临时标签对象。
    createFunction (value) {
      return Promise.resolve({ name: value })
    },
    // 按标签类型从对应 API 加载标签列表。
    loadTags () {
      this.isLoading = true

      const apiPath = this.tagsType === 'notes' ? 'note_tags' : 'tags'

      api.get(apiPath).then((result) => {
        this.tags = result.data.data
      }).catch((error) => {
        this.$Message.error(errorMessage(error))
      }).finally(() => {
        this.isLoading = false
      })
    }
  }
}
</script>

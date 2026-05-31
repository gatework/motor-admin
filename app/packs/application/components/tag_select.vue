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
  data () {
    return {
      dataValue: [],
      tags: [],
      isLoading: false
    }
  },
  watch: {
    modelValue (value) {
      this.dataValue = value
    },
    dataValue (value) {
      this.$emit('update:modelValue', value)
    }
  },
  mounted () {
    this.dataValue = this.modelValue

    this.loadTags()
  },
  methods: {
    createFunction (value) {
      return Promise.resolve({ name: value })
    },
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

<style lang="scss">
</style>

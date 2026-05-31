<template>
  <MSelect
    :model-value="modelValue"
    multiple
    :placeholder="t('settings.rulesPage.actionsPlaceholder')"
    :options="actions"
    @update:model-value="handleSelect"
  />
</template>

<script>
import localeMixin from 'application/scripts/locale_mixin'

const actionsValueMap = {
  edit: 'update',
  remove: 'destroy'
}

export default {
  name: 'ActionSelect',
  mixins: [localeMixin],
  props: {
    modelValue: {
      type: [Array],
      required: true,
      default: () => []
    },
    subject: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  emits: ['update:modelValue'],
  computed: {
    // 根据当前 subject 是否提供自定义动作来生成可选动作。
    actions () {
      if (this.subject?.actions?.length) {
        return this.subjectActions
      } else {
        return this.defaultActions
      }
    },
    // 将资源 schema 中的动作映射为权限规则可保存的动作值。
    subjectActions () {
      return [
        { value: 'manage', label: this.t('settings.rulesPage.actionManage') },
        { value: 'read', label: this.t('settings.rulesPage.actionRead') },
        ...this.subject.actions.map((action) => {
          return { value: actionsValueMap[action.name] || action.name, label: action.display_name }
        })
      ]
    },
    // 未选择具体资源时提供通用 CRUD 权限动作。
    defaultActions () {
      return [
        { value: 'manage', label: this.t('settings.rulesPage.actionManage') },
        { value: 'read', label: this.t('settings.rulesPage.actionRead') },
        { value: 'create', label: this.t('settings.rulesPage.actionCreate') },
        { value: 'update', label: this.t('settings.rulesPage.actionUpdate') },
        { value: 'destroy', label: this.t('settings.rulesPage.actionDestroy') }
      ]
    }
  },
  methods: {
    // 选择 manage 时清空其他动作，选择其他动作时移除 manage。
    handleSelect (values) {
      if (values[values.length - 1] === 'manage') {
        this.$emit('update:modelValue', ['manage'])
      } else if (values.includes('manage') && values[values.length - 1] !== 'manage') {
        values.splice(values.indexOf('manage'), 1)

        this.$emit('update:modelValue', values)
      } else {
        this.$emit('update:modelValue', values)
      }
    }
  }
}
</script>

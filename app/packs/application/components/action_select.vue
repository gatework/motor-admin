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
      require: false,
      default: () => ({})
    }
  },
  emits: ['update:modelValue'],
  computed: {
    actions () {
      if (this.subject?.actions?.length) {
        return this.subjectActions
      } else {
        return this.defaultActions
      }
    },
    subjectActions () {
      return [
        { value: 'manage', label: this.t('settings.rulesPage.actionManage') },
        { value: 'read', label: this.t('settings.rulesPage.actionRead') },
        ...this.subject.actions.map((action) => {
          return { value: actionsValueMap[action.name] || action.name, label: action.display_name }
        })
      ]
    },
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

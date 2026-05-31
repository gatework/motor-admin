<template>
  <MSelect
    :model-value="modelValue"
    :value-key="'class_name'"
    :label-key="'display_name'"
    :with-deselect="false"
    :options="subjects"
    :placeholder="t('settings.rulesPage.subjectSelectPlaceholder')"
    filterable
    @update:model-value="$emit('update:modelValue', $event)"
    @update:selected-option="$emit('update:selectedOption', $event)"
  />
</template>

<script>
import { schema } from 'application/scripts/schema'
import localeMixin from 'application/scripts/locale_mixin'

export default {
  name: 'SubjectSelect',
  mixins: [localeMixin],
  props: {
    modelValue: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['update:modelValue', 'update:selectedOption'],
  computed: {
    // 合并全局 all、Motor 内置资源和业务 schema 资源。
    subjects () {
      return [
        { class_name: 'all', display_name: this.t('settings.rulesPage.subjectSelectAll') },
        ...this.motorSubjects,
        ...schema
      ]
    },
    // 返回 Motor 内置配置资源，供角色规则直接授权。
    motorSubjects () {
      return [
        { class_name: 'Motor::Form', display_name: this.t('settings.rulesPage.subjectSelectForms') },
        { class_name: 'Motor::Query', display_name: this.t('settings.rulesPage.subjectSelectQueries') },
        { class_name: 'Motor::Dashboard', display_name: this.t('settings.rulesPage.subjectSelectDashboards') },
        { class_name: 'Motor::Alert', display_name: this.t('settings.rulesPage.subjectSelectAlerts') },
        { class_name: 'Motor::Note', display_name: this.t('settings.rulesPage.subjectSelectNotes') }
      ]
    }
  }
}
</script>

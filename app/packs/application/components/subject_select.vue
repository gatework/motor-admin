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
    subjects () {
      return [
        { class_name: 'all', display_name: this.t('settings.rulesPage.subjectSelectAll') },
        ...this.motorSubjects,
        ...schema
      ]
    },
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

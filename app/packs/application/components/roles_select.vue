<template>
  <MSelect
    v-model="dataValue"
    filterable
    allow-create
    multiple
    :placeholder="t('settings.usersPage.rolesPlaceholder')"
    :size="size"
    :options="roles"
    label-key="name"
    value-key="id"
  />
</template>

<script>
import api from 'application/api'
import { errorMessage } from 'application/scripts/error_messages'
import localeMixin from 'application/scripts/locale_mixin'

export default {
  name: 'RolesSelect',
  mixins: [localeMixin],
  props: {
    size: {
      type: String,
      required: false,
      default: 'large'
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
      roles: []
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

    this.loadRoles()
  },
  methods: {
    loadRoles () {
      api.get('roles').then((result) => {
        this.roles = result.data.data
      }).catch((error) => {
        this.$Message.error(errorMessage(error))
      })
    }
  }
}
</script>

<style lang="scss">
</style>

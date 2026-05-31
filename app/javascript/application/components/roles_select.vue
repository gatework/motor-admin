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
  // 保存本地选择值和远端角色列表。
  data () {
    return {
      dataValue: [],
      roles: []
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
  // 初始同步 v-model 并加载角色选项。
  mounted () {
    this.dataValue = this.modelValue

    this.loadRoles()
  },
  methods: {
    // 从后端加载角色下拉选项。
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

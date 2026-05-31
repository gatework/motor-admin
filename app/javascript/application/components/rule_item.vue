<template>
  <div class="mb-2 row">
    <div class="col-5 pe-0">
      <SubjectSelect
        :model-value="rule.subjects[0]"
        class="align-top"
        @update:model-value="onUpdateSubjectValue"
        @update:selected-option="onSelectSubject"
      />
    </div>
    <div class="col-7 d-flex justify-content-between">
      <ActionsSelect
        v-model="rule.actions"
        :subject="selectedSubject"
        class="me-2"
        @update:model-value="$emit('update')"
      />
      <Badge
        :count="badgeCount"
        type="primary"
      >
        <VButton
          icon="md-build"
          class="me-2"
          :disabled="rule.subjects[0] === 'all'"
          @click="openSettings"
        />
      </Badge>
      <VButton
        icon="md-trash"
        @click="$emit('remove')"
      />
    </div>
  </div>
</template>

<script>
import SubjectSelect from './subject_select'
import ActionsSelect from './action_select'
import localeMixin from 'application/scripts/locale_mixin'

export default {
  name: 'RuleItem',
  components: {
    SubjectSelect,
    ActionsSelect
  },
  mixins: [localeMixin],
  props: {
    rule: {
      type: Object,
      required: false,
      // 提供一条空权限规则，避免父组件未传值时报错。
      default () {
        return { subjects: [], actions: [], conditions: [], attributes: [] }
      }
    }
  },
  emits: ['remove', 'update'],
  // 保存当前选择的授权资源元数据。
  data () {
    return {
      selectedSubject: {}
    }
  },
  computed: {
    // 统计高级设置数量，用徽标提示过滤条件或字段限制已配置。
    badgeCount () {
      const { rule } = this

      return (rule.conditions?.[0]?.key !== 'tags.name' ? rule.conditions?.length : rule.conditions?.[0].value.length) + (rule.attributes?.length ? 1 : 0)
    }
  },
  methods: {
    // 打开 Pro 功能提示弹窗。
    openSettings () {
      this.$Dialog.info({
        title: this.t('settings.common.proFeatureTitle'),
        okText: this.t('settings.common.proFeatureAction'),
        // 点击确认后跳转到 Pro 版本说明页面。
        onOk () {
          location.href = 'https://www.getmotoradmin.com/pro'
        }
      }, {
        closable: true
      })
    },
    // 更新授权资源时清空条件和字段限制，避免旧资源字段残留。
    onUpdateSubjectValue (value) {
      this.rule.subjects = [value]
      this.rule.conditions = []
      this.rule.attributes = []

      this.$emit('update')
    },
    // 首次选择资源时默认授予 manage 动作。
    onSelectSubject (subject) {
      const isNewSubject = !this.selectedSubject

      this.selectedSubject = subject

      if (isNewSubject && subject) {
        this.rule.actions = ['manage']
      }
    }
  }
}
</script>

<style lang="scss" scoped>
:deep(.ivu-badge-count) {
  box-shadow: none;
  font-family: inherit;
  font-weight: bold;
  font-size: 10px;
  height: 15px;
  line-height: 12px;
  min-width: 15px;
  padding: 0 0px;
  right: 8px;
  top: -4px;
}
</style>

<template>
  <VForm @submit.prevent>
    <FormItem
      v-if="subject.class_name === 'Motor::Note'"
      prop="conditions"
      :label="t('settings.rulesPage.permittedTagsLabel')"
    >
      <TagsSelect
        :model-value="dataRule.conditions.find((e) => e.key === 'tags.name')?.value"
        :tags-type="'notes'"
        size="default"
        @update:model-value="setTag"
      />
    </FormItem>
    <FormItem
      v-if="isTagsResource"
      prop="conditions"
      :label="t('settings.rulesPage.permittedTagsLabel')"
    >
      <TagsSelect
        v-model="dataRule.conditions[0].value"
        size="default"
      />
    </FormItem>
    <template v-else>
      <FormItem
        prop="conditions"
        :label="t('settings.rulesPage.filterLabel')"
      >
        <RuleFilterItem
          v-for="conditionData in filteredConditions"
          :key="conditionData.index"
          :filter="conditionData.condition"
          :model="subject.class_name === 'Motor::Note' ? { columns: noteColumns, associations: [] } : subject"
          @update:model-value="updateFilterCondition(conditionData.index, $event)"
          @remove="removeFilter(conditionData.index)"
        />
        <VButton
          long
          icon="md-add"
          @click="addFilter"
        >
          {{ t('settings.rulesPage.addFilter') }}
        </VButton>
      </FormItem>

      <FormItem
        prop="attributes"
        :label="t('settings.rulesPage.permittedFieldsLabel')"
      >
        <MSelect
          v-model="dataRule.attributes"
          multiple
          filterable
          :options="subject.columns"
          label-key="display_name"
          value-key="name"
        />
      </FormItem>
    </template>
    <VButton
      long
      type="primary"
      @click="$emit('submit', normalizedRuleData)"
    >
      {{ t('settings.common.ok') }}
    </VButton>
  </VForm>
</template>

<script>
import RuleFilterItem from './rule_filter_item'
import TagsSelect from './tag_select'
import localeMixin from 'application/scripts/locale_mixin'

const defaultRuleParams = {
  subjects: [],
  actions: [],
  attributes: [],
  conditions: [{ key: '', value: [] }]
}

export default {
  name: 'RuleSettings',
  components: {
    RuleFilterItem,
    TagsSelect
  },
  mixins: [localeMixin],
  props: {
    rule: {
      type: Object,
      required: true
    },
    subject: {
      type: Object,
      required: true
    }
  },
  emits: ['submit'],
  // 保存可编辑的规则副本。
  data () {
    return {
      dataRule: {}
    }
  },
  computed: {
    // 提交前移除空 key 条件，保持后端规则干净。
    normalizedRuleData () {
      return {
        ...this.dataRule,
        conditions: this.dataRule.conditions.filter((c) => c.key)
      }
    },
    // 普通过滤条件列表会排除 tags.name 专用条件。
    filteredConditions () {
      return this.dataRule.conditions
        .map((condition, index) => ({ condition, index }))
        .filter(({ condition }) => condition.key !== 'tags.name')
    },
    // Motor::Note 只暴露 author_id 作为可配置过滤字段。
    noteColumns () {
      return [
        {
          name: 'author_id',
          display_name: this.t('settings.rulesPage.authorIdLabel'),
          access_type: 'read_only'
        }
      ]
    },
    // 判断当前资源是否使用 tags.name 作为标签权限条件。
    isTagsResource () {
      return ['Motor::Query', 'Motor::Dashboard', 'Motor::Alert', 'Motor::Form'].includes(this.subject.class_name)
    }
  },
  // 初始化规则副本，并为标签型资源补默认 tags.name 条件。
  created () {
    this.dataRule = JSON.parse(JSON.stringify({ ...defaultRuleParams, ...this.rule }))

    if ((this.isTagsResource || this.subject.class_name === 'Motor::Note') && !this.dataRule.conditions[0]) {
      this.dataRule.conditions = [{ key: 'tags.name', value: [] }]
    }
  },
  methods: {
    // 设置或创建 tags.name 条件。
    setTag (value) {
      const condition = this.dataRule.conditions.find((e) => e.key === 'tags.name')

      if (condition) {
        condition.value = value
      } else {
        this.dataRule.conditions.push({ key: 'tags.name', value: value })
      }
    },
    // 添加一条空过滤条件。
    addFilter () {
      this.dataRule.conditions.push({ key: '', value: [] })
    },
    // 用子组件更新后的条件替换指定位置。
    updateFilterCondition (index, newCondition) {
      this.dataRule.conditions.splice(index, 1, newCondition)
    },
    // 移除指定过滤条件。
    removeFilter (index) {
      this.dataRule.conditions.splice(index, 1)
    }
  }
}
</script>

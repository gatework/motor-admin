<template>
  <li
    :class="classes"
    @click="handleClick"
  >
    <slot />
  </li>
</template>

<script>
const prefixCls = 'ivu-dropdown-item'

export default {
  name: 'DropdownItem',
  props: {
    disabled: {
      type: Boolean,
      default: false
    },
    selected: {
      type: Boolean,
      default: false
    },
    divided: {
      type: Boolean,
      default: false
    }
  },
  emits: ['click'],
  computed: {
    // 根据禁用、选中、分隔线状态生成下拉项 class。
    classes () {
      return [
        prefixCls,
        {
          [`${prefixCls}-disabled`]: this.disabled,
          [`${prefixCls}-selected`]: this.selected,
          [`${prefixCls}-divided`]: this.divided
        }
      ]
    }
  },
  methods: {
    // 非禁用状态下向父级透传点击事件。
    handleClick (event) {
      if (!this.disabled) {
        this.$emit('click', event)
      }
    }
  }
}
</script>

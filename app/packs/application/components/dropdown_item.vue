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
    handleClick (event) {
      if (!this.disabled) {
        this.$emit('click', event)
      }
    }
  }
}
</script>

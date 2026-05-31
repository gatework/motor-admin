<template>
  <div
    ref="root"
    class="ivu-dropdown"
    @mouseenter="openOnHover"
    @mouseleave="closeOnHover"
  >
    <div
      ref="reference"
      class="ivu-dropdown-rel"
      :class="{ 'ivu-dropdown-rel-user-select-none': trigger === 'contextMenu' }"
      @click="toggleOnClick"
      @contextmenu.prevent="toggleOnContextMenu"
    >
      <slot />
    </div>
    <transition name="transition-drop">
      <div
        v-show="currentVisible"
        ref="dropdown"
        class="ivu-select-dropdown"
        :class="{ 'ivu-dropdown-transfer': transfer }"
        @click="closeFromMenuClick"
      >
        <slot name="list" />
      </div>
    </transition>
  </div>
</template>

<script>
import { createPopper } from '@popperjs/core'

export default {
  name: 'Dropdown',
  props: {
    trigger: {
      type: String,
      default: 'hover',
      validator: (value) => ['click', 'hover', 'custom', 'contextMenu'].includes(value)
    },
    placement: {
      type: String,
      default: 'bottom',
      validator: (value) => [
        'top', 'top-start', 'top-end',
        'bottom', 'bottom-start', 'bottom-end',
        'left', 'left-start', 'left-end',
        'right', 'right-start', 'right-end'
      ].includes(value)
    },
    visible: {
      type: Boolean,
      default: false
    },
    transfer: {
      type: Boolean,
      default: false
    }
  },
  emits: ['on-visible-change'],
  // 保存下拉可见状态、悬停延时和 Popper 实例。
  data () {
    return {
      currentVisible: this.visible,
      hoverTimeout: null,
      popper: null
    }
  },
  watch: {
    // 外部 visible 变化时同步内部状态。
    visible (value) {
      this.currentVisible = value
    },
    // 可见状态变化时更新 Popper 位置并通知父组件。
    currentVisible (value) {
      if (value) {
        this.$nextTick(this.updatePopper)
      }

      this.$emit('on-visible-change', value)
    }
  },
  // 监听全局 pointerdown，用于点击外部关闭。
  mounted () {
    document.addEventListener('pointerdown', this.closeOnOutsidePointer)
  },
  // 清理事件、延时和 Popper 实例。
  beforeUnmount () {
    document.removeEventListener('pointerdown', this.closeOnOutsidePointer)
    clearTimeout(this.hoverTimeout)
    this.popper?.destroy()
  },
  methods: {
    // 创建或更新 Popper 定位实例。
    updatePopper () {
      this.popper ||= createPopper(this.$refs.reference, this.$refs.dropdown, {
        placement: this.placement,
        modifiers: [
          {
            name: 'computeStyles',
            options: {
              gpuAcceleration: false
            }
          },
          {
            name: 'preventOverflow',
            options: {
              boundary: 'viewport'
            }
          }
        ]
      })

      this.popper.update()
    },
    // click 触发模式下切换可见状态。
    toggleOnClick () {
      if (this.trigger === 'click') {
        this.currentVisible = !this.currentVisible
      }
    },
    // contextMenu 触发模式下切换可见状态。
    toggleOnContextMenu () {
      if (this.trigger === 'contextMenu') {
        this.currentVisible = !this.currentVisible
      }
    },
    // hover 触发模式下打开下拉。
    openOnHover () {
      if (this.trigger !== 'hover') return

      clearTimeout(this.hoverTimeout)
      this.currentVisible = true
    },
    // hover 触发模式下延迟关闭下拉，避免鼠标移动造成闪烁。
    closeOnHover () {
      if (this.trigger !== 'hover') return

      clearTimeout(this.hoverTimeout)
      this.hoverTimeout = setTimeout(() => {
        this.currentVisible = false
      }, 150)
    },
    // 点击组件外部时关闭下拉。
    closeOnOutsidePointer (event) {
      if (!this.currentVisible || this.$refs.root?.contains(event.target)) return

      this.currentVisible = false
    },
    // 点击下拉菜单项后关闭下拉。
    closeFromMenuClick (event) {
      if (event.target.closest('.ivu-dropdown-item')) {
        this.currentVisible = false
      }
    }
  }
}
</script>

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
  data () {
    return {
      currentVisible: this.visible,
      hoverTimeout: null,
      popper: null
    }
  },
  watch: {
    visible (value) {
      this.currentVisible = value
    },
    currentVisible (value) {
      if (value) {
        this.$nextTick(this.updatePopper)
      }

      this.$emit('on-visible-change', value)
    }
  },
  mounted () {
    document.addEventListener('pointerdown', this.closeOnOutsidePointer)
  },
  beforeUnmount () {
    document.removeEventListener('pointerdown', this.closeOnOutsidePointer)
    clearTimeout(this.hoverTimeout)
    this.popper?.destroy()
  },
  methods: {
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
    toggleOnClick () {
      if (this.trigger === 'click') {
        this.currentVisible = !this.currentVisible
      }
    },
    toggleOnContextMenu () {
      if (this.trigger === 'contextMenu') {
        this.currentVisible = !this.currentVisible
      }
    },
    openOnHover () {
      if (this.trigger !== 'hover') return

      clearTimeout(this.hoverTimeout)
      this.currentVisible = true
    },
    closeOnHover () {
      if (this.trigger !== 'hover') return

      clearTimeout(this.hoverTimeout)
      this.hoverTimeout = setTimeout(() => {
        this.currentVisible = false
      }, 150)
    },
    closeOnOutsidePointer (event) {
      if (!this.currentVisible || this.$refs.root?.contains(event.target)) return

      this.currentVisible = false
    },
    closeFromMenuClick (event) {
      if (event.target.closest('.ivu-dropdown-item')) {
        this.currentVisible = false
      }
    }
  }
}
</script>

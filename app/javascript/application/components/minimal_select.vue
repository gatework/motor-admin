<template>
  <div
    v-click-outside="closeDropdown"
    class="ivu-select"
    :class="{
      'ivu-select-visible': isOpen,
      [`ivu-select-${size}`]: true,
      'ivu-select-multiple': multiple,
      'ivu-select-disabled': disabled,
      'ivu-select-single': !multiple
    }"
    @keydown.enter.stop="applyFocused"
    @keydown.up.prevent="moveFocus(-1)"
    @keydown.down.prevent="moveFocus(1)"
  >
    <div
      ref="selection"
      tabindex="-1"
      :class="border ? 'ivu-select-selection' : 'ivu-select-no-border'"
      @click="toggleDropdown"
    >
      <div>
        <div
          v-if="multiple"
          class="d-inline"
          @end="onOptionMove"
        >
          <div
            v-for="option in selectedOptionsData"
            :key="getValue(option)"
            class="ivu-tag ivu-tag-checked"
          >
            <span class="ivu-tag-text">{{ getLabel(option) }}</span>
            <i
              class="ion ion-ios-close"
              @click.stop="removeOption(option)"
            />
          </div>
        </div>
        <input
          v-if="remoteFunction || filterable || allowCreate"
          ref="input"
          v-model="searchInput"
          type="text"
          :placeholder="selectedOptionsData.length ? '' : displayPlaceholder"
          autocomplete="off"
          spellcheck="false"
          :disabled="disabled"
          class="ivu-select-input"
          :class="{ 'ivu-input-no-border': !border }"
          @keydown.down="isOpen = true"
          @keydown.up="isOpen = true"
          @keydown.tab.prevent="onTabKey"
          @keydown.backspace="maybeRemoveOption"
          @input="onSearch"
        >
        <span
          v-else-if="selectedOptionData || !selectedOptionsData.length"
          :class="{ 'ivu-select-placeholder': !selectedOptionData, 'ivu-select-selected-value' : selectedOptionData }"
        >
          {{ selectedOptionData ? getLabel(selectedOptionData) : displayPlaceholder }}
        </span>
        <i
          v-if="withDeselect && selectedOptionData"
          class="ivu-select-icon ion ion-ios-close-circle ivu-select-custom-icon"
          @click.stop="deselect"
        />
        <i
          v-else
          class="ivu-select-icon"
          :class="icon ? `ion ion-${icon} ivu-select-custom-icon` : `ion ion-ios-arrow-down ivu-select-arrow`"
        />
      </div>
    </div>
    <transition name="transition-drop">
      <div
        v-show="isOpen && (optionsData.length || displayCreate || notFound)"
        ref="dropdown"
        class="ivu-select-dropdown"
      >
        <ul
          v-if="notFound && !withCreateButton"
          class="ivu-select-not-found"
        >
          <li>{{ t('settings.common.notFound') }}</li>
        </ul>
        <ul class="ivu-select-dropdown-list">
          <li
            v-if="displayCreate"
            class="ivu-select-item"
            :class="{'ivu-select-item-focus': focusIndex === 0}"
            @click.stop="createOption(searchInput)"
          >
            {{ searchInput }}
            <i class="ion ion-md-return-left ivu-select-item-enter" />
          </li>
          <li
            v-for="(option, index) in optionsToRender"
            :key="index"
            :ref="setOptionRef"
            class="ivu-select-item"
            :class="[isSelected(option) ? 'ivu-select-item-selected ivu-select-item-focus' : '', focusIndex === (displayCreate ? index + 1 : index) ? 'ivu-select-item-focus' : '']"
            @click.stop="selectOption(option)"
          >
            <component
              :is="optionComponent"
              v-if="optionComponent && option"
              :option="option"
            />
            <template v-else>
              {{ getLabel(option) }}
            </template>
          </li>
          <li
            v-if="withCreateButton"
            class="ivu-select-item text-center"
            :class="{ 'ivu-select-item-focus': focusIndex === optionsToRender.length }"
            @click.stop="$emit('click-create')"
          >
            <Icon type="md-add" />
            {{ t('settings.common.createNew') }}
          </li>
        </ul>
        <div
          v-show="isLoading"
          class="ivu-select-loading"
        >
          {{ t('settings.common.loading') }}
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import { directive as clickOutside } from 'view3/src/directives/v-click-outside-x'
import { getStyle } from 'view3/src/utils/assist'
import throttle from 'view3/src/utils/throttle'
import { createPopper } from '@popperjs/core'
import localeMixin from 'application/scripts/locale_mixin'

const MAX_FILTER_ITEMS = 100
const REMOTE_SEARCH_THROTTLE_DURATION = 500

export default {
  name: 'SimpleSelect',
  directives: { clickOutside },
  mixins: [localeMixin],
  props: {
    modelValue: {
      type: [String, Number, Array, Boolean],
      reqired: false,
      default: ''
    },
    options: {
      type: Array,
      required: false,
      default: () => []
    },
    selectedOptions: {
      type: Array,
      required: false,
      default: () => []
    },
    selectedOption: {
      type: [Array, Object],
      required: false,
      default: null
    },
    size: {
      type: String,
      reqired: false,
      default: 'default'
    },
    icon: {
      type: String,
      reqired: false,
      default: null
    },
    filterable: {
      type: Boolean,
      required: false,
      default: false
    },
    multiple: {
      type: Boolean,
      required: false,
      default: false
    },
    allowCreate: {
      type: Boolean,
      required: false,
      default: false
    },
    withCreateButton: {
      type: Boolean,
      required: false,
      default: false
    },
    withDeselect: {
      type: Boolean,
      required: false,
      default: true
    },
    createFunction: {
      type: Function,
      required: false,
      default: (value) => {
        return Promise.resolve({ value, label: value })
      }
    },
    border: {
      type: Boolean,
      required: false,
      default: true
    },
    placeholder: {
      type: String,
      reqired: false,
      default: ''
    },
    labelKey: {
      type: [String, Number],
      reqired: false,
      default: 'label'
    },
    labelFunction: {
      type: Function,
      required: false,
      default: null
    },
    valueFunction: {
      type: Function,
      required: false,
      default: null
    },
    focusFirst: {
      type: Boolean,
      required: false,
      default: false
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false
    },
    optionComponent: {
      type: Object,
      required: false,
      default: null
    },
    valueKey: {
      type: [String, Number],
      reqired: false,
      default: 'value'
    },
    inputValue: {
      type: String,
      reqired: false,
      default: ''
    },
    remoteFunction: {
      type: Function,
      required: false,
      default: null
    }
  },
  emits: ['update:modelValue', 'update:selectedOptions', 'update:selectedOption', 'search', 'select', 'click-create'],
  // 保存选项、选中项、搜索值、焦点索引和下拉 Popper 状态。
  data () {
    return {
      isLoading: false,
      optionsData: [],
      optionRefs: [],
      popper: null,
      selectedOptionData: null,
      selectedOptionsData: [],
      focusIndex: -1,
      searchInput: this.inputValue,
      isOptionsLoaded: false,
      isOpen: false
    }
  },
  computed: {
    // 返回显示用 placeholder。
    displayPlaceholder () {
      return this.placeholder || this.t('settings.common.select')
    },
    // 对远程搜索函数做节流，减少输入过程中的请求量。
    remoteFunctionThrottled () {
      return throttle((query) => this.remoteFunction(query), REMOTE_SEARCH_THROTTLE_DURATION)
    },
    // 判断当前搜索词是否可以创建为新选项。
    displayCreate () {
      return this.searchInput && this.allowCreate && !this.optionsToRender.find((opt) => this.getValue(opt) === this.searchInput)
    },
    // 判断是否展示搜索输入。
    withFilter () {
      return this.remoteFunction || this.filterable || this.allowCreate
    },
    // 计算当前需要渲染的选项，支持本地过滤、远程搜索和单选已选项补位。
    optionsToRender () {
      if ((this.filterable || this.allowCreate) && !this.remoteFunction) {
        return this.filteredOptions.slice(0, MAX_FILTER_ITEMS)
      } else {
        if (this.remoteFunction && !this.multiple && this.selectedOptionData && this.searchInput === this.getLabel(this.selectedOptionData)) {
          const notSelectedOptions = this.optionsData.filter((option) => {
            return this.getValue(option) !== this.getValue(this.selectedOptionData)
          })

          return [this.selectedOption, ...notSelectedOptions]
        } else {
          return this.optionsData
        }
      }
    },
    // 本地过滤选项，远程搜索模式下由外部函数提供选项。
    filteredOptions () {
      if (this.remoteFunction) return []

      if (this.searchInput && this.searchInput !== this.getLabel(this.selectedOptionData)) {
        return this.optionsData.filter((option) => {
          return this.getLabel(option).toString().toLowerCase().includes(this.searchInput.toString().toLowerCase())
        })
      } else {
        return this.optionsData
      }
    },
    // 判断是否展示未找到状态。
    notFound () {
      return !this.allowCreate && this.withFilter && ((this.remoteFunction ? !!this.searchInput : true) && this.optionsToRender.length === 0)
    }
  },
  watch: {
    // 选项首次加载后按 v-model 反推已选项。
    isOptionsLoaded () {
      this.assignSelectedFromValue(this.modelValue)

      if (!this.multiple) {
        const label = this.getLabel(this.selectedOptionData)

        if (label) {
          this.searchInput = label
        }
      }
    },
    // 外部多选选项变化时同步内部副本。
    selectedOptions (value) {
      this.selectedOptionsData = [...value]
    },
    // 外部单选选项变化时同步内部副本和搜索框展示值。
    selectedOption (value) {
      this.selectedOptionData = value

      this.searchInput = this.getLabel(this.selectedOptionData)
    },
    // 选项数量变化时更新浮层位置。
    optionsToRender (newArray, oldArray) {
      if (newArray.length !== oldArray.length) {
        this.popper?.update()
      }
    },
    // v-model 变化时重新匹配选中项，远程单选模式会先拉取候选项。
    modelValue (value) {
      if (this.remoteFunction && !this.multiple) {
        if (this.searchInput !== this.getLabel(this.selectedOptionData)) {
          this.remoteFunction(this.searchInput || value).then(() => {
            this.assignSelectedFromValue(value)

            this.searchInput = this.getLabel(this.selectedOptionData)
          })
        } else {
          this.remoteFunction('')
        }
      } else {
        this.assignSelectedFromValue(value)

        this.searchInput = this.getLabel(this.selectedOptionData)
      }
    },
    options: {
      deep: true,
      // 外部 options 变化时归一化并重新匹配选中项。
      handler (value) {
        this.optionsData = this.normalizeOptions(value)

        if (!this.remoteFunction) {
          this.assignSelectedFromValue(this.modelValue)
        }

        if (this.optionsData.length) {
          this.isOptionsLoaded = true
        }
      }
    },
    // 下拉打开时同步最小宽度，避免浮层比输入框窄。
    isOpen (value) {
      if (value) {
        this.$refs.dropdown.style.minWidth = getStyle(this.$el, 'width')
      }
    }
  },
  // 初始化远程或本地选项，并根据 v-model 反推初始选中项。
  mounted () {
    if (this.remoteFunction) {
      this.remoteFunction(this.multiple ? this.searchInput : '')

      if (!this.multiple) {
        this.selectedOptionData = this.selectedOption
        this.searchInput = this.getLabel(this.selectedOptionData) || this.modelValue
      }
    } else {
      this.optionsData = this.normalizeOptions(this.options)

      if (this.multiple) {
        this.selectedOptionsData = [...this.selectedOptions]

        if (!this.options.length && this.allowCreate) {
          this.optionsData = [...this.normalizeOptions(this.modelValue)]
        }

        this.assignSelectedFromValue(this.modelValue)
      } else {
        this.selectedOptionData = this.selectedOption
        this.assignSelectedFromValue(this.modelValue)

        this.searchInput = this.getLabel(this.selectedOptionData) || this.modelValue
      }
    }
  },
  // 销毁 Popper 实例。
  beforeUnmount () {
    this.popper?.destroy()
  },
  // 每次更新前重置选项 DOM 引用列表。
  beforeUpdate () {
    this.optionRefs = []
  },
  methods: {
    // 收集选项 DOM 引用，用于键盘导航滚动。
    setOptionRef (el) {
      if (el) {
        this.optionRefs.push(el)
      }
    },
    // 调用创建函数生成新选项并立即选中。
    createOption (value) {
      this.createFunction(value).then((option) => {
        this.optionsData.unshift(option)
        this.selectOption(option)
      })
    },
    // Tab 键应用当前焦点项或创建项。
    onTabKey () {
      if (this.displayCreate && this.focusIndex === 0) {
        this.createOption(this.searchInput)
      } else {
        const label = this.getLabel(this.optionsToRender[this.focusIndex])

        if (label) {
          this.searchInput = label
          this.onSearch()
        }
      }
    },
    // 把基础类型选项归一化为 { value, label } 对象。
    normalizeOptions (options) {
      if (!options?.length) {
        return []
      } else if (['string', 'number', 'boolean'].includes(typeof options[0])) {
        return options.map(option => {
          return { value: option, label: option.toString() }
        })
      } else {
        return [...options]
      }
    },
    // 读取选项显示标签，支持外部 labelFunction。
    getLabel (option) {
      if (option) {
        return this.labelFunction ? this.labelFunction(option) : (option[this.labelKey] ?? '')
      } else {
        return ''
      }
    },
    // 读取选项值，支持外部 valueFunction。
    getValue (option) {
      if (option) {
        return this.valueFunction ? this.valueFunction(option) : (option[this.valueKey] ?? '')
      } else {
        return ''
      }
    },
    // 处理搜索输入，触发远程搜索、打开下拉并更新焦点。
    onSearch () {
      this.remoteFunction && this.remoteFunctionThrottled(this.searchInput)
      const index = this.optionsToRender.indexOf(this.selectedOptionData)
      this.focusIndex = index === -1 ? 0 : index
      this.isOpen = true
      this.popper?.update()
      this.$emit('search', this.searchInput)
    },
    // 按键盘方向移动焦点，首尾循环并滚动到可见区域。
    moveFocus: throttle(function (index) {
      const maxLength = this.displayCreate || this.withCreateButton ? (this.optionsToRender.length + 1) : this.optionsToRender.length
      const nextIndex = this.focusIndex + index
      if (nextIndex >= maxLength) {
        this.focusIndex = 0
      } else if (nextIndex < 0) {
        this.focusIndex = maxLength - 1
      } else {
        this.focusIndex += index
      }

      this.$nextTick(() => {
        this.optionRefs[this.focusIndex]?.scrollIntoView({ block: 'nearest' })
      })
    }, 80),
    // 应用当前焦点项：创建、触发创建按钮或选中候选项。
    applyFocused () {
      if (this.displayCreate && this.focusIndex === 0) {
        this.createOption(this.searchInput)

        this.toggleDropdown()
      } else if (this.withCreateButton && this.focusIndex === this.optionsToRender.length) {
        this.$emit('click-create')
      } else {
        const index = this.displayCreate ? this.focusIndex + 1 : this.focusIndex
        const option = this.optionsToRender[index]

        if (option) {
          this.selectOption(option)
        }
      }
    },
    // 根据 v-model 值反向匹配内部选中对象。
    assignSelectedFromValue (value) {
      if (this.multiple) {
        if (value) {
          this.selectedOptionsData = value.map((val) => {
            return this.selectedOptionsData.find((option) => this.getValue(option).toString() === (val ?? '').toString()) ||
              this.optionsData.find((option) => this.getValue(option).toString() === (val ?? '').toString())
          })
        }
      } else {
        if (this.getValue(this.selectedOption).toString() === (value ?? '').toString()) {
          this.selectedOptionData = this.selectedOption
        } else {
          this.selectedOptionData = this.optionsData.find((option) => this.getValue(option).toString() === (value ?? '').toString())
        }

        const index = this.optionsToRender.indexOf(this.selectedOptionData)

        this.focusIndex = this.focusFirst && index === -1 ? 0 : index

        this.$emit('update:selectedOption', this.selectedOptionData)
      }
    },
    // 判断给定选项是否处于选中状态。
    isSelected (option) {
      const hasSelected = this.getValue(option) && (this.selectedOptionData || this.selectedOptionsData.length)

      if (hasSelected) {
        return (this.multiple ? this.selectedOptionsData : [this.selectedOptionData]).find((opt) => this.getValue(opt) === this.getValue(option))
      } else {
        return false
      }
    },
    // 清空单选值并同步给父组件。
    deselect () {
      this.selectedOptionData = null
      this.searchInput = ''
      this.$emit('update:modelValue', '')
      this.$emit('update:selectedOption', null)
      this.$emit('select', null)
    },
    // 选中或取消选中选项，并按单选/多选模式同步事件。
    selectOption (option) {
      if (this.multiple) {
        const existingOption = this.selectedOptionsData.find((opt) => this.getValue(opt) === this.getValue(option))

        if (existingOption) {
          this.selectedOptionsData.splice(this.selectedOptionsData.indexOf(existingOption), 1)
        } else {
          this.selectedOptionsData.push(option)
        }

        this.searchInput = ''

        if (this.remoteFunction) {
          this.remoteFunction(this.searchInput)
        }

        this.$emit('update:selectedOptions', this.selectedOptionsData)
        this.$emit('update:modelValue', this.selectedOptionsData.map(this.getValue))
        this.$emit('select', this.selectedOptionsData)

        this.focusIndex = this.optionsToRender.indexOf(option)

        this.popper?.update()
        this.$refs.input?.focus()
      } else {
        this.selectedOptionData = option
        this.searchInput = this.getLabel(option)
        this.focusIndex = this.optionsToRender.indexOf(option)
        this.$emit('update:modelValue', this.getValue(option))
        this.$emit('update:selectedOption', option)
        this.$emit('select', option)

        this.closeDropdown()
      }
    },
    // 拖拽排序后同步多选值。
    onOptionMove () {
      this.$emit('update:modelValue', this.selectedOptionsData.map(this.getValue))
      this.$emit('update:selectedOptions', this.selectedOptionsData)
    },
    // 从多选已选列表中移除指定选项。
    removeOption (option) {
      this.selectedOptionsData.splice(this.selectedOptionsData.indexOf(option), 1)

      this.$emit('update:modelValue', this.selectedOptionsData.map(this.getValue))
      this.$emit('update:selectedOptions', this.selectedOptionsData)
    },
    // 搜索框为空时 Backspace 移除最后一个多选项。
    maybeRemoveOption () {
      if (this.multiple && this.searchInput === '') {
        this.removeOption(this.selectedOptions[this.selectedOptionsData.length - 1])
      }
    },
    // 关闭下拉并恢复单选展示文本。
    closeDropdown () {
      this.isOpen = false

      if (this.selectedOptionData) {
        this.searchInput = this.getLabel(this.selectedOptionData)
      }

      this.$nextTick(() => {
        this.optionRefs[0]?.scrollIntoView({ block: 'nearest' })
      })
    },
    // 切换下拉显示状态，并按需创建 Popper 实例。
    toggleDropdown () {
      if (!this.disabled) {
        this.isOpen = !this.isOpen

        this.popper ||= createPopper(this.$el, this.$refs.dropdown, {
          placement: 'bottom-start',
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
        this.$refs.input?.focus()
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.ivu-select-custom-icon {
  color: #808695;
  font-size: 14px;
  line-height: 1;
  position: absolute;
  right: 8px;
  top: calc(50% - 7px);
}

.ivu-select-no-border {
  position: relative;
  height: 40px;
}

.ivu-select-input {
  cursor: initial;
}
</style>

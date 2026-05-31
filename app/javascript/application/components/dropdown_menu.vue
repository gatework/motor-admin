<template>
  <ul class="ivu-dropdown-menu">
    <slot />
  </ul>
</template>

<script>
// 下拉菜单容器组件，只负责渲染菜单内容 slot。
export default {
  name: 'DropdownMenu'
}
</script>

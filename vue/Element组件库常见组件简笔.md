# Element组件库常见组件简笔

## el-menu 与 vue router

### main.js

```js
import {createApp} from 'vue'
import App from './App.vue'
import ElementPlus from "element-plus"
import "element-plus/dist/index.css"
import {createRouter, createWebHistory} from "vue-router"
// 引入自定义routes路由信息
import routes from "./router/router";

const app = createApp(App)

// 创建router对象
const router = createRouter({
    // 选择histroy模式
    history: createWebHistory(),
    // 初始化路由信息
    routes
})

// 加载插件
app.use(router)
app.use(ElementPlus)
app.mount('#app')
```

### router.js

```js
import Home from "../components/Home";
import NotFound from "../components/NotFound";
import StudentManager from "../components/StudentManager";
import TeacherManager from "../components/TeacherManager";
import CookManager from "../components/CookManager";
import SportsEquipmentManager from "../components/SportsEquipmentManager";
import CanteenEquipmentManager from "../components/CanteenEquipmentManager";

const routes = [
    {
        path: "/",
        component: Home,
        children: [
            {
                path: "1-1",
                component: StudentManager
            },
            {
                path: "1-2",
                component: TeacherManager
            },
            {
                path: "1-3",
                component: CookManager
            },
            {
                path: "2",
                component: SportsEquipmentManager
            },
            {
                path: "3",
                component: CanteenEquipmentManager
            },
        ]
    },
    {
        // 匹配所有路径, 必须放到最后, 当前面的所有路径都没有匹配的时候, 就会匹配这个路由
        path: "/:pathMatch(.*)*",
        component: NotFound
    }
]

export default routes
```

### Home.vue

```html
<template>
  <el-aside>
      <!-- 开启menu-item router-link功能, 根据index跳转路由 -->
    <el-menu router="true">
      <template v-for="menu in menus">
        <el-sub-menu v-if="menu.children" :index="menu.path" :key="menu.path">
          <template #title>{{ menu.title }}</template>
          <div v-for="menuItem in menu.children">
            <el-menu-item :index="menuItem.path" :key="menu.path">{{ menuItem.title }}</el-menu-item>
          </div>
        </el-sub-menu>
        <el-menu-item v-if="!menu.children" :index="menu.path" :key="menu.path">{{ menu.title }}</el-menu-item>
      </template>
    </el-menu>
  </el-aside>
  <el-main>
    <router-view></router-view>
    <!--    <h1>{{ $route.params }}</h1>
        <h1>{{ $route.query }}</h1>-->
  </el-main>
</template>

<script>
export default {
  name: "Home",
  data() {
    return {
      menus: [
        {
          path: "1",
          title: "人员管理",
          children: [
            {
              path: "1-1",
              title: "学生管理",
            },
            {
              path: "1-2",
              title: "教师管理",
            },
            {
              path: "1-3",
              title: "厨师管理",
            }
          ]
        },
        {
          path: "2",
          title: "体育器材管理",
        },
        {
          path: "3",
          title: "食堂食材管理",
        }
      ]
    }
  }
}
</script>

<style scoped>

</style>
```
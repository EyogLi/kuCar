# kuCar 3D — 汽车模型说明

## 当前模型

目前使用 Khronos Group 的 **CarConcept** 模型作为占位：
- 来源: KhronosGroup/glTF-Sample-Assets (CC0 许可)
- 大小: ~12MB
- 格式: GLB (glTF Binary)
- 特点: PBR材质、可分离车身/轮毂

## 如何添加真实车型

### 1. 获取 3D 模型

购买或下载真实车型 GLB/GLTF 文件（必须是 GLB 或 GLTF 格式）：

| 平台 | 价格 | 推荐指数 |
|------|------|----------|
| [Hum3D](https://hum3d.com/3d-models/car/) | $50-150/辆 | ⭐⭐⭐⭐⭐ 最逼真 |
| [88Cars3D](https://88cars3d.com/) | $15-60/辆 | ⭐⭐⭐⭐ 选择多 |
| [CGTrader](https://www.cgtrader.com/3d-models/car) | $5-60/辆 | ⭐⭐⭐ 性价比高 |
| [Sketchfab](https://sketchfab.com/search?q=car&type=models&downloadable=true) | $10-80/辆 | ⭐⭐⭐ 社区活跃 |

**推荐首批购买（覆盖主流车型类型）**：
| 车型 | 类型 | 预估大小 |
|------|------|----------|
| BMW M3 Competition | 性能轿车 | 15-25MB |
| Porsche 911 Turbo S | 跑车 | 12-20MB |
| Mercedes-Benz S-Class | 豪华轿车 | 18-28MB |
| Tesla Model S Plaid | 电动轿车 | 12-18MB |
| Toyota GR Supra | 跑车 | 12-20MB |
| Honda Civic Type R | 掀背车 | 12-18MB |
| Toyota RAV4 | SUV | 18-28MB |
| Audi e-tron GT | 电动跑车 | 15-22MB |

### 2. 模型要求

每个 GLB 模型必须满足：
- ✅ 格式: `.glb` (推荐) 或 `.gltf`
- ✅ 车身和轮毂是**独立 mesh**（不同节点名称）
- ✅ 包含 UV 贴图坐标（用于 PBR 渲染）
- ✅ 文件大小: < 30MB（太大影响加载速度）
- ✅ 不含动画（静态模型即可）

### 3. 放置模型文件

将 `.glb` 文件放入此目录，命名规范：`品牌_型号.glb`

例如：
```
models/
  BMW_M3.glb
  Porsche_911_Turbo.glb
  Mercedes_S_Class.glb
  Tesla_Model_S.glb
  Toyota_GR_Supra.glb
```

### 4. 配置模型信息

编辑 `../www/index.html` 中的 `carModels` 数组，为每个模型添加条目：

```javascript
{
  id: 'bmw_m3',
  make: 'BMW',
  model: 'M3 Competition',
  year: 2024,
  style: '性能轿车',
  url: './models/BMW_M3.glb',
  scale: 1.0,
  // 车身/轮毂的节点名称（用于自动检测）
  bodyNames: ['body', 'Body', 'car_body', 'bodyshell'],
  wheelNames: ['wheel', 'Wheel', 'rim', 'Rim'],
  glassNames: ['glass', 'Glass', 'window', 'Window'],
  offset: [0, 0, 0],
},
```

### 5. 节点名称匹配

如果模型加载后颜色/轮毂更换不生效，需要在浏览器中检查模型结构：

1. 打开网页版 `https://eyogli.github.io/kuCar/`
2. 按 F12 打开开发者工具
3. 在 Console 中输入：`console.log(allNodes)` 查看所有节点名称
4. 更新 `bodyNames` / `wheelNames` / `glassNames` 以匹配实际的节点名称

系统会自动：
- 按名称匹配车身/轮毂/玻璃 mesh
- 如果未匹配到，自动将最大 mesh 作为车身
- 修改 `bodyNames` 数组可以添加更多匹配规则

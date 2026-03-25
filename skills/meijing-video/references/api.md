# 美境 API 详细参考

## 1. IP图片生成 API

### POST `/api/aidesign/sd/create`

#### 请求体

```json
{
  "type": 101,
  "styleId": 30001,
  "modelVersion": "flux",
  "modelPath": "Flux/flux1-dev.safetensors",
  "lora": [],
  "prompt": "画面描述文字",
  "promptReinforce": true,
  "referenceImages": {
    "variants": 0.6,
    "images": [],
    "mode": "union"
  },
  "sampler": "euler",
  "strength": "3.5",
  "seed": -1,
  "width": "1344",
  "height": "768",
  "batchSize": 4,
  "context": {
    "ratio": "16:9",
    "styleActive": 0
  }
}
```

#### 关键字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| type | number | 101=IP图片生成 |
| styleId | number | 30001=三维袋鼠IP, 30002=插画袋鼠IP |
| modelVersion | string | "flux" |
| prompt | string | 画面描述，不需要写"袋鼠"（LoRA自动融合） |
| promptReinforce | boolean | true=启用prompt增强 |
| width/height | string | 常用比例：1:1(1024×1024), 4:3(1088×832), 3:4(832×1088), 9:16(768×1344), 16:9(1344×768) |
| batchSize | number | 每次生成图片数量，通常4 |
| seed | number | -1=随机 |
| referenceImages.images | array | 参考图URL数组（可选） |

#### 响应

```json
{
  "code": 0,
  "result": 19156054,
  "message": null
}
```

`result` 为任务ID。

---

## 2. AI视频生成 API

### POST `/api/aidesign/ai/generate`

#### 请求体

```json
{
  "promptReinforce": true,
  "sampler": "euler",
  "seed": -1,
  "strength": "3.5",
  "batchSize": 1,
  "type": 503,
  "prompt": "画面运动描述",
  "aspectRatio": "原图比例",
  "referenceImages": {
    "images": ["首帧URL", "尾帧URL"]
  },
  "width": 1344,
  "height": 768,
  "videoLength": 5,
  "context": {
    "input": "{JSON字符串，包含videoList等详细信息}"
  }
}
```

#### 关键字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| type | number | 503=即梦视频3.0 |
| prompt | string | 描述画面如何从首帧过渡到尾帧 |
| referenceImages.images | array | [首帧URL, 尾帧URL]，仅首帧时只传1个 |
| videoLength | number | 视频时长，5秒 |
| width/height | number | 注意这里是number不是string |
| context.input | string | JSON字符串，包含videoList详细配置 |

#### context.input 中的 videoList 项结构

```json
{
  "id": "唯一ID",
  "preview": "图片URL",
  "uploadType": "image",
  "flag": true,
  "loadProcess": 100,
  "url": "图片URL",
  "file": {},
  "frameType": "start 或 end",
  "ratio": 1.75,
  "width": 1344,
  "height": 768,
  "isSucceed": true
}
```

#### 响应

```json
{
  "code": 0,
  "message": null,
  "data": 19162110,
  "success": true
}
```

`data` 为任务ID。

---

## 3. IP图片历史查询 API

### GET `/api/aidesign/sd/create/history`

#### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| page | number | 页码，从1开始 |
| pageSize | number | 每页数量 |
| endTime | number | 截止时间戳（毫秒） |
| type | number | 101=IP图片 |

#### 响应

```json
{
  "code": 0,
  "result": {
    "total": 127,
    "results": [
      {
        "type": 101,
        "id": 19156054,
        "inputs": { "prompt": "..." },
        "status": 3,
        "images": ["https://p0.meituan.net/aigchub/xxx.png", ...],
        "promptEn": "翻译后的英文prompt",
        "addTime": 1773496477000,
        "creatorMis": "yinjuechen"
      }
    ]
  }
}
```

#### status 值

| 值 | 含义 |
|----|------|
| 1 | 排队中 |
| 2 | 生成中 |
| 3 | 已完成 |
| 4 | 失败 |

---

## 4. AI视频历史查询 API

### POST `/api/aidesign/ai/generate/history`

#### 请求体

```json
{
  "page": 1,
  "pageSize": 10,
  "endTime": 1773496009353,
  "typeList": [503]
}
```

#### typeList 常用值

| 值 | 含义 |
|----|------|
| 503 | 即梦视频3.0 |
| 501 | 其他视频模型 |
| 602 | QWEN_IMAGE_TURBO |
| 106 | SEEDREAM5 |
| 105 | SEEDREAM |
| 104 | SEEDREAM4 |
| 102 | SEEDREAM3 |

#### 响应

```json
{
  "code": 0,
  "data": {
    "list": [
      {
        "id": 19162110,
        "status": 3,
        "videoUrl": "https://...",
        "videoPreviewUrl": "https://...",
        "images": ["https://..."],
        "prompt": "..."
      }
    ]
  }
}
```

---

## 5. 图片URL格式

生成的图片托管在美团CDN：
```
https://p0.meituan.net/aigchub/{hash}{filesize}.png
https://p1.meituan.net/aigchub/{hash}{filesize}.png
```

这些URL可直接用作视频生成的首帧/尾帧参考图。

## 6. 图片上传

页面上传图片后，文件会被上传到：
```
https://s3plus.sankuai.com/v1/mss_fad1a48f61e8451b8172ba5abfdbbee5/aigc-warehouse/{uuid}_{hash}.png
```

但实际测试发现 aigchub CDN URL 也可以直接用于视频生成的 referenceImages，无需额外上传。

# feed

[![CI](https://github.com/turinglambdaai/feed/actions/workflows/ci.yml/badge.svg)](https://github.com/turinglambdaai/feed/actions/workflows/ci.yml)

Racket 的 RSS 2.0 与 Atom 解析库。纯函数：字节进、条目出——抓取、HTML 清洗、去重策略都留给调用者。

## 安装

```
raco pkg install feed
```

## 使用

```racket
(require feed)

(define items
  (parse-feed (fetch-bytes "https://example.com/feed.xml")))

(for ([it items])
  (displayln (feed-item-title it))
  (displayln (feed-item-link it)))      ; 无链接时为 #f
  (displayln (feed-item-published it))) ; UTC 秒或 #f
```

- `parse-feed` 自动嗅探 RSS 2.0 / Atom 并分发；已知格式可直接用 `parse-rss` / `parse-atom`
- summary 原样输出（通常内嵌 HTML——按自己的策略清洗）；`content:encoded` / `dc:date` / `<updated>` 等回退字段已处理
- 畸形字节返回 `'()`，绝不抛异常
- `#:max-entries` 防御病态大源
- `xexpr-*` 工具（CDATA 包装剥离、命名空间后缀标签匹配）一并导出——这是每个 feed 解析器都要重写的部分
- `parse-date-any` / `parse-8601` / `parse-rfc822` 把 feed 时间戳转成 UTC 秒

## 开发

```
raco pkg install --auto --link .
raco test tests
raco setup --check-pkg-deps -l feed
```

## 许可

[MIT](LICENSE)

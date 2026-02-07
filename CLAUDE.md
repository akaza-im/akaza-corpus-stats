# CLAUDE.md

## Project Overview

Akaza (日本語かな漢字変換エンジン) 用の n-gram 統計データを生成するパイプライン。
日本語 Wikipedia (CirrusSearch ダンプ) と青空文庫をトーカナイズし、unigram/bigram の wordcnt trie と語彙ファイルを生成する。

生成物は [akaza-default-model](https://github.com/akaza-im/akaza-default-model) の `learn-corpus` で使用される。

## Build Commands

```bash
# 前提: akaza-data のインストール
cargo install --git https://github.com/akaza-im/akaza.git akaza-data

# git submodule の初期化
git submodule update --init

# フルビルド
make

# dist/ に成果物を出力
make dist
```

## Pipeline

```
Wikipedia CirrusSearch (.json.gz)
    → extract-cirrus.py → extracted/ (<doc> 形式)
    → akaza-data tokenize → jawiki/vibrato-ipadic/

青空文庫 (aozorabunko_text submodule)
    → akaza-data tokenize → aozora_bunko/vibrato-ipadic/

振り分け結果
    → akaza-data wfreq → vibrato-ipadic.wfreq (corpus 抜き)
    → akaza-data vocab → vibrato-ipadic.vocab
    → akaza-data wordcnt-unigram → unigram.wordcnt.trie
    → akaza-data wordcnt-bigram → bigram.wordcnt.trie
```

wfreq の計算に corpus/ は含めない（akaza-default-model 側の corpus 変更で再ビルド不要にするため）。

## Key Files

- `Makefile` — ビルドパイプライン
- `scripts/extract-cirrus.py` — CirrusSearch NDJSON → `<doc>` 形式変換
- `mecab-user-dict.csv` — Vibrato ユーザー辞書（akaza-default-model と同期）
- `NOTICE` — 生成データのライセンス情報（配布 tarball に同梱）

## Release

CalVer (`YYYY.MMDD.PATCH`)。`v*` タグ push で GitHub Actions が tarball を Release に添付。

```bash
git tag v2026.0207.0
git push origin v2026.0207.0
```

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Akaza (日本語かな漢字変換エンジン) 用の n-gram 統計データを生成するパイプライン。
日本語 Wikipedia (CirrusSearch ダンプ)、青空文庫、CC-100 Japanese をトーカナイズし、unigram/bigram の wordcnt trie と語彙ファイルを生成する。

生成物は [akaza-default-model](https://github.com/akaza-im/akaza-default-model) の `learn-corpus` で使用される。

## Build Commands

```bash
# 前提: akaza-data のインストール (AKAZA_REV でハッシュ固定)
make install-akaza-data

# git submodule の初期化 (青空文庫テキスト)
git submodule update --init

# ビルド (jawiki + 青空文庫のみ)
make

# CC-100 込みビルド
make all-full

# 配布用成果物の生成
make dist        # dist/ (jawiki + 青空文庫)
make dist-full   # dist-full/ (jawiki + 青空文庫 + CC-100)

# リリース (CalVer タグ + GitHub Release に両 tarball をアップロード)
make release

# クリーンアップ
make clean             # dist/ dist-full/ を削除
make clean-tokenized   # tokenize 以降の中間ファイルを削除 (抽出結果は残す)
```

### Makefile 変数

- `AKAZA_REV`: akaza リポジトリのコミットハッシュ (`make install-akaza-data` で使用)
- `CIRRUS_DATE`: Wikipedia ダンプの日付 (デフォルト: `20251229`)
- `CC100_LIMIT`: CC-100 の処理文書数上限 (デフォルト: `5000000`、`0` で無制限)
- `TOKENIZER_OPTS`: `akaza-data tokenize` への追加オプション

## Pipeline

```
Wikipedia CirrusSearch (.json.gz)
    → extract-cirrus.py → work/jawiki/extracted/ (<doc> 形式)
    → akaza-data tokenize → work/jawiki/vibrato-ipadic/

青空文庫 (aozorabunko_text submodule)
    → akaza-data tokenize → work/aozora_bunko/vibrato-ipadic/

CC-100 Japanese (ja.txt.xz)
    → extract-cc100.py (フィルタ付き) → work/cc100/extracted/ (<doc> 形式)
    → akaza-data tokenize → work/cc100/vibrato-ipadic/

統計生成 (2 バリアント):
    jawiki + aozora       → wfreq → vocab / unigram.trie / bigram.trie → dist/
    jawiki + aozora + cc100 → *-full.wfreq → *-full.vocab / *-full.trie → dist-full/
```

## 配布物の分離

| バリアント | コーパス | ターゲット |
|---|---|---|
| `dist/` (デフォルト) | jawiki + 青空文庫 | `make dist` |
| `dist-full/` | jawiki + 青空文庫 + CC-100 | `make dist-full` |

`dist-full/` 内のファイル名は `dist/` と同一 (接尾辞なし) のため、利用側での差し替えが容易。
`make release` は `akaza-corpus-stats.tar.gz` と `akaza-corpus-stats-full.tar.gz` の両方を GitHub Release にアップロードする。

## Key Files

- `Makefile` — ビルドパイプライン全体の定義
- `scripts/extract-cirrus.py` — CirrusSearch NDJSON → `<doc>` 形式変換
- `scripts/extract-cc100.py` — CC-100 ja.txt.xz → `<doc>` 形式変換 (品質フィルタ付き)
- `mecab-user-dict.csv` — Vibrato ユーザー辞書（akaza-default-model と同期）
- `NOTICE` — 生成データのライセンス情報（配布 tarball に同梱）
- `docs/cc100-cleaning-strategy.md` — CC-100 クリーニング方針の詳細

## CC-100 フィルタ

`scripts/extract-cc100.py` は文書単位で以下のフィルタを適用する:
1. 最小文書長 (200 文字未満を除外)
2. ひらがな比率 (10% 未満を除外)
3. 行の繰り返し (30% 以上重複行で除外)
4. 制御文字・私用領域・Specials 文字の除去 (行レベル)

`--no-filter` で全フィルタを無効化可能。詳細は `docs/cc100-cleaning-strategy.md` を参照。

## 抽出スクリプトの共通パターン

両 extract スクリプトは wikiextractor 互換の `<doc>` 形式を出力する:
- 出力ディレクトリ構造: `OUTPUT_DIR/AA/wiki_00`, `AA/wiki_01`, ..., `AB/wiki_00`, ...
- 1 ファイルあたり 1000 文書、サブディレクトリあたり 100 ファイル
- `akaza-data tokenize --reader=jawiki` でそのまま消費可能

## Release

CalVer (`YYYY.MMDD.PATCH`)。ローカルビルド + `gh` CLI でリリース。
同日に複数回実行すると PATCH が自動インクリメントされる。

wfreq の計算に corpus/ は含めない（akaza-default-model 側の corpus 変更で再ビルド不要にするため）。

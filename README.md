# akaza-corpus-stats

[Akaza](https://github.com/akaza-im/akaza) (Japanese kana-kanji conversion engine) 用の n-gram 統計データを生成するパイプラインです。

日本語 Wikipedia および青空文庫のテキストをトーカナイズし、unigram/bigram の wordcnt trie と語彙ファイルを生成します。
生成物は [akaza-default-model](https://github.com/akaza-im/akaza-default-model) で `learn-corpus` の入力として使用されます。

## 生成物

| ファイル | 内容 | サイズ目安 |
|---|---|---|
| `dist/stats-vibrato-unigram.wordcnt.trie` | Unigram wordcnt (marisa-trie) | ~6MB |
| `dist/stats-vibrato-bigram.wordcnt.trie` | Bigram wordcnt (marisa-trie) | ~25MB |
| `dist/vibrato-ipadic.vocab` | 語彙リスト (頻度閾値=16) | ~12MB |

## ビルド

### 前提

- `akaza-data` (Rust): `cargo install --git https://github.com/akaza-im/akaza.git akaza-data`
- `wget`, `unzip`, `zstd`
- Python 3 (標準ライブラリのみ使用)
- git submodule の初期化: `git submodule update --init`

### 実行

```bash
make          # フルビルド (初回は Wikipedia ダンプのダウンロードに時間がかかる)
make dist     # dist/ に成果物を出力
```

## データソース

### Japanese Wikipedia (CirrusSearch dump)

- URL: `https://dumps.wikimedia.org/other/cirrussearch/`
- 形式: gzip 圧縮 NDJSON (テンプレート展開済みプレーンテキスト)
- `scripts/extract-cirrus.py` でストリーミング展開

### 青空文庫

- git submodule `aozorabunko_text` で取得
- 著作権の消滅した日本語文学作品のテキストアーカイブ

## ライセンス

### スクリプト・設定ファイル

このリポジトリ内のスクリプトおよび設定ファイル (`scripts/`, `Makefile`, `mecab-user-dict.csv` 等) は MIT License で提供されます。詳細は [LICENSE](LICENSE) を参照してください。

### 生成データ

生成される統計データ (wordcnt trie, vocab) は以下のデータソースに由来する派生物です。

- **Japanese Wikipedia**: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) (Wikimedia Foundation)
- **青空文庫**: パブリックドメイン (著作権の消滅した作品)

Wikipedia 由来のデータを含むため、生成物の再配布には CC BY-SA 4.0 の条件が適用されます。

### 使用する外部ツール・辞書

- **Vibrato** (MeCab 互換トーカナイザー): 辞書データは Apache-2.0 / BSD ライセンス (IPADIC)
- **akaza-data**: MIT License

## リリース

CalVer (`YYYY.MMDD.PATCH`) 形式。GitHub Actions の **Actions → Create release tag → Run workflow** を実行すると、CalVer タグが自動生成・push され、ビルド → Release への tarball 添付まで自動で行われます。

同日に複数回実行すると PATCH が自動インクリメントされます (`v2026.0207.0` → `v2026.0207.1` → ...)。

手動でタグを打つ場合:

```bash
git tag v2026.0207.0
git push origin v2026.0207.0
```

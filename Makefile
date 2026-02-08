CIRRUS_DATE ?= 20251229
TOKENIZER_OPTS ?=

all: work/stats-vibrato-bigram.wordcnt.trie work/vibrato-ipadic.vocab

# =========================================================================
#  dist: 配布用 tarball の作成
# =========================================================================

dist: all
	mkdir -p dist/
	cp work/stats-vibrato-unigram.wordcnt.trie dist/
	cp work/stats-vibrato-bigram.wordcnt.trie dist/
	cp work/vibrato-ipadic.vocab dist/
	cp NOTICE dist/

# =========================================================================
#  release: CalVer タグ作成 + GitHub Release にアップロード
# =========================================================================

release: dist
	@PREFIX="v$$(date +%Y.%m%d)"; \
	EXISTING=$$(git tag -l "$${PREFIX}.*" | sort -t. -k3 -n | tail -1); \
	if [ -z "$$EXISTING" ]; then \
		TAG="$${PREFIX}.0"; \
	else \
		PATCH=$$(echo "$$EXISTING" | rev | cut -d. -f1 | rev); \
		TAG="$${PREFIX}.$$((PATCH + 1))"; \
	fi; \
	echo "Creating release $$TAG ..."; \
	tar czvf akaza-corpus-stats.tar.gz -C dist . && \
	git tag "$$TAG" && \
	git push origin "$$TAG" && \
	gh release create "$$TAG" akaza-corpus-stats.tar.gz \
		--title "$$TAG" --generate-notes && \
	rm -f akaza-corpus-stats.tar.gz && \
	echo "Released $$TAG"

# =========================================================================
#  Wikipedia (CirrusSearch ダンプ)
# =========================================================================

work/jawiki/jawiki-cirrussearch-content.json.gz:
	mkdir -p work/jawiki/
	wget --show-progress --no-clobber -O work/jawiki/jawiki-cirrussearch-content.json.gz \
		https://dumps.wikimedia.org/other/cirrussearch/$(CIRRUS_DATE)/jawiki-$(CIRRUS_DATE)-cirrussearch-content.json.gz

work/jawiki/extracted/_SUCCESS: work/jawiki/jawiki-cirrussearch-content.json.gz
	python3 scripts/extract-cirrus.py work/jawiki/jawiki-cirrussearch-content.json.gz work/jawiki/extracted/
	touch work/jawiki/extracted/_SUCCESS

# =========================================================================
#  Vibrato 辞書
# =========================================================================

work/vibrato/ipadic-mecab-2_7_0.tar.xz:
	mkdir -p work/vibrato/
	wget --show-progress --no-clobber -O work/vibrato/ipadic-mecab-2_7_0.tar.xz \
		https://github.com/daac-tools/vibrato/releases/download/v0.5.0/ipadic-mecab-2_7_0.tar.xz

work/vibrato/ipadic-mecab-2_7_0/system.dic: work/vibrato/ipadic-mecab-2_7_0.tar.xz
	mkdir -p work/vibrato/
	tar -xmJf work/vibrato/ipadic-mecab-2_7_0.tar.xz -C work/vibrato/
	zstd -d work/vibrato/ipadic-mecab-2_7_0/system.dic.zst -o work/vibrato/ipadic-mecab-2_7_0/system.dic

# =========================================================================
#  トーカナイズ
# =========================================================================

work/jawiki/vibrato-ipadic/_SUCCESS: mecab-user-dict.csv work/jawiki/extracted/_SUCCESS work/vibrato/ipadic-mecab-2_7_0/system.dic
	akaza-data tokenize \
		--reader=jawiki \
		--user-dict=mecab-user-dict.csv \
		--system-dict=work/vibrato/ipadic-mecab-2_7_0/system.dic \
		$(TOKENIZER_OPTS) \
		work/jawiki/extracted \
		work/jawiki/vibrato-ipadic/ \
		-vvv

work/aozora_bunko/vibrato-ipadic/_SUCCESS: work/vibrato/ipadic-mecab-2_7_0/system.dic
	akaza-data tokenize \
		--reader=aozora_bunko \
		--user-dict=mecab-user-dict.csv \
		--system-dict=work/vibrato/ipadic-mecab-2_7_0/system.dic \
		aozorabunko_text/cards/ \
		work/aozora_bunko/vibrato-ipadic/ -vv

# =========================================================================
#  統計データ生成
# =========================================================================

work/vibrato-ipadic.wfreq: work/jawiki/vibrato-ipadic/_SUCCESS work/aozora_bunko/vibrato-ipadic/_SUCCESS
	akaza-data wfreq \
		--src-dir=work/jawiki/vibrato-ipadic/ \
		--src-dir=work/aozora_bunko/vibrato-ipadic/ \
		work/vibrato-ipadic.wfreq -vvv

work/vibrato-ipadic.vocab: work/vibrato-ipadic.wfreq
	akaza-data vocab --threshold 16 work/vibrato-ipadic.wfreq work/vibrato-ipadic.vocab -vvv

work/stats-vibrato-unigram.wordcnt.trie: work/vibrato-ipadic.wfreq
	akaza-data wordcnt-unigram \
		work/vibrato-ipadic.wfreq \
		work/stats-vibrato-unigram.wordcnt.trie

work/stats-vibrato-bigram.wordcnt.trie: work/stats-vibrato-unigram.wordcnt.trie work/jawiki/vibrato-ipadic/_SUCCESS work/aozora_bunko/vibrato-ipadic/_SUCCESS
	mkdir -p work/dump/
	akaza-data wordcnt-bigram --threshold=3 \
		--corpus-dirs work/jawiki/vibrato-ipadic/ \
		--corpus-dirs work/aozora_bunko/vibrato-ipadic/ \
		work/stats-vibrato-unigram.wordcnt.trie work/stats-vibrato-bigram.wordcnt.trie

# =========================================================================

clean:
	rm -rf dist/

.PHONY: all dist release clean

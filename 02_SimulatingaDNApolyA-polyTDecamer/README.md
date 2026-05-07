# 章 02 — Simulating a DNA polyA-polyT Decamer

[AMBER 公式 Tutorial 1](https://ambermd.org/tutorials/basic/tutorial1/index.php) に対応する章です。

## この章で学ぶこと

**10 塩基対の DNA 二重鎖** (片方が poly-A、もう片方が poly-T) を題材に、**3 つの異なる溶媒モデル** で MD を回して比較します:

1. **真空中 MD** (溶媒なし)
2. **暗黙溶媒 MD** (Generalized Born / GB モデル)
3. **明示溶媒 MD** (TIP3P 水分子で囲む)

これにより:

- **溶媒モデルを変えると挙動がどう変わるか** を肌で理解
- **DNA という荷電分子** (リン酸基が負電荷を持つ) の扱い (カウンターイオン Na+ で中和)
- **核酸用の力場** (`DNA.bsc1`) の使い方
- **NAB** (Nucleic Acid Builder) という DNA/RNA 構造ジェネレータの存在
- **段階的な平衡化** (溶媒先 → DNA 後) — 章 01 より一歩進んだ手順

を身につけます。

---

## 章 01 (アラニン) との比較

| 項目 | 章 01 (アラニン) | 章 02 (DNA) |
|---|---|---|
| 系 | ペプチド (中性) | **DNA (負電荷)** ← イオンが必要 |
| 力場 | ff19SB (タンパク質) | **DNA.bsc1** (核酸) |
| 水モデル | OPC | **TIP3P** |
| 構造の作り方 | tleap の `sequence` で完結 | **NAB → tleap** の 2 段構え |
| MD バリエーション | 1 種類 (明示溶媒) | **3 種類** (真空/GB/明示) |
| 最小化段階 | 1 段 | **2 段** (DNA 拘束 → 全自由) |

章 01 で身につけたパイプラインの上に、**「複雑な現実の系をどう扱うか」** が乗っかってくるイメージ。

---

## 前提

プロジェクトルートの [README](../README.md) と [PRIMER.md](../PRIMER.md) を読み、章 01 を完了していることを推奨します。  
すなわち:

1. Nix がインストール済み
2. リポジトリルート (= この `tutorial/` レベル) で `nix develop` で起動済み
3. 章 01 の 5 ステップを一通りやっていれば、概念の積み上げが楽

---

## 5 つのステップ

| ステップ | 何をやる | 所要時間目安 |
|---|---|---|
| [01_setup](solutions/01_setup/) | NAB で DNA らせん生成 + tleap で 3 系統 (真空/GB/明示) のトポロジー作成 | 5〜10 分 |
| [02_vacuum_md](solutions/02_vacuum_md/) | 真空中 MD (cutoff 12Å vs 無限大の比較) | 10〜30 分 |
| [03_implicit_solvent](solutions/03_implicit_solvent/) | GB 暗黙溶媒で MD | 10〜30 分 |
| [04_explicit_solvent](solutions/04_explicit_solvent/) | 明示溶媒で 4 段階 MD (本格的) | 数時間 |
| [05_analysis](solutions/05_analysis/) | 3 種類の結果を比較・RMSD 解析 | 10 分 |

---

## 進め方

```bash
# プロジェクトルートにいる前提
cd tutorial/02_SimulatingaDNApolyA-polyTDecamer

# 学習者向けの手順は workspace/ にある
cd workspace
cat README.md
```

`workspace/README.md` の指示に従って各ステップを実行します。詰まったら `solutions/0X_*/README.md` を答えとして参照してください。

---

## この章のキーワード (詳細は [GLOSSARY](../GLOSSARY.md))

- **NAB (Nucleic Acid Builder)** — AmberTools 同梱の核酸構造生成ツール
- **DNA.bsc1 力場** — 核酸用の現代的な力場 (2015 年公開)
- **暗黙溶媒 / GB (Generalized Born)** — 水を陽に置かず溶媒効果を平均場として扱う高速モデル
- **カウンターイオン** — 荷電分子の電荷を中和するためのイオン (DNA なら Na+)
- **段階的平衡化** — まず溶媒だけ動かして DNA を固定 → 全自由、という手順

---

## この章を完走したら次は

→ 章 03 以降 (タンパク質-リガンド、フリーエネルギー計算など) に進めます。

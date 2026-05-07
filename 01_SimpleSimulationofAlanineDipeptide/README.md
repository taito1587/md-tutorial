# 章 01 — Simple Simulation of Alanine Dipeptide

[AMBER 公式 Tutorial 0](https://ambermd.org/tutorials/basic/tutorial0/index.php) に対応する章です。

## この章で学ぶこと

**アラニンジペプチド** (アミノ酸 1 個を両端でキャップした最小ペプチド) を水中で MD シミュレーションする一連の流れを通して、**MD の最も基本的なパイプライン** を身につけます。

具体的には:

- AMBER の中核ツール `tleap` / `sander` / `cpptraj` の使い方
- 入力ファイル (`*.in`) の各パラメータが何を意味するか
- 力場 (ff19SB) と水モデル (OPC) の組み合わせ
- 加熱・平衡化・本番の 3 段階構成
- RMSD・温度・密度などの結果の見方

ここで身につけたパイプラインは、章 02 (DNA) でもタンパク質でも、**どんな MD プロジェクトにも共通**で使えます。

---

## 前提

プロジェクトルートの [README](../README.md) と [PRIMER.md](../PRIMER.md) を読み終わっていることを想定しています。すなわち:

1. Nix がインストール済み
2. リポジトリルート (= この `tutorial/` レベル) で `nix develop` でシェルに入った状態
3. `sander -h` がそのシェル内で通る

---

## 5 つのステップ

| ステップ | 何をやる | 所要時間目安 |
|---|---|---|
| [01_setup](solutions/01_setup/) | tleap で分子を組み立てる + 水で溶かす | 5 分 |
| [02_minimization](solutions/02_minimization/) | エネルギー最小化 (構造のひずみ取り) | 1〜2 分 |
| [03_heating](solutions/03_heating/) | 0 K → 300 K にゆっくり加熱 (20 ps の MD) | 5〜10 分 |
| [04_production](solutions/04_production/) | 300 K で本番 MD (10 ns) | マシン次第で数時間 |
| [05_analysis](solutions/05_analysis/) | RMSD・温度・密度をプロット | 5 分 |

各ステップに詳細な README が付いています。

---

## 進め方

```bash
# プロジェクトルートにいる前提
cd tutorial/01_SimpleSimulationofAlanineDipeptide

# 学習者向けの手順は workspace/ にある
cd workspace
cat README.md
```

`workspace/README.md` の指示に従って各ステップを実行します。詰まったら `solutions/0X_*/README.md` を答えとして参照してください。

---

## この章の特徴

| 項目 | 内容 |
|---|---|
| 系 | アラニンジペプチド (3 残基: ACE-ALA-NME) + OPC 水 |
| 力場 | ff19SB (タンパク質) + OPC (水) |
| 系のサイズ | 全 ~3000 原子 |
| 本番 MD | NPT, 300 K, 1 atm, 10 ns |
| 解析 | RMSD (mass-weighted, 残基 ALA に対して) |

---

## この章を完走したら次は

→ [章 02 (DNA decamer)](../02_SimulatingaDNApolyA-polyTDecamer/) で核酸の MD に進めます。同じパイプラインで違う題材を扱う体験。

# Step 01 — System setup (NAB + tleap で 3 系統作る)

> 必要な前知識: なし (詳細は [GLOSSARY](../../../GLOSSARY.md))

## このステップで何をやるか

10 塩基対の poly(A)·poly(T) DNA を組み立てて、後段の 3 種類の MD (真空 / GB / 明示溶媒) で使う **3 つのトポロジー + 座標ファイル** を一括で作ります。

具体的なアウトプット:

| ファイル | 用途 |
|---|---|
| `nuc.pdb` | NAB が生成した DNA 二重らせんの PDB |
| `polyAT_vac.prmtop` / `polyAT_vac.rst7` | **真空 / GB MD** で使う (水もイオンもなし) |
| `polyAT_cio.prmtop` / `polyAT_cio.rst7` | カウンターイオンだけ追加 (使わないが教育的に作る) |
| `polyAT_wat.prmtop` / `polyAT_wat.rst7` | **明示溶媒 MD** で使う (水 + イオン入り) |

---

## 1. まずは DNA の基礎おさらい

「DNA って何だっけ?」をすばやく:

### 構造

DNA は 2 本鎖の **二重らせん** (double helix)。各鎖は **塩基 + 糖 + リン酸** の繰り返し:

```
鎖 A:    5'─P─糖─塩基(A)─糖─塩基(A)─糖─塩基(A)─...─3'
              │     │       │      │       │      │
              │     │       │      │       │      │     ← 塩基対 (水素結合)
              │     │       │      │       │      │
鎖 B:    3'─P─糖─塩基(T)─糖─塩基(T)─糖─塩基(T)─...─5'
```

### 4 つの塩基

| 略号 | 名前 | 対になる塩基 |
|---|---|---|
| **A** | アデニン (Adenine) | **T** |
| **T** | チミン (Thymine) | **A** |
| **G** | グアニン (Guanine) | **C** |
| **C** | シトシン (Cytosine) | **G** |

A=T は 2 本の水素結合、G≡C は 3 本の水素結合 → **G/C リッチな DNA は熱に強い**。

### 今回扱う poly(A)·poly(T) decamer

- 一方の鎖が **A 10 個** (`AAAAAAAAAA`)
- もう一方の鎖が **T 10 個** (`TTTTTTTTTT`)
- 互いに塩基対を組んで 10 bp の二重鎖を形成

```
5' ─ A A A A A A A A A A ─ 3'
     |  |  |  |  |  |  |  |  |  |
3' ─ T T T T T T T T T T ─ 5'
```

### なぜ poly(A)·poly(T) なのか

| 理由 | 詳細 |
|---|---|
| **規則的** | 全塩基対が同じ A=T → 結果の解釈が単純 |
| **小さい** | 10 bp = 約 640 原子 → 計算が速い |
| **教科書的** | 配列特異的効果がない、純粋にらせん構造の物理だけ見られる |
| **歴史的標準** | DNA MD の検証によく使われる |

実際の研究では特定の遺伝子配列を扱うことが多いですが、メソッド検証や教育では「**最も単純で扱いやすい標準系**」として poly(A)·poly(T) が選ばれます。

---

## 2. なぜ NAB が必要なのか — tleap だけでは不十分

章 01 (アラニン) では `tleap` の `sequence { ACE ALA NME }` だけで分子が組めました。**じゃあ DNA も `sequence { DA DA DA ... }` で OK では?** という疑問が湧きます。

答え: **3D 座標を生成できないから**。

```
tleap の sequence:
  - 残基を「線状に繋ぐ」のは得意
  - 各残基の原子を相対位置で置くだけ
  - 「らせんに巻く」「Watson-Crick 塩基対形成」 までは知らない
```

DNA は実空間で **美しい二重らせんに巻きついた立体構造** を持っているので、これを正しい位置関係で生成するには専用ツールが必要です。それが **NAB**。

代替案として:
- 既存の DNA 構造を [PDB データベース](https://www.rcsb.org/) からダウンロード
- [3DNA](http://x3dna.org/) という別ツールで生成
- AMBER 同梱の NAB を使う ← **今回これを選ぶ** (公式チュートリアル踏襲)

---

## 3. NAB (Nucleic Acid Builder) とは

NAB は **核酸構造を生成する専用 DSL** (= Domain Specific Language) です。AmberTools に同梱されています。

特徴:

- C 言語ベースの構文 (中括弧 `{}`、セミコロン、関数呼び出し)
- 核酸モデリング用の組み込み関数を多数持つ (`fd_helix`, `bdna`, `getres` など)
- スクリプトを **コンパイル** して実行ファイルを作る (Python のように直接実行ではなく、C のようにビルドする)

### 今回使う `fd_helix`

```c
m = fd_helix( "abdna", "aaaaaaaaaa", "dna" );
```

- **第 1 引数 `"abdna"`** — 「Arnott B-form DNA」というらせんの種類 (= 標準的な右巻き B 型 DNA)
- **第 2 引数 `"aaaaaaaaaa"`** — 1 本鎖の塩基配列 (10 個の adenine)。**相補鎖 (T の 10 連) は自動生成** される
- **第 3 引数 `"dna"`** — 分子タイプ (`"dna"` か `"rna"`)

返り値の `m` は **両鎖を含む 3D 構造**。これを `putpdb` で PDB ファイルに書き出します。

### B 型 DNA とは

DNA は溶液状態と湿度に応じて何種類かのらせん形を取ります:

| 型 | 特徴 | 状況 |
|---|---|---|
| **A 型** | 太く短い | 低水分 |
| **B 型** | 細く長い (右巻き) | **生体内の標準** |
| Z 型 | 左巻き | 特殊な GC 配列 |

「**`abdna`** = Arnott が決めた B 型 DNA の理想座標」。生体内の現実に最も近い型なので、研究の出発点として標準的。

### NAB の使い方 — コンパイル型

NAB スクリプトは **コンパイル型**:

```bash
nab build.nab -o build_dna   # ① コンパイル: build.nab → build_dna (実行ファイル)
./build_dna                  # ② 実行: nuc.pdb が生成される
```

**C 言語**の `gcc hello.c -o hello && ./hello` と同じ感覚です。Python のような「直接実行」ではなく、C のような「ビルドしてから実行」。

これは NAB が C 言語の上に薄い DSL レイヤーを構築しているため。`nab` コマンドは「**NAB スクリプト → C コード → コンパイル → 実行ファイル**」の流れを自動化します。

---

## 4. DNA.bsc1 力場とは

タンパク質に ff19SB があるように、DNA には専用の力場があります。

| 力場 | 公開 | 特徴 |
|---|---|---|
| ff99 / ff99bsc0 | 古典 (1999) | 古い、現在は非推奨 |
| **DNA.bsc1** | **2015** (Ivani et al.) | **現在の AMBER 公式 DNA 推奨** |
| DNA.OL15, DNA.OL21 | 2015〜2021 (Olomouc 大学) | 別流派の改良。bsc1 とほぼ同等 |

### bsc1 が解決した問題

古い ff99 などで長時間 MD するとよく観察された問題:

- DNA backbone の二面角が間違った領域に入る (γ-trans 状態の過剰サンプリング)
- DNA がだんだん「ねじれていって」非物理的な構造に達する

bsc1 では backbone の二面角ポテンシャルを丁寧にチューニングしてこれらを修正しました。**長い MD でも構造が壊れにくい**のが特徴。

`source leaprc.DNA.bsc1` の 1 行で読み込みます。

### bsc1 と組み合わせる水モデル

bsc1 は **TIP3P** との組み合わせで開発・検証されてきた経緯があります。なので章 02 では TIP3P を使います。

| 力場 | 推奨水モデル |
|---|---|
| ff19SB (タンパク質) | OPC (専用に最適化) |
| **DNA.bsc1** | **TIP3P** (歴史的にずっとこの組み合わせ) |

DNA.bsc1 と OPC の組み合わせも可能ですが、論文のデータと比較する都合で TIP3P が標準です。

---

## 5. なぜカウンターイオンが必要なのか

DNA の各リン酸基は **-1 の電荷** を持っています。10 塩基対の二重鎖では:

- リン酸基 = 各鎖に内部 9 個 (両端は OH 末端なのでカウントしない場合あり) × 2 鎖 = **約 18 個**
- 全体電荷 = **約 -18**

このまま MD すると:

- **マクロな電荷中性が崩れる** (周期境界では系全体が中性であるべき)
- **PME 計算で「中性化のための背景電荷」が自動補正される** (= 実は計算は走る)
- でも背景電荷補正は人工的、本当は **ちゃんと Na+ などのイオンで中和すべき**

実際の溶液中では Na+ や Mg²+ などの金属イオンがリン酸の周りに存在して中和しています。これを忠実に再現するため、**Na+ を 18 個追加** します。

### `addions` の使い方

```
addions dna_wat Na+ 0
```

- 第 1 引数: 対象分子変数
- 第 2 引数: 追加するイオン名 (`Na+`、`Cl-`、`K+` など)
- 第 3 引数: **`0` = 系がちょうど中性になる数だけ追加**

最後の `0` が「**自動計算**」のキーワード。tleap が DNA の全体電荷を計算して、必要な Na+ の数を決定してくれます。

数値を直接指定もできます (`addions dna_wat Na+ 18` のように)。

### Cl- も入れるべきか?

塩 (NaCl) として両方入れるのが「より生理的」(実際の細胞内・血液中は ~150 mM NaCl):

```
addions dna_wat Na+ 18 Cl- 18    # 中性 + 余分の塩
```

ただし教育目的では **中性化に必要な分の Na+ だけ** で十分。チュートリアルもこのシンプルな形式に従います。

---

## 6. なぜ 3 系統作るのか

| 系統 | ファイル名 | 何で使う |
|---|---|---|
| **vac** (vacuum) | `polyAT_vac.*` | Step 02 の真空 MD と Step 03 の GB MD |
| **cio** (counterions only) | `polyAT_cio.*` | 教育用 (今回の MD では使わない、ただ作っておく) |
| **wat** (water) | `polyAT_wat.*` | Step 04 の明示溶媒 MD |

3 種類同時に作るのは、後で「**同じ DNA で溶媒だけ違う**」という比較実験をするため。Step 05 で 3 つのトラジェクトリを並べてグラフ化することで「**水と GB と真空の違い**」が一目で分かります。

`cio` (counterions only) は今回直接 MD には使いませんが、「DNA + Na+ だけで水なし」という中間ケースを **教育用に作っておく** 意図です (公式チュートリアルもそうしているので踏襲)。

---

## 7. 実行してみる

```bash
# プロジェクトルートで `nix develop` 済みのシェルで
cd workspace
mkdir -p 01_setup && cd 01_setup

# スクリプトをコピー
cp ../../solutions/01_setup/build.nab .
cp ../../solutions/01_setup/build.leap.in .

# ① NAB でコンパイル → DNA らせんを生成
nab build.nab -o build_dna
./build_dna
# nuc.pdb ができているはず
ls nuc.pdb

# ② tleap で 3 系統のトポロジーを作る
tleap -f build.leap.in
```

### 期待される出力

実行末尾に以下のような表示が出ます:

```
> addions dna_cio Na+ 0
18 Na+ ions required to neutralize.
Adding 18 counter ions to "dna_cio" using 1A grid
...
> solvateoct dna_wat TIP3PBOX 8.0
  Solute vdw bounding box:              ...
  Total bounding box for atom centers:  ...
  Volume:  ... A^3
  Total mass ... amu, Density ... g/cc
  Added ... residues.
```

ポイント:
- ✅ `18 Na+ ions required` の数値 (理論通り)
- ✅ `Added X residues` で水分子が数千個追加されている
- ✅ エラーが `leap.log` に出ていない

### 各種ファイルが正しく出来たか確認

```bash
ls -lh polyAT_*
```

期待される出力:
```
polyAT_cio.prmtop   ~200 KB    DNA + Na+
polyAT_cio.rst7      ~30 KB
polyAT_vac.prmtop   ~150 KB    DNA だけ
polyAT_vac.rst7      ~25 KB
polyAT_wat.prmtop   ~600 KB    DNA + Na+ + 数千個の水
polyAT_wat.rst7     ~150 KB
```

`wat` 版だけサイズが大きい (水分子が入っている分)。

---

## 8. 出力ファイル一覧

```
01_setup/
├── build.nab          # NAB スクリプト
├── build.leap.in      # tleap スクリプト
├── build_dna          # コンパイル済み NAB 実行ファイル
├── nuc.pdb            # NAB が生成した DNA らせん PDB
├── polyAT_vac.prmtop  # ★真空系 (Step 02, 03 で使う)
├── polyAT_vac.rst7    # ★
├── polyAT_cio.prmtop  # カウンターイオン系 (作っておくだけ)
├── polyAT_cio.rst7
├── polyAT_wat.prmtop  # ★明示溶媒系 (Step 04 で使う)
├── polyAT_wat.rst7    # ★
└── leap.log           # tleap の実行ログ
```

---

## 9. nuc.pdb を覗いてみよう (任意)

```bash
head -20 nuc.pdb
```

PDB 形式は構造生物学の標準フォーマット。中身はこんな感じ:

```
HEADER    PDB
ATOM      1  H5T  DA5 A   1      ...   ...   ...  1.00  0.00           H
ATOM      2  O5'  DA5 A   1      ...   ...   ...  1.00  0.00           O
ATOM      3  C5'  DA5 A   1      ...   ...   ...  1.00  0.00           C
...
```

各行が 1 原子。座標 (x, y, z) と所属残基などが書かれています。VMD などのビューアで開けば 3D で見られます。

---

## 10. つまずきポイント

| 症状 | 対処 |
|---|---|
| `nab: command not found` | conda env の AmberTools に NAB が含まれているか確認: `which nab`。なければ `nix develop` で正しく起動しているか |
| `nab` でコンパイルエラー | `cc` (C コンパイラ) が PATH にあるか確認。conda env 内に通常含まれる |
| `nuc.pdb` ができない | `./build_dna` の実行で何かエラーが出ていないか確認 |
| `Could not find type` で tleap がエラー | `source leaprc.DNA.bsc1` の前に `loadpdb` を呼んでいる可能性。順番を確認 |
| `addions` が動かない | バージョンによっては `addions2` を使う。エラー文で示唆される |
| 水分子の数が極端に多い | バッファサイズ (`solvateoct ... 8.0` の `8.0`) を確認。10.0 や 12.0 にすると水が増える |

---

## 11. 用語ミニ辞典

- **NAB**: 核酸構造生成ツール。コンパイルしてから実行する DSL
- **B-form DNA**: 最も普通の右巻き 2 重らせん構造 (生体内の標準)
- **DNA.bsc1**: AMBER の現代的な DNA 力場 (2015)
- **TIP3P**: 古典的な 3 点水モデル
- **カウンターイオン**: 荷電分子を中和するイオン
- **Watson-Crick 塩基対**: A=T, G≡C の標準的な塩基対形成
- **PDB 形式**: 原子座標を記述する標準テキスト形式

---

## 次のステップ

→ [02_vacuum_md](../02_vacuum_md/) で真空中での MD を試します (cutoff の影響を観察)。

→ [03_implicit_solvent](../03_implicit_solvent/) で GB (Generalized Born) 暗黙溶媒の MD。

→ [04_explicit_solvent](../04_explicit_solvent/) で明示溶媒の本格的な MD。

→ [05_analysis](../05_analysis/) で 3 種類を比較。

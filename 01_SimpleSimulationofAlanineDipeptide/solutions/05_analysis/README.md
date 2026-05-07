# Step 05 — Analysis (結果の分析と可視化)

> このステップで必要な前知識: [PRIMER](../../../PRIMER.md), Step 04 が完了していること

## このステップで何をやるか

これまでに走らせた MD のログ (`02_Heat.out`, `03_Prod.out`) とトラジェクトリ (`02_Heat.nc`, `03_Prod.nc`) から、

1. **温度** (`TEMP`) が安定しているか
2. **密度** (`DENSITY`) が水の値 (≈ 1.0 g/cm³) で落ち着いているか
3. **構造のゆらぎ (RMSD)** がどれくらいか

を**数値とグラフで**確認します。

MD は走らせて終わりではなく、**結果を見てシミュレーションが妥当だったか判断する**ところまでが 1 セットです。具体的に何が「妥当」なのかも、このステップで身につきます。

---

## 1. 解析の 3 つの軸

### (a) Temperature の確認

意図した温度 (300 K) が**実際に維持できているか**を見ます。Langevin サーモスタットがちゃんと働いているかの最終チェック。

### (b) Density の確認

NPT で得られる密度が**水の実験値 (≒ 1.0 g/cm³)** に近いか。これが大きくズレていると力場 + 水モデルの組み合わせがおかしいか、平衡化不十分。

### (c) Structural fluctuation (RMSD) の確認

最も「**MD らしい**」解析。アラニンジペプチドが時間経過でどう構造を変えていったかを 1 つの数値で表す。

---

## 2. 道具の紹介

### `process_mdout.perl`

`*.out` (= sander/pmemd の人間向けログ) から指定された物理量を抜き出して、各物理量ごとに **`summary.<NAME>` ファイル** に書き出す Perl スクリプト。AmberTools に標準で同梱。

```
03_Prod.out
    │
    │ process_mdout.perl
    ▼
summary.TEMP        ← 温度の時系列
summary.DENSITY     ← 密度の時系列
summary.ETOT        ← 全エネルギーの時系列
summary.EPTOT       ← ポテンシャルエネルギー
summary.EKTOT       ← 運動エネルギー
summary.PRES        ← 圧力
summary.VOLUME      ← 体積
... など
```

各 `summary.*` は単純な 2 列テキスト (時間, 値) なので gnuplot 等にそのまま渡せます。

### `cpptraj`

AmberTools の **解析エンジン**。スクリプト言語っぽいインタプリタで、

- RMSD / RMSF (柔軟性指標)
- 二面角の時系列・ヒストグラム
- 水素結合数
- クラスタリング
- SASA (溶媒接触表面積)

など、構造解析ならほぼ何でもできます。今回は最もシンプルな RMSD だけ使います。

### `gnuplot`

軽量な 2D プロットツール。コマンドラインに `plot "ファイル" with lines` と打つだけで 2 列テキストをグラフ化してくれます。論文に出せる品質。

```bash
# 1 行コマンドでウィンドウを開く (-p = 終了後もウィンドウを残す)
gnuplot -p -e 'plot "summary.TEMP" with lines'

# 2 つを重ねる
gnuplot -p -e 'plot "summary.TEMP" with lines, "summary.DENSITY" with lines'

# PNG にエクスポート
gnuplot -e 'set terminal png size 800,600; set output "temp.png"; plot "summary.TEMP" with lines'
```

> 📝 **公式チュートリアルは xmgrace を使っていますが**、xmgrace (= Grace) は古い X11 アプリで Apple Silicon Mac の conda-forge には用意されていません。本リポジトリでは同等の `gnuplot` で代用しています。見える結果はほぼ同じです。

`gnuplot` を **対話モード** で使うときは引数なしで起動:

```bash
gnuplot
gnuplot> set title "Temperature"
gnuplot> set xlabel "step"
gnuplot> set ylabel "T [K]"
gnuplot> plot "summary.TEMP" with lines
gnuplot> exit
```

---

## 3. RMSD の数学的な定義

### 公式

参照構造 `r_i^ref` と任意のフレームの座標 `r_i` の **差の RMS (root mean square)**:

```
        ┌────────────────────────────────┐
        │     1                          │
RMSD = √│ ───── Σ_i  m_i (r_i - r_i^ref)²
        │     M                          │
        └────────────────────────────────┘
```

- M = 重みの総和 (mass-weighted のとき = 全原子の質量和)
- 単位は Å

### Mass-weighted RMSD ってどう違うのか

| | 通常 RMSD | Mass-weighted RMSD |
|---|---|---|
| 重み | 全原子で同じ (= 1) | 質量に比例 |
| 軽い水素のノイズ | 影響大 | **影響小** |
| 重い C, N, O のズレ | 影響中 | **影響大** |

タンパク質骨格は C, N, O が中心で、**水素は熱運動でブルブル震えている**ので、mass-weighted の方が「**意味のある構造変化**」を捉えやすい。今回は mass-weighted を使います。

### Reference の選び方

「何を基準にズレを測るか」を決めるのが reference。

| 選択肢 | 用途 |
|--------|------|
| `first` | トラジェクトリ最初のフレームを参照。「シミュレーション開始からどれだけ動いたか」 |
| `reference <file>` | 指定したファイルを参照。今回は **最小化後の構造** を使う |
| 結晶構造 | 実験構造との比較に |

このチュートリアルでは `01_Min.ncrst` (= 最小化後の構造) を reference にして「**MD 中に最小化構造からどれだけズレたか**」を見ます。

---

## 4. autoimage — 周期境界対策

### なぜ必要か

周期境界条件下では、分子が箱の壁を越えると**反対側から入ってくる**(ように見える) 動きをします:

```
箱の中:  ┌────●────┐
        │         │
        └─────────┘

次のフレーム:
        ┌─────────┐
        │         │  ← 元の箱は空
        └─────────┘
              ●→ →    実際にはこっちへ
        ┌────●────┐  ← 数値座標は隣の箱の位置に
        │         │
        └─────────┘
```

このとき**素朴に座標を読むと、分子が一瞬で巨大な距離を移動した**ように見えます。これでは RMSD が桁違いに大きくなります。

### autoimage の役割

cpptraj の `autoimage` コマンドは、**境界をまたいだ分子をシミュレーション箱の中に巻き戻し** ます。これにより RMSD の計算が正しくなります。

> ⚠️ **PBC (周期境界) 下のトラジェクトリでは RMSD 解析の前に必ず autoimage**

---

## 5. ファイル一覧

- [`rmsd.cpptraj`](./rmsd.cpptraj) — RMSD を計算する cpptraj スクリプト
- [`plot.sh`](./plot.sh) — `process_mdout.perl` を呼んで `summary.*` を作るシェルスクリプト

---

## 6. 実行コマンド

### Phase A — 温度・密度・エネルギーの時系列を作る

```bash
cd workspace
mkdir -p 05_analysis && cd 05_analysis

cp ../../solutions/05_analysis/plot.sh .
cp ../../solutions/05_analysis/rmsd.cpptraj .

bash plot.sh
```

これで `summary.TEMP`, `summary.DENSITY`, `summary.ETOT`, `summary.PRES` などが生成されます。

### Phase B — RMSD を計算

```bash
# トポロジーは -p フラグで渡し、解析手順は -i のスクリプトで指示
cpptraj -p ../01_setup/diala.parm7 -i rmsd.cpptraj &> cpptraj.log
```

→ `02_03.rms` が生成されます (2 列: time [ps], mass-weighted RMSD [Å])。

### Phase C — プロット

```bash
# 温度 vs 時刻 (-p でウィンドウ閉じても残す)
gnuplot -p -e 'set xlabel "step"; set ylabel "T [K]"; plot "summary.TEMP" with lines'

# 密度 vs 時刻
gnuplot -p -e 'set xlabel "step"; set ylabel "rho [g/cc]"; plot "summary.DENSITY" with lines'

# RMSD vs 時刻
gnuplot -p -e 'set xlabel "time [ps]"; set ylabel "RMSD [A]"; plot "02_03.rms" with lines'
```

#### `gnuplot` の対話モード操作

`gnuplot` (引数なし) で起動した場合:

| 操作 | コマンド |
|------|---------|
| プロット | `plot "ファイル" with lines` |
| タイトル | `set title "..."` |
| 軸ラベル | `set xlabel "..."` / `set ylabel "..."` |
| 範囲指定 | `set xrange [0:1000]` |
| 凡例 | `set key top right` |
| 描き直し | `replot` |
| PNG 出力 | `set terminal png; set output "out.png"; plot ...; set terminal pop; set output` |
| 終了 | `exit` または Ctrl-D |

### Phase D — ヘッドレス環境 (PNG だけ作る)

GUI ウィンドウなしで PNG だけ吐きたい場合:

```bash
gnuplot -e 'set terminal png size 800,600; set output "temperature.png"; plot "summary.TEMP" with lines'
gnuplot -e 'set terminal png size 800,600; set output "rmsd.png"; plot "02_03.rms" with lines'
```

---

## 7. 結果の判定基準

### `summary.TEMP` (温度)

期待されるパターン:

```
T [K]
  │       ┌─────────────────────────────────  ← Production: 300 ± 数 K で振動
300├─────┘
  │   ╱
  │ ╱        ← Heating: 0 → 300 K の線形上昇
  │╱
0 │
  └────────────────────────────────────────── time [ps]
  0   20            10020
```

判定:

- ✅ Heating で 0 → 300 K の **滑らかな上昇**
- ✅ Production 中は **300 ± 5 K** で振動 (Langevin の効果)
- ❌ 急激なスパイク → サーモスタットの不調
- ❌ 平均が 295 K や 305 K に偏る → ig (乱数) の影響、ステップを増やせば平均化される

### `summary.DENSITY` (密度)

判定:

- ✅ Production フェーズで **0.99 〜 1.00 g/cm³** に収束 (OPC 水の理論値)
- ❌ 0.95 以下 / 1.05 以上 → 平衡化が不十分、または力場ミス
- 最初の数 ps は不安定なので、平均を取るときは平衡化済み区間 (例: 1 ns 以降) を使う

### `02_03.rms` (RMSD)

判定:

- ✅ アラニン残基の mass-weighted RMSD は **0.5〜2 Å** くらいの範囲で振動
- ✅ 構造遷移 (φ/ψ のフリップ) があると **段差** がプロットに現れる (これは正常)
- ❌ 単調増加し続ける → 系が崩壊している可能性
- ❌ 100 Å 級の値 → autoimage 忘れ

---

## 8. さらに進んでみるなら (任意)

このチュートリアル 0 はここまでで完了ですが、興味があればこれらの解析もできます:

### 二面角 (φ, ψ) のヒストグラム

cpptraj スクリプトの例:

```
trajin ../03_heating/02_Heat.nc
trajin ../04_production/03_Prod.nc
autoimage
multidihedral phipsi resrange 2 out phipsi.dat
hist phipsi.dat,-180,180,72 phipsi.hist out rama.dat
run
```

これでアラニンの **Ramachandran プロット** の素材が得られます。

### 水素結合数

```
hbond out hbond.dat
```

### 3D 可視化 (VMD)

VMD がインストールされていれば:

```bash
vmd -parm7 ../01_setup/diala.parm7 -netcdf ../04_production/03_Prod.nc
```

トラジェクトリを再生して、アラニンが揺れる様子を直感的に見られます。

これら追加解析は **AMBER 公式チュートリアル 1 以降** で本格的に扱われます。

---

## 9. つまずきポイント

| 症状 | 原因と対処 |
|------|-----------|
| `process_mdout.perl: command not found` | AmberTools の bin にあるはず。`nix develop` 環境内で実行しているか確認、もしくは `which process_mdout.perl` |
| `cpptraj` がトラジェクトリを読めない | パスが間違っている。`ls ../03_heating/02_Heat.nc` で存在確認 |
| RMSD が異様に大きい (100 Å 級) | `autoimage` を忘れている。スクリプトに含まれているはずだが、自分で書き直した時に注意 |
| `gnuplot` ウィンドウが開かない | リモートシェルでは X11 forwarding (`ssh -X`) が必要。または `set terminal png` で PNG ファイル出力 |
| 温度が 300 K より明らかに低い | Langevin が強すぎる、または平衡化不十分 |

---

## 10. 用語ミニ辞典 (このステップ初出)

- **RMSD**: 参照からの位置ズレの平均的大きさ。詳細 [GLOSSARY](../../../GLOSSARY.md#rmsd-root-mean-square-deviation)
- **mass-weighted RMSD**: 質量で重みを付けた RMSD。詳細 [GLOSSARY](../../../GLOSSARY.md#mass-weighted-rmsd)
- **autoimage**: 周期境界をまたいだ分子を箱に巻き戻す。詳細 [GLOSSARY](../../../GLOSSARY.md#autoimage)
- **gnuplot**: 軽量プロットツール。`gnuplot -p -e 'plot "..." with lines'` で 1 行プロット。詳細 [GLOSSARY](../../../GLOSSARY.md#gnuplot)

---

## おつかれさまでした 🎉

ここまで完走したら、AMBER チュートリアル 0 はクリアです。

### 次に進むなら

- [Tutorial A1: Simulating a Solvated Protein](https://ambermd.org/tutorials/basic/tutorial1/index.php) — 実際のタンパク質 (lysozyme) を扱う
- [Tutorial A2: An Introduction to Polarizable Force Fields](https://ambermd.org/tutorials/basic/tutorial2/index.php)
- [Tutorial A3: An Introduction to LiE](https://ambermd.org/tutorials/basic/tutorial3/index.php)

---

## 11. このリポジトリでやったことの総括

| ステップ | 入力 | 出力 | 学んだこと |
|---------|------|------|----------|
| 01 setup | (なし、スクリプト内) | `diala.parm7`, `diala.rst7` | 力場と水モデル、tleap、溶媒和 |
| 02 minimization | parm7 + rst7 | 01_Min.ncrst | 最小化アルゴリズム、エネルギー成分 |
| 03 heating | 01_Min.ncrst | 02_Heat.{ncrst,nc} | Langevin、SHAKE、`&wt` |
| 04 production | 02_Heat.ncrst | 03_Prod.{ncrst,nc} | NPT、Berendsen、リスタート |
| 05 analysis | .nc + .out | summary.*, .rms, グラフ | 結果の信頼性判定、cpptraj |

**この流れはどんな MD プロジェクトでも共通**です。タンパク質、DNA、薬剤・タンパク質複合体、脂質二重膜 — どれも準備 → 最小化 → 加熱 → 平衡化 → 本番 → 解析の流れを踏みます。

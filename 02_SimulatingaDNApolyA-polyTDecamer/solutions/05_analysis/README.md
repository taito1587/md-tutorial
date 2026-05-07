# Step 05 — Analysis (3 種類の MD を比較)

> 必要な前知識: Step 02, 03, 04 のいずれか (3 つ全部やってあると比較が美味しい)

## このステップで何をやるか

Step 02 (真空)、Step 03 (GB)、Step 04 (明示溶媒) の **4 つのトラジェクトリ** から DNA backbone の RMSD を計算し、**1 枚のグラフに重ねて比較** します。

これで「**溶媒モデルが結果にどれだけ影響するか**」が一目で分かるのが本章の最大の見どころ。

具体的なアウトプット:

- `vac_12Acut.rms`, `vac_nocut.rms` — 真空 MD の RMSD (2 種類のカットオフ)
- `gb.rms` — GB MD の RMSD
- `explicit.rms` — 明示溶媒 MD の RMSD
- `summary_*/summary.TEMP`, `summary.DENSITY` etc. — 各 run の温度・密度等

---

## 1. RMSD — DNA の安定性を 1 つの数値で要約する

### 数式

参照構造との「位置ズレ」の平均的な大きさ:

```
        ┌──────────────────────────────┐
        │     1                        │
RMSD = √│ ───── Σ_i  m_i (r_i - r_i^ref)²
        │     M                        │
        └──────────────────────────────┘
```

- M は重みの総和 (mass-weighted のとき = 全選択原子の質量和)
- 単位は Å

### イメージ

```
時刻 t=0 (参照):     ┃          ← まっすぐな DNA らせん
                     ┃
                     ┃
                     ┃
                     ┃

時刻 t=T:           ╲┃          ← ねじれた DNA
                    ╱┃
                    ┃╲
                    ┃ ╲
                    ┃  ╲

各原子について「t=0 からどれだけズレたか」を平均化 → RMSD
```

- **RMSD = 0**: 構造が初期状態と完全に一致
- **RMSD = 1 Å**: 各原子が平均 1 Å ズレている (= **典型的な熱揺らぎ**)
- **RMSD = 5 Å**: 大きく構造変化している (構造遷移、または崩壊)
- **RMSD = 50 Å**: もう「同じ分子だ」とは言えないレベル → MD 失敗

### Mass-weighted RMSD ってどう違うのか

| | 通常 RMSD | Mass-weighted RMSD |
|---|---|---|
| 重み | 全原子で同じ (= 1) | 質量に比例 |
| 軽い水素のノイズ | 影響大 | **影響小** |
| 重い C, N, O のズレ | 影響中 | **影響大** |

DNA backbone は P, O, C などの重い原子中心。**水素は熱運動でブルブル震えている**ので、mass-weighted の方が「**意味のある構造変化**」を捉えやすい。**今回は mass-weighted を使います**。

---

## 2. DNA backbone の原子セレクション

DNA の安定性指標として伝統的に使われるのが **backbone 原子の RMSD**:

```
DNA の構造 (1 残基)

       塩基 (Base: A or T)
         │
         │
  C1' ── 糖環  
   │    /\
   │   C4'  C3'──── O3' ──┐
   │   |   |             │
   │   |   O5'           │
   │   |   |             │
   └─ C5' ─O5' ── P =O   ← リン酸
          ↑      |        
       糖環の主要原子    
```

| 原子 | 役割 |
|---|---|
| **P** | リン酸の中心 |
| **O3', O5'** | リン酸-糖鎖の繋ぎ |
| **C3', C4', C5'** | 糖環の主要骨格 |

これら **6 種類** を全 20 残基 (両鎖) で集めた原子群が "**backbone**"。これだけで DNA の構造変化を十分捉えられます。

セレクション式: `@P,O3',O5',C3',C4',C5'`

水素原子・塩基の原子は除外 → 主鎖だけ → ノイズ少ない、解釈クリア。

---

## 3. 期待される結果のイメージ

```
RMSD [Å]
  │
10│ ─── vacuum 12A cut    ← 数十 ps で発散 (cutoff の影響)
  │     ╱
  │    ╱
 5│   ╱
  │  ╱  ─── vacuum no cut  ← 12A よりはマシだが不安定
  │ ╱  ╱
  │╱ ╱       ─── GB        ← 安定 (3-4 Å 程度)
  │╱      ─── explicit     ← 最も安定 (1-2 Å)
  └──────────────────────── time [ps]
  0           50           100
```

**真空 12A cut > 真空 no cut > GB > 明示溶媒** という順で安定度が上がる。これが「**水を入れるのは大事**」「**実用的な MD は明示溶媒**」のエビデンスになる。

---

## 4. cpptraj スクリプトの中身

3 つに分けてあるのは **トポロジーが違う** から:

| スクリプト | 使うトポロジー | 対象トラジェクトリ |
|---|---|---|
| `rmsd_vacuum.cpptraj` | `polyAT_vac.prmtop` | `02_vacuum_md/*.nc` |
| `rmsd_gb.cpptraj` | `polyAT_vac.prmtop` (← GB は水なし) | `03_implicit_solvent/md.nc` |
| `rmsd_explicit.cpptraj` | `polyAT_wat.prmtop` (← 水入り) | `04_explicit_solvent/*.nc` |

明示溶媒だけ **`autoimage`** が必要 (周期境界をまたぐ可能性があるため)。

### `rms` コマンドの主要引数

```
rms first mass out vac_12Acut.rms @P,O3',O5',C3',C4',C5' time 0.1
```

| 引数 | 意味 |
|---|---|
| `first` | 最初のフレームを参照 (= 「シミュレーション開始時から何 Å ズレたか」を測る) |
| `mass` | 質量重みつき RMSD |
| `out vac_12Acut.rms` | 出力ファイル |
| `@P,O3',...` | 原子セレクション (DNA backbone) |
| `time 0.1` | 時間ストライド (フレーム間隔の見た目)。実時間と一致させたければ `dt × ntwx` の値 |

### 章 01 との違い

章 01 では `reference 01_Min.ncrst` を参照に使い、`:2` (= ALA 残基) を選択しました。章 02 では `first` (= トラジェクトリ最初フレーム) を参照に、`@P,...` (DNA backbone 原子) を選択。

選び方の違い:
- 章 01: 「**最小化された理想構造からのズレ**」を見たい
- 章 02: 「**MD 開始時 (= 加熱直後の構造) からのズレ**」を見たい (それぞれの run の開始時を基準にすることで、4 つの run を独立に評価できる)

---

## 5. 実行コマンド

### Phase A — 温度・密度・エネルギーの時系列

```bash
cd workspace
mkdir -p 05_analysis && cd 05_analysis

cp ../../solutions/05_analysis/*.cpptraj .
cp ../../solutions/05_analysis/plot.sh .

bash plot.sh
```

これで `summary_explicit/`, `summary_gb/`, `summary_vac/` の中に `summary.TEMP`, `summary.DENSITY`, `summary.ETOT` 等が生成されます。

### Phase B — RMSD 計算

```bash
# 3 つ別々に。トポロジーが違うので -p フラグが run ごとに異なる
cpptraj -p ../01_setup/polyAT_vac.prmtop -i rmsd_vacuum.cpptraj
cpptraj -p ../01_setup/polyAT_vac.prmtop -i rmsd_gb.cpptraj
cpptraj -p ../01_setup/polyAT_wat.prmtop -i rmsd_explicit.cpptraj
```

### Phase C — 4 系列を 1 枚のグラフに

```bash
gnuplot -p -e '
  set xlabel "time [ps]";
  set ylabel "RMSD [A]";
  set key top left;
  plot "vac_12Acut.rms" w l lw 2 t "vacuum, 12 A cutoff", \
       "vac_nocut.rms"  w l lw 2 t "vacuum, no cutoff",   \
       "gb.rms"         w l lw 2 t "GB implicit solvent",  \
       "explicit.rms"   w l lw 2 t "TIP3P explicit solvent"
'
```

これが**この章のゴール画像**。4 系統が並ぶことで「水と溶媒モデルの威力」が一目で分かる。

### Phase D — その他のプロット

```bash
# 明示溶媒の温度推移 (加熱フェーズ含む)
gnuplot -p -e 'plot "summary_explicit/summary.TEMP" w l'

# 明示溶媒の密度 (NPT 制御の効きを見る)
gnuplot -p -e 'plot "summary_explicit/summary.DENSITY" w l'

# GB の全エネルギー
gnuplot -p -e 'plot "summary_gb/summary.ETOT" w l'
```

---

## 6. 何を観察するか

### RMSD グラフ (4 系列重ね)

| 系列 | 期待される範囲 | 解釈 |
|---|---|---|
| **真空 12 Å cut** | 数十 ps で **5 Å 超え**、最後は 8-15 Å | cutoff で抜けた静電のせいで構造が崩壊 |
| **真空 no cut** | 3-5 Å 程度を行ったり来たり | 全静電あっても、水なしでは DNA は不安定 |
| **GB** | **2-3 Å 前後で安定** | 水なしの代わりに Born ソルベーションが効いて安定化 |
| **明示溶媒** | **1-2 Å が中心** | 最も安定、現実的、実験データと整合 |

### 明示溶媒の温度・密度

- **温度**: 加熱フェーズで 0→300 K の上昇、本番中は **300 ± 5 K** で振動
- **密度**: 本番中は **0.99-1.00 g/cm³** で安定 (TIP3P + DNA + Na+ の典型値)

これらが想定通りなら明示溶媒の MD は健全に進行している証拠。

### 解釈

「**真空 MD を信用してはいけない**」「**GB は速くて使いやすい**」「**明示溶媒が最もリアルだが計算重い**」という MD 業界の共通認識を、自分の手で実演できたわけです。

---

## 7. 追加で試せる解析 (任意)

### 二面角の軌跡

DNA backbone の二面角 (α, β, γ, δ, ε, ζ) は構造変化のセンサー:

```
multidihedral phipsi resrange 1-20 out dihedral.dat
```

これで各残基の二面角時系列が取れる。

### Watson-Crick 水素結合数の時間変化

```
hbond out hbond.dat distance 3.0 angle 120 :1-10@N1,N3 :11-20@N1,N3
```

塩基対が崩壊し始めると hbond の数が減る → 構造崩壊の早期警告に。

### 主成分分析 (PCA)

```
matrix mwcovar :1-20@P,C1' name pca
diagmatrix pca out pca.dat name eigen
```

DNA の主要な構造変化軸を抽出。

### 3D 可視化 (VMD)

VMD があれば:

```bash
vmd -parm7 ../01_setup/polyAT_wat.prmtop -netcdf ../04_explicit_solvent/prod.nc
```

トラジェクトリを再生して DNA がどう揺れるかを直感的に。

これら追加解析は AMBER 公式 Tutorial 2 以降で本格的に扱われます。

---

## 8. つまずきポイント

| 症状 | 対処 |
|---|---|
| `process_mdout.perl: command not found` | AmberTools の bin にあるはず。`which process_mdout.perl` で確認 |
| `cpptraj` がトラジェクトリを読めない | パスが間違っている。`ls ../03_implicit_solvent/md.nc` で存在確認 |
| RMSD が異様に大きい (50 Å 級) | `autoimage` が抜けているか、原子セレクションが空かも。`@P,O3',O5',C3',C4',C5'` のシングルクォートに注意 |
| `gnuplot` が起動しない | `nix develop` 内で実行しているか確認。リモート環境ならファイル出力 (`set terminal png; ...`) で代替 |
| 4 系列のグラフが重ならない (時間軸ズレ) | `time 0.1` の値が run ごとに違う可能性。`time 0.1` (vacuum/GB) と `time 0.2` (explicit) で異なる |
| 真空 vs GB が同じ挙動 | `igb=1` ではなく `igb=0` になっていないか? |

---

## 9. 用語ミニ辞典

- **RMSD**: 参照からの位置ズレの平均的大きさ。詳細 [GLOSSARY](../../../GLOSSARY.md#rmsd-root-mean-square-deviation)
- **mass-weighted RMSD**: 質量で重みを付けた RMSD。詳細 [GLOSSARY](../../../GLOSSARY.md#mass-weighted-rmsd)
- **autoimage**: 周期境界をまたいだ分子を箱内に巻き戻す。詳細 [GLOSSARY](../../../GLOSSARY.md#autoimage)
- **DNA backbone 原子**: P, O3', O5', C3', C4', C5' — リン酸+糖環の主要原子
- **gnuplot**: 軽量プロットツール。詳細 [GLOSSARY](../../../GLOSSARY.md#gnuplot)

---

## おつかれさまでした 🎉

ここまで完走したら、AMBER Tutorial 1 はクリアです。

### 学んだことの総括

| 項目 | 章 01 (アラニン) | 章 02 (DNA) |
|---|---|---|
| 系の構築 | tleap だけ | NAB + tleap |
| 力場 | ff19SB + OPC (タンパク質) | DNA.bsc1 + TIP3P (核酸) |
| カウンターイオン | 不要 | Na+ で中和 |
| MD 種類 | 1 種 (明示溶媒) | **3 種比較 (真空/GB/明示)** |
| 平衡化 | 1 段最小化 | **2 段最小化 + 制約付き加熱** |
| 制約付き MD | なし | あり (`ntr=1`, restraint mask) |
| 解析の比較軸 | 1 系列 | **4 系列重ねて溶媒モデル比較** |

DNA 系で身につけた:
- **段階的平衡化**
- **複数溶媒モデルの比較**
- **暗黙溶媒 (GB) と明示溶媒の使い分け**
- **位置拘束 (positional restraint)**
- **荷電分子のカウンターイオン処理**

これらは、これから扱うどんな複雑な系 (タンパク質-リガンド、膜タンパク質、DNA-タンパク質複合体、薬剤候補スクリーニング) でも応用できる重要な技術です。

### 次に進むなら

- **AMBER 公式 Tutorial 2 以降** — タンパク質、フリーエネルギー計算、QM/MM など
- **自分の研究課題に当てはめる** — 興味のある系で同じパイプラインを試す
- **力場 / 水モデルを変えて比較** — DNA.OL21 や OPC 水で同じ DNA を MD

研究レベルでも、この章で身につけたパイプラインがそのまま使えます。

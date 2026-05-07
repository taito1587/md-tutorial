# Workspace — DNA decamer のハンズオン

このディレクトリは **章 02 (DNA decamer) を学習者が手で実行する作業エリア**。詰まったら [`solutions/`](../solutions/) を答えとして参照してください。

---

## 前提

- プロジェクトルートの [README](../../README.md) に従って `nix develop` でシェルに入っている
- 章 01 を一通り完了している (推奨)

---

## 全体フロー (5 ステップ)

```
01_setup            → NAB で DNA + tleap で 3 系統 → polyAT_{vac,cio,wat}.{prmtop,rst7}
02_vacuum_md        → 真空 MD (12A cut vs no cut)  → md_12Acut.nc, md_nocut.nc
03_implicit_solvent → GB MD                         → md.nc
04_explicit_solvent → 明示溶媒 4 段階 MD            → heat.nc, prod.nc
05_analysis         → 3 つの結果を比較             → *.rms, summary.*, グラフ
```

---

## ハンズオン手順

### Step 01 — NAB + tleap で 3 系統作成

詳しい解説: [`solutions/01_setup/README.md`](../solutions/01_setup/README.md)

```bash
cd $(git rev-parse --show-toplevel)/tutorial/02_SimulatingaDNApolyA-polyTDecamer/workspace
mkdir -p 01_setup && cd 01_setup

cp ../../solutions/01_setup/build.nab .
cp ../../solutions/01_setup/build.leap.in .

# ① NAB で DNA らせんを生成
nab build.nab -o build_dna
./build_dna
# → nuc.pdb ができる

# ② tleap で 3 系統のトポロジーを作成
tleap -f build.leap.in
# → polyAT_vac/cio/wat.prmtop と .rst7 ができる

ls polyAT_*    # 確認
cd ..
```

---

### Step 02 — 真空中 MD

詳しい解説: [`solutions/02_vacuum_md/README.md`](../solutions/02_vacuum_md/README.md)

```bash
mkdir -p 02_vacuum_md && cd 02_vacuum_md
cp ../../solutions/02_vacuum_md/*.in .

PARM=../01_setup/polyAT_vac.prmtop
INIT=../01_setup/polyAT_vac.rst7

# (a) 最小化
sander -O -i min.in -o min.out -p $PARM -c $INIT -r min.ncrst

# (b) 12 Å cutoff の MD
sander -O -i md_12Acut.in -o md_12Acut.out \
    -p $PARM -c min.ncrst -r md_12Acut.ncrst -x md_12Acut.nc

# (c) 無限大 cutoff の MD
sander -O -i md_nocut.in -o md_nocut.out \
    -p $PARM -c min.ncrst -r md_nocut.ncrst -x md_nocut.nc

cd ..
```

---

### Step 03 — GB 暗黙溶媒 MD

詳しい解説: [`solutions/03_implicit_solvent/README.md`](../solutions/03_implicit_solvent/README.md)

```bash
mkdir -p 03_implicit_solvent && cd 03_implicit_solvent
cp ../../solutions/03_implicit_solvent/*.in .

PARM=../01_setup/polyAT_vac.prmtop   # GB は水なしの prmtop で OK
INIT=../01_setup/polyAT_vac.rst7

sander -O -i min.in -o min.out -p $PARM -c $INIT -r min.ncrst
sander -O -i md.in  -o md.out  -p $PARM -c min.ncrst -r md.ncrst -x md.nc

cd ..
```

---

### Step 04 — 明示溶媒 4 段階 MD

詳しい解説: [`solutions/04_explicit_solvent/README.md`](../solutions/04_explicit_solvent/README.md)

> ⚠️ このステップが最も時間がかかります (CPU で 1 時間程度)。

```bash
mkdir -p 04_explicit_solvent && cd 04_explicit_solvent
cp ../../solutions/04_explicit_solvent/*.in .

PARM=../01_setup/polyAT_wat.prmtop
INIT=../01_setup/polyAT_wat.rst7

# Stage 1: 溶媒だけ最小化 (DNA 拘束)
sander -O -i min1.in -o min1.out \
    -p $PARM -c $INIT -r min1.ncrst -ref $INIT

# Stage 2: 全系最小化
sander -O -i min2.in -o min2.out \
    -p $PARM -c min1.ncrst -r min2.ncrst

# Stage 3: 0→300 K 加熱 (DNA に弱い拘束)
sander -O -i heat.in -o heat.out \
    -p $PARM -c min2.ncrst -r heat.ncrst -x heat.nc \
    -ref min2.ncrst

# Stage 4: NPT 本番 MD
sander -O -i prod.in -o prod.out \
    -p $PARM -c heat.ncrst -r prod.ncrst -x prod.nc

cd ..
```

---

### Step 05 — 3 つの結果を比較

詳しい解説: [`solutions/05_analysis/README.md`](../solutions/05_analysis/README.md)

```bash
mkdir -p 05_analysis && cd 05_analysis
cp ../../solutions/05_analysis/*.cpptraj .
cp ../../solutions/05_analysis/plot.sh .

# (a) RMSD 計算
cpptraj -p ../01_setup/polyAT_vac.prmtop -i rmsd_vacuum.cpptraj
cpptraj -p ../01_setup/polyAT_vac.prmtop -i rmsd_gb.cpptraj
cpptraj -p ../01_setup/polyAT_wat.prmtop -i rmsd_explicit.cpptraj

# (b) 温度・密度等のサマリ生成
bash plot.sh

# (c) 4 系列を重ねたプロット
gnuplot -p -e 'set xlabel "time [ps]"; set ylabel "RMSD [A]"; \
  plot "vac_12Acut.rms" w l t "vacuum 12A cut", \
       "vac_nocut.rms"  w l t "vacuum no cut", \
       "gb.rms"         w l t "GB implicit", \
       "explicit.rms"   w l t "TIP3P explicit"'

cd ..
```

---

## 期待される最終形

```
workspace/
├── 01_setup/           polyAT_vac/cio/wat.{prmtop,rst7}, nuc.pdb
├── 02_vacuum_md/       min.*, md_12Acut.*, md_nocut.*
├── 03_implicit_solvent/ min.*, md.*
├── 04_explicit_solvent/ min1/2.*, heat.*, prod.*
└── 05_analysis/        *.rms, summary_*, plot 出力
```

巨大ファイル (`*.parm7`, `*.nc`, `*.out` 等) はプロジェクトルートの `.gitignore` で除外済みです。

---

## やり直しのコツ

- 特定のステップだけやり直したい → そのフォルダを `rm -rf` して再実行
- 全部やり直したい → `rm -rf 0?_*` で workspace 直下のステップフォルダを全消去

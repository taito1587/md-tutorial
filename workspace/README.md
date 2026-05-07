# Workspace — ここで実際に手を動かす

このディレクトリは **学習者が AMBER チュートリアル 0 を自分の手で実行する作業エリア** です。各ステップで生成される入出力ファイルがここに溜まっていきます。

詰まったら [`solutions/`](../solutions/) を「答え」として参照してください。

---

## 前提

ルートの [README](../README.md) に従って、すでに

1. Nix をインストール済み
2. `nix develop` でシェルに入っている (プロンプト先頭で `sander -h` が通ること)

を満たしてください。

---

## 全体フロー (5 ステップ)

```
01_setup        → tleap で系を作る            → diala.parm7, diala.rst7
02_minimization → エネルギー最小化            → 01_Min.ncrst
03_heating      → 0 K → 300 K に加熱 (20 ps)  → 02_Heat.{ncrst,nc}
04_production   → 本番 MD (10 ns, NPT)        → 03_Prod.{ncrst,nc}
05_analysis     → 温度・密度・RMSD のプロット → summary.*, 02_03.rms
```

各ステップは **直前のステップの出力**を入力として使うので、順番に進めます。

---

## ハンズオン手順

### Step 01 — System setup

詳しい解説: [`solutions/01_setup/README.md`](../solutions/01_setup/README.md)

```bash
# このリポジトリのルートにいる前提
cd workspace
mkdir -p 01_setup && cd 01_setup

# 解答スクリプトをコピー (もしくは中身を見ながら自分で書く)
cp ../../solutions/01_setup/build.leap.in .

# tleap を実行
tleap -f build.leap.in

# 出力確認
ls -lh        # diala.parm7 と diala.rst7 ができているはず

cd ..
```

---

### Step 02 — Energy minimization

詳しい解説: [`solutions/02_minimization/README.md`](../solutions/02_minimization/README.md)

```bash
mkdir -p 02_minimization && cd 02_minimization
cp ../../solutions/02_minimization/01_Min.in .

sander -O \
    -i 01_Min.in \
    -o 01_Min.out \
    -p ../01_setup/diala.parm7 \
    -c ../01_setup/diala.rst7 \
    -r 01_Min.ncrst \
    -inf 01_Min.mdinfo

# エネルギーが下がっていることを確認
grep -A3 "FINAL RESULTS" 01_Min.out

cd ..
```

---

### Step 03 — Heating (0 K → 300 K, 20 ps)

詳しい解説: [`solutions/03_heating/README.md`](../solutions/03_heating/README.md)

```bash
mkdir -p 03_heating && cd 03_heating
cp ../../solutions/03_heating/02_Heat.in .

sander -O \
    -i 02_Heat.in \
    -o 02_Heat.out \
    -p ../01_setup/diala.parm7 \
    -c ../02_minimization/01_Min.ncrst \
    -r 02_Heat.ncrst \
    -x 02_Heat.nc \
    -inf 02_Heat.mdinfo

# 最後の数ステップで温度が ~300 K になっていることを確認
grep "TEMP(K)" 02_Heat.out | tail -5

cd ..
```

---

### Step 04 — Production MD (10 ns)

詳しい解説: [`solutions/04_production/README.md`](../solutions/04_production/README.md)

> ⚠️ このステップが**一番時間がかかります** (CPU で数時間)。  
> まずは動作確認として `03_Prod.in` の `nstlim = 5000000` を `nstlim = 500000` (= 1 ns) に書き換えるのがおすすめ。

```bash
mkdir -p 04_production && cd 04_production
cp ../../solutions/04_production/03_Prod.in .

# 短縮したい場合は今ここで 03_Prod.in を編集する
# (例) sed -i.bak 's/nstlim   = 5000000/nstlim   = 500000/' 03_Prod.in

pmemd -O \
    -i 03_Prod.in \
    -o 03_Prod.out \
    -p ../01_setup/diala.parm7 \
    -c ../03_heating/02_Heat.ncrst \
    -r 03_Prod.ncrst \
    -x 03_Prod.nc \
    -inf 03_Prod.mdinfo &

# 進捗を眺めるなら
tail -f 03_Prod.out
# or
cat 03_Prod.mdinfo

cd ..
```

---

### Step 05 — Analysis (プロット)

詳しい解説: [`solutions/05_analysis/README.md`](../solutions/05_analysis/README.md)

```bash
mkdir -p 05_analysis && cd 05_analysis
cp ../../solutions/05_analysis/plot.sh .
cp ../../solutions/05_analysis/rmsd.cpptraj .

# (a) 温度・密度・エネルギーの summary.* を生成
bash plot.sh

# (b) RMSD を計算 (トポロジーは -p で渡す)
cpptraj -p ../01_setup/diala.parm7 -i rmsd.cpptraj

# (c) gnuplot でプロット (-p はウィンドウを閉じても残すオプション)
gnuplot -p -e 'set xlabel "step"; set ylabel "T [K]"; plot "summary.TEMP" with lines'
gnuplot -p -e 'set xlabel "step"; set ylabel "rho [g/cc]"; plot "summary.DENSITY" with lines'
gnuplot -p -e 'set xlabel "time [ps]"; set ylabel "RMSD [A]"; plot "02_03.rms" with lines'

cd ..
```

---

## ディレクトリの最終形

すべてのステップが終わると、`workspace/` 以下はこんな構造になっています:

```
workspace/
├── README.md
├── 01_setup/
│   ├── build.leap.in
│   ├── diala.parm7
│   ├── diala.rst7
│   └── leap.log
├── 02_minimization/
│   ├── 01_Min.in
│   ├── 01_Min.out
│   └── 01_Min.ncrst
├── 03_heating/
│   ├── 02_Heat.in
│   ├── 02_Heat.out
│   ├── 02_Heat.nc
│   └── 02_Heat.ncrst
├── 04_production/
│   ├── 03_Prod.in
│   ├── 03_Prod.out
│   ├── 03_Prod.nc
│   └── 03_Prod.ncrst
└── 05_analysis/
    ├── plot.sh
    ├── rmsd.cpptraj
    ├── summary.TEMP
    ├── summary.DENSITY
    ├── summary.ETOT
    ├── ...
    └── 02_03.rms
```

`*.parm7`, `*.rst7`, `*.nc`, `*.out`, `summary.*` は `.gitignore` に入れているので、誤ってリポジトリに巨大ファイルをコミットすることはありません。

---

## やり直しのコツ

- **特定のステップだけやり直したい**: そのステップのディレクトリを丸ごと消して再実行
- **全部最初からやり直したい**: `rm -rf 0?_*` で `workspace/` 直下のステップディレクトリを全部消す

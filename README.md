# AMBER MD チュートリアル ハンズオン教材

[AMBER の公式 basic チュートリアル](https://ambermd.org/tutorials/) を、**前提知識ゼロでも手を動かしながら理解できる**ように再構成した日本語教材です。各章は AMBER 公式の Tutorial に対応していて、この 1 つのリポジトリ + 1 つの環境で全章を順に学習できます。

> **対象**: 分子動力学 (Molecular Dynamics, MD) 計算をこれから始める人。Linux/Mac のターミナル操作が少しできれば OK。AMBER も Nix も初めてで構いません。

> 📚 **本編に入る前に必ず読む 2 つ**:
> - **[PRIMER.md](PRIMER.md)** — MD とは何か、全章を通じて何が起きるかの大枠 (15 分)
> - **[GLOSSARY.md](GLOSSARY.md)** — 出てくる専門用語の解説 (随時参照)

---

## 章の一覧

| 章 | 元のチュートリアル | 題材 | 何を学ぶか |
|---|---|---|---|
| **[01 — アラニンジペプチド](01_SimpleSimulationofAlanineDipeptide/)** | [Tutorial 0](https://ambermd.org/tutorials/basic/tutorial0/index.php) | アミノ酸 1 個 (ALA) を水中で MD | **MD の最も基本的なパイプライン** (準備→最小化→加熱→本番→解析) |
| **[02 — DNA polyA-polyT decamer](02_SimulatingaDNApolyA-polyTDecamer/)** | [Tutorial 1](https://ambermd.org/tutorials/basic/tutorial1/index.php) | 10 塩基対の DNA 二重鎖 | **核酸の MD**、真空 / 暗黙溶媒 / 明示溶媒の比較、カウンターイオン処理 |

各章の詳細は対応するフォルダの `README.md` を参照してください。

---

## 進め方の概要

```
1. Nix をインストール (初回だけ)
2. このリポジトリをクローン
3. ルートで `nix develop` を 1 回打つ ← これで全章で使う環境が整う
4. PRIMER.md を読んで全体像を掴む
5. 01_*/ から順に進める (各章の README に従う)
6. 詰まったら solutions/ の同じステップを「答え」として参照する
7. 専門用語に出会ったら GLOSSARY.md を引く
```

---

## 必要なもの

### 必須

- **Nix** (パッケージマネージャ。Mac でも Linux でも動く)
- インターネット接続 (初回 `nix develop` 時に AmberTools を conda-forge からダウンロードする)
- ディスク空き容量: 5 GB 以上推奨 (環境は全章で共有するので 1 度ダウンロードで済む)

### 任意 (可視化を使いたい場合)

- **VMD** (3D 分子ビューア) — Nix/conda では扱いづらいので公式から別途インストール: <https://www.ks.uiuc.edu/Research/vmd/>

### 環境管理の仕組み (ハイブリッド構成)

AmberTools は nixpkgs に入っていないため、Nix と conda-forge を組み合わせます:

```
flake.nix  ──provides──▶  micromamba (mini conda)
                              │
                              │ reads environment.yml
                              ▼
                          conda-forge
                              │
                              │ installs into ./.mamba-env/
                              ▼
                          ambertools, gnuplot, perl
```

- ユーザー視点では **`nix develop` 1 つで完結** (中で micromamba が自動的に conda env を作る)
- 初回のみ AmberTools のダウンロードで 5-15 分かかる
- すべて `./.mamba-env/` 内に閉じ込められ、グローバル環境は汚さない
- **全章でこの 1 つの環境を共有** (3 GB を 1 回だけ)

---

## セットアップ手順

### 1. Nix のインストール

まだ Nix が入っていない場合は、[Determinate Systems インストーラ](https://install.determinate.systems/) (公式推奨の一つ) を使うのが楽です:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

インストール後、ターミナルを開き直してください。

> ⚠️ Nix をインストールすると `/nix` ディレクトリがホスト OS 直下に作られます。会社支給端末などで管理者権限が必要な場合は、システム管理者に確認してから実行してください。

### 2. このリポジトリをクローン

```bash
git clone <このリポジトリのURL>
cd <クローンしたディレクトリ名>
```

### 3. 開発シェルに入る

**プロジェクトルートで** 1 度実行すれば、全章で使えます:

```bash
nix develop
```

**初回**は次の 2 段階で時間がかかります:

1. Nix が `micromamba` 等の小物を取得 (数十秒〜数分)
2. `micromamba` が conda-forge から AmberTools をダウンロード・展開 (約 3 GB、5-15 分)

すべて `./.mamba-env/` の中に展開されるので、グローバル環境は触りません。

**2 回目以降** は `./.mamba-env/` を再利用するので数秒で起動します。

シェルに入ると `sander` `tleap` `cpptraj` `gnuplot` が使えるようになります:

```bash
sander -h    # ヘルプが出れば成功
tleap -h
```

### 4. ハンズオン開始

```bash
# 例: 章 01 を始める
cd 01_SimpleSimulationofAlanineDipeptide
cat README.md
```

各章の `README.md` の指示に沿って進めてください。各ステップで詰まったら、対応する `solutions/0X_*/` の README とファイルを答えとして見て OK です。

### 環境を作り直したいとき

```bash
exit                                  # nix develop シェルから抜ける
rm -rf .mamba-env .mamba-root         # conda env を消去
nix develop                           # 再構築 (再ダウンロード 5-15 分)
```

---

## ディレクトリ構造

```
tutorial/                   ← リポジトリのルート
├── flake.nix              # Nix 環境定義 (micromamba を提供 + 自動で conda env 構築)
├── flake.lock             # Nix inputs の正確なバージョン
├── environment.yml        # conda env 定義 (ambertools, gnuplot, perl)
├── README.md              # このファイル — 入口・セットアップ手順
├── PRIMER.md              # MD とは何か、全章を通じた大枠 (本編前に読む)
├── GLOSSARY.md            # 専門用語集 (随時引く)
├── .gitignore             # MD の出力ファイルと .mamba-env/ を除外
├── 01_SimpleSimulationofAlanineDipeptide/   # 章 01: アラニンジペプチド
│   ├── README.md                            # 章の概要
│   ├── solutions/                           # 解答例 + 詳細解説
│   │   ├── 01_setup/                        # tleap で系を構築
│   │   ├── 02_minimization/                 # エネルギー最小化
│   │   ├── 03_heating/                      # 0→300 K 加熱
│   │   ├── 04_production/                   # 本番 MD (10 ns)
│   │   └── 05_analysis/                     # RMSD・温度・密度の解析
│   └── workspace/                           # 学習者がここで手を動かす
│       └── README.md                        # ハンズオン手順
└── 02_SimulatingaDNApolyA-polyTDecamer/     # 章 02: DNA 10 塩基対
    ├── README.md
    ├── solutions/
    │   ├── 01_setup/                        # NAB + tleap で 3 系統作成
    │   ├── 02_vacuum_md/                    # 真空 MD
    │   ├── 03_implicit_solvent/             # GB 暗黙溶媒
    │   ├── 04_explicit_solvent/             # 明示溶媒 4 段階 MD
    │   └── 05_analysis/                     # 3 系統比較
    └── workspace/

# 初回 `nix develop` 後に以下が自動生成される (.gitignore 済):
# .mamba-env/   ← ambertools 等の実体が入る (~3 GB)
# .mamba-root/  ← micromamba 内部状態
```

---

## トラブルシューティング

### conda env の作成 (`micromamba create`) が失敗する

ネットワーク問題やストレージ不足が主な原因。再試行手順:

```bash
exit                                  # nix develop シェルから抜ける
rm -rf .mamba-env .mamba-root         # 失敗作を消す
nix develop                           # やり直し
```

それでもダメな場合:

1. **Docker で代用する** — AMBER 公式イメージ:
   ```bash
   docker run -it --rm -v "$(pwd)":/work -w /work ambermd/ambertools:latest bash
   ```
   この場合 Nix を使わず Docker 内で直接 `sander` 等を実行します。

2. **手動で conda 環境を作る** — Nix を経由せず:
   ```bash
   curl -L micro.mamba.pm/install.sh | bash
   micromamba create -n amber -f environment.yml
   micromamba activate amber
   ```

### `nix develop` で「command not found: nix」

Nix のインストール後、ターミナルを開き直してください。それでもダメな場合はシェルのプロファイル (`~/.zshrc` 等) に Nix の初期化スクリプトが書かれているか確認します (Determinate Systems インストーラなら自動)。

### MD が遅すぎる

各章の production 入力ファイル (`03_Prod.in` など) の `nstlim` を 1/10 や 1/100 に減らすと短時間で終わります。学習目的ならこれで十分です。

---

## ライセンス・免責

これは AMBER 公式チュートリアルを学習者向けに再構成した教材です。AMBER 本体・チュートリアル原文の権利は AMBER 開発元に帰属します。本リポジトリの解説 (README, コメント) 部分は学習目的での自由利用を想定しています。

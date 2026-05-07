# AMBER MD Tutorial 0 — ハンズオン教材

[AMBER 公式チュートリアル 0](https://ambermd.org/tutorials/basic/tutorial0/index.php) (アラニンジペプチドの簡単な MD シミュレーション) を、**前提知識ゼロでも手を動かしながら理解できる**ように再構成した教材です。

> **対象**: 分子動力学 (Molecular Dynamics, MD) 計算をこれから始める人。Linux/Mac のターミナル操作が少しできれば OK。AMBER も Nix も初めてで構いません。

> 📚 **本編に入る前に必ず読む 2 つ**:
> - **[PRIMER.md](PRIMER.md)** — MD とは何か、このチュートリアル全体で何が起きるかの大枠 (15 分)
> - **[GLOSSARY.md](GLOSSARY.md)** — 出てくる専門用語の解説 (随時参照)

---

## このリポジトリで何が学べるか

- アラニンジペプチド (アミノ酸 1 個を両端でキャップした最小のペプチド) を水中で MD シミュレーションする一連の流れ
- AMBER の中核ツール `tleap` / `sander` / `cpptraj` の使い方
- 入力ファイル (`*.in`) のパラメータが何を意味するか
- 結果 (温度・密度・RMSD) の見方

---

## 進め方の概要

```
1. Nix をインストール (初回だけ)
2. このリポジトリをクローン
3. `nix develop` で AMBER 入りのシェルに入る
4. PRIMER.md を読んで全体像を掴む
5. workspace/ に移動して README に沿って手を動かす
6. 詰まったら solutions/ の同じステップを「答え」として参照する
7. 専門用語に出会ったら GLOSSARY.md を引く
```

ステップは 5 つ:

| ステップ                                    | 何をやる                                       | 所要時間目安      |
| ------------------------------------------- | ---------------------------------------------- | ----------------- |
| [01_setup](solutions/01_setup/)             | tleap で分子を組み立てる + 水で溶かす          | 5 分              |
| [02_minimization](solutions/02_minimization/) | エネルギー最小化 (構造のひずみ取り)            | 1〜2 分           |
| [03_heating](solutions/03_heating/)         | 0 K → 300 K にゆっくり加熱 (20 ps の MD)       | 5〜10 分          |
| [04_production](solutions/04_production/)   | 300 K で本番 MD (10 ns)                        | マシン次第で数時間 |
| [05_analysis](solutions/05_analysis/)       | RMSD・温度・密度をプロット                     | 5 分              |

---

## 必要なもの

### 必須

- **Nix** (パッケージマネージャ。Mac でも Linux でも動く)
- インターネット接続 (初回 `nix develop` 時に AmberTools を conda-forge からダウンロードする)
- ディスク空き容量: 5 GB 以上推奨

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
                          ambertools, grace, perl
```

- ユーザー視点では **`nix develop` 1 つで完結** (中で micromamba が自動的に conda env を作る)
- 初回のみ AmberTools のダウンロードで 5-15 分かかる
- すべて `./.mamba-env/` 内に閉じ込められ、グローバル環境は汚さない

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
git clone <このリポジトリのURL> ando_study
cd ando_study
```

### 3. 開発シェルに入る

```bash
nix develop
```

**初回**は次の 2 段階で時間がかかります:

1. Nix が `micromamba` 等の小物を取得 (数十秒〜数分)
2. `micromamba` が conda-forge から AmberTools をダウンロード・展開 (約 3 GB、5〜15 分)

すべて `./.mamba-env/` の中に展開されるので、グローバル環境は触りません。

**2 回目以降** は `./.mamba-env/` を再利用するので数秒で起動します。

シェルに入ると `sander` `tleap` `cpptraj` `gnuplot` が使えるようになります:

```bash
sander -h    # ヘルプが出れば成功
tleap -h
```

### 環境を作り直したいとき

```bash
# シェルから抜ける
exit

# conda env を消去
rm -rf .mamba-env .mamba-root

# もう一度 nix develop で再構築
nix develop
```

### 4. ハンズオン開始

```bash
cd workspace
cat README.md
```

`workspace/README.md` の指示に沿って進めてください。各ステップで詰まったら、対応する `solutions/0X_*/` の README とファイルを答えとして見て OK です。

---

## ディレクトリ構造

```
ando_study/
├── flake.nix              # Nix 環境定義 (micromamba を提供 + 自動で conda env 構築)
├── flake.lock             # Nix inputs の正確なバージョン
├── environment.yml        # conda env 定義 (ambertools, grace, perl)
├── README.md              # このファイル — 入口・セットアップ手順
├── PRIMER.md              # MD とは何か、全体像のイントロ (本編前に読む)
├── GLOSSARY.md            # 専門用語集 (随時引く)
├── .gitignore             # MD の出力ファイルと .mamba-env/ を除外
├── solutions/             # ★答え★ (コピペで動く完成形 + 詳細解説)
│   ├── 01_setup/          # tleap で系を構築
│   ├── 02_minimization/   # エネルギー最小化
│   ├── 03_heating/        # 0 → 300 K 加熱
│   ├── 04_production/     # 本番 MD (10 ns)
│   └── 05_analysis/       # RMSD・温度・密度の解析
└── workspace/             # 学習者がここで実際に手を動かす場所
    └── README.md          # ハンズオン手順

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

`solutions/04_production/03_Prod.in` の `nstlim=5000000` (= 10 ns) を `nstlim=500000` (= 1 ns) に減らすと短時間で終わります。学習目的ならこれで十分です。

---

## 本リポジトリと公式チュートリアルの差分

本リポジトリは [AMBER 公式チュートリアル 0](https://ambermd.org/tutorials/basic/tutorial0/index.php) の内容を学習者向けに再構成したもので、以下の点で公式と異なります:

| 項目 | 公式 | 本リポジトリ |
|------|------|------------|
| インストール | 各自で AMBER をビルド | Nix + micromamba で自動化 |
| ファイル命名 | `parm7`, `rst7` (拡張子なし) | `diala.parm7`, `diala.rst7` |
| ディレクトリ構成 | フラット | ステップ別 (`01_setup/`, `02_minimization/`, ...) |
| Production MD エンジン | `pmemd` | `pmemd` (代替で `sander` も可) |
| 解説 | 英語、簡潔 | 日本語、詳細 |
| `barostat=1`, `ntpr=100`, `ntwx=100` 等 | 同じ (公式に倣う) | 同じ |
| RMSD 解析 (`mass`, `:2`, `time 2.0`) | 同じ | 同じ |

中身の物理 (力場・パラメータ) は公式と同じなので、結果も実質同等になります。

---

## ライセンス・免責

これは AMBER 公式チュートリアル 0 を学習者向けに再構成した教材です。AMBER 本体・チュートリアル原文の権利は AMBER 開発元に帰属します。本リポジトリの解説 (README, コメント) 部分は学習目的での自由利用を想定しています。

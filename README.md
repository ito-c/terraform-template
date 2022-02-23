# terraform-template

## 概要

elb - public - private の汎用的な AWS 構成を terraform で作成しています。

## 使い方

### 準備

- terraform 用 IAM ユーザーの作成
- アクセスキーの払い出し
  - `~/.aws/credentials`に terraform 用アカウントのプロファイルを作成
- direnv の導入
  - 各ディレクトリで`.envrc`を使用してプロファイルを読み込む
  ```bash
  # .envrc
  export AWS_PROFILE=hogehoge
  export AWS_REGION=ap-northeast-1
  ```
- `.envrc`については、グローバルな`gitignore`対象を推奨します

### terraform 実行

- apply 時の影響範囲、変更可能性、RDS や S3 のステートフルな性質を考慮し、各リソースで実行ファイルを分割しています
  - そのため、各リソースディレクトリ内で init から apply までを行います
- tfstate はリモートで S3 に格納しています
  - `tfstate-terraform-template`バケットが存在しない場合、aws-cli から作成します
  ```bash
  $ aws s3api create-bucket --bucket tfstate-terraform-template \
  --create-bucket-configuration LocationConstraint=ap-northeast-1
  ```
  - 同バケットについて、バージョニング、暗号化(SSE-S3)、ブロックパブリックアクセスを設定します

```bash
$ cd network

$ terraform init
$ terraform plan
$ terraform apply
```

```bash
$ cd s3

$ terraform init
$ terraform plan
$ terraform apply
```

```bash
$ cd ec2

$ terraform init
$ terraform plan
$ terraform apply
```

```bash
$ cd rds

$ terraform init
$ terraform plan
$ terraform apply
```

```bash
$ cd alb

$ terraform init
$ terraform plan
$ terraform apply
```

### モジュールについて

- セキュリティグループと IAM についてはモジュール化しています
- variable については、各モジュールディレクトリの`variables.tf`を参照してください

### tag について

- tag は以下の 5 つで分類しています
  - Name
  - Environment
  - ProjectName
  - ResourceName
  - Tool

# Azure マネージド ID サンプルコード

## 概要

何らかのデータを Functions を経由して Cosmos DB に保管・取得するアプリとインフラのコードのサンプルです。

データは id と category の値を持ちます。
category は Cosmos DB 上のパーティションキーとして設定しますので、一定の法則で値が入ると良いことがありそうですね。

Functions の認証は Functions の webbook の API キーを利用します。

## Terraform について

Terraform v1.2.5 で検証しています。
Azure CLI にて構築先の Azure 環境に接続してから terraform を実行してください。

```
az login -t <構築先AzureテナントID>
az account set -s <構築先AzureサブスクリプションID>
terraform init
terraform apply
```

`terraform apply` が成功すると、Outputs として構築された Functions の名前が出力されます。

(XXXXXX はランダムな英数字、NNNNN はランダムな数字)

```
Apply complete! Resources: N added, 0 changed, 0 destroyed.

Outputs:

functions_name = "func-XXXXXX-prod-japaneast-NNNNN"
```

この Functions 名がアプリのデプロイ時に必要となります。

構築される Azure リソースについては、下記の命名規則を尊重しています。

https://docs.microsoft.com/ja-jp/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

Workload/Application にあたる文字列と Instance にあたる数値は上述のようにランダムな値が設定されるようになっています。
実際に使う場合は固定文字列にする等、調整すると良いと思います。

## アプリについて

アプリは C#での実装です。

ポイントとしては、マネージド ID を使用して Cosmos DB にアクセスしていることです。

このリポジトリの terraform を用いて構築した場合、Functions のシステム割り当てマネージド ID が Cosmos DB のデータにアクセスできるように権限設定が実施されます。

このため `DefaultAzureCredential` で取得されるマネージド ID のクレデンシャルを用いて Cosmos DB へのアクセスが可能です。

アプリのデプロイは [Azure Functions Core Tools](https://docs.microsoft.com/ja-jp/azure/azure-functions/functions-run-local?tabs=v4%2Cwindows%2Ccsharp%2Cportal%2Cbash#install-the-azure-functions-core-tools) の使用を想定しています。
ツールをインストール後、下記を実行してください。

```
cd applications/DataApis/DataApis
func azure functionapp publish func-XXXXXX-prod-japaneast-NNNNN
```

## アプリの動作確認

Postman 等を使用して動作を確認できます。

### データの登録(上書き)

- URL
  - https://func-XXXXXX-prod-japaneast-NNNNN.azurewebsites.net/api/putdata
- URL パラメータ
  | 項目 | 値 |
  | ------ | ---------------------------------------------------------------------- |
  | code |Functions のホストキー(default) |
- リクエストボディ
  - `id`と`category`を持つ任意のデータ
  - Body の例
    ```json
    {
      "id": "abc123",
      "category": "test",
      "data": "aaaabbbbcccc"
    }
    ```

### データの取得

- URL
  - https://func-XXXXXX-prod-japaneast-NNNNN.azurewebsites.net/api/getdata
- URL パラメータ
  | 項目 | 値 |
  | ------ | ---------------------------------------------------------------------- |
  | code | Functions のホストキー(default) |
  | id | 取得対象の id の値 |
  | category | 取得対象の category の値 |

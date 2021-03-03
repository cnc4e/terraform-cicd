# OPA/Regoリファレンス

本リファレンスは`OPA（Open Policy Agent）`でTerraformのポリシーチェックを行う際のリファレンスです。実行等の詳細は本リファレンスでは省き、`Rego`で記述するコード部分のみを取り上げます。  

## 事前準備
Regoの実行環境が無い方は公式のプレイグラウンドを使用してください。以降は基本的にプレイグラウンドを使用している前提で解説します。プレイグラウンドには以下を入力しておいてください。  

|入力内容|入力箇所|サンプルファイル|
|-|-|-|
|ポリシーコード|プレイグラウンド左側|[サンプルファイル](../sample-repos/policy/dev/deploy.rego)|
|チェック対象のJSON|プレイグラウンド右上|[サンプルファイル]()|

チェック対象のJSONを自身で用意する場合は、以下のコマンドを使用してJSON形式のファイルを作成してください。Regoは`.tfplan`ファイルを読み込めないため、JSONに変換して使用します。  

```
terraform plan -out sample.tfplan -lock=false
terraform show -json sample.tfplan > sample.json
```

## 定義
ここではTerraformのポリシーチェックに登場する概念を確認します。

### namespace
ファイルを実行する名前空間を指定します。プレイグラウンドやconftest（Rego実行環境の1つ）ではデフォルトは`main`になっています。名前空間を分けることで、実行時の引数で複数のコードを使い分けることができます。  
ファイル先頭に以下の形で指定します。  

```
package <名前空間名>
```

### import
外部ファイルを読み込みます。プレイグラウンドで言えば右上の`INPUT`タブの内容を読み込みます。また他の実行環境では実行時の引数でファイルパスを与えることで読み込むことができます。  
以下の形で指定します。`input`は`data`でも構いませんが、それ以外の指定はできません。

```
import input
```

`input`以外の名称で使用したい場合は、`as` 句を使用して別名に変更することが可能です。以下の例では読み込んだ内容を`tfplan`というグローバル変数に割り当てています。  

```
import input as tfplan
```

（参考）読み込み時点で内容をトリミングすることもできます。トリミングはJSONパスを指定します。

```
import input.terraform_version as tfplan
```

### 変数
ルール外で宣言する変数とルール内で宣言する変数が存在します。前者はコード全体、後者はルール内がスコープです。どちらも`=`または`:=`で宣言することができます。`=`は変数が未割り当てであれば変数宣言として働き、割り当て済みであれば比較として働きます。変数宣言以外の挙動を想定しない場合は`:=`を使用するのが無難です。

以下の形で宣言します。  

```
ec2_instance_type := "t2.micro"
```

### ルール
定義したルールはすべて実行されます。戻り値を明示的に指定する場合はルール内で宣言した変数を指定します。戻り値を明示的に指定しない場合は`true`、または`undefined`が返されます。

- 戻り値を明示的に指定するルール。`1`が返される
```
rule[return] {
  x := 1
  x == 1

  return := x
}
```

- 戻り値を明示的に指定しないルール。`true`が返される
```
rule {
  x := 1
  x == 1
}
```

### 反復処理と比較
読み込んだJSONオブジェクトが以下のような配列である場合、反復処理を行うことができます。  

```
"resource_changes": [
    {
        "address": "module.deployed_instance.aws_instance.deployed_instance",
        "module_address": "module.deployed_instance"
    },
    {
        "address": "module.deployed_instance.aws_security_group.deployed_instance",
        "module_address": "module.deployed_instance"
    }
]

```

反復処理は配列のオブジェクトに対して`[_]`を使用することで可能です。また、この際比較子である`==`を使用することで配列に対してフィルターのような働きをさせることができます。  
反復処理と比較を使用する場合、以下のようなルールになります。

```
violation_ec2_instance_type[reason] {
    r := tfplan.resource_changes[_]
    r.mode == "managed"
    r.type == "aws_instance"
    not r.change.after.instance_type == ec2_instance_type

    reason := sprintf(
      "%-40s :: instance type %q is not allowed",
      [r.address, r.change.after.instance_type]
    )
}
```
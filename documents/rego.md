# OPA/Regoリファレンス

本リファレンスは`OPA（Open Policy Agent）`でTerraformのポリシーチェックを行う際のリファレンスです。実行等の詳細は本リファレンスでは省き、`Rego`で記述するコード部分のみを取り上げます。  

## 事前準備
Regoの実行環境が無い方は公式のプレイグラウンドを使用してください。以降は基本的にプレイグラウンドを使用している前提で解説します。プレイグラウンドには以下を入力しておいてください。  

|入力内容|入力箇所|サンプルファイル|
|-|-|-|
|ポリシーコード|プレイグラウンド左側|[サンプルファイル](../sample-repos/policy/production/deploy.rego)|
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
ec2_instance_type := "t2.large"
```

### 比較
`==`を使用して左辺と右辺の比較を行うことができます。条件を満たしていれば`true`、満たしていなければ`undefined`が返されます。なお左辺と右辺の型は同一である必要があります。型を調べる場合は`type_name()`functionを使用してください。  
`!=`または`not A == B`で条件を満たしていれば`undefined`、満たしていなければ`true`を返させることもできます。    

実際の使用例は次項の[ルール](#ルール)で示します。

### ルール
定義したルールはすべて実行されます。戻り値を明示的に指定する場合はルール内で宣言した変数を指定します。戻り値を明示的に指定しない場合は`true`が返されます。どちらの場合でもルールブロック内で`true`にならない条件式があった場合、ルールの戻り値は`undefined`になります。

- 戻り値を明示的に指定するルール。ここでは条件を満たしているため`1`が返される
```
rule[return] {
    x := 1
    x == 1
  
    return := x
}
```

- 戻り値を明示的に指定しないルール。ここでは条件を満たしているため`true`が返される
```
rule {
    x := 1
    x == 1
}
```

- 戻り値を明示的に指定するルール。ここでは条件を満たしているが、`not`を使用しているため`undefined`が返される
```
rule[return] {
    x := 1
    not x == 1
  
    return := x
}
```

### function
ルールは定義したものがすべて実行されますが、functionは呼び出し元がなければ実行されません。実行時に引数を取ることができます。戻り値を明示的に指定する場合はルール内で宣言した変数を指定します。戻り値を明示的に指定しない場合は`true`が返されます。どちらの場合でもfunctionブロック内で`true`にならない条件式があった場合、functionの戻り値は`undefined`になります。

- 戻り値を明示的に指定するfunction。ここでは`function_a`は`2`が返される
```
rule_a[return] {
    x := 1
    function_a(x) == 2
  
    return := x
}

function_a(x) = y {
    y := x + 1
}
```

- 戻り値を明示的に指定しないfunction。ここでは`function_b`は`true`が返される
```
rule_b[return] {
    x := 1
    function_b(x) == true
  
    return := x
}

function_b(x) {
    x == 1
}
```

- 戻り値を明示的に指定するfunction。ここでは`function_c`は`undefined`が返される。`rule_c`も`undefined`を返すことになる。
```
rule_c[return] {
    x := 1
    function_c(x) == 2
  
    return := x
}

function_c(x) = y {
    x != 1
    y := x + 1
}
```


### 反復処理
読み込んだJSONオブジェクトが以下のような`配列`である場合、`反復処理`として配列内のすべてのオブジェクトに対して処理を行うことができます。

```
"resource_changes": [
    {
        "address": "module.deployed_instance.aws_instance.deployed_instance",
        "module_address": "module.deployed_instance",
        "type": "aws_instance"
    },
    {
        "address": "module.deployed_instance.aws_security_group.deployed_instance",
        "module_address": "module.deployed_instance",
        "type": "aws_security_group"
    }
]

```

反復処理は配列のオブジェクトに対して`[_]`を付与することで可能です。`[_]`が宣言された以降のコードは、配列内のすべてのオブジェクトに対して処理を行うコードになります。  
また、この際比較子である`==`を使用することで配列に対してフィルターのような働きをさせることができます。比較結果が`true`であるものはそのまま処理され、`undefined`であるものは処理されないためです。  
反復処理と比較を使用する場合、以下のようなルールになります。

```
rule_example_ec2_instance[r] {
    r := tfplan.resource_changes[_]
    r.type == "aws_instance"
}
```

このルールでは配列である`resource_changes`内のすべてのオブジェクトに対して比較処理が実行され、`type`が`aws_instance`であるものが残るため、以下のようなオブジェクトが返されます。

```
{
    "address": "module.deployed_instance.aws_instance.deployed_instance",
    "module_address": "module.deployed_instance",
    "type": "aws_instance"
}
```

### 書式指定子
`sprintf()`functionを利用して標準出力にメッセージを表示する際、コード内の変数を埋め込むことができます。この際の書式指定子の仕様はGo言語の仕様に似ています。型が不明、型指定が不要な場合は`%v`を指定してください。  
例えば以下のような書式指定子があります。  

|書式指定子|型|備考|
|-|-|-|
|%v|不定||
|%s|string|`%-40s`等でスライス可能|
|%q|string|クォーテーション付き出力|
|%d|number||

以下のような指定が可能です。

```
ec2_instance_type = "t2.large"

write_output[message]{
    message := sprintf("%v is large", [ec2_instance_type])
}

```


他にも色々な定義を行うことができますが、少なくともこれらの定義を理解すればTerraformのポリシーチェックを書くことができると思います。次項ではポリシーの例を見ていきます。  

## ポリシーチェック
変数として予め宣言したポリシーの値と、チェックする対象の値を比較してポリシーチェックを行います。どうやってチェックする対象の値に辿り着くかという部分が肝です。  

[ルール](#ルール)の項で、条件式がすべて`true`の場合に指定した戻り値が返されると解説しました。ここではポリシーに反していたら標準出力にメッセージを表示するようにするため、「ポリシーに反していること」も含めて条件式の結果はすべて`true`にします。「ポリシーに反していること」の条件式は、「ポリシーに合致していること」を`not`で否定することで書けます。  

### 配列が登場する場合
ポリシー側が単一の値、チェックする対象が配列内にある場合、反復処理と比較を利用してチェックすることができます。EC2インスタンスタイプをチェックするルールをベースに解説します。  

**コード**
```
package main
import input as tfplan
 
# Policies
ec2_instance_type = "t2.large"

# Rules
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

ルールブロックで、反復処理と比較で`managed`かつ`aws_instance`のオブジェクトを取得し、その中のインスタンスタイプをポリシーと比較します。「ポリシーに反していること」の条件式は、「ポリシーに合致していること」を`not`で否定することで書けます。この条件式が`true`、つまりポリシーに反している場合は`reason`の変数宣言へ移行し、`sprintf`という標準出力にメッセージを表示するfunctionを戻り値として返します。  
配列が登場する場合の値はこのようにチェックできます。  

### 配列が複数登場する場合
ポリシー側が単一の値、チェックする対象が配列内のさらに配列内にある場合、反復処理と比較を複数回行うことでチェックすることができます。EBSボリュームサイズをチェックするルールをベースに解説します。  

**コード**
```
package main
import input as tfplan
 
# Policies
ec2_root_block_volume_size = 30

# Rules
violation_ec2_root_block_volume_size[reason] {
    r := tfplan.resource_changes[_]
    r.mode == "managed"
    r.type == "aws_instance"
    root_block_device = r.change.after.root_block_device[_]
    not root_block_device.volume_size == ec2_root_block_volume_size

    reason := sprintf(
      "%-40s :: instance volume %d is exceeded",
      [r.address, root_block_device.volume_size]
    )
}
```

[EC2インスタンスタイプをチェックする](#ec2インスタンスタイプをチェックする)と同様、`managed`かつ`aws_instance`のオブジェクトを取得します。ただしEBSボリュームサイズはさらに配列が存在します。この時点では以下のようなオブジェクトです。（一部抜粋）  

```
{
    "address": "module.deployed_instance.aws_instance.deployed_instance",
    "module_address": "module.deployed_instance",
    "mode": "managed",
    "type": "aws_instance",
    "change": {
        "after": {
            "root_block_device": [
                {
                    "delete_on_termination": true,
                    "volume_size": 30
                }
            ]
        }
    }
}
```

`root_block_device`が配列になっています。そのため再度反復処理を行うため、`r.change.after.root_block_device[_]`を変数宣言してその中の値を比較します。`root_block_device`配列内に複数オブジェクトが存在していてもすべてチェックされます。  
配列が複数登場する場合の値はこのようにチェックできます。  

### ポリシー側が配列である場合
ポリシー側が配列、チェックする対象も配列の場合、自作functionを利用して値をチェックする方法があります。セキュリティグループのインバウンドポートをチェックするルールをベースに解説します。  

**コード**
```
package main
import input as tfplan
 
# Parameters
sg_ingress_port := [22,80,443]

# Rules
violation_sg_ingress_port[reason] {
    r := tfplan.resource_changes[_]
    r.mode == "managed"
    r.type == "aws_security_group_rule"
    r.name == "ingress"
    not array_contains(sg_ingress_port, r.change.after.from_port)
    not array_contains(sg_ingress_port, r.change.after.to_port)

    reason := sprintf(
      "%-40s :: ingress port '%d' is not allowed",
      [r.address, r.change.after.from_port]
    )
}

# Support functions
array_contains(arr, elem) {
  arr[_] == elem
}
```

反復処理と比較で`managed`、`aws_security_group_rule`かつ`ingress`のオブジェクトを取得します。ポリシー側が配列であるため、そのままでは比較できません。そのため自作functionである`array_contains`にポリシー配列とチェックする対象の値を渡し、ポリシー配列の中にチェックする対象があるかどうかを比較します。このfunctionはチェックする対象があれば`true`、なければ`undefined`を返します。ルールブロックの最初で反復処理（`[_]`）を宣言しているため、functionもオブジェクトの個数だけ呼び出されます。  
ポリシー側が配列の場合はこのようにチェックできます。


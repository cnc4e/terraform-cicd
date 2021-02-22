# 使い方

以下の順番で各モジュールを実行します。環境構築の`ネットワーク`は自身の環境に合わせて実行要否を判断してください。環境構築の`Githubレポジトリの準備`と、サービス構築の`Githubへのソース配置`、`サービスデプロイ`はTerraformモジュールの実行ではなく、Githubのレポジトリに対する作業になります。サービス構築はサービスごとに実行してください。

- 環境構築
  - tfバックエンド
  - ネットワーク（任意）
  - Githubレポジトリの準備
  - Github Runner
- サービス構築
  - Githubへのソース配置
  - サービスデプロイ

まずは本レポジトリを任意の場所でクローンしてください。なお、以降の手順では任意のディレクトリのパスを`$CLONEDIR`環境変数として進めます。

``` sh
export CLONEDIR=`pwd`
git clone https://github.com/cnc4e/terraform-cicd.git
```

## 環境構築

環境構築はプロジェクトで一度だけ行います。環境の分け方によっては複数実施するかもしれません。`main-template`ディレクトリをコピーして`環境名`ディレクトリなどの作成がオススメです。以下の手順では`tf-cicd`という環境名を想定して記載します。

``` sh
cd $CLONEDIR/terraform-cicd/terraform/environment
export PJNAME=tf-cicd
cp -r main-template $PJNAME
```

また、すべてのモジュールで共通して設定する`PJ-NAME`、`REGION`、`OWNER`の値はsedで置換しておくと後の手順が楽です。regionは他の手順でも使用するので環境変数にしておきます。以下の手順では`us-east-2`を設定します。

**Linuxの場合**

``` sh
cd $CLONEDIR/terraform-cicd/terraform/environment/$PJNAME
export REGION=us-east-2
find ./ -type f -exec grep -l 'REGION' {} \; | xargs sed -i -e 's:REGION:'$REGION':g'
find ./ -type f -exec grep -l 'PJ-NAME' {} \; | xargs sed -i -e 's:PJ-NAME:'$PJNAME':g'
find ./ -type f -exec grep -l 'OWNER' {} \; | xargs sed -i -e 's:OWNER:nobody:g'
```

**macの場合**

``` sh
cd $CLONEDIR/terraform-cicd/terraform/environment/$PJNAME
export REGION=us-east-2
find ./ -type f -exec grep -l 'REGION' {} \; | xargs sed -i "" -e 's:REGION:'$REGION':g'
find ./ -type f -exec grep -l 'PJ-NAME' {} \; | xargs sed -i "" -e 's:PJ-NAME:'$PJNAME':g'
find ./ -type f -exec grep -l 'OWNER' {} \; | xargs sed -i "" -e 's:OWNER:nobody:g'
```

### tfバックエンド

Terraformのtfstateを保存するバックエンドを作成します。

tfバックエンドモジュールのディレクトリへ移動します。

``` sh
cd $CLONEDIR/terraform-cicd/terraform/environment/$PJNAME/tf-backend
```

以下コマンドでリソースを作成します。

``` sh
terraform init
terraform apply
> yes
```

なお、以降の手順で作成するリソースの情報は上記手順で作成したS3バケットに保存されます。しかし、このモジュールで作成したS3やDynamoDBの情報は実行したディレクトリのtfstateファイルに保存されます。このtfstateファイルは削除しないようにしましょう。

**作成後のイメージ**

![](./images/use-backend.svg)

### ネットワーク

すでにVPCやサブネットがある場合、ネットワークのモジュールは実行しなくても良いです。その場合はVPCとサブネットのIDを確認し以降のモジュール内の`data.terraform_remote_state.network~`で定義している部分をハードコードで書き換えてください。ネットワークモジュールでVPCやサブネットを作成する場合は以下の手順で作成します。

ネットワークモジュールのディレクトリへ移動します。

``` sh
cd $CLONEDIR/terraform-cicd/terraform/environment/$PJNAME/network
```

`network.tf`を編集します。`locals`配下のパラメータを修正します。VPCやサブネットのCIDRは自身の環境にあわせて任意のアドレス帯に修正してください。

修正したら以下コマンドでリソースを作成します。

``` sh
terraform init
terraform apply
> yes
```

**作成後のイメージ**

![](./images/use-network.svg)


### Githubレポジトリの準備
Githubにログインし、レポジトリを作成します。なお、Githubへのサインアップは済んでいるものとします。  
- メニューバー右の[+マーク] - [New repository]をクリックし、新規レポジトリ作成画面に移動します。
- 新規レポジトリ作成画面では以下を入力し、`Create repository`をクリックしてください。特にVisiblityは必ず`Private`を選択してください。
  - レポジトリ名
  - レポジトリのVisiblity Private

TerraformのバックエンドとしてS3を使用するため、GithubのSecretsにAWSの認証情報を登録します。
- レポジトリトップ画面から[Settings] - [Secrets] - [New repository secret]を順にクリックします。
- 以下の2つのsecretを作成します。

|Name|Value|
|-|-|
|AWS_ACCESS_KEY_ID|バックエンドを作成したユーザのAWSアクセスキー|
|AWS_SECRET_ACCESS_KEY|バックエンドを作成したユーザのAWSシークレットキー|
  

セルフホストランナーに与えるトークンを確認します。
- レポジトリトップ画面から[Settings] - [Actions] - [Self-hosted runner] - [Add runner]を順にクリックします。
- [Configure]コードブロック内で以下のようなコマンドを探します。
  - `./config.cmd --url https://github.com/<ユーザ名>/<レポジトリ名> --token <レジストレーショントークン>`
- `--url`の値と`--token`の値を控えてください。次の手順で使用します。

### Github Runner

Github Runnerサーバモジュールのディレクトリへ移動します。

``` sh
cd $CLONEDIR/terraform-cicd/terraform/environment/$PJNAME/gitlab-runner
```

`github-runner.tf`を編集します。`region`と`locals`配下のパラメータを修正します。とくにec2_github_urlとec2_registration_tokenを`Githubレポジトリの準備`で確認した値に必ず修正してください。

**Linuxの場合**

``` sh
# ↓sedで置換する時、http:の`:`の前にエスケープを入れてください。例 https\://github.com
sed -i -e 's:GITHUB-URL:<先ほどGithubレポジトリで確認したURL>:g' github-runner.tf 
sed -i -e 's:REGIST-TOKEN:<先ほどGithubレポジトリで確認したレジストレーショントークン>:g' github-runner.tf
```

**macの場合**

``` sh
# ↓sedで置換する時、http:の`:`の前にエスケープを入れてください。例 https\://github.com
sed -i "" -e 's:GITHUB-URL:<先ほどGithubレポジトリで確認したURL>:g' github-runner.tf
sed -i "" -e 's:REGIST-TOKEN:<先ほどGithubレポジトリで確認したレジストレーショントークン>:g' github-runner.tf
```

修正したら以下コマンドでリソースを作成します。

``` sh
terraform init
terraform apply
> yes
```

上記実行が完了したらGithub側にRunnerが認識されているか確認します。

- Githubにログインし、レポジトリトップ画面から[Settings] - [Actions] - [Self-hosted runner]を確認し、作成したRunnerが表示されていれば登録完了です。表示されるまでには少し時間がかかります。

**作成後のイメージ**

![](./images/use-runner.svg)

## サービス構築

サービスの構築はサービスごとに行います。terraformのコードもサービスごとに作成するため、あらかじめ用意された`deploy`ディレクトリをコピーし、`サービス名`ディレクトリなどの作成がオススメです。以下の手順では`test-app`というサービス名を想定して記載します。

``` sh
cd $CLONEDIR/terraform-cicd/terraform/deploy
export APPNAME=test-app
cp -r main-template $APPNAME
```

また、すべてのモジュールで共通して設定する値はsedで置換しておくと後の手順が楽です。

**Linuxの場合**

``` sh
cd $APPNAME
find ./ -type f -exec grep -l 'REGION' {} \; | xargs sed -i -e 's:REGION:'$REGION':g'
find ./ -type f -exec grep -l 'PJ-NAME' {} \; | xargs sed -i -e 's:PJ-NAME:'$PJNAME':g'
find ./ -type f -exec grep -l 'OWNER' {} \; | xargs sed -i -e 's:OWNER:nobody:g'
find ./ -type f -exec grep -l 'APP-NAME' {} \; | xargs sed -i -e 's:APP-NAME:'$APPNAME':g'
```

**macの場合**

``` sh
cd $APPNAME
find ./ -type f -exec grep -l 'REGION' {} \; | xargs sed -i "" -e 's:REGION:'$REGION':g'
find ./ -type f -exec grep -l 'PJ-NAME' {} \; | xargs sed -i "" -e 's:PJ-NAME:'$PJNAME':g'
find ./ -type f -exec grep -l 'OWNER' {} \; | xargs sed -i "" -e 's:OWNER:nobody:g'
find ./ -type f -exec grep -l 'APP-NAME' {} \; | xargs sed -i "" -e 's:APP-NAME:'$APPNAME':g'
```

### Githubへのソース配置
これはterraformを実行する手順ではありません。Githubで実施する手順になります。    
- `Githubレポジトリの準備`で作成したレポジトリをクローンし、そこにサンプルとなるTerraformコードをコピーします。その後GitLab-flowを参考に、Githubにdevブランチをプッシュします。

``` sh
  cd $CLONEDIR
  git clone <GithubレポジトリのクローンURL>
  # クローン時にID/パスワードが求められたらGithubのユーザでログイン
  cd <Githubレポジトリ名>
  git checkout -b dev
  cp -r $CLONEDIR/terraform-cicd/terraform/deploy/$APPNAME/* ./
  git add .
  git commit -m "init"
  git push origin dev:dev
  ```

レポジトリルートに`.github/workflows/terraform-ci.yml`とTerraformコードが配置されていることで、プルリクエストの作成/更新をトリガにGithubActionsが動作します。  

### サービスデプロイ




つくったGithubからクローン  
デプロイディレクトリをコピー
チェックアウトproduction    
チェックアウトdev  
置換する  
- ブランチ
devをコミットしてプッシュ

GithubでPR作成  
Actions確認  
弾かれる確認  
修正プッシュ  
Actions確認  
マージ  
Actions確認  
デプロイ確認

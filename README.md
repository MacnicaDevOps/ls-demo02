### ls-demo02

# GitHubの指定リポジトリからSBOMをエクスポートし、脆弱性情報を取得の上トリアージを行います。

1. .circleci/config.ymlの18行目でリポジトリオーナー、19行目でリポジトリ名を指定してコミットすると、CircleCIのパイプラインが起動する
2. パイプライン処理は次のように進行する
   1. [environment]変数の読み込み
      1. 18行目のリポジトリオーナーを変数に入れる
      2. 19行目のリポジトリ名を変数に入れる
   2. [Prepare environment] 27行目−29行目で処理に必要なパッケージのインストール ※ これらが予め入っているRunner用のコンテナを用意したりSelf−hosted Runnerをもちいることで、本ステップは除外可能
      1. 必要な依存関係をインストール
         1. curl (GitHubやLeanSeeksへのAPIで利用)
         2. golang（OSV-Scannerのインストールに利用）
         3. python3 python3-pip (cvss_calculatorのインストールに利用)
      2. OSV-Scannerのインストール
      3. cvss_calculatorのインストール
   3. [OSV Scanner] GitHubからのSBOM取り込みとフォーマット変換、LeanSeeksへのトリアージリクエストを実行
      1. getSBOM.shでGitHubの指定リポジトリからSBOMをエクスポートし、LeanSeeksのフォーマットに変換
         1. この際、SBOMから脆弱性情報を取得するためにosv-scannerを利用
         2. osv-scannerの出力のCVSSベクターからCVSSスコアとセベリティを取得するためにcvss_calculatorを利用
      2. triage.shでLeanSeeksにデータを登録してトリアージを実行

トリアージ結果(2023年5月時点)
![トリアージ結果](LeanSeeksTtiageResult.png)
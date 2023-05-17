#!/bin/bash

# GithubからSBOMを取得する
curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${owner}/${repo}/dependency-graph/sbom | jq -r ".sbom" > sbom.spdx

# OSV-Scannerを使ってSBOMの脆弱性情報を取得する
echo $(osv-scanner --sbom=sbom.spdx --json) > OSVOut.json

# OSVOut.jsonの.results[].packages[]からパッケージ名.package.nameとパッケージバージョン.package.versionとCVE番号.vulnerabilities[].aliases[]を抽出する。CVE番号.vulnerabilities[].aliases[]が存在しない場合は空白とする。.vulnerabilities[].scoreがある場合は、それも抽出する。
jq -r '.results[].packages[] | .package.name + "," + .package.version + "," + (.vulnerabilities[].aliases[0]? // empty) + "," + (.vulnerabilities[].severity[0].score? // empty)' OSVOut.json > OSVOut.csv

# OSVOut.csvを一行ずつよみながら、中のベクターストリングからセベリティ情報を補完してLeanSeeks用のJSONファイルを作成する。OSVOut.cvsの中のベクターストリングの値は、cvss_calculatorの出力の2行目の出力から()の中にあるCVSSセベリティを抽出する。
it=1
number=$(cat OSVOut.csv | grep -c "CVE-")
echo '[' > "osv_vlun_LS.json"
while read row; do
  packageName=$(echo $row | cut -d "," -f 1 )
  packageVersion=$(echo $row | cut -d "," -f 2 )
  cveId=$(echo $row | cut -d "," -f 3 )
  vectorString=$(echo $row | cut -d "," -f 4 )
  severity=$(cvss_calculator -v ${vectorString} | sed -n 2p | cut -d "(" -f 2 | cut -d ")" -f 1)
  score=$(cvss_calculator -v ${vectorString} | sed -n 2p | cut -d ":" -f 2 | tr -d " " | cut -d "(" -f 1)
  echo "{
    \"cveId\": \"${cveId}\",
    \"packageName\": \"${packageName}\",
    \"packageVersion\": \"${packageVersion}\",
    \"severity\": \"$(echo "${severity}" | tr "[A-Z]" "[a-z]")\",
    \"cvssScore\": \"${score}\",
    \"title\": \"\",
    \"description\": \"\",
    \"link\": \"\",
    \"AV\": \"\",
    \"AC\": \"\",
    \"C\": \"\",
    \"I\": \"\",
    \"A\": \"\",
    \"hasFix\": \"\",
    \"exploit\": \"\",
    \"publicExploits\": \"\",
    \"published\": \"\",
    \"updated\": \"\",
    \"type\": \"\"" >> "osv_vlun_LS.json"
  if [ ${it} -eq ${number} ]; then
    echo "}]" >> "osv_vlun_LS.json"
  else
    echo "}," >> "osv_vlun_LS.json"
  fi
  echo "${it}/${number}"
  it=$((it+1))
done < OSVOut.csv

# LeanSeeks用のアップロードデータを生成する
echo "------- LeanSeeksのアップロードデータを生成中"
  echo '[{"id": "ci_scan.json","scanner": 255,"payload":' > vuln_data.json
  echo $(cat "osv_vlun_LS.json") >> vuln_data.json
  echo "}]" >> vuln_data.json

# LeanSeeksの環境変数を指定してファイルに書き出す
echo "app_name=OSV_SCAN_${CIRCLE_BUILD_NUM}" > param.txt
echo 'app_priority="H"' >> param.txt
echo "scanner=255" >> param.txt

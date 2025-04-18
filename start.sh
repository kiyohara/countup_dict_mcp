#!/bin/bash

# rbenvの初期化
eval "$(rbenv init -)"

# カレントディレクトリをこのスクリプトのある場所に変更
cd "$(dirname "$0")"

# 必要なgemのインストール
bundle install > /dev/null 2>&1

# インストールに失敗したらエラーを出力して終了
if [ $? -ne 0 ]; then
  echo "Failed to install gems" >&2
  exit 1
fi

# サーバーの起動
bundle exec ruby server.rb 
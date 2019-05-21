#!/bin/bash
# 変数DEBUGにonが定義されていたら処理内容を出力
if [ "$DEBUG" = "on" ];then set -x ;fi

######################################################################
#
# [処理概要]
#  前日分の送信ログなどのファイル郡(/home/test/data)を圧縮し、
#  /home/test/logs配下に移動後、圧縮前ファイルを削除。
#
# [引数]
#  なし
#
# [関連ファイル]
#  なし
#
######################################################################
######################################################################
# バージョン 作成／更新者 更新日      変更内容
#---------------------------------------------------------------------
# 001-01    XX XX     YYYY/MM/DD   新規作成
######################################################################
######################################################################
# 事前処理
######################################################################
#---------------------------------------------------------------------
# 変数、定数定義
#---------------------------------------------------------------------
# タイムスタンプ
NOW=`date "+%Y-%m-%d %H:%M:%S"`
# 日付
TODAY=`date "+%Y%m%d"`
# 前日の日付格納
YESTERDAY=`date '+%Y%m%d' --date '1day ago'`
# このスクリプトの名前
SCRIPT_NAME=$(basename $0)
# エラーフラグ
ERROR_FLAG=0
# ファイルカウント用
FILE_COUNT=0
# バックアップ作業ルートディレクトリ
readonly WORK_DIR="/home/test"
# 前日分ファイル格納ディレクトリ
readonly DATA_DIR="${WORK_DIR}/data"
# Tarファイル退避ディレクトリ
readonly BACKUP_DIR="${WORK_DIR}/logs"
# ログ格納ディレクトリ
readonly LOG_DIR="${BACKUP_DIR}/bk_log"
# ファイル名接頭辞
readonly FILE_NAME_PREFIX="test."
# バックアップログファイル
readonly BACKUP_LOG="${LOG_DIR}/backup.log"
# エラーログファイル
readonly ERROR_LOG="${LOG_DIR}/backup_error.log"
## メール送信用変数
# 送信元アドレス
readonly FROM="noreply@backup"
# 送信先アドレス
readonly TO="infra@test.ne.jp"
# メールタイトル
readonly SUBJECT="【XXX】backup_error "

######################################################################
# 関数定義
######################################################################
#---------------------------------------------------------------------
# バックアップログ出力
#---------------------------------------------------------------------
function fnc_output_scriptlog() {
  (echo "$SCRIPT_NAME: $1 $NOW" >>$BACKUP_LOG) 2>/dev/null
  return $?
}

#---------------------------------------------------------------------
# アラートメール送信関数
#---------------------------------------------------------------------
function fnc_send_mail() {
  echo -e "$1 \nfilename: $SCRIPT_NAME" | mail -s $SUBJECT -r $FROM $TO
  return $?
}

######################################################################
# メイン処理
######################################################################
#---------------------------------------------------------------------
# 前日分の送信ログなどのファイル郡を圧縮
#---------------------------------------------------------------------
#開始ログ出力
fnc_output_scriptlog "start backup process."

# 作業ディレクトリ移動
cd $WORK_DIR 2>> $ERROR_LOG

# 前日分ファイル存在確認
FILE_COUNT=$(find $DATA_DIR -type f -name "*${FILE_NAME_PREFIX}${YESTERDAY}*" | wc -l)
if [ $FILE_COUNT -gt 0 ]; then

  # 前日分ファイルアーカイブ実行
  tar zcvf data${YESTERDAY}.tgz /home/test/data 2>> $ERROR_LOG

  if [ "$?" = "0" ];then
    fnc_output_scriptlog  "backup completed."
  else
    # エラー通知(圧縮を失敗した場合)
    for i in fnc_output_scriptlog fnc_send_mail; do ${i} "backup failed."; done
    # エラーフラグ指定
    ERROR_FLAG=1
  fi

else
    # エラー通知(前日分ファイルが存在しない場合)
    for i in fnc_output_scriptlog fnc_send_mail; do ${i} "there were no files of one day before in directory."; done
    # エラーフラグ指定
    ERROR_FLAG=1
fi

#---------------------------------------------------------------------
# バックアップTarファイル退避
#---------------------------------------------------------------------
#バックアップTarファイル退避実行
if [ $ERROR_FLAG -eq 0 ]; then

  mv data${YESTERDAY}.tgz logs/ 2>> $ERROR_LOG

  if [ "$?" = "0" ];then
    fnc_output_scriptlog  "To transfer backup tar file is completed."

    # 圧縮前ファイル削除
    rm -f ${DATA_DIR}/muryou.* 2>> $ERROR_LOG
      if [ "$?" = "0" ];then
        fnc_output_scriptlog "To delete file is completed."
      else
        # エラー通知(圧縮前ファイル削除に失敗した場合)
        for i in fnc_output_scriptlog fnc_send_mail; do ${i} "To delete file is failed."; done
      fi

  else
    # エラー通知(Tarファイル退避に失敗した場合)
    for i in fnc_output_scriptlog fnc_send_mail ;do ${i} " To transfer tar file is failed."; done
  fi
  fnc_output_scriptlog "finished backup process."

else
  fnc_output_scriptlog "backup process has not finished."
fi

######################################################################
# 終了処理
######################################################################

exit 0

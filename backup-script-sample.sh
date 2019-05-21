#!/bin/bash
# �ϐ�DEBUG��on����`����Ă����珈�����e���o��
if [ "$DEBUG" = "on" ];then set -x ;fi

######################################################################
#
# [�����T�v]
#  �O�����̑��M���O�Ȃǂ̃t�@�C���S(/home/test/data)�����k���A
#  /home/test/logs�z���Ɉړ���A���k�O�t�@�C�����폜�B
#
# [����]
#  �Ȃ�
#
# [�֘A�t�@�C��]
#  �Ȃ�
#
######################################################################
######################################################################
# �o�[�W���� �쐬�^�X�V�� �X�V��      �ύX���e
#---------------------------------------------------------------------
# 001-01    XX XX     YYYY/MM/DD   �V�K�쐬
######################################################################
######################################################################
# ���O����
######################################################################
#---------------------------------------------------------------------
# �ϐ��A�萔��`
#---------------------------------------------------------------------
# �^�C���X�^���v
NOW=`date "+%Y-%m-%d %H:%M:%S"`
# ���t
TODAY=`date "+%Y%m%d"`
# �O���̓��t�i�[
YESTERDAY=`date '+%Y%m%d' --date '1day ago'`
# ���̃X�N���v�g�̖��O
SCRIPT_NAME=$(basename $0)
# �G���[�t���O
ERROR_FLAG=0
# �t�@�C���J�E���g�p
FILE_COUNT=0
# �o�b�N�A�b�v��ƃ��[�g�f�B���N�g��
readonly WORK_DIR="/home/test"
# �O�����t�@�C���i�[�f�B���N�g��
readonly DATA_DIR="${WORK_DIR}/data"
# Tar�t�@�C���ޔ��f�B���N�g��
readonly BACKUP_DIR="${WORK_DIR}/logs"
# ���O�i�[�f�B���N�g��
readonly LOG_DIR="${BACKUP_DIR}/bk_log"
# �t�@�C�����ړ���
readonly FILE_NAME_PREFIX="test."
# �o�b�N�A�b�v���O�t�@�C��
readonly BACKUP_LOG="${LOG_DIR}/backup.log"
# �G���[���O�t�@�C��
readonly ERROR_LOG="${LOG_DIR}/backup_error.log"
## ���[�����M�p�ϐ�
# ���M���A�h���X
readonly FROM="noreply@backup"
# ���M��A�h���X
readonly TO="infra@test.ne.jp"
# ���[���^�C�g��
readonly SUBJECT="�yXXX�zbackup_error "

######################################################################
# �֐���`
######################################################################
#---------------------------------------------------------------------
# �o�b�N�A�b�v���O�o��
#---------------------------------------------------------------------
function fnc_output_scriptlog() {
  (echo "$SCRIPT_NAME: $1 $NOW" >>$BACKUP_LOG) 2>/dev/null
  return $?
}

#---------------------------------------------------------------------
# �A���[�g���[�����M�֐�
#---------------------------------------------------------------------
function fnc_send_mail() {
  echo -e "$1 \nfilename: $SCRIPT_NAME" | mail -s $SUBJECT -r $FROM $TO
  return $?
}

######################################################################
# ���C������
######################################################################
#---------------------------------------------------------------------
# �O�����̑��M���O�Ȃǂ̃t�@�C���S�����k
#---------------------------------------------------------------------
#�J�n���O�o��
fnc_output_scriptlog "start backup process."

# ��ƃf�B���N�g���ړ�
cd $WORK_DIR 2>> $ERROR_LOG

# �O�����t�@�C�����݊m�F
FILE_COUNT=$(find $DATA_DIR -type f -name "*${FILE_NAME_PREFIX}${YESTERDAY}*" | wc -l)
if [ $FILE_COUNT -gt 0 ]; then

  # �O�����t�@�C���A�[�J�C�u���s
  tar zcvf data${YESTERDAY}.tgz /home/test/data 2>> $ERROR_LOG

  if [ "$?" = "0" ];then
    fnc_output_scriptlog  "backup completed."
  else
    # �G���[�ʒm(���k�����s�����ꍇ)
    for i in fnc_output_scriptlog fnc_send_mail; do ${i} "backup failed."; done
    # �G���[�t���O�w��
    ERROR_FLAG=1
  fi

else
    # �G���[�ʒm(�O�����t�@�C�������݂��Ȃ��ꍇ)
    for i in fnc_output_scriptlog fnc_send_mail; do ${i} "there were no files of one day before in directory."; done
    # �G���[�t���O�w��
    ERROR_FLAG=1
fi

#---------------------------------------------------------------------
# �o�b�N�A�b�vTar�t�@�C���ޔ�
#---------------------------------------------------------------------
#�o�b�N�A�b�vTar�t�@�C���ޔ����s
if [ $ERROR_FLAG -eq 0 ]; then

  mv data${YESTERDAY}.tgz logs/ 2>> $ERROR_LOG

  if [ "$?" = "0" ];then
    fnc_output_scriptlog  "To transfer backup tar file is completed."

    # ���k�O�t�@�C���폜
    rm -f ${DATA_DIR}/muryou.* 2>> $ERROR_LOG
      if [ "$?" = "0" ];then
        fnc_output_scriptlog "To delete file is completed."
      else
        # �G���[�ʒm(���k�O�t�@�C���폜�Ɏ��s�����ꍇ)
        for i in fnc_output_scriptlog fnc_send_mail; do ${i} "To delete file is failed."; done
      fi

  else
    # �G���[�ʒm(Tar�t�@�C���ޔ��Ɏ��s�����ꍇ)
    for i in fnc_output_scriptlog fnc_send_mail ;do ${i} " To transfer tar file is failed."; done
  fi
  fnc_output_scriptlog "finished backup process."

else
  fnc_output_scriptlog "backup process has not finished."
fi

######################################################################
# �I������
######################################################################

exit 0

# -*- coding: utf-8 -*-
import time, calendar
import sys, os,ConfigParser, datetime

class MongoBackup():
    def __init__(self, backconfig):
        print "start!"
        self.db_beforetime = calendar.timegm(time.gmtime())
        self.oplog_beforetime = calendar.timegm(time.gmtime())
        self.backupConfig = backconfig
        self.host = self.backupConfig.get('Base', 'MongoHost')
        self.port = self.backupConfig.get('Base', 'MongoPost')
        self.db_name = self.backupConfig.get('Backup', 'BackupDBName')
        self.MongoUser = self.backupConfig.get('Base', 'MongoUser')
        self.MongoPW = None
        if self.MongoUser != 0:
            self.MongoPW = self.backupConfig.get('Base', 'MongoPaassWord')
        self.db_output = self.backupConfig.get('Backup', 'DB_OutputPath')
        self.oplog_output = self.backupConfig.get('Backup', 'Oplog_OutputPath')


    def db_backup(self):
        print "Do DB backup"
        os.system("mongodump --host "+str(self.host)+ " --port "+ str(self.port) + " -d " + str(self.db_name) +
                  " -o " + str(self.db_output) + "/" + str(self.db_name) + "_" + str(self.datetime_gmt_yyyymmdd_int(gmt=8)))

    def oplog_backup(self, starttime, endtime):
        try:
            print "Do Oplog backup"
            query = '"{ts:{\$lt:Timestamp('+str(endtime)+', 4200000000), \$gte:Timestamp(' + str(starttime) +', 0)}}"'
            print query
            start_name = datetime.datetime.fromtimestamp(int(starttime)).strftime('%Y-%m-%d %H:%M:%S').replace(' ', '')
            start_name = start_name.replace(':','')
            start_name = start_name.replace('-','')
            end_name = datetime.datetime.fromtimestamp(int(endtime)).strftime('%Y-%m-%d %H:%M:%S').replace(' ', '')
            end_name = end_name.replace(':','')
            end_name = end_name.replace('-','')
            os.system('mongodump --host '+str(self.host)+ ' --port '+ str(self.port) + ' -d local -c oplog.rs -q ' + str(query) + ' -o ' + str(self.oplog_output) + '/local' + '_' + str(start_name) + '_' + str(end_name))
        except Exception as e:
            print "Error: ", str(e)

    def db_beforetime(self):
        return self.db_beforetime

    def db_settingbeforetime(self, new_time):
        self.db_beforetime = new_time

    def oplog_beforetime(self):
        return self.oplog_beforetime

    def oplog_settingbeforetime(self, new_time):
        self.oplog_beforetime = new_time

    def datetime_gmt_yyyymmdd_int(self, gmt=0):
        return int((datetime.datetime.utcnow() + datetime.timedelta(hours=int(gmt))).strftime('%Y%m%d'))

if __name__ == '__main__':
    backupConfig = ConfigParser.RawConfigParser()
    backupConfig.read('setting.config')
    back = MongoBackup(backupConfig)

    while(1):
        now_time = calendar.timegm(time.gmtime())
        date_name = datetime.datetime.fromtimestamp(int(now_time)).strftime('%Y-%m-%d ') + \
                    str(backupConfig.get('Backup', 'DB_BackupTime'))
        date_name = time.mktime(time.strptime(date_name, '%Y-%m-%d %H:%M:%S'))
        #備份日備份檔案
        if int(now_time) == int(date_name):
            back.db_backup()
            back.db_settingbeforetime(now_time)
        #備份Oplog檔案
        if (now_time - back.oplog_beforetime) > int(backupConfig.get('Backup', 'Oplog_BackupTime')):
            back.oplog_backup(starttime=back.oplog_beforetime, endtime=now_time)
            back.oplog_settingbeforetime(now_time)

import pymysql
from pynq.overlays.base import BaseOverlay
from pynq.lib.pmod import *
import math
from time import sleep

pynq_name='pynq0002'
base = BaseOverlay("base.bit")
# 打开数据库连接
#Here to put ur own MySQL info
db = pymysql.connect("xxx.xxx.xxx.xxx","root","password","pynq" )
cursor = db.cursor()


tmp = Grove_TMP(base.PMODB,PMOD_GROVE_G4)
temperature = tmp.read()
print(float("{0:.2f}".format(temperature)),'degree Celsius')

data=(temperature,pynq_name)
# SQL 更新语句
sql = "update pynq set sensor='%.2f degree Celsius' where usrname='%s'"
try:
   # 执行SQL语句
   cursor.execute(sql % data)
   # 提交到数据库执行
   db.commit()
except:
   # 发生错误时回滚
   print("ERROR")
   db.rollback()

#cursor.execute(sql)
   # 提交到数据库执行
#db.commit()

# 关闭数据库连接
db.close()

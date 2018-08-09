import xlrd

from datetime import date,datetime

def read_exec():
    #文件位置
    ExcelFile = xlrd.open_workbook('model.xlsx')
    #打印sheet名字
    print(ExcelFile.sheet_names())
    #打印sheet名字，行数，列数
    sheet = ExcelFile.sheet_by_name('VM list')
    print(sheet.name,sheet.nrows,sheet.ncols)
    #调取单元格数据
    VM_Name = sheet.cell_value(1,0)
    #定义空字典
    dict = {}
    num = 0
    #循环赋值添加入字典
    while num < int(sheet.ncols):
        dict[sheet.cell_value(0,num)] = sheet.cell_value(1,num)
        num = num+1
    
    print(dict)
    print(dict['Name'])
    

read_exec()
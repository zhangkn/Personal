#!usr/bin/python
#coding=utf-8  
from BaseHTTPServer import BaseHTTPRequestHandler
from BaseHTTPServer import HTTPServer   
import cgi  

import socket   #用于获取ip
import qrcode

import sys,os,time,threading
from selenium import webdriver

global elements         # index.html的网页input元素
global maxInputCount    # 每次最大上传数量
global uploadURL        # 上传URL
global sever


# 监听键盘输入
class KeyboardHookThread(threading.Thread):
    input_str = ''
    def __init__(self,callback,args):
        threading.Thread.__init__(self)
        self.callback = callback
        self.args = args

    def run(self):
        while 1:
            input_kb = str(sys.stdin.readline()).strip('\n')
            if input_kb == 'help':
                print '提示:输入"send"可以向移动端发送文件'
            elif input_kb == 'send':
                print '发送文件'
                self.callback(self.args)
            else:
                print '无效指令!!提示:输入"send"可以向移动端发送文件,输入"help"查看帮助'

# 重写get和post方法
class PostHandler(BaseHTTPRequestHandler):
    userUrl = ''
    def do_POST(self):  
        form = cgi.FieldStorage(  
            fp=self.rfile,  
            headers=self.headers,  
            environ={'REQUEST_METHOD':'POST',  
                     'CONTENT_TYPE':self.headers['Content-Type'],  
                     }  
        )  
        self.send_response(200)  
        self.end_headers()  
        self.wfile.write('Client: %sn ' % str(self.client_address) )  
        self.wfile.write('User-agent: %sn' % str(self.headers['user-agent']))  
        self.wfile.write('Path: %sn'%self.path)  
        self.wfile.write('Form data:n')  
        print form.headers
        for field in form.keys():
            print '----'
            field_item = form[field]  
            filename = field_item.filename  
            filevalue  = field_item.value  
            filesize = len(filevalue)#文件大小(字节)
            savePath = ('/Users/admin/Desktop/WifiTranser/%s'%filename).decode('utf-8')
            print '保存到目录:'.decode('utf-8')+savePath
#            print '----%s'%(field_item).value
            with open(savePath,'wb') as f:
                f.write(filevalue)
        return
    
    def do_GET(self):
        try:
            # f=open(self.path[1:],'r') # 获取客户端输入的页面文件名称
            # self.path 就是客户端的请求路径如 http://172.20.105.87:8000/connect?url=http://nikilong.com,这时候self.path就是后面的/connect?url=http://nikilong.com
            # self.wfile.write(f.read())#通过wfile将下载的页面传给客户
            # f.close() #关闭
            self.send_response(200)#如果正确返回200
            self.send_header('Content-type','text/html') #定义下处理的文件的类型
            self.end_headers()#结束处理
            print '+++' + self.path
            if 'connect?' in self.path:
                #回调链接反馈
                self.wfile.write('connect success\r\n')
                # 连接成功之后开启键盘监听
                startHookKeyboard(self.path.split('connect?url=')[-1])
            # if 'sendFiles?url=' in self.path:
            #     print self.path
            #     self.userUrl = self.path.split('sendFiles?url=')[-1]
            #     startToTransfer(self.path.split('sendFiles?url=')[-1])
        except IOError:
            self.send_error(404, 'file not found: %s'%self.path)
  
#启动http服务
def StartServer(port):
    sever = HTTPServer(("",port),PostHandler)  
    sever.serve_forever()  

#查询本机ip
def get_host_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    finally:
        s.close()
    return ip


# 提供一个函数刷新网页,更新元素
def refreshUploadhtml(url):
    global elements,maxInputCount,uploadURL
    options = webdriver.ChromeOptions()
    options.set_headless()
    options.add_argument('--disable-gpu')
    browser = webdriver.Chrome(options=options)
    browser.get(url)
    elements = browser.find_elements_by_tag_name('input')
    maxInputCount = len(elements) - 1


# 传输文件
def startToTransfer(url):
    print '连接到: %s'%url
    transFlag = True
    while transFlag:
        #1.将要上传的文件传入一个数组
        fileStr = raw_input('拖拽要传送的文件: \n').replace('\\','')
        fileList = fileStr.split(" /Users")
        if len(fileStr) == 0:
            print '=====没有选择文件====='
#            return
        print '=====已选择文件====='
        for ele in fileList:
            print ele
        #2.分批上传
        #先获得上传网页信息
        refreshUploadhtml(url)
        #分批上传,先上传每个文件的路径,上传完立马判断是否已经达到最大的上传个数,达到了限制个数先上传,上传完之后休眠2秒在刷新网页上传下一批,上传忘了最后一个文件后要点击上传
        hasInputCount = 0
        print '=====开始上传====='
        for index in range(0,len(fileList)):
            # 排除DS_Store文件
            if 'DS_Store' in fileList[index]:
                continue
            # 一次添加文件
            inputEle = elements[hasInputCount]
            file = fileList[index]
            if not '/Users' in file:
                file = '/Users' + file
            # 先清空内容,再传路径
            inputEle.clear()
            inputEle.send_keys(file.decode('utf-8'))
            print 'input %s'%fileList[index]
            # 统计添加个数
            hasInputCount += 1
            # 达到最大或者最后一个文件要提交,提交完了要刷新
            if hasInputCount == maxInputCount or index == (len(fileList) - 1):
                hasInputCount = 0
                sumitBtn = elements[-1]
                sumitBtn.click()
                print 'commit'
                time.sleep(3)
                refreshUploadhtml(url)
        
        #输入命令决定是否继续传递
        transFlag =  bool(raw_input('是否继续传输?(按下Enter结束传输,输入任意字符继续传输) :'))
    
    print '>>>>传输文件完成'

# 与手机连接成功之后启用键盘监听
def startHookKeyboard(url):
    print 'agent ip is >>>>>' + url
    #开始监听键盘输入
    kb_hook_t = KeyboardHookThread(callback = startToTransfer,args=(url))
    kb_hook_t.start()
  
if __name__=='__main__':
#    #开始监听键盘输入
#    kb_hook_t = KeyboardHookThread(callback = aaa)
#    kb_hook_t.start()
    #端口号
    port = 8300
    serverUrl = 'http://%s:%s'%(get_host_ip(),port)
    print '本机ip是:' + serverUrl
#    img = qrcode.make(serverUrl)
#    img.get_image().show()
#    img.save('/Users/admin/Desktop/wifiTransQrcode.png')
    StartServer(8300)

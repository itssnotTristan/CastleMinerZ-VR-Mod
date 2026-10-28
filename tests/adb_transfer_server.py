"""Loopback ADB smart-socket/sync fixture, NOT Android or a real headset.

The real installed adb client speaks its native transfer protocol to this model.
Missing nested parents reproduce the reported secure_mkdirs failure contract;
the model does not establish Quest filesystem permission acceptance. No device,
shell process, network service beyond loopback, or disk import tree is touched.
"""
import hashlib
import posixpath
import re
import shlex
import socketserver
import struct
import threading

ROOT='/sdcard/Android/data/org.codex.castleminerzvr/files'

def read(s,n):
    data=b''
    while len(data)<n:
        chunk=s.recv(n-len(data))
        if not chunk:raise EOFError()
        data+=chunk
    return data

class Model:
    def __init__(self,mode='ok'):
        self.mode=mode
        self.dirs={'/','/sdcard','/sdcard/Android','/sdcard/Android/data',ROOT.rsplit('/',1)[0],ROOT,'/data','/data/local','/data/local/tmp',ROOT+'/game'}
        self.files={ROOT+'/game/old-import.sentinel':b'OLD IMPORT',ROOT+'/vr-world.save':b'SAVE',ROOT+'/vr-settings.save':b'SETTINGS'}
        self.calls=[];self.errors=[];self.installs=0;self.commits=0;self.sent=0
    def record(self,kind,*args):self.calls.append([kind,*args])
    def mkdir(self,path):
        path=posixpath.normpath(path)
        if '/game-incoming-' in path and (self.mode=='mkdir-root-fail' or self.mode=='mkdir-audio-fail' and path.endswith('/audio')):
            return b'',b'mkdir: Operation not permitted\n',1
        parts=path.split('/')
        for i in range(2,len(parts)+1):self.dirs.add('/'.join(parts[:i]))
        return b'',b'benign synthetic notice\n' if self.mode=='success-stderr' else b'',0
    def shell(self,cmd):
        self.record('shell',cmd)
        if cmd=='getprop ro.product.model':return b'Quest 3\n',b'',0
        if 'pidof org.codex.castleminerzvr' in cmd:return b'',b'',0
        if cmd.startswith('mkdir -p '):return self.mkdir(cmd[len('mkdir -p '):])
        if cmd.startswith("mkdir '"):
            # New host clients attempt best-effort bulk mkdir and ignore its
            # status. Inject its failure explicitly, leaving missing parents
            # for the sync daemon. This is a fault model, not Android evidence.
            self.record('fault','best-effort bulk mkdir rejected')
            return b'',b'synthetic bulk mkdir failure\n',1
        if cmd.startswith('pm path '):return b'package:/data/app/inert/base.apk\n',b'',0
        words=shlex.split(cmd)
        if words[:2]==['pm','install']:
            self.installs+=1
            if self.mode=='install-fail':return b'Failure [INERT_INSTALL_FAILURE]\n',b'',1
            return b'Success\n',b'',0
        if words and words[0]=='rm' and len(words)>1 and words[1].startswith('/data/local/tmp/'):
            self.files.pop(words[1],None);return b'',b'',0
        if cmd.startswith('cd ') and 'sha256sum -c setup-checksums.txt' in cmd:
            stage=cmd[3:].split(' && ')[0]
            checks=self.files.get(stage+'/setup-checksums.txt',b'').decode()
            if not checks:return b'',b'missing checksums\n',1
            for line in checks.splitlines():
                digest,name=line.split('  ',1)
                data=self.files.get(stage+'/'+name)
                if data is None or hashlib.sha256(data).hexdigest()!=digest or self.mode=='checksum-fail':
                    return b'',b'checksum failed\n',1
            return b'',b'',0
        if cmd.startswith('if [ -d ') and 'game-before-setup-' in cmd:
            incoming=re.search(r'/sdcard/[^ ;]+/game-incoming-[0-9a-f]{32}',cmd)[0]
            backup=re.search(r'/sdcard/[^ ;]+/game-before-setup-[0-9a-f]{32}',cmd)[0]
            self.rename(ROOT+'/game',backup)
            self.rename(incoming,ROOT+'/game');self.commits+=1
            return b'',b'',0
        if cmd.startswith('sha256sum '):
            path=cmd[len('sha256sum '):];data=self.files.get(path)
            if data is None:return b'',b'No such file\n',1
            return (hashlib.sha256(data).hexdigest()+'  '+path+'\n').encode(),b'',0
        if cmd.startswith('mv '):
            _,src,dst=cmd.split(' ');self.rename(src,dst);return b'',b'',0
        raise AssertionError('Unexpected modeled shell command: '+cmd)
    def rename(self,src,dst):
        for key in list(self.files):
            if key==src or key.startswith(src+'/'):self.files[dst+key[len(src):]]=self.files.pop(key)
        for key in list(self.dirs):
            if key==src or key.startswith(src+'/'):self.dirs.remove(key);self.dirs.add(dst+key[len(src):])
    def snapshot(self):
        return {'mode':self.mode,'calls':self.calls,'errors':self.errors,'installs':self.installs,'commits':self.commits,
                'files':{p:{'bytes':len(d),'sha256':hashlib.sha256(d).hexdigest()} for p,d in self.files.items()}}

class Handler(socketserver.BaseRequestHandler):
    def payload(self,data):self.request.sendall(b'OKAY'+f'{len(data):04x}'.encode()+data)
    def handle(self):
        s=self.request;m=self.server.model
        try:
            while True:
                request=read(s,int(read(s,4),16)).decode();m.record('service',request)
                if request=='host:version':self.payload(b'0029');return
                if request=='host:devices-l':self.payload(b'QUEST-LAB\tdevice product:inert model:Quest_3 device:fixture transport_id:1\n');return
                if request.endswith(':features') or request=='host:features':self.payload(b'shell_v2');return
                if request.endswith(':wait-for-any-device'):
                    s.sendall(b'OKAYOKAY');return
                if request.startswith('host:transport:') or request.startswith('host:transport-id:'):
                    s.sendall(b'OKAY');continue
                if request.startswith('host:tport:'):
                    s.sendall(b'OKAY'+struct.pack('<Q',1));continue
                if request=='sync:':s.sendall(b'OKAY');self.sync();return
                if request.startswith(('shell:','shell,v2:','shell,v2,','exec:')):
                    s.sendall(b'OKAY');cmd=request.split(':',1)[1];stdout,stderr,code=m.shell(cmd)
                    if request.startswith('shell,v2'):
                        for channel,data in ((1,stdout),(2,stderr),(3,bytes([code]))):
                            if data:s.sendall(struct.pack('<BI',channel,len(data))+data)
                    else:s.sendall(stdout+stderr)
                    return
                raise AssertionError('Unexpected ADB service: '+request)
        except (EOFError,ConnectionResetError,BrokenPipeError):pass
        except Exception as e:m.errors.append(repr(e))
    def sync(self):
        s=self.request;m=self.server.model
        while True:
            tag,n=struct.unpack('<4sI',read(s,8))
            if tag==b'QUIT':return
            path=read(s,n).decode();m.record('sync',tag.decode(),path)
            if tag==b'STAT':
                path=posixpath.normpath(path);data=m.files.get(path)
                mode=0o40775 if path in m.dirs else 0o100644 if data is not None else 0
                s.sendall(struct.pack('<4sIII',b'STAT',mode,len(data) if data else 0,1));continue
            if tag==b'SEND':
                path=posixpath.normpath(path.rsplit(',',1)[0]);chunks=[]
                while True:
                    tag,n=struct.unpack('<4sI',read(s,8))
                    if tag==b'DONE':break
                    assert tag==b'DATA',tag
                    chunks.append(read(s,n))
                data=b''.join(chunks)
                parent=posixpath.dirname(path)
                if parent not in m.dirs:
                    # Model AOSP's missing-parent mkdir/chown failure, leaving
                    # the failed staging directory, as a real daemon may do.
                    m.dirs.add(parent)
                    reason=b'remote secure_mkdirs failed: Operation not permitted'
                    s.sendall(struct.pack('<4sI',b'FAIL',len(reason))+reason);continue
                m.sent+=1
                if m.mode=='push-fail' and '/game-incoming-' in path:
                    m.files[path]=data[:max(1,len(data)//2)]
                    reason=b'synthetic disconnected partial transfer'
                    s.sendall(struct.pack('<4sI',b'FAIL',len(reason))+reason);continue
                m.files[path]=data;s.sendall(struct.pack('<4sI',b'OKAY',0));continue
            raise AssertionError('Unexpected sync operation: '+repr(tag))

class Server(socketserver.ThreadingTCPServer):
    daemon_threads=True
    allow_reuse_address=False
    def __init__(self,model):super().__init__(('127.0.0.1',0),Handler);self.model=model
    def __enter__(self):
        self.thread=threading.Thread(target=self.serve_forever,daemon=True);self.thread.start();return self
    def __exit__(self,*unused):self.shutdown();self.server_close();self.thread.join()

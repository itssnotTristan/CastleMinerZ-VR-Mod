"""Production transfer functions with real adb + an explicitly modeled daemon.

All payloads are synthetic. Never connect this fixture to a device. For complete
entry tests with privately verified originals, pass --full-entry and --imports.
"""
from pathlib import Path
import argparse, hashlib, json, os, subprocess, tempfile, uuid
from adb_transfer_server import Model, ROOT, Server

p=argparse.ArgumentParser()
p.add_argument('--adb',type=Path,required=True);p.add_argument('--ps',type=Path,required=True)
p.add_argument('--work',type=Path,required=True)
p.add_argument('--script',type=Path,default=Path(__file__).resolve().parents[1]/'QuestSetup/Setup-QuestStandalone.ps1')
p.add_argument('--full-entry',type=Path);p.add_argument('--imports',type=Path)
p.add_argument('--old-script',type=Path)
a=p.parse_args();a.work.mkdir(parents=True,exist_ok=True)
records=[]

def run(mode='ok',old=False,model=None,full=False):
    case=a.work/(mode+'-'+uuid.uuid4().hex[:8]);case.mkdir()
    local=case/'Local imports with spaces';local.mkdir()
    files={'atlas.rgba':b'ROOT'*80,'audio/cues.bin':b'CUES'*90,'audio/another level/tone.bin':b'not used'}
    # The public path contract intentionally excludes whitespace remotely.
    files.pop('audio/another level/tone.bin');files['audio/deeper/tone.bin']=b'TONE'*70
    files['hud-items.sha256']=b'synthetic receipt'
    files['audio/sfx; Gun Shot.wav']=b'SPACE AND SEMICOLON LEAF'
    for name,data in files.items():
        path=local/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
    if full:local=a.imports
    incoming=ROOT+'/game-incoming-'+uuid.uuid4().hex
    wrapper=case/'Invoke transfer.ps1'
    quote=lambda s:"'"+str(s).replace("'","''")+"'"
    if full:
        script=a.old_script if old else a.script
        command='& '+quote(script)+' -GameDirectory '+quote(a.full_entry)+' -ImportDirectory '+quote(local)+' -Adb '+quote(a.adb)
    else:
        command='''$ast=[Management.Automation.Language.Parser]::ParseFile(SCRIPT,[ref]$null,[ref]$null)
foreach($name in @('Quest','Get-QuestImportDirectories','Copy-QuestImports')){
 $fn=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
 if(-not $fn){throw "Missing production function $name"};Invoke-Expression $fn.Extent.Text
}
$Adb=ADB
$manifest=@(@{path='game/atlas.rgba'},@{path='game/audio/cues.bin'},@{path='game/audio/deeper/tone.bin'},@{path='game/audio/sfx; Gun Shot.wav'})
$directories=@(Get-QuestImportDirectories -Assets $manifest)
'''.replace('SCRIPT',quote(a.script)).replace('ADB',quote(a.adb))
        if old:
            command+="Quest -Arguments @('-s','QUEST-LAB','shell','mkdir','-p',"+quote(incoming)+") | Out-Null\n"
            command+="Quest -Arguments @('-s','QUEST-LAB','push',"+quote(str(local)+'/.')+","+quote(incoming)+") | Out-Host\n"
        else:command+='Copy-QuestImports -ImportDirectory '+quote(local)+' -Incoming '+quote(incoming)+" -Serial QUEST-LAB -Directories $directories\n"
    wrapper.write_text("$ErrorActionPreference='Stop'\n$env:PSModulePath=Join-Path $PSHOME 'Modules'\n"+command,encoding='utf-8-sig')
    m=model or Model(mode);m.mode=mode
    with Server(m) as server:
        env={**os.environ,'ADB_SERVER_SOCKET':'tcp:127.0.0.1:'+str(server.server_address[1]),'LOCALAPPDATA':str(case/'local')}
        for key in list(env):
            if key.upper() in ('PSMODULEPATH','ANDROID_ADB_SERVER_PORT','ANDROID_SERIAL'):del env[key]
        result=subprocess.run([str(a.ps),'-NoProfile','-ExecutionPolicy','Bypass','-File',str(wrapper)],env=env,capture_output=True,text=True,timeout=180)
    text=result.stdout+result.stderr;(case/'output.txt').write_text(text,encoding='utf-8')
    snapshot=m.snapshot();snapshot.update(exit=result.returncode,fullEntry=full,old=old)
    (case/'protocol.json').write_text(json.dumps(snapshot,indent=2),encoding='utf-8')
    assert not m.errors,m.errors
    assert m.files[ROOT+'/vr-world.save']==b'SAVE' and m.files[ROOT+'/vr-settings.save']==b'SETTINGS'
    records.append({'case':case.name,'exit':result.returncode,'old':old,'fullEntry':full,'protocol':str(case/'protocol.json')})
    return result,text,m,incoming,files

def no_commit(m):
    assert m.installs==0 and m.commits==0
    assert m.files[ROOT+'/game/old-import.sentinel']==b'OLD IMPORT'

if a.full_entry:
    assert a.imports and a.old_script
    r,t,m,_,_=run(old=True,full=True)
    assert r.returncode!=0 and 'Quest USB command failed (exit 1)' in t and 'remote secure_mkdirs failed: Operation not permitted' in t,t
    no_commit(m);print('PASS OLD full released entry: native adb push exit1 secure_mkdirs; active imports/saves untouched',flush=True)
    for mode in ('mkdir-root-fail','mkdir-audio-fail','push-fail','checksum-fail','install-fail','success-stderr','ok'):
        r,t,m,_,_=run(mode,full=True)
        assert (r.returncode==0)==(mode in ('ok','success-stderr')),t
        if mode in ('mkdir-root-fail','mkdir-audio-fail','push-fail','checksum-fail'):no_commit(m)
        if mode=='install-fail':assert m.installs==1 and m.commits==0 and m.files[ROOT+'/game/old-import.sentinel']==b'OLD IMPORT'
        if r.returncode==0:
            assert m.installs==1 and m.commits==1
            for path in (a.imports).rglob('*'):
                if path.is_file():assert m.files[ROOT+'/game/'+path.relative_to(a.imports).as_posix()]==path.read_bytes(),path
            assert any('game-before-setup-' in key and key.endswith('/old-import.sentinel') for key in m.files)
        print('PASS full entry',mode,'native exit',r.returncode,flush=True)
    r,t,m,_,_=run('push-fail',full=True);no_commit(m)
    previous={x for x in m.dirs if '/game-incoming-' in x}
    r,t,m,_,_=run('ok',model=m,full=True);assert r.returncode==0,t
    assert len({x.split('/game-incoming-')[1].split('/')[0] for x in m.dirs if '/game-incoming-' in x})>=1
    assert all(x in m.dirs for x in previous) and m.commits==1
    print('PASS partial transfer retry keeps failed GUID isolated; backup/save sentinels retained',flush=True)
else:
    r,t,m,_,_=run(old=True)
    assert r.returncode!=0 and 'remote secure_mkdirs failed: Operation not permitted' in t,t
    print('PASS OLD transfer sequence: real adb exit1 missing-parent rejection',flush=True)
    for mode in ('ok','success-stderr','mkdir-root-fail','mkdir-audio-fail','push-fail'):
        r,t,m,incoming,files=run(mode)
        assert (r.returncode==0)==(mode in ('ok','success-stderr')),t
        if r.returncode==0:
            for name,data in files.items():assert m.files[incoming+'/'+name]==data
            pushes=[i for i,x in enumerate(m.calls) if x[:2]==['sync','SEND']]
            mkdirs=[i for i,x in enumerate(m.calls) if x[0]=='shell' and x[1].startswith('mkdir -p ')]
            assert max(mkdirs)<min(pushes)
            assert any('/./audio/' in x[2] for x in m.calls if x[:2]==['sync','SEND']),m.calls
        elif mode.startswith('mkdir-'):assert not any(x[:2]==['sync','SEND'] for x in m.calls)
        else:assert 'Quest USB command failed (exit 1)' in t
        no_commit(m);print('PASS transfer',mode,'native exit',r.returncode,flush=True)

(a.work/'results.json').write_text(json.dumps({'cases':records,'adb':str(a.adb),'ps':str(a.ps),'evidenceType':'Real native ADB client against loopback sync/shell model; NOT Android or Quest acceptance'},indent=2),encoding='utf-8')
print('QUEST_TRANSFER_PASS cases='+str(len(records))+' real_adb_client=1 android=0 headset=0',flush=True)

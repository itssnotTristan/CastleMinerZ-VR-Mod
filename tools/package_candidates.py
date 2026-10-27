"""Create reviewed, content-free candidate installers; never publish/deploy.

Run from a clean committed public checkout. --apk must be the exact verified
same-signer GitHub artifact referenced by QuestSetup/apk-info.json.
"""
from pathlib import Path
import argparse, hashlib, json, shutil, stat, subprocess, zipfile
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--apk',type=Path)
p.add_argument('--installer-version',default='0.58.3',choices=['0.58.1','0.58.2','0.58.3'])
p.add_argument('--quest-only',action='store_true',help='Do not repackage unaffected PC files')
a=p.parse_args()
assert not a.quest_only or a.apk,'--quest-only requires --apk'
a.output.mkdir(parents=True,exist_ok=True)
def sha(data):return hashlib.sha256(data).hexdigest()
tracked=subprocess.check_output(['git','ls-files','-z'],cwd=ROOT).decode().split('\0')[:-1]
assert not subprocess.check_output(['git','status','--porcelain','--untracked-files=no'],cwd=ROOT),'Commit reviewed source before packaging'
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
def committed(name):
    # Package the exact reviewed Git bytes, independent of autocrlf settings.
    return subprocess.check_output(['git','show','HEAD:'+name],cwd=ROOT)
for name in ('GeneratedHud.cs','Import-Validation.ps1','source-inputs.json','Setup-CastleMinerZVR.ps1'):
    assert (ROOT/'CastleMinerZVR'/name).read_bytes()==(ROOT/'QuestSetup/Tools'/name).read_bytes(),'PC/Quest importer drift: '+name
forbidden={'.xnb','.xwb','.xsb','.rgba','.mesh','.skin','.cube','.wav','.ogg','.save','.keystore','.jks','.pem','.key','.p12','.pfx','.log','.pdb'}
def package(stem,entries):
    report=[];target=a.output/(stem+'.zip')
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for name,data in sorted(entries.items()):
            path=Path(name)
            assert path.suffix.lower() not in forbidden and path.name not in ('CastleMinerZ.exe','DNA.Common.dll','DNA.Steam.dll') and not path.name.startswith('.env'),name
            assert '..' not in path.parts and not path.is_absolute()
            info=zipfile.ZipInfo(name,(1980,1,1,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.create_system=3;info.external_attr=(stat.S_IFREG|0o644)<<16
            z.writestr(info,data);report.append({'path':name,'bytes':len(data),'sha256':sha(data)})
    with zipfile.ZipFile(target) as z:assert z.testzip() is None
    data=target.read_bytes();digest=sha(data)
    (a.output/(target.name+'.sha256')).write_text(digest+'  '+target.name+'\n')
    return {'file':target.name,'bytes':len(data),'sha256':digest,'publicSourceCommit':commit,'files':report}
pc={name:committed(name) for name in tracked if not name.startswith(('QuestSetup/','tests/','tools/','.git'))}
assert 'CastleMinerZVR/CastleMinerZVR.exe' in pc and 'CastleMinerZVR/THIRD-PARTY-LICENSES.txt' in pc
reports=[] if a.quest_only else [package('CastleMinerZ-PCVR-v'+a.installer_version+'-SetupCandidate',pc)]
if a.apk:
    info=json.loads((ROOT/'QuestSetup/apk-info.json').read_text());apk=a.apk.read_bytes()
    assert len(apk)==info['bytes'] and sha(apk)==info['sha256'] and a.apk.name==info['apk']
    expected=(63,'0.58.3-quest3-pc-eye') if a.installer_version=='0.58.3' else (62,'0.58.1-installer-hud')
    assert (info['versionCode'],info['versionName'])==expected
    assert info['signerSha256']=='90feab64d6f679f199c4e39a9407e25f17d038de58ff3a047dcecae01ae1e737'
    with zipfile.ZipFile(a.apk) as z:
        assert z.testzip() is None
        assert [n for n in z.namelist() if n.startswith('assets/') and not n.endswith('/')]==['assets/cmz-asset-checksums.txt']
        assert b'\r' not in z.read('assets/cmz-asset-checksums.txt')
    quest={name[len('QuestSetup/'): ]:committed(name) for name in tracked if name.startswith('QuestSetup/')}
    quest[a.apk.name]=apk
    assert 'Tools/THIRD-PARTY-LICENSES.txt' in quest
    reports.append(package('CastleMinerZVR-Quest2-v'+a.installer_version+'-SetupCandidate',quest))
    shutil.copy2(a.apk,a.output/a.apk.name)
(a.output/'candidate-packages.json').write_text(json.dumps({'publication':'held','publicSourceCommit':commit,'packages':reports},indent=2)+'\n')
for report in reports:print(report['file'],report['bytes'],report['sha256'])

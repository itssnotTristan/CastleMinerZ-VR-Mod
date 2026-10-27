"""Execute production Windows installers against disposable fixtures and inert ADB.

CMZ_REAL_GAME/CMZ_IMPORTS are read-only, supported owned inputs. Thin fixture
manifests keep transaction tests small; the separate fresh-import run checks all
416 outputs. These tests do not install anything on a headset.
"""
from pathlib import Path
import hashlib, json, os, shutil, subprocess, tempfile, unittest

ROOT=Path(__file__).resolve().parents[1]
GAME=Path(os.environ['CMZ_REAL_GAME'])
IMPORTS=Path(os.environ['CMZ_IMPORTS'])
STUB=Path(os.environ['CMZ_ADB_STUB'])
PS=Path(os.environ.get('CMZ_TEST_PS',r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'))
BASE=Path(os.environ['CMZ_TEST_WORK'])
BASE.mkdir(parents=True,exist_ok=True)
identity=subprocess.run([str(STUB),'--cmz-test-double-identity'],capture_output=True,text=True,timeout=5)
if identity.returncode or identity.stdout.strip()!='CMZ_ADB_TEST_DOUBLE_V1':
    raise RuntimeError('CMZ_ADB_STUB must be the compiled inert AdbStub.exe, never real adb.exe')

def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def quoted(value):return "'"+str(value).replace("'","''")+"'"

class Installers(unittest.TestCase):
    def setUp(self):
        self.work=Path(tempfile.mkdtemp(prefix='case-',dir=BASE))
        self.quest=self.work/'Quest Setup'
        self.tools=self.quest/'Tools';self.tools.mkdir(parents=True)
        for p in (ROOT/'QuestSetup/Tools').iterdir():
            if p.is_file():shutil.copy2(p,self.tools/p.name)
        for name in ('Setup-QuestStandalone.ps1','Setup-QuestGameCheck.ps1'):
            shutil.copy2(ROOT/'QuestSetup'/name,self.quest/name)
        self.manifest=json.loads((self.tools/'import-manifest.json').read_text())
        self.manifest['assets']=[x for x in self.manifest['assets'] if x['path'] in ('game/hud-items.rgba','game/atlas.rgba')]
        (self.tools/'import-manifest.json').write_text(json.dumps(self.manifest))
        self.imports=self.work/'Private Imports';self.imports.mkdir()
        for name in ('hud-items.rgba','atlas.rgba','hud-items.sha256'):
            shutil.copy2(IMPORTS/name,self.imports/name)
        self.apk=self.quest/'CastleMinerZVR-Quest2-v0.58.3-PublicUpdate.apk'
        self.apk.write_bytes(b'INERT APK TEST DOUBLE - NOT INSTALLABLE')
        (self.quest/'apk-info.json').write_text(json.dumps({'bytes':self.apk.stat().st_size,'sha256':digest(self.apk)}))
        self.log=self.work/'adb.jsonl'
        self.env={**os.environ,'LOCALAPPDATA':str(self.work/'local'),'CMZ_ADB_LOG':str(self.log),'CMZ_ADB_MODE':'ok'}
        # Windows PowerShell must discover its own modules, not inherit a Core
        # module path from the test driver's shell.
        for key in list(self.env):
            if key.upper()=='PSMODULEPATH':del self.env[key]
    def run_script(self,script,args,mode='ok',inject=''):
        self.env['CMZ_ADB_MODE']=mode
        command=inject+'\n& '+quoted(script)+' '+ ' '.join(k+' '+quoted(v) if v is not None else k for k,v in args.items())
        wrapper=self.work/'invoke.ps1';wrapper.write_text("$ErrorActionPreference='Stop'\n$env:PSModulePath=Join-Path $PSHOME 'Modules'\nImport-Module Microsoft.PowerShell.Utility\n"+command)
        result=subprocess.run([str(PS),'-NoProfile','-ExecutionPolicy','Bypass','-File',str(wrapper)],env=self.env,capture_output=True,text=True,timeout=120)
        (self.work/'last.stdout.txt').write_text(result.stdout+result.stderr)
        return result
    def quest_args(self):return {'-GameDirectory':GAME,'-ImportDirectory':self.imports,'-Adb':STUB}
    def calls(self):return [json.loads(x) for x in self.log.read_text().splitlines()] if self.log.exists() else []
    def test_quest_device_and_activity_failures_are_read_only(self):
        for mode in ('none','multiple','unauthorized','phone','running'):
            result=self.run_script(self.quest/'Setup-QuestStandalone.ps1',self.quest_args(),mode)
            self.assertNotEqual(result.returncode,0,mode)
            calls=self.calls();self.assertFalse(any(x[0]=='-s' and len(x)>2 and x[2] in ('push','install') for x in calls),mode)
            self.assertNotIn('force-stop',str(calls));self.assertNotIn('uninstall',str(calls));self.assertNotIn('pm clear',str(calls))
            self.log.unlink()
    def test_quest_prepare_only_never_calls_adb(self):
        args=self.quest_args();args['-PrepareOnly']=None
        result=self.run_script(self.quest/'Setup-QuestStandalone.ps1',args)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr);self.assertEqual(self.calls(),[])
    def test_quest_native_stderr_uses_exit_status_in_both_entry_points(self):
        for script,args in (
            (self.quest/'Setup-QuestStandalone.ps1',self.quest_args()),
            (self.quest/'Setup-QuestGameCheck.ps1',{'-GameDirectory':GAME,'-Adb':STUB,'-NoLaunch':None}),
        ):
            result=self.run_script(script,args,'startup-stderr')
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertTrue(any(len(x)>2 and x[2]=='push' for x in self.calls()))
            self.log.unlink()
            result=self.run_script(script,args,'stderr')
            self.assertNotEqual(result.returncode,0)
            self.assertIn('Quest USB command failed (exit 7): synthetic USB failure',result.stdout+result.stderr)
            self.assertNotIn('NativeCommandError',result.stdout+result.stderr)
            self.assertFalse(any(len(x)>2 and x[2] in ('push','install') for x in self.calls()))
            self.log.unlink()
    def test_quest3_discovery_and_setup_preserve_quest2(self):
        for mode in ('ok','quest3','quest3-startup-stderr'):
            result=self.run_script(self.quest/'Setup-QuestStandalone.ps1',self.quest_args(),mode)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertTrue(any(len(x)>2 and x[2]=='install' for x in self.calls()))
            self.assertNotIn('uninstall',str(self.calls()));self.assertNotIn('pm clear',str(self.calls()))
            self.log.unlink()
    def test_quest_transfer_install_and_commit_failures_retry(self):
        for mode in ('transfer-fail','install-fail','commit-fail','ok'):
            result=self.run_script(self.quest/'Setup-QuestStandalone.ps1',self.quest_args(),mode)
            self.assertEqual(result.returncode==0,mode=='ok',result.stdout+result.stderr)
            calls=self.calls();install=[i for i,x in enumerate(calls) if len(x)>2 and x[2]=='install']
            verify=[i for i,x in enumerate(calls) if 'sha256sum -c' in str(x)]
            commit=[i for i,x in enumerate(calls) if 'if [ -d' in str(x)]
            if mode=='transfer-fail':self.assertFalse(install);self.assertFalse(commit)
            else:self.assertLess(verify[0],install[0]);self.assertIn('-r',calls[install[0]])
            if mode=='install-fail':self.assertFalse(commit)
            if mode=='ok':self.assertTrue(commit);self.assertNotIn("'am', 'start'",str(calls))
            self.assertNotIn('force-stop',str(calls));self.assertNotIn('uninstall',str(calls));self.assertNotIn('pm clear',str(calls))
            self.log.unlink()
    def test_apk_corruption_blocks_device_writes(self):
        self.apk.write_bytes(b'corrupt')
        result=self.run_script(self.quest/'Setup-QuestStandalone.ps1',self.quest_args())
        self.assertNotEqual(result.returncode,0);self.assertIn('integrity check',result.stdout+result.stderr)
        self.assertFalse(any(len(x)>2 and x[2] in ('push','install') for x in self.calls()))
    def test_generated_variant_receipt_and_deterministic_corruption(self):
        atlas=self.imports/'hud-items.rgba';data=bytearray(atlas.read_bytes())
        for i in range(8,len(data),4):
            if data[i+3] and data[i]>1:data[i]-=1;break
        atlas.write_bytes(data);(self.imports/'hud-items.sha256').write_bytes((digest(atlas)+'\n').encode('ascii'))
        args={'-GameDirectory':GAME,'-PrivateOutput':self.imports,'-VerifyOnly':None}
        result=self.run_script(self.tools/'Setup-CastleMinerZVR.ps1',args)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        policy=next(x for x in self.manifest['assets'] if x['path']=='game/hud-items.rgba')
        original_hash=policy['sha256'];policy['sha256']='e'*64
        (self.tools/'import-manifest.json').write_text(json.dumps(self.manifest))
        result=self.run_script(self.tools/'Setup-CastleMinerZVR.ps1',args)
        self.assertNotEqual(result.returncode,0);self.assertIn('Different: game/hud-items.rgba',result.stdout+result.stderr)
        policy['sha256']=original_hash;(self.tools/'import-manifest.json').write_text(json.dumps(self.manifest))
        result=self.run_script(self.quest/'Setup-QuestStandalone.ps1',self.quest_args())
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        checks=next((self.work/'local/CastleMinerZ-Quest-Setup').glob('checksums-*.txt')).read_text()
        self.assertIn(digest(atlas)+'  hud-items.rgba\n',checks)
        self.assertIn(next(x['sha256'] for x in self.manifest['assets'] if x['path']=='game/atlas.rgba')+'  atlas.rgba\n',checks)
        data[i]-=1;atlas.write_bytes(data)
        result=self.run_script(self.tools/'Setup-CastleMinerZVR.ps1',args)
        self.assertNotEqual(result.returncode,0);self.assertIn('receipt',result.stdout+result.stderr)
        shutil.copy2(IMPORTS/'hud-items.rgba',atlas)
        deterministic=self.imports/'atlas.rgba';data=bytearray(deterministic.read_bytes());data[100]^=1;deterministic.write_bytes(data)
        result=self.run_script(self.tools/'Setup-CastleMinerZVR.ps1',args)
        self.assertNotEqual(result.returncode,0);self.assertIn('Different: game/atlas.rgba',result.stdout+result.stderr)
    def test_pc_fresh_upgrade_rollback_retry_preserves_data(self):
        args={'-GameDirectory':GAME,'-ImportDirectory':self.imports}
        save=self.tools/'vr-world.save';save.write_bytes(b'SAVE-SENTINEL')
        settings=self.tools/'vr-settings.save';settings.write_bytes(b'SETTINGS-SENTINEL')
        hd=self.tools/'hd-textures';hd.mkdir();(hd/'keep.bin').write_bytes(b'HD-SENTINEL')
        script=self.tools/'Setup-CastleMinerZVR.ps1'
        result=self.run_script(script,args);self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertEqual(digest(self.tools/'game/hud-items.rgba'),digest(self.imports/'hud-items.rgba'))
        (self.tools/'game/prior-sidecar.txt').write_bytes(b'OLD-IMPORT-SENTINEL')
        injected="""function Move-Item {param([string]$LiteralPath,[string]$Destination)
if($LiteralPath -like '*game-import-*'){throw 'INJECTED COMMIT FAILURE'}
Microsoft.PowerShell.Management\\Move-Item -LiteralPath $LiteralPath -Destination $Destination
}"""
        result=self.run_script(script,args,inject=injected)
        self.assertNotEqual(result.returncode,0);self.assertEqual((self.tools/'game/prior-sidecar.txt').read_bytes(),b'OLD-IMPORT-SENTINEL')
        result=self.run_script(script,args);self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        backups=list(self.tools.glob('game-before-setup-*'))
        self.assertTrue(any((p/'prior-sidecar.txt').exists() for p in backups))
        self.assertEqual(save.read_bytes(),b'SAVE-SENTINEL');self.assertEqual(settings.read_bytes(),b'SETTINGS-SENTINEL');self.assertEqual((hd/'keep.bin').read_bytes(),b'HD-SENTINEL')
    def test_unsupported_original_fails_before_staging(self):
        fake=self.work/'Unsupported Game';fake.mkdir();(fake/'CastleMinerZ.exe').write_bytes(b'bad')
        result=self.run_script(self.tools/'Setup-CastleMinerZVR.ps1',{'-GameDirectory':fake,'-ImportDirectory':self.imports})
        self.assertNotEqual(result.returncode,0);self.assertFalse((self.tools/'game').exists())
        self.assertFalse((self.work/'local').exists())

if __name__=='__main__':unittest.main(verbosity=2)

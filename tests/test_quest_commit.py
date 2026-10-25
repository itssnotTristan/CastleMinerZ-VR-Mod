"""Execute the actual captured Quest commit shell command in a disposable lab.

The ADB stub records the command from the production script. Git Bash executes
that command with its fixed app path mapped into the workspace. No ADB/device is
used, and failure injection affects only this subprocess's mv function.
"""
from pathlib import Path
import argparse, json, re, shlex, subprocess, tempfile

p=argparse.ArgumentParser();p.add_argument('--adb-log',type=Path,required=True);p.add_argument('--work',type=Path,required=True);p.add_argument('--bash',type=Path,default=Path(r'C:\Program Files\Git\bin\bash.exe'));a=p.parse_args()
calls=[json.loads(x) for x in a.adb_log.read_text().splitlines()]
command=next(x[-1] for x in calls if len(x)>3 and x[2]=='shell' and x[-1].startswith('if [ -d '))
remote='/sdcard/Android/data/org.codex.castleminerzvr/files'
incoming=re.search(r'game-incoming-[0-9a-f]{32}',command)[0]
backup=re.search(r'game-before-setup-[0-9a-f]{32}',command)[0]
assert 'rm ' not in command and 'uninstall' not in command and '|| exit 1' in command
a.work.mkdir(parents=True,exist_ok=True)
checks=0
for mode in ('fresh','upgrade','first-move-fail','second-move-fail'):
    root=Path(tempfile.mkdtemp(prefix=mode+'-',dir=a.work)).resolve()
    assert root.is_relative_to(a.work.resolve())
    stage=root/incoming;stage.mkdir();(stage/'content.txt').write_text('NEW')
    (root/'vr-world.save').write_text('SAVE')
    if mode!='fresh':(root/'game').mkdir();(root/'game/content.txt').write_text('OLD')
    script=command.replace(remote,shlex.quote(root.as_posix()))
    if mode=='first-move-fail':script='mv(){ return 1; }; '+script
    if mode=='second-move-fail':script='mv(){ if [ "$1" = '+shlex.quote((root/incoming).as_posix())+' ]; then return 1; fi; command mv "$@"; }; '+script
    r=subprocess.run([str(a.bash),'--noprofile','--norc','-c',script],capture_output=True,text=True,timeout=15)
    assert (r.returncode==0)==(mode in ('fresh','upgrade')),(mode,r.stderr)
    assert (root/'vr-world.save').read_text()=='SAVE'
    assert (root/'game/content.txt').read_text()==('NEW' if mode in ('fresh','upgrade') else 'OLD')
    if mode=='upgrade':assert (root/backup/'content.txt').read_text()=='OLD'
    if mode.endswith('fail'):assert (stage/'content.txt').read_text()=='NEW'
    checks+=1;print('PASS',mode,'save and imports preserved')
print('QUEST_COMMIT_SHELL_PASS checks='+str(checks)+' actual_shell_command=1 physical_device=0')

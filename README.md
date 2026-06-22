# self-bucket
用法：

powershell
cd D:\scoop-bucket
.\update-bucket.ps1

只检查，不写入更新：

powershell
.\update-bucket.ps1 -CheckOnly

跳过某个有问题的 app，比如 light-c：

powershell
.\update-bucket.ps1 -Exclude light-c

更新后自动提交：

powershell
.\update-bucket.ps1 -Commit

更新、提交并推送：

powershell
.\update-bucket.ps1 -Commit -Push

如果 PowerShell 拦截脚本执行，临时用这个方式运行：

powershell
powershell -ExecutionPolicy Bypass -File .\update-bucket.ps1

这个脚本比直接跑 checkver.ps1 -App * -Dir . -u 更稳：它逐个 manifest 更新，某一个 app 报错不会影响其它软件。
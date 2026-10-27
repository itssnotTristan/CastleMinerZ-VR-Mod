// Inert argv/device double. Never connects to ADB or a headset.
using System;
using System.IO;
using System.Web.Script.Serialization;
class AdbStub {
    static int Main(string[] args) {
        if(args.Length==1&&args[0]=="--cmz-test-double-identity"){
            Console.WriteLine("CMZ_ADB_TEST_DOUBLE_V1");return 0;
        }
        var json=new JavaScriptSerializer();
        File.AppendAllText(Environment.GetEnvironmentVariable("CMZ_ADB_LOG"),json.Serialize(args)+"\n");
        string mode=Environment.GetEnvironmentVariable("CMZ_ADB_MODE")??"ok";
        string joined=string.Join(" ",args);
        if(mode=="stderr"){Console.Error.WriteLine("synthetic USB failure");return 7;}
        if(mode=="success-stderr"){
            Console.Error.WriteLine("synthetic daemon startup notice");
            Console.Out.WriteLine("synthetic stdout success");return 0;
        }
        if(mode=="stdout-only"){Console.Out.WriteLine("synthetic stdout success");return 0;}
        if(args.Length==2&&args[0]=="devices"&&args[1]=="-l"){
            if(mode=="startup-stderr"||mode=="quest3-startup-stderr")Console.Error.WriteLine("synthetic daemon startup notice");
            Console.WriteLine("List of devices attached");
            if(mode=="unauthorized")Console.WriteLine("QUEST-STUB unauthorized");
            else if(mode!="none")Console.WriteLine(mode.StartsWith("quest3")?"QUEST-STUB device product:eureka model:Quest_3":"QUEST-STUB device product:hollywood model:Quest_2");
            if(mode=="multiple")Console.WriteLine("QUEST-OTHER device model:Quest_3");
            Console.WriteLine("emulator-5562 device model:Quest_2");return 0;
        }
        if(joined.Contains("ro.product.model")){Console.WriteLine(mode=="phone"?"Pixel":mode.StartsWith("quest3")?"Quest 3":"Quest 2");return 0;}
        if(joined.Contains("pidof")){if(mode=="running")Console.WriteLine("running");return 0;}
        if(args.Length>2&&args[2]=="install"){
            if(mode=="install-fail"){Console.Error.WriteLine("INSTALL_FAILED_UPDATE_INCOMPATIBLE");return 1;}
            Console.WriteLine("Success");return 0;
        }
        if(joined.Contains("sha256sum -c")&&mode=="transfer-fail"){Console.Error.WriteLine("checksum failed");return 1;}
        if(joined.Contains("if [ -d")&&mode=="commit-fail"){Console.Error.WriteLine("commit failed (simulated)");return 1;}
        if(joined.Contains("pm path")){Console.WriteLine("package:/data/app/stub/base.apk");return 0;}
        if(joined.Contains("sha256sum")&&!joined.Contains(" -c "))Console.WriteLine("45d951391f204a20803c5e249d7f43fec0acbf320f5cf6c3e42ccccfe778cea3  CastleMinerZ.exe.pending");
        // Argv-only calls echo the exact native argument vector.
        if(args.Length==0||args[0]!="-s")Console.WriteLine(json.Serialize(args));
        return 0;
    }
}

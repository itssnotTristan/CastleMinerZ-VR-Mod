// Generated HUD validation policy v1. Counts/sums are non-reconstructable
// measurements, not texture pixels. SHA-256 receipts detect subsequent changes.
using System;
using System.IO;
public static class CmzGeneratedHud {
    static readonly int[] counts = new int[]{0,1891,1891,1891,1891,1891,1891,1891,1891,1891,1891,1891,1891,324,482,1505,1505,1505,1505,686,811,811,811,297,297,297,297,297,297,356,356,356,356,356,349,349,349,349,349,1190,1190,746,746,746,1013,1013,1013,1013,1013,460,391,473,278,258,515,460,391,473,278,258,515,460,391,473,278,258,515,460,391,473,278,258,515,1891,1891,1891,1414,1190,1190,1891,1891,0,732,1013,614,470,886,732,1013,614,470,886,732,1013,614,470,886,732,1013,614,470,886,1891,169,169,193,1088,1891,1088,1013,1273,746,169,169,219,219,219,219,219,360,360,360,360,546,0,0,972,1891,1891,1891,1891,1891,1891,1891,0,0,0,899,744,117,117,204,0,732,0,0,0,1414,1891,732,0,1891,0,1414,1414,0,0,0,0,0};
    static readonly int[] colors = new int[]{0,425227,749681,551485,501476,333941,543974,119744,343037,665395,484670,604126,289134,51660,47284,119976,155324,148830,170321,333999,191344,174130,222946,54626,46540,48260,52300,47879,36284,67236,52572,55421,62373,53930,56418,50891,52092,54202,51637,68149,73125,226027,158408,176235,288596,304621,219915,241989,174204,100856,58307,59220,30605,19969,68878,106907,58356,58283,30859,20286,69090,99637,58089,60626,30630,20041,69157,73955,57094,57098,30274,20020,66754,609650,1249199,935534,201048,74929,67197,562603,433789,0,122699,164530,95932,79774,178138,124032,163882,95261,79057,177620,130298,177530,99150,80863,186450,123631,164512,95713,79670,177372,420586,20991,0,26174,119712,343037,79885,233745,124660,154603,20991,0,41798,40921,63318,40752,84853,15341,15404,15089,14294,83306,0,0,94589,725062,648849,582205,360684,1153718,426613,842993,0,0,0,275771,187111,68561,68561,27980,0,74752,0,0,0,495842,776078,74124,0,849656,0,246684,458750,0,0,0,0,0};
    public static void Validate(string path) {
        using(var stream=File.OpenRead(path)) using(var r=new BinaryReader(stream)) {
            if(stream.Length!=2621448 || r.ReadInt32()!=512 || r.ReadInt32()!=1280)
                throw new InvalidDataException("Generated HUD dimensions or byte count are invalid.");
            int[] actual=new int[160], sums=new int[160];
            for(int y=0;y<1280;y++)for(int x=0;x<512;x++) {
                int red=r.ReadByte(),green=r.ReadByte(),blue=r.ReadByte(),alpha=r.ReadByte();
                int cell=(y/64)*8+x/64;
                if(alpha==0 && (red!=0 || green!=0 || blue!=0))
                    throw new InvalidDataException("Generated HUD has invalid transparent pixels.");
                if(alpha>0)actual[cell]++;
                sums[cell]+=red+green+blue;
            }
            for(int i=0;i<160;i++) {
                int coverageTolerance=Math.Max(16,counts[i]/4);
                int colorTolerance=Math.Max(4096,colors[i]*35/100);
                if((counts[i]==0 && (actual[i]!=0 || sums[i]!=0)) ||
                   (counts[i]>0 && (Math.Abs(actual[i]-counts[i])>coverageTolerance ||
                                    Math.Abs(sums[i]-colors[i])>colorTolerance)))
                    throw new InvalidDataException("Generated HUD icon failed coverage/color validation: "+i);
            }
        }
    }
}

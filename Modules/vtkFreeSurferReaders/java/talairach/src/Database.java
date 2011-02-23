// Decompiled by DJ v3.5.5.77 Copyright 2003 Atanas Neshkov  Date: 10/17/2003 11:03:24 AM
// Home Page : http://members.fortunecity.com/neshkov/dj.html  - Check often for new version!
// Decompiler options: packimports(3)
// Source File Name:   Database.java

import java.io.*;
import java.util.Hashtable;
import java.util.StringTokenizer;

public class Database
{

    public Database()
    {
        Labels = new String[255];
        Level = new byte[255];
        Error = new String();
        loaded = false;
    }

    public void Load_Database(String s, String dbTextFile)
    {
        int i = 0;
        d_lenght = 0;
        try
        {
            FileInputStream fileinputstream = new FileInputStream(s);
            BufferedInputStream bufferedinputstream = new BufferedInputStream(fileinputstream, 1000);
            DataInputStream datainputstream1 = new DataInputStream(bufferedinputstream);
            d_lenght = datainputstream1.readInt();
            TD_brain = new Hashtable(d_lenght + 1000, 1.0F);
            String s1 = new String();
            for(long l = 0L; l < (long)d_lenght; l++)
            {
                boolean flag = false;
                byte byte0 = datainputstream1.readByte();
                String s2 = "";
                short word0 = datainputstream1.readByte();
                s2 = s2 + word0 + ",";
                word0 = datainputstream1.readByte();
                s2 = s2 + word0 + ",";
                word0 = datainputstream1.readByte();
                s2 = s2 + word0;
                byte abyte0[] = new byte[byte0 - 3];
                for(int i1 = 0; i1 < byte0 - 3; i1++)
                    abyte0[i1] = datainputstream1.readByte();

                TD_brain.put(s2, abyte0);
                if(++i == 1000)
                {
                    // IBO
                    // father.prog.update(((int)l * 100) / d_lenght);
                    i = 0;
                }
            }

        }
        catch(IOException ioexception)
        {
            Error = ioexception.toString();
            ioexception.printStackTrace();
            loaded = false;
        }
        try
        {
            //IBO
            DataInputStream datainputstream = new DataInputStream(new FileInputStream(dbTextFile));   //"./database/database.txt"));
            int j = Integer.valueOf(datainputstream.readLine()).intValue();
            for(int k = 0; k < j;)
            {
                StringTokenizer stringtokenizer = new StringTokenizer(datainputstream.readLine(), ",");
                Labels[k] = stringtokenizer.nextToken();
                Level[k++] = Byte.valueOf(stringtokenizer.nextToken()).byteValue();
            }

            loaded = true;
            return;
        }
        catch(Exception exception)
        {
            Error = "Error in loading database headers from file" + exception.toString();
        }
        loaded = false;
    }

    boolean equals(TDLabel tdlabel, TDLabel tdlabel1)
    {
        byte byte0 = 0;
        for(int i = 0; i < 5; i++)
            if(tdlabel.pointer[i] - tdlabel1.pointer[i] == 0)
                byte0++;

        return byte0 == 5;
    }

    TDLabel[] search_range(int i, int j, int k, int l)
    {
        int j3 = 0;
        j3 = 2 * l + 1;
        TDLabel atdlabel[] = new TDLabel[(j3 * j3 * j3) / 3];
        j3 = 0;
        for(int k2 = k - l; k2 < k + l + 1; k2++)
        {
            for(int l1 = j - l; l1 < j + l + 1; l1++)
            {
                for(int i1 = i - l; i1 < i + l + 1; i1++)
                {
                    TDLabel tdlabel = find_label(i1, l1, k2);
                    if(tdlabel != null)
                    {
                        boolean flag = false;
                        for(int i3 = 0; i3 < j3; i3++)
                            if(equals(atdlabel[i3], tdlabel))
                            {
                                atdlabel[i3].hits[0]++;
                                flag = true;
                                i3 = j3;
                            }

                        if(!flag)
                        {
                            atdlabel[j3] = tdlabel;
                            atdlabel[j3].hits[0] = 1;
                            j3++;
                        }
                    }
                }

            }

        }

        int j1 = 0;
        for(int i2 = 0; i2 < j3; i2++)
            if(atdlabel[i2] != null)
                j1++;

        int l2 = 0;
        TDLabel atdlabel1[] = new TDLabel[j1];
        short word0 = 0;
        for(int j2 = 0; j2 < j3; j2++)
        {
            int k3 = 0;
            for(int k1 = 0; k1 < j3; k1++)
                if(atdlabel[k1].hits[0] > k3)
                {
                    k3 = atdlabel[k1].hits[0];
                    word0 = (short)k1;
                }

            if(k3 > 0)
            {
                atdlabel1[l2] = atdlabel[word0];
                atdlabel1[l2].hits[1] = atdlabel1[l2].hits[0];
                atdlabel[word0].hits[0] = 0;
                l2++;
            }
        }

        return atdlabel1;
    }

    TDLabel find_label(String s)
    {
        if(!loaded)
        {
            TDLabel tdlabel = new TDLabel();
            tdlabel.Labels[0] = "No Data Base is Loaded restart program from original directory";
        }
        byte abyte0[] = (byte[])TD_brain.get(s);
        if(abyte0 == null)
            return null;
        TDLabel tdlabel1 = new TDLabel();
        int i = abyte0.length;
        String s1 = new String();
        boolean flag = false;
        for(int k = 0; k < i / 2; k++)
        {
            byte byte0;
            byte byte1 = byte0 = 0;
            int j = abyte0[2 * k];
            if(j <= 0)
                j = -j + 127;
            String s2 = Labels[j - 1];
            byte1 = Level[j - 1];
            byte0 = abyte0[2 * k + 1];
            if(tdlabel1.hits[byte1 - 1] < byte0)
            {
                tdlabel1.pointer[byte1 - 1] = abyte0[2 * k];
                tdlabel1.Labels[byte1 - 1] = s2;
                tdlabel1.hits[byte1 - 1] = byte0;
            }
        }

        return tdlabel1;
    }

    TDLabel find_GM(int i, int j, int k)
    {
        TDLabel tdlabel = find_label(i, j, k);
        if(tdlabel != null && (tdlabel.pointer[3] == 79 || tdlabel.pointer[3] == 82))
        {
            tdlabel.hits[0] = 1;
            return tdlabel;
        }
        TDLabel atdlabel[] = search_range(i, j, k, 1);
        for(int l = 0; l < atdlabel.length; l++)
            if(atdlabel[l].pointer[3] == 79 || atdlabel[l].pointer[3] == 82)
            {
                atdlabel[l].hits[0] = 3;
                return atdlabel[l];
            }

        atdlabel = search_range(i, j, k, 2);
        for(int i1 = 0; i1 < atdlabel.length; i1++)
            if(atdlabel[i1].pointer[3] == 79 || atdlabel[i1].pointer[3] == 82)
            {
                atdlabel[i1].hits[0] = 5;
                return atdlabel[i1];
            }

        atdlabel = search_range(i, j, k, 3);
        for(int j1 = 0; j1 < atdlabel.length; j1++)
            if(atdlabel[j1].pointer[3] == 79 || atdlabel[j1].pointer[3] == 82)
            {
                atdlabel[j1].hits[0] = 7;
                return atdlabel[j1];
            }

        atdlabel = search_range(i, j, k, 4);
        for(int k1 = 0; k1 < atdlabel.length; k1++)
            if(atdlabel[k1].pointer[3] == 79 || atdlabel[k1].pointer[3] == 82)
            {
                atdlabel[k1].hits[0] = 9;
                return atdlabel[k1];
            }

        atdlabel = search_range(i, j, k, 5);
        for(int l1 = 0; l1 < atdlabel.length; l1++)
            if(atdlabel[l1].pointer[3] == 79 || atdlabel[l1].pointer[3] == 82)
            {
                atdlabel[l1].hits[0] = 11;
                return atdlabel[l1];
            }

        return null;
    }

    TDLabel find_label(int i, int j, int k)
    {
        String s = new String();
        s = i + "," + j + "," + k;
        byte abyte0[] = (byte[])TD_brain.get(s);
        if(abyte0 == null)
        {
            String s1 = i + "," + j + "," + (k + 1);
            abyte0 = (byte[])TD_brain.get(s1);
            if(abyte0 == null)
            {
                String s2 = i + "," + j + "," + (k - 1);
                abyte0 = (byte[])TD_brain.get(s2);
                if(abyte0 == null)
                {
                    String s3 = i + "," + j + "," + (k + 2);
                    abyte0 = (byte[])TD_brain.get(s3);
                    if(abyte0 == null)
                    {
                        String s4 = i + "," + j + "," + (k - 2);
                        abyte0 = (byte[])TD_brain.get(s4);
                        if(abyte0 == null)
                            return null;
                    }
                }
            }
        }
        TDLabel tdlabel = new TDLabel();
        int l = abyte0.length;
        String s5 = new String();
        boolean flag = false;
        for(int j1 = 0; j1 < l / 2; j1++)
        {
            byte byte0;
            byte byte1 = byte0 = 0;
            int i1 = abyte0[2 * j1];
            if(i1 <= 0)
                i1 = -i1 + 127;
            String s6 = Labels[i1 - 1];
            byte1 = Level[i1 - 1];
            byte0 = abyte0[2 * j1 + 1];
            if(tdlabel.hits[byte1 - 1] < byte0)
            {
                tdlabel.pointer[byte1 - 1] = abyte0[2 * j1];
                tdlabel.Labels[byte1 - 1] = s6;
                tdlabel.hits[byte1 - 1] = byte0;
            }
        }

        return tdlabel;
    }

    String Labels[];
    byte Level[];
    int d_lenght;
    Hashtable TD_brain;
    String Error;
    boolean loaded;
}
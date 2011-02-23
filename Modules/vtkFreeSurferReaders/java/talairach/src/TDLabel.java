// Decompiled by DJ v3.5.5.77 Copyright 2003 Atanas Neshkov  Date: 10/17/2003 11:19:36 AM
// Home Page : http://members.fortunecity.com/neshkov/dj.html  - Check often for new version!
// Decompiler options: packimports(3) 
// Source File Name:   TDLabel.java


public class TDLabel
{

    public TDLabel()
    {
        pointer = new short[5];
        Labels = new String[5];
        hits = new short[5];
        for(int i = 0; i < 5; i++)
        {
            pointer[i] = 0;
            Labels[i] = "*";
            hits[i] = 0;
        }

    }

    public String toStr()
    {
        String s = new String();
        for(int i = 0; i < 5; i++)
            s = s + Labels[i] + ",";

        return s;
    }

    short pointer[];
    String Labels[];
    short hits[];
}
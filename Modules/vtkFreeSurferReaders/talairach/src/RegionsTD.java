import java.awt.*;
import java.io.*;
import java.util.StringTokenizer;
import java.lang.*;

public class RegionsTD {
   protected Database database = new Database();
   protected static RegionsTD instance = null;


  protected RegionsTD() {}

  /**
   * delibrately not thread safe. Needs to be created at the startup in single thread
   * operation mode.
   * @return
   */
  public static RegionsTD getInstance() {
      if (instance == null)
        instance = new RegionsTD();
      return instance;
  }


  public void startup(String dbPath, String dbTextFilePath) throws Exception {
     String homeDir = System.getProperty("user.home");
     String databasePath = homeDir + File.separator + "database/database.dat";
     System.out.println("databasePath="+ databasePath);
     database.Load_Database( dbPath , dbTextFilePath);
     if (!database.loaded)
       throw new Exception(database.Error);
  }

  public void shutdown() {}


  public String getTalairachLabel(int x, int y, int z) {
    TDLabel tdlabel1 = database.find_GM(x,y,z);
    String s = null;
    if (tdlabel1 == null)
      s = "No GM is found even in the 11x11x11mm cube range";
    else
      s = tdlabel1.toStr() + "Range=" + tdlabel1.hits[0];
    return s;
  }

   public void process(InputStream in, OutputStream out) throws IOException {
     // DataInputStream din = new DataInputStream( new BufferedInputStream( in ) );
     BufferedInputStream bin = new BufferedInputStream( in ) ;

     DataOutputStream dout = new DataOutputStream( out );	
    
     byte[] barr = new byte[11];
     bin.read(barr);

     String request = new String(barr);
     System.out.println("request="+ request);
     StringTokenizer st = new StringTokenizer(request," ");
     String xx = st.nextToken();
     String yy = st.nextToken();
     String zz = st.nextToken();

     int x = Integer.parseInt(xx);
     int y = Integer.parseInt(yy);
     int z = Integer.parseInt(zz);
    
     /*String ints;

     ints = din.readUTF();
     System.out.println(ints);
     StringTokenizer st = new StringTokenizer(ints," ");
     String xx = st.nextToken();
     String yy = st.nextToken();
     String zz = st.nextToken();

     //int x = Integer.parseInt(xx);
     //int y = Integer.parseInt(yy);
    /int z = Integer.parseInt(zz);
   

     int x,y,z;
     x = din.readInt();
     y = din.readInt();
     z = din.readInt();
     System.out.println("x="+ x + " y=" + y + " z=" + z);*/
     // get the talairach label and send it back to the client
     String result = getTalairachLabel(x,y,z);
     dout.writeUTF(result);
     dout.flush();
   }
  public static void main(String args[]) {
    Database TDdatabase = new Database();

    TDdatabase.Load_Database("./database/database.dat", "./database/database.txt");

    if (!TDdatabase.loaded) {
      System.out.println(TDdatabase.Error);
    }
    int x = 1, y = 1, z = 1;
    TDLabel tdlabel1 = TDdatabase.find_GM(x,y,z);
    String s = null;
    if (tdlabel1 == null)
      s = "No GM is found even in the 11x11x11mm cube range";
    else
      s = tdlabel1.toStr() + "Range=" + tdlabel1.hits[0];
    System.out.println(s);
  }

}


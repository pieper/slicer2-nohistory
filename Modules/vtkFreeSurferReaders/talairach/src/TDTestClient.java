import java.net.*;
import java.io.*;
import java.util.StringTokenizer;

public class TDTestClient {
  protected Socket sock;

  public TDTestClient(String host,int serverPort) throws Exception {
    sock = new Socket(host, serverPort);
  }


  public void testServer()  {

    DataInputStream din = null;
    DataOutputStream dout = null;
     try {
       din = new DataInputStream( new BufferedInputStream( sock.getInputStream() ) );
       dout = new DataOutputStream( sock.getOutputStream() );
       int x,y,z;
       BufferedReader in = new BufferedReader( new InputStreamReader( System.in ) );

       while(true) {
         System.out.print("Enter x,y,z coordinates (for example 12 12 14) To exit just press Enter >>");
         String ans = in.readLine();
         if (ans.trim().length() == 0)
           break;
         StringTokenizer stok = new StringTokenizer(ans," \t");
         if (stok.countTokens() != 3)
           continue;
         x = Integer.parseInt( stok.nextToken());
         y = Integer.parseInt( stok.nextToken());
         z = Integer.parseInt( stok.nextToken());

         // send coordinates
         dout.writeInt(x);
         dout.writeInt(y);
         dout.writeInt(z);
         dout.flush();
         // read the label send by the Regions server
         String label = din.readUTF();
         System.out.println("label gotten :"+ label);
       }
     } catch (Exception ex) {
       ex.printStackTrace();
     } finally {
       if ( din != null) try {  din.close(); } catch(Exception ex) { /* ignore */ }
       if ( dout != null) try {  dout.close(); } catch(Exception ex) { /* ignore */ }
       if ( sock != null) try {  sock.close(); } catch(Exception ex) { /* ignore */ }
     }

  }

  public static void main(String[] args) {
    TDTestClient client = null;
    try {
      client = new TDTestClient("localhost",19000);
        client.testServer();

    } catch(Exception x) {
      x.printStackTrace();
    }
  }

}
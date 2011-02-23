import java.io.*;
import java.net.*;

public class RegionsServer implements Runnable {
  private Socket socket;

  public RegionsServer(Socket socket) {
     this.socket = socket;
  }


  public void run() {
     System.out.println("Client "+ socket.getInetAddress().toString()+ " has connected!");
     InputStream in = null;
     OutputStream out = null;
     try {
       in = socket.getInputStream();
       out = socket.getOutputStream();
       RegionsTD.getInstance().process(in,out);
     } catch (Exception ex) {
       ex.printStackTrace();
     } finally {
       if ( in != null) try {  in.close(); } catch(Exception ex) { /* ignore */ }
       if ( out != null) try {  out.close(); } catch(Exception ex) { /* ignore */ }
     }
  }

  public static void usage() {
    System.err.println("Usage: runtd.sh <server-port-number> <db-filename> <db-text-filename>");
    System.exit(1);
  }
  public static void main(String[] args) {
    int serverPort = -1;
    if ( args.length != 3) {
      usage();
    }
    try {
      serverPort = Integer.parseInt(args[0]);
    } catch(NumberFormatException nfe) {
      serverPort = 19000;
    }
    String dbPath = args[1];
    String dbTextFilePath = args[2];
    ServerSocket ss = null;
    try {
       ss = new ServerSocket(serverPort);
       RegionsTD regionsTD = RegionsTD.getInstance();
       regionsTD.startup(dbPath, dbTextFilePath);
       System.out.println("Waiting clients on port "+ serverPort+ "...");
       while(true) {
          Thread th = new Thread( new RegionsServer( ss.accept() ) );
          th.start();
       }
    } catch(Exception x) {
      x.printStackTrace();
    } finally {
      RegionsTD.getInstance().shutdown();
    }

  }
}
import java.io.*;
import java.util.*;

import org.apache.axis.client.Call;
import org.apache.axis.client.Service;
import org.apache.axis.encoding.XMLType;
import org.apache.axis.utils.Options;
import javax.xml.rpc.ParameterMode;

/**
 *
 *  @author I. Burak Ozyurt
 *  @version $Id: StatsSOAPClient.java,v 1.1 2004/03/17 20:21:58 ajoyner Exp $
 */
public class StatsSOAPClient {
  public StatsSOAPClient() {}


    public static void usage() {
	System.err.println("Usage:java StatsSOAPClient <population-ids-file-path> <subjectid>");
	System.exit(1);
    }

    protected static String[] loadPopIds(String filename) throws Exception {
	BufferedReader in = null;
	try {
	    in = new BufferedReader( new FileReader(filename) );
	    String line = null;
	    List idList = new LinkedList();
	    while( ( line = in.readLine() ) != null) {
		idList.add(line);
	    }
	    String[] ids = new String[ idList.size() ];
	    return (String[]) idList.toArray(ids);
	} finally {
	    if (in != null)
		try { in.close(); } catch(Exception x) {}
	}
    }
    
    public static void getStats(String[] args) throws Exception {
	// String[] args = {"-p8080"};
	Options options = new Options(args);
	// for SSL trust manager support
	/*
	  System.getProperties().setProperty("javax.net.ssl.trustStore",
	  "/home/bozyurt/testbed/web_services/clinical_client.ks");
	  System.getProperties().setProperty("javax.net.ssl.keyStore",
	  "/home/bozyurt/testbed/web_services/clinical_client.ks");
	  System.getProperties().setProperty("javax.net.ssl.keyStorePassword",
	  "<pwd>");
	*/
	args = options.getRemainingArgs();
	if ( args == null || args.length != 2) {
	    usage();
	}
	// System.out.println(">> host=" + options.getHost());
	String host = (options.getHost() == null) ? "192.168.147.71" : options.getHost();
	String endPoint = "http://"+ host  +":" + options.getPort() + "/clinical/services/StatsService";
	System.out.println("endpoint="+ endPoint);
	
	String popIDsFile = args[0];
	String subjectID= args[1];
	
	String method = "getDerivedDataStatsForSubject";
	String[] popIds = loadPopIds(popIDsFile); 
	Service service = new Service();
	Call call = (Call) service.createCall();
	call.setTargetEndpointAddress( new java.net.URL(endPoint) );
	call.setOperationName(method);
	call.addParameter("op1", XMLType.XSD_STRING,ParameterMode.IN);
	call.addParameter("op2", XMLType.SOAP_ARRAY,String[].class, ParameterMode.IN);
	call.setReturnType(XMLType.XSD_STRING, String.class);
	// UCSD00156805
	String result = (String) call.invoke( new Object[] { subjectID, popIds });
	
	System.out.println("Result\n----------");
	System.out.println(result);
    }
    
    public static void main(String[] args) throws Exception {            
	getStats(args);
    }
    
}

/*     */ package de.tsystems.mms.tic;
/*     */ 
/*     */ import java.io.File;
/*     */ import java.io.FileInputStream;
/*     */ import java.io.IOException;
/*     */ import java.io.InputStream;
/*     */ import java.net.Socket;
/*     */ import java.net.UnknownHostException;
/*     */ import java.security.KeyManagementException;
/*     */ import java.security.KeyStore;
/*     */ import java.security.KeyStoreException;
/*     */ import java.security.NoSuchAlgorithmException;
/*     */ import java.security.SecureRandom;
/*     */ import java.security.UnrecoverableKeyException;
/*     */ import java.security.cert.CertificateException;
/*     */ import java.text.MessageFormat;
/*     */ import java.util.Properties;
/*     */ import javax.net.ssl.KeyManagerFactory;
/*     */ import javax.net.ssl.SSLContext;
/*     */ import javax.net.ssl.SSLServerSocket;
/*     */ import javax.net.ssl.SSLServerSocketFactory;
/*     */ import org.apache.log4j.Logger;
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ public class ProvisioningServerMock
/*     */ {
/*     */   private SSLServerSocket serverSocket;
/*     */   public static final String keystoreFileName = "server.jks";
/*     */   public static final String keystorePassword = "123456";
/*     */   public static final String keyPass = "123456";
/*  33 */   private static Logger m_log = Logger.getLogger(ProvisioningServerMock.class);
/*     */   
/*  35 */   public static Properties prop = new Properties();
/*     */   
/*     */ 
/*     */ 
/*     */ 
/*     */   public static void main(String[] args)
/*     */   {
/*  42 */     InputStream input = null;
/*     */     try {
/*  44 */       input = new FileInputStream("config.properties");
/*     */       
/*  46 */       prop.load(input);
/*     */       
/*  48 */       new ProvisioningServerMock().startUp();
/*     */     } catch (IOException e) {
/*  50 */       e.printStackTrace();
/*     */     }
/*     */   }
/*     */   
/*     */   private void startUp() throws IOException
/*     */   {
/*     */     try
/*     */     {
/*  58 */       KeyStore ks = KeyStore.getInstance("JKS");
/*     */       
/*  60 */       File keystoreFile = new File("server.jks");
/*  61 */       ks.load(new FileInputStream(keystoreFile), "123456".toCharArray());
/*  62 */       KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
/*  63 */       kmf.init(ks, "123456".toCharArray());
/*     */       
/*     */ 
/*  66 */       SSLContext sc = SSLContext.getInstance("TLS");
/*  67 */       sc.init(kmf.getKeyManagers(), null, new SecureRandom());
/*     */       
/*  69 */       SSLServerSocketFactory ssf = sc.getServerSocketFactory();
/*  70 */       this.serverSocket = ((SSLServerSocket)ssf.createServerSocket(Integer.parseInt(prop.getProperty("port"))));
/*  71 */       this.serverSocket.setNeedClientAuth(false);
/*  72 */       this.serverSocket.setWantClientAuth(false);
/*     */       
/*  74 */       m_log.info("Server started:");
/*  75 */       m_log.info("   Local socket address = " + this.serverSocket.getLocalSocketAddress().toString());
/*  76 */       m_log.info("   Local port = " + this.serverSocket.getLocalPort());
/*     */     }
/*     */     catch (UnknownHostException localUnknownHostException) {}catch (CertificateException e)
/*     */     {
/*  80 */       e.printStackTrace();
/*     */     } catch (UnrecoverableKeyException e) {
/*  82 */       e.printStackTrace();
/*     */     } catch (NoSuchAlgorithmException e) {
/*  84 */       e.printStackTrace();
/*     */     } catch (KeyStoreException e) {
/*  86 */       e.printStackTrace();
/*     */     } catch (KeyManagementException e) {
/*  88 */       e.printStackTrace();
/*     */     }
/*  90 */     Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
/*     */       public void run() {
/*  92 */         ProvisioningServerMock.this.shutDown();
/*     */       }
/*     */     }));
/*     */     for (;;)
/*     */     {
/*  97 */       Socket incomingRequest = this.serverSocket.accept();
/*  98 */       new Thread(new RequestHandler(incomingRequest)).start();
/*     */     }
/*     */   }
/*     */   
/*     */   private void shutDown() {
/* 103 */     if (this.serverSocket != null) {
/*     */       try {
/* 105 */         m_log.info("Shutting down server ...");
/* 106 */         this.serverSocket.close();
/* 107 */         m_log.info(" done");
/*     */       } catch (IOException ioEx) {
/* 109 */         m_log.info(MessageFormat.format(
/* 110 */           "An exception occurred while shutting down the test socket server: {0}", new Object[] {
/* 111 */           ioEx.getMessage() }));
/* 112 */         ioEx.printStackTrace(System.err);
/*     */       }
/*     */     }
/*     */   }
/*     */ }


/* Location:              /root/testnetzrepository/provisioning-mock-0.3.jar!/de/tsystems/mms/tic/ProvisioningServerMock.class
 * Java compiler version: 7 (51.0)
 * JD-Core Version:       0.7.1
 */
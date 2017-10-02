/*     */ package de.tsystems.mms.tic;
/*     */ 
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
/*     */ public class ProvisioningServerMock
/*     */ {
/*     */   private SSLServerSocket serverSocket;
/*  28 */   private static Logger m_log = Logger.getLogger(ProvisioningServerMock.class);
/*     */   
/*  30 */   public static Properties prop = new Properties();
/*     */   
/*     */ 
/*     */ 
/*     */ 
/*     */   public static void main(String[] args)
/*     */   {
/*  37 */     InputStream input = null;
/*     */     try {
/*  39 */       input = new FileInputStream("config.properties");
/*     */       
/*  41 */       prop.load(input);
/*     */       
/*  43 */       new ProvisioningServerMock().startUp();
/*     */     } catch (IOException e) {
/*  45 */       e.printStackTrace();
/*     */     }
/*     */   }
/*     */   
/*     */   private void startUp() throws IOException
/*     */   {
/*     */     try {
/*  52 */       m_log.info("   Using Keystorefile: " + prop.getProperty("keystoreFileName"));
/*  53 */       m_log.info("   Using Keystorepassword: " + prop.getProperty("keystorePassword"));
/*  54 */       m_log.info("   Using Keypassword: " + prop.getProperty("keyPass"));
/*     */       
/*  56 */       KeyStore ks = KeyStore.getInstance("JKS");
/*  57 */       FileInputStream keystoreFile = new FileInputStream(prop.getProperty("keystoreFileName"));
/*  58 */       ks.load(keystoreFile, prop.getProperty("keystorePassword").toCharArray());
/*  59 */       KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
/*  60 */       kmf.init(ks, prop.getProperty("keyPass").toCharArray());
/*     */       
/*  62 */       SSLContext sc = SSLContext.getInstance("TLS");
/*  63 */       sc.init(kmf.getKeyManagers(), null, new SecureRandom());
/*     */       
/*  65 */       SSLServerSocketFactory ssf = sc.getServerSocketFactory();
/*  66 */       this.serverSocket = ((SSLServerSocket)ssf.createServerSocket(Integer.parseInt(prop.getProperty("port"))));
/*  67 */       this.serverSocket.setNeedClientAuth(false);
/*  68 */       this.serverSocket.setWantClientAuth(false);
/*     */       
/*  70 */       m_log.info("   Local socket address = " + this.serverSocket.getLocalSocketAddress().toString());
/*  71 */       m_log.info("   Local port = " + this.serverSocket.getLocalPort());
/*  72 */       m_log.info("Server started:");
/*     */     }
/*     */     catch (UnknownHostException localUnknownHostException) {}catch (CertificateException e)
/*     */     {
/*  76 */       e.printStackTrace();
/*     */     } catch (UnrecoverableKeyException e) {
/*  78 */       e.printStackTrace();
/*     */     } catch (NoSuchAlgorithmException e) {
/*  80 */       e.printStackTrace();
/*     */     } catch (KeyStoreException e) {
/*  82 */       e.printStackTrace();
/*     */     } catch (KeyManagementException e) {
/*  84 */       e.printStackTrace();
/*     */     }
/*  86 */     Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
/*     */       public void run() {
/*  88 */         ProvisioningServerMock.this.shutDown();
/*     */       }
/*     */     }));
/*     */     for (;;)
/*     */     {
/*  93 */       Socket incomingRequest = this.serverSocket.accept();
/*  94 */       new Thread(new RequestHandler(incomingRequest)).start();
/*     */     }
/*     */   }
/*     */   
/*     */   private void shutDown() {
/*  99 */     if (this.serverSocket != null) {
/*     */       try {
/* 101 */         m_log.info("Shutting down server ...");
/* 102 */         this.serverSocket.close();
/* 103 */         m_log.info(" done");
/*     */       } catch (IOException ioEx) {
/* 105 */         m_log.info(MessageFormat.format(
/* 106 */           "An exception occurred while shutting down the test socket server: {0}", new Object[] {
/* 107 */           ioEx.getMessage() }));
/* 108 */         ioEx.printStackTrace(System.err);
/*     */       }
/*     */     }
/*     */   }
/*     */ }


/* Location:              /root/testnetzrepository/provisioning-mock-0.4.jar!/de/tsystems/mms/tic/ProvisioningServerMock.class
 * Java compiler version: 6 (50.0)
 * JD-Core Version:       0.7.1
 */
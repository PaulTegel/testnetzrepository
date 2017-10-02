/*     */ package de.tsystems.mms.tic;
/*     */ 
/*     */ import java.io.BufferedReader;
/*     */ import java.io.BufferedWriter;
/*     */ import java.io.FileInputStream;
/*     */ import java.io.IOException;
/*     */ import java.io.InputStream;
/*     */ import java.io.InputStreamReader;
/*     */ import java.io.OutputStreamWriter;
/*     */ import java.net.Socket;
/*     */ import java.text.SimpleDateFormat;
/*     */ import java.util.Date;
/*     */ import java.util.Properties;
/*     */ import org.apache.log4j.Logger;
/*     */ 
/*     */ public class RequestHandler implements Runnable
/*     */ {
/*  18 */   private static Logger m_log = Logger.getLogger(RequestHandler.class);
/*  19 */   public static Properties prop = new Properties();
/*  20 */   public static Properties register = new Properties();
/*  21 */   public static Properties deregister = new Properties();
/*  22 */   public static Properties status = new Properties();
/*     */   
/*  24 */   private Socket rs = null;
/*  25 */   private BufferedReader reader = null;
/*  26 */   private BufferedWriter output = null;
/*     */   
/*  28 */   String message = "";
/*  29 */   String log = "";
/*  30 */   String header = "";
/*  31 */   String i = "";
/*     */   
/*     */ 
/*     */   public RequestHandler(Socket requestSocket)
/*     */   {
/*  36 */     this.rs = requestSocket;
/*     */     try {
/*  38 */       this.reader = new BufferedReader(new InputStreamReader(this.rs.getInputStream()));
/*  39 */       this.output = new BufferedWriter(new OutputStreamWriter(this.rs.getOutputStream()));
/*     */     } catch (IOException e) {
/*  41 */       e.printStackTrace();
/*  42 */       e.getCause().printStackTrace();
/*     */     }
/*     */   }
/*     */   
/*     */   private String getLine() throws IOException {
/*  47 */     return this.reader.readLine();
/*     */   }
/*     */   
/*     */   public void run()
/*     */   {
/*     */     try {
/*  53 */       InputStream input = null;
/*  54 */       input = new FileInputStream("config.properties");
/*     */       
/*  56 */       prop.load(input);
/*     */       
/*  58 */       InputStream registerresponse = null;
/*  59 */       registerresponse = new FileInputStream("register.response.txt");
/*  60 */       register.load(registerresponse);
/*     */       
/*  62 */       InputStream deregisterresponse = null;
/*  63 */       deregisterresponse = new FileInputStream("deregister.response.txt");
/*  64 */       deregister.load(deregisterresponse);
/*     */       
/*  66 */       InputStream statusresponse = null;
/*  67 */       statusresponse = new FileInputStream("status.response.txt");
/*  68 */       status.load(statusresponse);
/*     */       
/*     */ 
/*     */ 
/*  72 */       String requestType = "";
/*     */       
/*     */       String incoming;
/*  75 */       while ((incoming = getLine()) != null) { String incoming;
/*  76 */         incoming.trim();
/*  77 */         if (incoming.contains("urn:#regOperation")) {
/*  78 */           requestType = "regOperation";
/*  79 */         } else if (incoming.contains("urn:#deregOperation")) {
/*  80 */           requestType = "deregOperation";
/*  81 */         } else if (incoming.contains("urn:#statusOperation")) {
/*  82 */           requestType = "statusOperation";
/*     */         }
/*     */         
/*  85 */         if ((incoming.contains("<") & incoming.contains(">"))) {
/*  86 */           if (this.log.equals(""))
/*     */           {
/*  88 */             this.log = incoming;
/*     */           }
/*     */           else {
/*  91 */             this.log = (this.log + " " + incoming);
/*     */           }
/*     */           
/*     */         }
/*  95 */         else if (this.header.equals("")) {
/*  96 */           this.header = incoming;
/*     */         }
/*     */         else {
/*  99 */           this.header = (this.header + "\n" + incoming);
/*     */         }
/*     */         
/*     */ 
/* 103 */         if ((incoming.contains("</") & incoming.contains("SOAP") & incoming.contains("Body"))) {
/* 104 */           this.log = (this.log + " " + "</SOAP-ENV:Envelope>");
/* 105 */           break;
/*     */         }
/*     */       }
/*     */       
/*     */ 
/* 110 */       m_log.info("\n#### REQUEST Anfang #### \nFolgende Nachricht wurde vom Server empfangen (Request):\n" + this.header + "\n" + this.log + "\n#### REQUEST ENDE ####");
/*     */       
/* 112 */       SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX");
/*     */       
/* 114 */       if (requestType.equals("regOperation")) {
/* 115 */         this.output.write(register.getProperty("register_http_res").toString());
/* 116 */         this.output.write(register.getProperty("register_http_char").toString());
/* 117 */         this.output.write("Connection: close\r\n");
/* 118 */         this.output.write("\r\n");
/*     */         
/* 120 */         this.output.write(register.getProperty("register").toString().replace("THEDATE", sdf.format(new Date()).toString()));
/* 121 */         m_log.info("\n#### RESPONSE Anfang #### \nFolgende Nachricht wurde vom Server gesendet (Response): \n" + register.getProperty("register").toString().replace("THEDATE", sdf.format(new Date()).toString()) + "#### RESPONSE ENDE ####");
/*     */         
/* 123 */         this.output.write("\r\n");
/*     */       }
/* 125 */       else if (requestType.equals("deregOperation")) {
/* 126 */         this.output.write(deregister.getProperty("dereg_http_res"));
/* 127 */         this.output.write("Content-Type: text/xml;charset=utf-8\r\n");
/* 128 */         this.output.write("Connection: close\r\n");
/* 129 */         this.output.write("\r\n");
/*     */         
/* 131 */         this.output.write(deregister.getProperty("dereg").toString().replace("THEDATE", sdf.format(new Date()).toString()));
/* 132 */         m_log.info("\n#### RESPONSE Anfang #### \nFolgende Nachricht wurde vom Server gesendet (Response): \n" + deregister.getProperty("dereg").toString().replace("THEDATE", sdf.format(new Date()).toString()) + "#### RESPONSE ENDE ####");
/*     */         
/* 134 */         this.output.write("\r\n");
/*     */       }
/* 136 */       else if (requestType.equals("statusOperation")) {
/* 137 */         this.output.write(status.getProperty("status_http_res"));
/* 138 */         this.output.write("Content-Type: text/xml;charset=utf-8\r\n");
/* 139 */         this.output.write("Connection: close\r\n");
/* 140 */         this.output.write("\r\n");
/*     */         
/* 142 */         this.output.write(status.getProperty("status").toString().replace("THEDATE", sdf.format(new Date()).toString()));
/* 143 */         m_log.info("\n#### RESPONSE Anfang #### \nFolgende Nachricht wurde vom Server gesendet (Response): \n" + status.getProperty("status").toString().replace("THEDATE", sdf.format(new Date()).toString()) + "#### RESPONSE ENDE ####");
/*     */         
/* 145 */         this.output.write("\r\n");
/*     */       }
/*     */       
/* 148 */       this.output.close();
/* 149 */       this.reader.close();
/* 150 */       this.rs.close();
/*     */     } catch (Exception ex) {
/* 152 */       m_log.info("An error occurred while receiving incoming message");
/* 153 */       ex.printStackTrace();
/*     */     }
/*     */   }
/*     */ }


/* Location:              /root/testnetzrepository/provisioning-mock-0.3.jar!/de/tsystems/mms/tic/RequestHandler.class
 * Java compiler version: 7 (51.0)
 * JD-Core Version:       0.7.1
 */
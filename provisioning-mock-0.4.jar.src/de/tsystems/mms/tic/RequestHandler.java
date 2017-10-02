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
/*     */   
/*     */ 
/*     */   public RequestHandler(Socket requestSocket)
/*     */   {
/*  35 */     this.rs = requestSocket;
/*     */     try {
/*  37 */       this.reader = new BufferedReader(new InputStreamReader(this.rs.getInputStream()));
/*  38 */       this.output = new BufferedWriter(new OutputStreamWriter(this.rs.getOutputStream()));
/*     */     } catch (IOException e) {
/*  40 */       e.printStackTrace();
/*  41 */       e.getCause().printStackTrace();
/*     */     }
/*     */   }
/*     */   
/*     */   private String getLine() throws IOException {
/*  46 */     return this.reader.readLine();
/*     */   }
/*     */   
/*     */   public void run()
/*     */   {
/*     */     try {
/*  52 */       InputStream input = null;
/*  53 */       input = new FileInputStream("config.properties");
/*     */       
/*  55 */       prop.load(input);
/*     */       
/*  57 */       InputStream registerresponse = null;
/*  58 */       registerresponse = new FileInputStream("register.response.txt");
/*  59 */       register.load(registerresponse);
/*     */       
/*  61 */       InputStream deregisterresponse = null;
/*  62 */       deregisterresponse = new FileInputStream("deregister.response.txt");
/*  63 */       deregister.load(deregisterresponse);
/*     */       
/*  65 */       InputStream statusresponse = null;
/*  66 */       statusresponse = new FileInputStream("status.response.txt");
/*  67 */       status.load(statusresponse);
/*     */       
/*     */ 
/*     */ 
/*  71 */       String requestType = "n/a";
/*     */       
/*     */       String incoming;
/*  74 */       while ((incoming = getLine()) != null) { String incoming;
/*  75 */         incoming.trim();
/*  76 */         if (incoming.contains("urn:#regOperation")) {
/*  77 */           requestType = "regOperation";
/*  78 */         } else if (incoming.contains("urn:#deregOperation")) {
/*  79 */           requestType = "deregOperation";
/*  80 */         } else if (incoming.contains("urn:#statusOperation")) {
/*  81 */           requestType = "statusOperation";
/*     */         }
/*     */         
/*  84 */         if ((incoming.contains("<") & incoming.contains(">"))) {
/*  85 */           if (this.log.equals(""))
/*     */           {
/*  87 */             this.log = incoming;
/*     */           }
/*     */           else {
/*  90 */             this.log = (this.log + " " + incoming);
/*     */           }
/*     */           
/*     */         }
/*  94 */         else if (this.header.equals("")) {
/*  95 */           this.header = incoming;
/*     */         }
/*     */         else {
/*  98 */           this.header = (this.header + "\n" + incoming);
/*     */         }
/*     */         
/*     */ 
/* 102 */         if ((incoming.contains("</") & incoming.contains("SOAP") & incoming.contains("Body"))) {
/* 103 */           this.log = (this.log + " " + "</SOAP-ENV:Envelope>");
/* 104 */           break;
/*     */         }
/*     */       }
/*     */       
/*     */ 
/* 109 */       m_log.info("\n#### REQUEST Anfang #### \nFolgende Nachricht wurde vom Server empfangen (Request):\n" + this.header + "\n" + this.log + "\n#### REQUEST ENDE ####");
/*     */       
/* 111 */       SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX");
/*     */       
/* 113 */       if (requestType.equals("regOperation")) {
/* 114 */         this.output.write(register.getProperty("register_http_res").toString());
/* 115 */         this.output.write(register.getProperty("register_http_char").toString());
/* 116 */         this.output.write("Connection: close\r\n");
/* 117 */         this.output.write("\r\n");
/*     */         
/* 119 */         this.output.write(register.getProperty("register").toString().replace("THEDATE", sdf.format(new Date()).toString()));
/* 120 */         m_log.info("\n#### RESPONSE Anfang #### \nFolgende Nachricht wurde vom Server gesendet (Response): \n" + register.getProperty("register").toString().replace("THEDATE", sdf.format(new Date()).toString()) + "#### RESPONSE ENDE ####");
/*     */         
/* 122 */         this.output.write("\r\n");
/*     */       }
/* 124 */       else if (requestType.equals("deregOperation")) {
/* 125 */         this.output.write(deregister.getProperty("dereg_http_res"));
/* 126 */         this.output.write("Content-Type: text/xml;charset=utf-8\r\n");
/* 127 */         this.output.write("Connection: close\r\n");
/* 128 */         this.output.write("\r\n");
/*     */         
/* 130 */         this.output.write(deregister.getProperty("dereg").toString().replace("THEDATE", sdf.format(new Date()).toString()));
/* 131 */         m_log.info("\n#### RESPONSE Anfang #### \nFolgende Nachricht wurde vom Server gesendet (Response): \n" + deregister.getProperty("dereg").toString().replace("THEDATE", sdf.format(new Date()).toString()) + "#### RESPONSE ENDE ####");
/*     */         
/* 133 */         this.output.write("\r\n");
/*     */       }
/* 135 */       else if (requestType.equals("statusOperation")) {
/* 136 */         this.output.write(status.getProperty("status_http_res"));
/* 137 */         this.output.write("Content-Type: text/xml;charset=utf-8\r\n");
/* 138 */         this.output.write("Connection: close\r\n");
/* 139 */         this.output.write("\r\n");
/*     */         
/* 141 */         this.output.write(status.getProperty("status").toString().replace("THEDATE", sdf.format(new Date()).toString()));
/* 142 */         m_log.info("\n#### RESPONSE Anfang #### \nFolgende Nachricht wurde vom Server gesendet (Response): \n" + status.getProperty("status").toString().replace("THEDATE", sdf.format(new Date()).toString()) + "#### RESPONSE ENDE ####");
/*     */         
/* 144 */         this.output.write("\r\n");
/* 145 */       } else if (requestType.equals("n/a")) {
/* 146 */         this.output.write(status.getProperty("status_http_res"));
/* 147 */         this.output.write("Content-Type: text/xml;charset=utf-8\r\n");
/* 148 */         this.output.write("Connection: close\r\n");
/* 149 */         this.output.write("\r\n");
/*     */         
/* 151 */         this.output.write("blöde kuh\r\n");
/*     */       }
/*     */       
/* 154 */       this.output.close();
/* 155 */       this.reader.close();
/* 156 */       this.rs.close();
/*     */     } catch (Exception ex) {
/* 158 */       m_log.info("An error occurred while receiving incoming message");
/* 159 */       ex.printStackTrace();
/*     */     }
/*     */   }
/*     */ }


/* Location:              /root/testnetzrepository/provisioning-mock-0.4.jar!/de/tsystems/mms/tic/RequestHandler.class
 * Java compiler version: 6 (50.0)
 * JD-Core Version:       0.7.1
 */
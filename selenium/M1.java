import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.firefox.FirefoxDriver;
//comment the above line and uncomment below line to use Chrome
//import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.support.ByIdOrName;
import com.google.common.io.Resources;

import com.google.gson.GsonBuilder;

public class M1 {

	public static void main(String[] args) {

		boolean passed = false;
		
		com.google.gson.GsonBuilder b = new GsonBuilder();
		
		// declaration and instantiation of objects/variables
    	System.setProperty("webdriver.firefox.marionette","/root/temp/geckodriver");
		WebDriver driver = new FirefoxDriver();
		//comment the above 2 lines and uncomment below 2 lines to use Chrome
//		System.setProperty("webdriver.chrome.driver","/root/temp/chromedriver");
//		WebDriver driver = new ChromeDriver();
    	
        String baseUrl = "https://10.10.8.15:4433/";

        // launch Fire fox and direct it to the Base URL
        driver.get(baseUrl);

        WebElement name = driver.findElement(By.id("NAME"));
        WebElement pass = driver.findElement(By.name("PASSWORD"));
        WebElement anmelden_btn = driver.findElement(By.id("btnLogin"));
        
        name.sendKeys("admin");
        pass.sendKeys("123456a!");
        
        anmelden_btn.click();
        
        driver.get("https://10.10.8.15:4433/config/cardterminal/");
        
        WebElement kt_bearbeiten_btn = driver.findElement(By.name("_btn_kt_edit_3"));
        
        kt_bearbeiten_btn.click();
        
        try{
        	WebElement verbinden = driver.findElement(By.id("id_button_change_correlation2"));
        	
        	if(verbinden.isDisplayed()){
        		passed = true;
//        		System.out.println("Test Passed!");
        	}
        	
        } catch (Exception e) {
			// TODO: handle exception
        	
		}
        
        try{
        	WebElement verbinden2 = driver.findElement(By.id("id_button_connect_terminal"));
        	
        	if(verbinden2.isDisplayed()){
        		passed = true;
//        		System.out.println("Test Passed!");
        	}
        }catch (Exception e) {
			// TODO: handle exception
		}
        
        
        try{
        	WebElement verbinden3 = driver.findElement(By.id("id_button_change_correlation1"));
        	
        	if(verbinden3.isDisplayed()){
        		passed = true;
//        		System.out.println("Test Passed!");
        	}
        }catch (Exception e) {
			// TODO: handle exception
		}
        
        driver.close();
        
        if(passed){
        	System.out.println("Test Passed!!!!");
        }else{
        	System.out.println("Test FAILED!!!!");
        }
        
        
        
        
        
        
        
        
        
        
        
    }

}


/*
  
 
javac  -cp /root/workspaceNeon/Web/lib/byte-buddy-1.8.3.jar:/root/workspaceNeon/Web/lib/commons-logging-1.2.jar:/root/workspaceNeon/Web/lib/httpcore-4.4.6.jar:/root/workspaceNeon/Web/lib/client-combined-3.12.0.jar:/root/workspaceNeon/Web/lib/gson-2.8.2.jar:/root/workspaceNeon/Web/lib/okhttp-3.9.1.jar:/root/workspaceNeon/Web/lib/client-combined-3.12.0-sources.jar:/root/workspaceNeon/Web/lib/gson-2.8.5.jar:/root/workspaceNeon/Web/lib/okio-1.13.0.jar:/root/workspaceNeon/Web/lib/commons-codec-1.10.jar:root/workspaceNeon/Web/lib/guava-23.6-jre.jar:/root/workspaceNeon/Web/lib/commons-exec-1.3.jar:/root/workspaceNeon/Web/lib/httpclient-4.5.3.jar:/root/workspaceNeon/Web/lib/selenium-angepasst.jar:.  M1.java 



java  -cp /root/workspaceNeon/Web/lib/byte-buddy-1.8.3.jar:/root/workspaceNeon/Web/lib/commons-logging-1.2.jar:/root/workspaceNeon/Web/lib/httpcore-4.4.6.jar:/root/workspaceNeon/Web/lib/client-combined-3.12.0.jar:/root/workspaceNeon/Web/lib/gson-2.8.2.jar:/root/workspaceNeon/Web/lib/okhttp-3.9.1.jar:/root/workspaceNeon/Web/lib/client-combined-3.12.0-sources.jar:/root/workspaceNeon/Web/lib/gson-2.8.5.jar:/root/workspaceNeon/Web/lib/okio-1.13.0.jar:/root/workspaceNeon/Web/lib/commons-codec-1.10.jar:root/workspaceNeon/Web/lib/guava-23.6-jre.jar:/root/workspaceNeon/Web/lib/commons-exec-1.3.jar:/root/workspaceNeon/Web/lib/httpclient-4.5.3.jar:/root/workspaceNeon/Web/lib/selenium-angepasst.jar:.  M1
  
  
  
  
  
  
  
 */












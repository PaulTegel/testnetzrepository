package konnektor.testsuite._01_Paket1._01_02_Anwendungskonnektor._01_02_06_Kartenterminaldienst._01_02_06_Kartenterminaldienst.TIP1_A_4552_01;

import java.net.URL;
import java.util.concurrent.TimeUnit;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import junit.framework.AssertionFailedError;
import junit.framework.TestCase;
import konnektor.testsuite.general.utils.Utils;
//import environment.EnvironmentManager;
//import environment.RunEnvironment;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.support.ByIdOrName;
import com.google.common.io.Resources;

import com.google.gson.GsonBuilder;
/**
 * The class implements Step 7 from TIP1-A_4552-01
 * 
 * @author Gero Matura, Fraunhofer FOKUS
 *
 */
public class Step7 extends TestCase {
	
	private boolean passed = true;
//	private WebDriver driver;
//	@Before
//	public void setUp() throws Exception {
//		System.out.println();
//	}
	
	@After
	public void tearDown() throws Exception {
		Utils.printTestResult(passed);
	}
	@Before
	public void setUp() throws Exception {
//		DesiredCapabilities capabilities = DesiredCapabilities.firefox();
//		capabilities.setCapability("version", "latest");
//		capabilities.setCapability("platform", Platform.LINUX);
//		capabilities.setCapability("name", "Testing Selenium");
//
//		this.driver = new RemoteWebDriver(
////		   new URL("http://key:secret@hub.testingbot.com/wd/hub"),
//		   new URL("https://10.10.8.15:4433"),
//		   capabilities);
//		driver.manage().timeouts().implicitlyWait(30, TimeUnit.SECONDS);
	}
	
	/*-
	 * Step 7
	 * ------------------------------------------------------------------
     * Description:
     * Aufforderung an Tester: "Bitte bestätigen Sie, dass die Managementschnittstelle Ihnen die Möglichkeit bietet,
     * einen manuellen Verbindungsaufbau zu [KT A] ($Hostname, $IP-Adresse, $MAC-Adresse) auszulösen.
     * Lösen Sie den Verbindungsaufbau noch nicht aus!"
     * 
     * Expected:
     * Tester bestätigt.
	 */
	@Test
	public void test() {
		
		System.out.println("Bitte bestätigen Sie, dass die Managementschnittstelle Ihnen die Möglichkeit bietet,");
		System.out.println("einen manuellen Verbindungsaufbau zu [KT A] ($Hostname, $IP-Adresse, $MAC-Adresse) auszulösen.");
		System.out.println("Lösen Sie den Verbindungsaufbau noch nicht aus!");
		
		
		
		System.setProperty("webdriver.firefox.marionette","/root/temp/geckodriver");
		WebDriver driver = new FirefoxDriver();
    	
        String baseUrl = "https://10.10.8.15:4433/";

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
//        	WebElement verbinden = driver.findElement(By.id("id_button_change_correlation2"));
        	WebElement verbinden = driver.findElement(By.id("id_button_connect_terminal"));
        	
        	if(verbinden.isDisplayed()){
        		System.out.println("Test Passed!");
        	}else{
        		System.out.println("Test Failed");
        	}
        	
        } catch (Exception e) {
			// TODO: handle exception
        	System.out.println("Test Failed");
		} finally {
			
			//close Firefox
			driver.close();
		}
		
		
	}
}









/*




//		try {
//			assertTrue(Utils.getInstance().askUserForYesOrNo("Bietet Ihnen die Managementschnittstelle diese Möglichkeit?"));
//		} catch (AssertionFailedError e) {
//			System.err.println("Der Tester hat NICHT mit ja geantwortet.");
//			passed = false;
//		}
		
//		com.google.gson.GsonBuilder b = new GsonBuilder();
//		b.create();
		
		WebElement name;
		
		// declaration and instantiation of objects/variables
    	System.setProperty("webdriver.firefox.marionette","/root/temp/geckodriver");
    	try {
//    		com.google.gson.GsonBuilder gb = new GsonBuilder();
//    		gb.setLenient();
    		
//    		GsonBuilder gsonBuilder = new GsonBuilder();  
//    		gsonBuilder.setLenient();  
//    		Gson gson = gsonBuilder.create();
    		
//    		org.openqa.selenium.WebDriver driver= new org.openqa.selenium.firefox.FirefoxDriver();// = null;
    		WebDriver driver = new FirefoxDriver();
//    		driver = new FirefoxDriver();
    		driver.close();
		} catch (java.lang.NoSuchMethodError e) {
			// TODO: handle exception
    		System.out.println("handle NoSuchMethodError exception");
    		e.printStackTrace();

		} catch (Exception e) {
			// TODO: handle exception
    		System.out.println("handle exception");
		}
//    	RunEnvironment.setWebDriver(driver);
		//comment the above 2 lines and uncomment below 2 lines to use Chrome
		//System.setProperty("webdriver.chrome.driver","/root/temp/chromedriver");
		//WebDriver driver = new ChromeDriver();
    	
        String baseUrl = "https://10.10.8.15:4433/";

        // launch Fire fox and direct it to the Base URL
//        driver.get(baseUrl);
//
//        name = driver.findElement(By.id("NAME"));
//        WebElement pass = driver.findElement(By.name("PASSWORD"));
//        WebElement anmelden_btn = driver.findElement(By.id("btnLogin"));
//        
//        name.sendKeys("admin");
//        pass.sendKeys("123456a!");
//        
//        anmelden_btn.click();
//        
//        driver.get("https://10.10.8.15:4433/config/cardterminal/");
//        
//        WebElement kt_bearbeiten_btn = driver.findElement(By.name("_btn_kt_edit_3"));
//        
//        kt_bearbeiten_btn.click();
//        
//        try{
//        	WebElement verbinden = driver.findElement(By.id("id_button_change_correlation2"));
//        	
//        	assertTrue(verbinden.isDisplayed());
//        	
////        	if(verbinden.isDisplayed()){
////        		System.out.println("Test Passed!");
////        	}else{
////        		System.out.println("Test Failed");
////        	}
//        	
//        } catch (Exception e) {
//			// TODO: handle exception
//        	System.out.println("Test Failed");
//        	assertTrue(false);
//		} finally {
//			
//			//close Firefox
//			driver.close();
//		}
//		





*/